require "./lexer/token"

module Valkyrie
	abstract class Node
		property loc : Location?
		property end_loc : Location?

		macro def_nodes(*nodes)
			{% for node in nodes %}
			property {{node}} : Node
			{% end %}

			def accept_children(vis)
				{% for node in nodes %}
				{{node}}.accept vis
				{% end %}
			end
		end

		def at(@loc)
			self
		end

		def at(node : Node)
			@loc=node.loc
			@end_loc=node.end_loc
			self
		end

		def at(node : Nil)
			self
		end

		def at_end(@end_loc)
			self
		end

		def at_end(node : Node)
			@end_loc=node.end_loc
			self
		end

		def at_end(node : Nil)
			self
		end

		def accept(vis)
			vis.visit self
		end

		def accept_children(vis);end

		def class_desc : String
			{{@type.name.split("::").last.id.stringify}}
		end
	end

	class NoOp < Node
		def_equals_and_hash
	end

	class Expressions < Node
		property children : Array(Node)

		def initialize
			@children=[] of Node
		end

		def initialize(*children)
			@children=children.map{|c| c.as Node}.to_a
		end

		def initialize(other : self)
			@children=other.children
		end

		def accept_children(vis)
			children.each &.accept vis
		end

		def loc
			@loc||@children.first?.try &.loc
		end

		def end_loc
			@end_loc||@children.last?.try &.end_loc
		end

		def_equals_and_hash children
	end

	class Literal < Node
	end

	# null
	class NullLiteral < Literal
		def_equals_and_hash
	end

	# true | false
	class BoolLiteral < Literal
		property value : Bool

		def initialize(@value);end

		def_equals_and_hash value
	end

	# [0-9][0-9_]*
	# 0b[0-9]+
	# 0x[0-9a-fA-F]+
	class IntLiteral < Literal
		property value : String

		def initialize(@value);end

		def_equals_and_hash value
	end

	# [0-9][0-9_]*\.[0-9_]+
	# [0-9][0-9_]*f
	# [0-9][0-9_]*[eE][0-9][0-9_]*
	# [0-9][0-9_]*\.[0-9][0-9_]*[eE][0-9][0-9_]*
	class FloatLiteral < Literal
		property value : String

		def initialize(@value);end

		def_equals_and_hash value
	end

	# "[^"]*"
	class StringLiteral < Literal
		property value : String

		def initialize(@value);end

		def_equals_and_hash value
	end

	# :"[^"]*" | :[^ ]+
	# [^ ]+: (contextual)
	class SymbolLiteral < Literal
		property value : String

		def initialize(@value);end

		def_equals_and_hash value
	end

	# [ (expr | range)... ]
	class VectorLiteral < Literal
		property items : Array(Node)

		def initialize(@items=[] of Node);end

		def accept_children(vis)
			items.each &.accept vis
		end

		def_equals_and_hash items
	end

	# from .. to
	# from ... to
	class RangeLiteral < Literal
		property? inclusive : Bool

		def initialize(@from,@to,@inclusive=false);end

		def_nodes from,to
		def_equals_and_hash from,to,inclusive
	end

	# { entry... }
	# entry = key: value | key => value
	class MapLiteral < Literal
		property entries : Array(Entry)

		record Entry,key : Node,value : Node

		def initialize(@entries=[] of Entry);end

		def accept_children(vis)
			entries.each do |e|
				e.key.accept vis
				e.value.accept vis
			end
		end

		def_equals_and_hash entries
	end

	class RegexLiteral < Literal
		property value : String

		def initialize(@value);end

		def_equals_and_hash value
	end

	# [a-z][a-zA-Z0-9_]*
	class Var < Node
		property name : String

		def initialize(@name);end

		def_equals_and_hash name
	end

	class Underscore < Var
		def initialize(@name="_");end

		def_equals_and_hash name
	end

	# [A-Z][a-zA-Z0-9_]*
	class Const < Node
		property name : String

		def initialize(@name);end

		def_equals_and_hash name
	end

	# ( expr )
	class ValueIpol < Node
		def initialize(@value);end

		def_nodes value
		def_equals_and_hash value
	end

	# self
	class Self < Node
		def_equals_and_hash
	end

	# candidate = expr
	class Assign < Node
		def initialize(@target,@value);end

		def_nodes target,value
		def_equals_and_hash target,value
	end

	# pattern =~ expr
	class MatchAssign < Node
		def initialize(@pattern,@value);end

		def_nodes pattern,value
		def_equals_and_hash pattern,value
	end

	# candidate op= expr
	class OpAssign < Node
		property op : String

		def initialize(@target,@op,@value);end

		def_nodes target,value
		def_equals_and_hash target,op,value
	end

	# if condition { body }[ else { body }]
	# expr if condition [else expr]
	# if condition do expr [else expr]
	class If < Node
		def initialize(@condition,@body=NoOp.new,@alt=NoOp.new);end

		def_nodes condition,body,alt
		def_equals_and_hash condition,body,alt
	end

	# try { body } rescue [ex : Type] { body }
	# try { body } rescue [ex : Type] { body } ensure { body }
	class Try < Node
		property ensure_block : Node?

		def initialize(@body=NoOp.new,@rescue_block=NoOp.new,@ensure_block=nil);end

		def_nodes body,rescue_block
		def_equals_and_hash body,rescue_block,ensure_block
	end

	class Rescue < Node
		property name : String?
		property ex : Node?

		def initialize(@body=NoOp.new,@name=nil,@ex=nil);end

		def_nodes body
		def_equals_and_hash body,name,ex
	end

	# while condition{body}
	# expr while condition
	# while condition do expr
	class While < Node
		def initialize(@condition,@body=NoOp.new);end

		def_nodes condition,body
		def_equals_and_hash condition,body
	end

	# for [init];[condition];[post]{body}
	# for [init];[condition];[post] do expr
	class For < Node
		def initialize(@init=NoOp.new,@condition=NoOp.new,@post=NoOp.new,@body=NoOp.new);end

		def_nodes init,condition,post,body
		def_equals_and_hash init,condition,post,body
	end

	# foreach var... =~ iter { body }
	# expr foreach var... =~ iter
	# foreach var... =~ iter do expr
	class ForEach < Node
		property vars : Array(Node)

		def initialize(@iter=NoOp.new,@vars=[] of Node,@body=NoOp.new);end

		def_nodes iter,body
		def_equals_and_hash vars,iter,body
	end

	abstract class BinaryOp < Node
		def initialize(@left,@right);end

		def_nodes left,right
		def_equals_and_hash left,right
	end

	# |
	class BitwiseOr < BinaryOp
		def_equals_and_hash
	end

	# &
	class BitwiseAnd < BinaryOp
		def_equals_and_hash
	end

	# ^
	class BitwiseXor < BinaryOp
		def_equals_and_hash
	end

	# ||
	class LogicalOr < BinaryOp
		def_equals_and_hash
	end

	# &&
	class LogicalAnd < BinaryOp
		def_equals_and_hash
	end

	abstract class UnaryOp < Node
		def initialize(@value);end

		def_nodes value
		def_equals_and_hash value
	end

	# !val
	class Not < UnaryOp
		def_equals_and_hash
	end

	# ++val
	class PreInc < UnaryOp
		def_equals_and_hash
	end

	# --val
	class PreDec < UnaryOp
		def_equals_and_hash
	end

	# val++
	class PostInc < UnaryOp
		def_equals_and_hash
	end

	# val--
	class PostDec < UnaryOp
		def_equals_and_hash
	end

	# +val
	class Abs < UnaryOp
		def_equals_and_hash
	end

	# -val
	class Neg < UnaryOp
		def_equals_and_hash
	end

	# *val
	class Splat < UnaryOp
		def_equals_and_hash
	end

	# [recv->] name [(] arg... [)]
	# arg op arg
	class Call < Node
		property! receiver : Node?
		property name : String
		property args : Array(Node)

		def initialize(@receiver,@name,@args=[] of Node);end

		def accept_children(vis)
			receiver?.try &.accept vis
			args.each &.accept vis
		end

		def_equals_and_hash receiver?,name,args
	end

	# name | *name | **name | &name
	# name [ : Type]
	class Arg < Node
		property restriction : Node?
		property! name : String?
		property? splat : Bool
		property? kwarg : Bool
		property? block : Bool

		def initialize(@name=nil,@splat=false,@kwarg=false,@block=false,@restriction=nil);end

		def_equals_and_hash name?,splat?,kwarg?,block?
	end

	# fn [name] [( arg... )] { body }
	class Func < Node
		property name : String?
		property args : Array(Arg)
		property! splat_index : Int32?
		property body : Node

		def initialize(@name=nil,@args=[] of Arg,@body=NoOp.new,@splat_index=nil);end

		def_equals_and_hash name,args,splat_index?,body
	end

	# type Const data
	class Type < Node
		property name : String
		property data : Node

		def initialize(@name,@data);end

		def_equals_and_hash name,data
	end

	# struct { mgruop... }
	# mgroup = ident... : Type
	class Struct < Node
		property name : String?
		property members : Array(Member)

		record Member,name : String,type : Node

		def initialize(@members=[] of Member,@name=nil);end

		def_equals_and_hash name,groups
	end

	# namespace ident { body }
	class Namespace < Node
		property name : String
		property body : Node

		def initialize(@name,@body=NoOp.new);end

		def accept_children(vis)
			body.accept vis
		end

		def_equals_and_hash name,body
	end

	# require "path"
	class Require < Node
		property sources : Array(Source)

		record Source,path : String,namespace : Node?

		def initialize(@sources=[] of Source);end

		def_equals_and_hash path
	end

	# use "pragma"
	class Use < Node
		property pragma : Node

		def initialize(@pragma);end

		def accept_children(vis)
			pragma.accept vis
		end

		def_equals_and_hash pragma
	end

	class Control < Node
		property! value : Node?

		def initialize(@value=nil);end

		def accept_children(vis)
			value.try &.accept vis
		end

		def_equals_and_hash value?
	end

	class Return < Control
		def_equals_and_hash
	end

	class Next < Control
		def_equals_and_hash
	end

	class Break < Control
		def_equals_and_hash
	end

	class Yield < Control
		def_equals_and_hash
	end
end
