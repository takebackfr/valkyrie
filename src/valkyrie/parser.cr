require "./parser/*"
require "./lexer"

module Valkyrie
	class Parser < Lexer
		@locals : Array(Set(String))

		def initialize(source : IO,fname : String?=nil,wd : String?=nil)
			super source,fname,wd
			@locals=[Set(String).new]
			read_token
		end

		def self.from_file(source : String)
			new File.open(source),source,File.expand_path(File.dirname source)
		end

		# skip whitespace
		def skip_ws : Token
			skip_tokens Token::Type.whitespace
		end

		# skip ws + newline
		def skip_ws_newline : Token
			skip_tokens Token::Type.whitespace+[Token::Type::NewLine]
		end

		# accept token type(s)
		def accept(*types : Token::Type) : Token?
			if types.includes? @target.type
				tok=@target
				read_token
				return tok
			end
		end

		# expect token type(s)
		def expect(*types : Token::Type) : Token?
			accept(*types)||raise SyntaxError.new @target.loc,"Expected one of #{types.join ','}; got #{@target.type}"
		end

		# expect a delimiter type
		def expect_delim : Token?
			expect Token::Type::Semi,Token::Type::NewLine
		end

		# expect delim or EOF
		def expect_delim_eof : Token?
			expect Token::Type::Semi,Token::Type::NewLine,Token::Type::EOF
		end

		# skip token type(s)
		private def skip_tokens(types : Array(Token::Type)) : Token
			while types.includes? @target.type
				read_token
			end
			@target
		end

		def push_scope(scope : Set(String)=Set(String).new)
			@locals.push scope
		end

		def pop_scope
			@locals.pop
		end

		def push_var(name : String)
			@locals.last.add name
		end

		def is_local?(name : String) : Bool
			@locals.last.includes? name
		end

		private def to_lhs(node)
			case node
				when Var
					push_var node.name
				when Underscore
					push_var node.name
					return node
				when Const
					return node
				when Call
					if node.receiver?||!node.args.empty?
						return node
					else
						push_var node.name
						return Var.new(node.name).at node
					end
				when Literal
					raise ValueError.new "Can't assign to literal value"
				else
					raise ValueError.new "Invalid left hand side in assignment: #{node}"
			end
		end

		private def to_pattern(node)
			case node
				when Var,Underscore
					push_var node.name
					return node
				when Const
					return node
				when Call
					if node.receiver?||!node.args.empty?
						raise ArgumentError.new "Calls are prohibited in pattern matching"
					else
						push_var node.name
						return Var.new(node.name).at node
					end
				when ListLiteral
					node.items=node.items.map{|i| to_pattern(i).as Node}
				when MapLiteral
					node.entries=node.entries.map{|e| MapLiteral::Entry.new e.key,to_pattern(e.value).as Node}
			end

			return node
		end

		# main parse method
		def parse
			prog=Expressions.new
			skip_ws_newline

			until accept Token::Type::EOF
				prog.children<<parse_expr
				expect_delim_eof
				skip_ws_newline
			end
			prog
		end
	end
end
