require "./lexer/token"

module Valkyrie
	class BaseException < Exception
		property loc : Location?

		def initialize(@loc=nil,@message="")
			@message="#{@message} at #{@loc}" if @loc
		end
	end

	class SyntaxError < BaseException
	end

	class ArgumentError < BaseException
	end

	class ValueError < BaseException
	end

	class TypeError < BaseException
	end
end
