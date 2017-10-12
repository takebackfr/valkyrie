require "./lexer/token"

module Valkyrie
	class SyntaxError < Exception
		property loc : Location

		def initialize(@loc,msg : String="")
			@messge="Syntax error: #{msg} at #{@loc}"
		end
	end

	class ArgumentError < Exception
	end

	class ValueError < Exception
	end
end
