module Valkyrie
	class Reader
		property target : Char
		property pos : Int32
		property buff : IO::Memory

		def initialize(@source : IO)
			@buff=IO::Memory.new
			@pos=0
			@target=read_char
		end

		def read_char : Char
			target=@source.read_char
			target='\0' unless target.is_a? Char

			@pos+=1
			@buff<<target
			target
		end

		def peek_char : Char
			if (slice=@source.peek)&&!slice.empty?
				slice[0].chr
			else
				'\0'
			end
		end

		def empty? : Bool
			if slice=@source.peek
				slice.empty?
			else
				true
			end
		end

		def buff_value : String
			@buff.to_s[0..-2]
		end
	end
end
