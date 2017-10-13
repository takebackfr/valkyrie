require "./lexer/token"

module Valkyrie
	class BaseException < Exception
		property loc : Location

		def initialize(@loc,@message="")
			@message="#{@message} at #{@loc}"
		end
	end

	class SyntaxError < BaseException
	end

	class ArgumentError < BaseException
	end

	class ValueError < BaseException
	end
end
