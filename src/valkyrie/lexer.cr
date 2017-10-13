require "./lexer/*"
require "./exceptions"

module Valkyrie
	class Lexer
		property target_char : Char	# current character
		property target : Token		# token being parsed
		property tokens : Array(Token)	# list of parsed tokens
		property reader : Reader	# reader
		property wd : String		# working directory

		property line : Int32
		property col : Int32

		@buff : IO::Memory	# buffer
		@source : String?

		# initializer method
		# @source -- source file name
		def initialize(data : IO,@source=nil,wd : String?=nil)
			@reader=Reader.new data
			@wd=wd||(@source ? File.dirname(source||"") : %x(pwd))

			@line=1
			@col=0
			@target=Token.new
			@buff=IO::Memory.new
			@tokens=[] of Token

			@target_char=' '
		end

		macro set_type(type)
			@target.type=Token::Type::{{type}}
			read_char
		end

		macro def_has_op(char,typea,typeb=nil)
			set_type {{typea}}
			{% if typeb %}
			if target_char=={{char}}
				set_type {{typeb}}{{typeb}}
			end
			{% end %}
			if target_char=='='
				case target.type
				when Token::Type::{{typea}}
						set_type {{typea}}Op
					{% if typeb %}
					when Token::Type::{{typeb}}{{typeb}}
						set_type {{typeb}}{{typeb}}Op
					{% end %}
				end
			end
		end

		macro def_equality(type)
			set_type {{type}}
			if target_char=='='
				set_type {{type}}Equal
			end
		end

		private def assign_numeric(is_fp)
			@target.value=@reader.buff_value.tr "_",""
			@target.type=is_fp ? Token::Type::Float : Token::Type::Int
		end

		# read all tokens until EOF
		def lex
			until @target.type==Token::Type::EOF
				read_token
			end
			tokens
		end

		# buffer next token
		def next_token
			@target=Token.new
			@target.loc.file=@source
			@target.loc.line=@line
			@target.loc.col=@col
		end

		def target_char : Char
			@reader.target
		end

		# location of the target token
		def location : Location
			@target.loc
		end

		# consume a char from the reader
		def read_char : Char
			if target_char=='\n'
				@line+=1
				@col=0
			end
			@col+=1
			@target.loc.length+=1

			@reader.read_char
		end

		# peek (read, don't consume) at the reader's content
		def peek_char : Char
			@reader.peek_char
		end

		# check if reader is empty
		def finished?
			@reader.empty?
		end

		# read a token
		def read_token : Token
			next_token	# get next token
			@target.type=Token::Type::Ident	# default token type to ident

			case target_char
				when '\0'
					set_type(EOF)
				when ','
					set_type(Comma)
				when '.'
					set_type(Dot)
					if target_char=='.'
						set_type(ElipsesIv)
						if target_char=='.'
							set_type(Elipses)
						end
					end
				when '&'
					def_has_op('&',Amp,And)
				when '|'
					def_has_op('|',Pipe,Or)
				when '^'
					def_has_op('^',Xor)
				when '='
					set_type(Equal)
					if target_char=='='
						set_type(EqualEqual)
					elsif target_char=='~'
						set_type(Match)
					end
				when '!'
					def_equality(Not)
				when '<'
					def_equality(Less)
				when '>'
					def_equality(Greater)
				when '+'
					def_has_op('+',Plus)
				when '-'
					def_has_op('-',Minus)
					if target_char=='>'
						set_type(Arrow)
					end
				when '*'
					set_type(Star)
					if target_char=='='
						set_type(StarOp)
					end
				when '/'
					set_type(Slash)
					if target_char=='='
						set_type(SlashOp)
					elsif target_char=='/'
						consume_comment
					elsif target_char=='*'
						consume_comment true
					else
						consume_regex
					end
				when '%'
					set_type(Mod)
					if target_char=='='
						set_type(ModOp)
					end
				when '\n'
					set_type(NewLine)
				when '"'
					@target.type=Token::Type::String
					consume_string
				when ':'
					if peek_char==':'
						set_type(Scope)
					else
						consume_sym_or_col
					end
				when '#'
					set_type(Static)
				when ';'
					set_type(Semi)
				when '('
					set_type(LParen)
				when ')'
					set_type(RParen)
				when '['
					set_type(LBrace)
				when ']'
					set_type(RBrace)
				when '{'
					set_type(LBrack)
				when '}'
					set_type(RBrack)
				when '0'..'9'
					consume_numeric
				when .ascii_whitespace?
					consume_ws
				when 'A'..'Z'
					consume_const
				else
					consume_ident
					check_kw
			end

			finalize_target
		end

		# finalize token creation
		def finalize_target : Token
			@target.raw=@reader.buff_value

			@reader.buff.clear
			@reader.buff<<target_char

			@tokens.push @target
			@target
		end

		# try to lex buffer as a keyword
		def check_kw
			if t_keyword=Token::Type.kw_map[@reader.buff_value]?
				@target.type=t_keyword
			end
		end

		# consume a numeric value
		def consume_numeric
			is_fp=false	# floating point flag

			loop do
				case target_char
					when '.'
						if !is_fp&&peek_char.ascii_number?
							read_char
							is_fp=true
						else
							assign_numeric(is_fp)
							break
						end
					when '_'
						read_char
					when .ascii_number?
						read_char
					else
						break
				end
			end

			assign_numeric is_fp
		end

		def consume_string
			read_char # read opening quote

			loop do
				case target_char
					when '"'
						# read closing quote & break
						read_char
						break
					when '\\'
						# read two characters for escape
						read_char
						read_char
					else
						read_char
				end
			end

			# replace escapes
			@target.value=@reader.buff_value.gsub /\\./ do |c|
				case c
					when "\\n" then '\n'
					when "\\\"" then '"'
					when "\\t" then '\t'
				end
			end

			@target.value=@target.value[1..-2]
		end

		def consume_regex
			read_char # read initial /

			loop do
				case target_char
					when '/'
						read_char
					when '\\'
						read_char
						read_char
					else
						read_char
				end
			end

			@target.value=@target.value[1..-2]
		end

		def consume_sym_or_col
			read_char # read colon
			force_sym=false

			case target_char
				when '"'
					consume_string
					force_sym=true
				else
					consume_ident
			end

			if force_sym||@target.value.size>1
				@target.type=Token::Type::Symbol
				@target.value=@target.value[1..-1]
			else
				@target.type=Token::Type::Colon
			end
		end

		def consume_comment(multi=false)
			if multi
				last_char=read_char
				until last_char=='*'&&(last_char=read_char)=='/';end
			else
				until ['\n','\0'].includes? read_char;end
			end
		end

		def consume_ws
			@target.type=Token::Type::WhiteSpace
			while(c=read_char).ascii_whitespace?&&'\n'!=c;end
		end

		def consume_const
			if target_char.ascii_uppercase?
				read_char
			else
				raise SyntaxError.new location,"Unexpected #{target_char} for Const. Buffer: `#{@reader.buff_value}`"
			end
			@target.type=Token::Type::Const

			loop do
				if target_char.ascii_alphanumeric?||target_char=='_'
					read_char
				else
					break
				end
			end
			@target.value=@reader.buff_value
		end

		def consume_ident
			unless target_char.ascii_letter?||target_char=='_'
				raise SyntaxError.new location,"Unexpected #{target_char} for Ident. Buffer: `#{@reader.buff_value}`"
			end

			loop do
				if target_char.ascii_alphanumeric?||target_char=='_'
					read_char
				else
					break
				end
			end
			@target.value=@reader.buff_value
		end
	end
end
