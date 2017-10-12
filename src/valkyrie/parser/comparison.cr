module Valkyrie
	class Parser < Lexer
		def parse_equality
			left=parse_comparative
			skip_ws

			if op=accept Token::Type::EqualEqual,Token::Type::NotEqual
				skip_ws_newline
				right=parse_equality
				return Call.new(left,op.value,[right] of Node).at(left).at_end right
			end
			left
		end

		def parse_comparative
			left=parse_add
			skip_ws

			if op=accept Token::Type::Less,Token::Type::LessEqual,Token::Type::Greater,Token::Type::GreaterEqual
				skip_ws_newline
				right=parse_comparative
				return Call.new(left,op.value,[right] of Node).at(left).at_end right
			end
			left
		end

		def parse_add(left=nil)
			left||=parse_mult
			skip_ws

			if op=accept Token::Type::Plus,Token::Type::Minus
				skip_ws_newline
				right=parse_mult
				return parse_add Call.new(left,op.value,[right] of Node).at(left).at_end right
			end
			left
		end

		def parse_mult(left=nil)
			left||=parse_assign
			skip_ws

			if op=accept Token::Type::Star,Token::Type::Slash,Token::Type::Mod
				skip_ws_newline
				if right=parse_assign
					return parse_mult Call.new(left,op.value,[right] of Node).at(left.loc).at_end right
				end
			end
			left
		end

		def parse_assign
			candidate=parse_unary
			skip_ws
			if accept Token::Type::Equal
				skip_ws_newline
				p @target
				value=parse_expr
				return Assign.new(candidate,value).at(candidate.loc).at_end value.end_loc
			elsif accept Token::Type::Match
				skip_ws_newline
				value=parse_expr
				return MatchAssign.new(to_pattern(candidate),value).at(candidate.loc).at_end value.end_loc
			elsif (op=target).type.op_assign?
				read_token
				skip_ws_newline
				value=parse_expr
				return OpAssign.new(candidate,op.value,value).at(candidate.loc).at_end value.end_loc
			end
			candidate
		end

		def parse_unary
			if init=accept Token::Type::Not
				skip_ws
				if value=parse_unary
					return Not.new(value).at(init.loc).at_end value
				end
			elsif init=accept Token::Type::Minus
				skip_ws
				if value=parse_unary
					return Neg.new(value).at(init.loc).at_end value
				end
			elsif init=accept Token::Type::Star
				skip_ws
				if value=parse_unary
					return Splat.new(value).at(init.loc).at_end value
				end
			end
			parse_postfix
		end

		def parse_postfix(receive=nil)
			receive||=parse_primary

			skip_ws
			if accept Token::Type::Dot
				skip_ws_newline
				return parse_postfix parse_var_call receive
			elsif accept Token::Type::LBrace
				skip_ws_newline
				call=Call.new receive,"[]"

				loop do
					skip_ws_newline
					call.args<<parse_expr
					skip_ws_newline

					unless accept Token::Type::Comma
						finish=expect Token::Type::RBrace
						call.at_end finish.loc
						break
					end
				end
			end
			receive
		end

		def parse_primary
			case target.type
				when Token::Type::LParen
					accept Token::Type::LParen
					skip_ws_newline

					expr=parse_expr
					skip_ws_newline

					expect Token::Type::RParen
					skip_ws_newline
					return expr
				when Token::Type::Self
					tok=target
					read_token
					return Self.new.at tok.loc
				when Token::Type::Const
					tok=target
					read_token
					return Const.new tok.value
				when Token::Type::Less
					parse_value_ipol
				when Token::Type::Ident
					parse_var_call
				else
					parse_literal
			end
		end

		def parse_value_ipol
			init=expect Token::Type::LParen
			skip_ws_newline
			val=parse_unary
			skip_ws_newline
			ValueIpol.new(val).at(init.loc).at_end expect(Token::Type::RParen).loc
		end

		def parse_var_call(receive=nil)
			init=expect Token::Type::Ident,Token::Type::Const
			name=init.value

			if receive.nil?
				if name=="_"
					return Underscore.new.at init.loc
				elsif is_local? name
					return Var.new(name).at init.loc
				end
			end

			call=Call.new(receive,name).at init.loc
			skip_ws
			if accept Token::Type::LParen
				skip_ws_newline
				if finish=accept Token::Type::RParen
					call.at_end finish.loc
				else
					loop do
						skip_ws_newline
						call.args<<parse_expr
						skip_ws_newline

						unless accept Token::Type::Comma
							finish=expect Token::Type::RParen
							call.at_end finish.loc
						end
					end
				end
			end

			call
		end
	end
end
