module Valkyrie
	class Parser < Lexer
		# parse a block
		def parse_block
			block=nil
			skip_ws_newline

			until target.type==Token::Type::RBrack
				block||=Expressions.new
				block.children<<parse_expr
				skip_ws

				break if target.type==Token::Type::RBrack
				expect_delim_eof
				skip_ws_newline
			end

			block||NoOp.new
		end

		# dispatch expression parsing
		def parse_expr
			case target.type
				when Token::Type::Func
					parse_func
				when Token::Type::Namespace
					parse_namespace
				when Token::Type::Require
					parse_require
				when Token::Type::Return,Token::Type::Break,Token::Type::Next,Token::Type::Yield
					parse_control
				when Token::Type::If,Token::Type::Else
					parse_conditional
				when Token::Type::For,Token::Type::While
					parse_loop
				else
					parse_logic_or
			end
		end

		# parse function definition
		def parse_func
			init=expect Token::Type::Func
			skip_ws
			ident=expect(Token::Type::Ident).value
			fn_def=Func.new(ident).at init.loc
			push_scope

			skip_ws
			if accept Token::Type::LParen
				skip_ws_newline
				unless accept Token::Type::RParen
					can_splat=true
					arg_index=0
					loop do
						skip_ws_newline
						next_arg=parse_arg can_splat
						skip_ws_newline

						if next_arg.splat?
							can_splat=false
							fn_def.splat_index=arg_index
						end

						fn_def.args<<next_arg
						arg_index+=1

						unless accept Token::Type::Comma
							expect Token::Type::RParen
						end
					end
				end
			end

			skip_ws
			expect Token::Type::LBrack
			skip_ws_newline
			if finish=accept Token::Type::RBrack
				fn_def.body=NoOp.new
			else
				fn_def.body=parse_block
				finish=expect Token::Type::RBrack
			end

			pop_scope
			fn_def.at_end finish.loc
		end

		# parse function argument
		def parse_arg(can_splat=true)
			arg=Arg.new
			if init=accept Token::Type::Star
				if can_splat
					arg.splat=true
					name=expect Token::Type::Ident
					push_var name.value
					arg.name=name.value
					return arg.at(init.loc).at_end name.loc
				else
					raise ArgumentError.new "Splat patterns are limited to one per function"
				end
			elsif init=accept Token::Type::Amp
				arg.block=true
				name=expect Token::Type::Ident
				arg.name=name.value
				return arg.at(init.loc).at_end name.loc
			elsif name=accept Token::Type::Ident
				arg.name=name.value
				push_var name.value
				arg.at name.loc
			elsif accept Token::Type::Match
				skip_ws
				name=expect Token::Type::Ident
				push_var name.value
				arg.name=name.value
				arg.at_end name.loc
			end

			skip_ws
			if accept Token::Type::Colon
				skip_ws
				rst=expect Token::Type::Const
				arg.restriction=Const.new(rst.value).at rst.loc
				arg.at_end rst.loc
			end

			arg
		end

		# parse type definitions
		def parse_type
			init=expect Token::Type::Type
			skip_ws
			name=expect(Token::Type::Const).value
			skip_ws

			if accept Token::Type::Struct
				data=parse_struct
			else
				data=expect Token::Type::Const
			end
			Type.new(name,data).at(init.loc).at_end data.end_loc
		end

		# parse require statements
		def parse_require
			req=Require.new.at expect(Token::Type::Require).loc
			skip_ws

			loop do
				if source=accept Token::Type::String
					req.sources<<Require::Source.new path: source.value,namespace: nil
				elsif source=parse_map_key
					req.sources<<Require::Source.new path: expect(Token::Type::String).value,namespace: source
				else
					raise ValueError.new "Cannot use #{target.inspect} (type #{target.type}) in require"
				end
				skip_ws_newline
				break unless accept Token::Type::Comma
				skip_ws_newline
			end
			req
		end

		# parse namespace definitions
		def parse_namespace
			init=expect Token::Type::Namespace
			skip_ws
			ns=Namespace.new(expect(Token::Type::Const).value).at init.loc
			skip_ws_newline
			expect Token::Type::LBrack
			skip_ws_newline

			if finish=accept Token::Type::RBrack
				return ns.at_end finish.loc
			end

			ns.body=parse_block
			return ns.at_end expect(Token::Type::RBrack).loc
		end

		# parse pragmas
		def parse_use
			init=expect Token::Type::Use
			skip_ws
			pragma=expect Token::Type::String
			return Use.new(pragma).at(init.loc).at_end pragma.end_loc
		end
	end
end
