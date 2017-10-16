require "./execptions"
require "./lib/*"

module Valkyrie
	Kernel=Scope.new

	def self.call_func(it,func,*args,receiver : Value?=nil)
		case func
			when TFunctor,TNativeFunc
				it.do_call func,receiver,args.to_a,nil
			else
				raise TypeError.new nil,"func is not callable"
		end
	end

	abstract class Value
		macro inherited
			Methods=Scope.new

			def self.methods
				Methods
			end
		end

		def self.from_literal(lit : Node)
			case lit
				when IntLiteral
					TInt.new lit.value.to_i64
				when FloatLiteral
					TFloat.new lit.value.to_f64
				when StringLiteral
					TString.new lit.value
				when SymbolLiteral
					TSymbol.new lit.value
				when BoolLiteral
					TBool.new lit.value
				when NullLiteral
					TNull.new
				else
					raise TypeError.new nil,"#{lit.class} has no literal value"
			end
		end

		def type_name
			self.class.type_name
		end

		def truthy?
			true
		end
	end

	abstract class TImmutable(T) < Value
		property value : T

		def initialize(@value : T);end

		def to_s
			value.to_s
		end

		def_equals_and_hash value
	end

	class TNull < Value
		# all null references are the same object
		NullObj=TNull.allocate

		def self.type_name
			"Null"
		end

		def self.new
			return NullObj
		end

		def to_s
			"(null)"
		end

		def truthy?
			false
		end

		def_equals_and_hash
	end

	class TBool < TImmutable(Bool)
		def self.type_name
			"Bool"
		end

		def to_s
			@value ? "true" : "false"
		end

		def truthy?
			@value
		end
	end

	class TInt < TImmutable(Int64)
		def self.type_name
			"Int"
		end

		def truthy?
			@value!=0i64
		end
	end

	class TFloat < TImmutable(Float64)
		def self.type_name
			"Float"
		end

		def truthy?
			@value!=0f64
		end
	end

	class TSymbol < TImmutable(UInt64)
		Symbols={} of String => TSymbol
		@@next=0u64

		property name : String

		def initialize(@value,@name);end

		def self.new(name)
			Symbols[name]||=TSymbol.allocate.initialize(@@next+=1,name)
		end

		def self.type_name
			"Symbol"
		end
	end

	class TVector < Value
		property elements : Array(Value)

		def initialize(@elements=[] of Value);end

		def self.type_name
			"Vector"
		end

		def_equals_and_hash elements
	end

	class TMap < Value
		property entries : Hash(Value,Value)

		def initialize(@entries={} of Value => Value);end

		def_equals_and_hash entries
	end

	class TFunctor < Value
		property clauses : Array(Func)
		property parent : Scope

		def initialize(@parent,@clauses=[] of Func);end

		def add_clause(func : Func)
			@clauses<<func
		end

		def_equals_and_hash clauses,parent
	end

	class TNativeFunc < Value
		alias TFunc=(Value?,Array(Value),TFunctor?,Interpreter->Value)
		property impl : TFunc

		def initialize(&@impl : TFunc);end

		def_equals_and_hash impl
	end
end
