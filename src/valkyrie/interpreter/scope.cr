require "./lib"

module Valkyrie
	class Scope
		property values : Hash(String,Value)
		property parent : Scope?

		def initialize(@parent=nil)
			@values={} of String => Value
		end

		def []?(key : String) : Value?
			@values[key]? || @parent.try &.[key]?
		end

		def [](key : String) : Value?
			self[key]? || raise IndexError.new
		end

		def []=(key : String,value : Value) : Value?
			scope=self
			while scope
				if scope.has_key? key
					return scope.assign key,value
				end
				scope=scope.parent
			end

			assign key,value
		end

		def has_key?(key : String)
			!!@values[key]?
		end

		def assign(key : String,value : Value)
			@values[key]=value
		end
	end
end
