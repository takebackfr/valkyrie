module Valkyrie
	class Reader
		property source : IO
		property buff : IO::Memory
		property target : Char
		property pos : Int32

		def initialize(@source : IO)
			@buff=IO::Memory.new
			@pos=0
			@target=read_char
		end

		def read_char : Char
			c=@source.read_char
			c='\0' unless c.is_a? Char

			@target=c
			@pos+=1
			@buff<<c
			c
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
