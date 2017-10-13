module Valkyrie
	class Parser < Lexer
		def parse_control
			node=if accept Token::Type::Return
				Return.new
			elsif accept Token::Type::Break
				Break.new
			elsif accept Token::Type::Next
				Next.new
			else
				raise SyntaxError.new target.loc,"Expected one of return, break, or next, got #{target.inspect}"
			end
			skip_ws

			unless target.type.delimiter?
				node.value=parse_expr
			end
			node
		end

		def parse_conditional
			if init=accept Token::Type::If
				skip_ws
				cond=parse_expr
				skip_ws
				expect_delim
				skip_ws_newline

				if accept Token::Type::Do
					skip_ws_newline
					body=parse_expr
				elsif accept Token::Type::LBrack
					skip_ws_newline
					body=parse_block
				else
					raise SyntaxError.new init.loc,"Expected do or {, got #{target.inspect}"
				end
				if alt=parse_conditional
					return If.new(cond,body,alt).at(init.loc).at_end alt.loc
				end
			elsif init=accept Token::Type::Else
				skip_ws_newline

				if accept Token::Type::Do
					return parse_expr
				elsif accept Token::Type::LBrack
					body=parse_block
					expect Token::Type::RBrack
					return body
				end
			end
			raise SyntaxError.new target.loc,"Expected if or else, got #{target.inspect}"
		end

		def parse_loop
			if init=accept Token::Type::While
				skip_ws
				cond=parse_expr
				skip_ws
				expect Token::Type::LBrack
				skip_ws_newline

				body=parse_block
				return While.new(cond,body).at(init.loc).at_end expect(Token::Type::RBrack).loc
			elsif init=accept Token::Type::For
				for_op=For.new.at init.loc
				skip_ws_newline
				unless accept Token::Type::Semi
					for_op.init=parse_expr
					skip_ws_newline
					expect Token::Type::Semi
				end
				skip_ws_newline
				unless accept Token::Type::Semi
					for_op.condition=parse_expr
					skip_ws_newline
					expect Token::Type::Semi
				end
				skip_ws_newline
				unless accept Token::Type::LBrack
					for_op.post=parse_expr
					skip_ws_newline
				end
				expect Token::Type::LBrack
				skip_ws_newline
				for_op.body=parse_block
				return for_op.at_end expect(Token::Type::RBrack).loc
			elsif init=accept Token::Type::ForEach
				skip_ws
				for_e=ForEach.new.at init.loc
				loop do
					if expect Token::Type::Ident
						for_e.vars<<parse_var_call
					end
					skip_ws
					break unless accept Token::Type::Comma
				end
				expect Token::Type::Match
				skip_ws_newline
				for_e.iter=parse_expr
				expect Token::Type::LBrack
				skip_ws_newline
				for_e.body=parse_block
				return for_e.at_end expect(Token::Type::RBrack).loc
			end
			raise SyntaxError.new target.loc,"Expected for, foreach, or while, got #{target.inspect}"
		end

		def parse_ex_handle
			init=expect Token::Type::Try
			want_type=false
			try_op=Try.new.at init.loc

			skip_ws_newline
			expect Token::Type::LBrack
			skip_ws_newline
			try_op.body=parse_block
			expect Token::Type::RBrack

			skip_ws_newline
			r_init=expect Token::Type::Rescue
			rescue_op=Rescue.new.at r_init.loc

			skip_ws
			if var=accept Token::Type::Ident
				skip_ws
				rescue_op.name=var.value
				if accept Token::Type::Colon
					skip_ws
					want_type=true
				end
			end

			if const=accept Token::Type::Const
				rescue_op.ex=parse_primary
			elsif want_type
				raise SyntaxError.new target.loc,"Expected type restriction"
			end

			skip_ws_newline
			expect Token::Type::LBrack
			rescue_op.body=parse_block
			expect Token::Type::RBrack
			try_op.rescue_block=rescue_op

			skip_ws_newline
			if accept Token::Type::Ensure
				skip_ws_newline
				expect Token::Type::LBrack
				try_op.ensure_block=parse_block
				expect Token::Type::RBrack
			end
			try_op
		end

		def parse_logic_or
			left=parse_logic_and
			skip_ws

			if accept Token::Type::OrOr
				skip_ws_newline
				right=parse_logic_or
				return LogicalOr.new(left,right).at(left).at_end right
			end
			left
		end

		def parse_logic_and
			left=parse_equality
			skip_ws

			if accept Token::Type::AndAnd
				skip_ws_newline
				right=parse_logic_and
				return LogicalAnd.new(left,right).at(left).at_end right
			end
			left
		end
	end
end
