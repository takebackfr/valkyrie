require "./interpreter/*"

module Valkyrie
	class Interpreter
		property stack : Array(Value)
		property sym_table : Scope

		def initialize
			@stack=[] of Value
			@sym_table=Scope.new
		end

		def this_scope
			@sym_table
		end

		def push_scope(sc : Scope=Scope.new)
			scope.parent||=@sym_table
			@sym_table=scope
		end

		def pop_scope
			@sym_table=@sym_table.parent.not_nil! if @sym_table.parent
		end

		def visit(node : Node)
			node.accept_children self
		end
	end
end
