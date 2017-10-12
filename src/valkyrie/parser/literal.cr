module Valkyrie
	class Parser < Lexer
		macro def_lit_cases(types)
			case (tok=read_token).type
				{% for type,init in types %}
				when Token::Type::{{type}}
					read_token
					{% if init[1]==nil %}
					{{init[0]}}Literal.new.at tok.loc
					{% else %}
					{{init[0]}}Literal.new({{init[1]}}).at tok.loc
					{% end %}
				{% end %}
				when Token::Type::LBrace
					parse_list_literal
				when Token::Type::LBrack
					parse_map_literal
				else
					raise ValueError.new "Expected literal value, got #{target.inspect}"
			end
		end

		def parse_literal
			def_lit_cases({
				Null: [Null,nil],
				True: [Bool,true],
				False: [Bool,false],
				Int: [Int,tok.value],
				Float: [Float,tok.value],
				String: [String,tok.value],
				Symbol: [Symbol,tok.value],
				Regex: [Regex,tok.value],
			})
		end

		def parse_list_literal
			init=expect Token::Type::LBrace
			list=VectorLiteral.new.at init.loc

			skip_ws_newline
			if finish=accept Token::Type::RBrace
				return list.at_end finish.loc
			end

			loop do
				item=parse_expr
				skip_ws_newline

				if accept Token::Type::Comma
					list.items<<item
					skip_ws_newline
					next
				elsif accept(Token::Type::Dot)&&accept Token::Type::Dot
					incv=!!accept Token::Type::Dot
					skip_ws_newline
					r_end=parse_expr
					list.items<<RangeLiteral.new(item,r_end).at(item.loc).at_end r_end.end_loc
				end

				if finish=accept Token::Type::RBrace
					return list.at_end finish.loc
				end
			end
		end

		def parse_map_literal
			init=expect Token::Type::LBrack
			map=MapLiteral.new.at init.loc

			skip_ws_newline
			if finish=accept Token::Type::RBrack
				return map.at_end finish.loc
			end

			loop do
				key=parse_map_key
				skip_ws_newline
				map.entries<<MapLiteral::Entry.new key: key,value: parse_expr

				skip_ws_newline
				if accept Token::Type::Comma
					skip_ws_newline
					next
				end
				if finish=accept Token::Type::RBrack
					return map.at_end finish.loc
				end
			end
		end

		def parse_map_key
			key=case target.type
				when Token::Type::Ident
					name=expect Token::Type::Ident
					SymbolLiteral.new(name.value).at name.loc
				when Token::Type::LParen
					parse_value_ipol
				else
					raise ValueError.new "#{target} is not a valid map key"
			end

			expect Token::Type::Colon
			return key
		end

		def parse_struct
			init=expect Token::Type::Struct
			struct_def=Struct.new.at init.loc
			skip_ws_newline
			if name=accept Token::Type::Ident
				struct_def.name=name
				skip_ws_newline
			end
			expect Token::Type::LBrack
			skip_ws_newline
			if finish=accept Token::Type::RBrack
				return struct_def.at_end finish.loc
			end

			loop do
				group=[] of String
				loop do
					group<<expect(Token::Type::Ident).value
					skip_ws
					break unless accept Token::Type::Comma
				end

				expect Token::Type::Colon
				g_type=expect Token::Type::Const
				skip_ws_newline

				group.each do |name|
					struct_def.members<<Struct::Member.new name,g_type
				end

				if finish=accept Token::Type::RBrack
					return struct_def.at_end finish.loc
				end
				expect_delim
			end
		end
	end
end
