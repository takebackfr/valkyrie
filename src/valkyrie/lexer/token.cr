module Valkyrie
	class Location
		property file : String?
		property line : Int32
		property col : Int32
		property length : Int32

		def initialize(@file=nil,@line=0,@col=0,@length=0);end

		def to_s
			"#{@file||"buffer"}:#{@line}:#{@col}"
		end

		def to_s(io : IO)
			io<<to_s
		end
	end

	class Token
		enum Type
			Int			# [0-9]+
			Float		# [0-9][0-9_]*\.[0-9]+
			String		# "[^"]+"
			Char		# '.'
			Symbol		# :([a-zA-Z0-9_]+|"[a-zA-Z0-9_]*")
			Regex		# /.+/

			Require		# require
			Namespace	# namespace
			Use			# use
			Func		# fn
			Type		# type
			Struct		# struct

			While		# while
			For			# for
			ForEach		# foreach
			If			# if
			Else		# else
			Do			# do

			Return		# return
			Yield		# yield
			Break		# break
			Next		# next

			Try			# try
			Rescue		# rescue
			Ensure		# ensure
			Raise		# raise

			True		# true
			False		# false
			Null		# null
			Ident		# [a-z][a-zA-Z0-9_]*
			Const		# [A-Z][a-zA-Z0-9_]*
			Self		# self

			Plus		# +
			PlusPlus	# ++
			PlusOp		# +=
			Minus		# -
			MinusMinus	# --
			MinusOp		# -=
			Star		# *
			StarOp		# *=
			Slash		# /
			SlashOp		# /=
			Mod			# %
			ModOp		# %=

			Scope		# ::
			Static		# #
			Arrow		# ->

			Equal		# =
			Match		# =~
			EqualEqual	# ==
			Not			# !
			NotEqual	# !=
			Less		# <
			LessEqual	# <=
			Greater		# >
			GreaterEqual# >=

			Amp			# &
			AmpOp		# &=
			Pipe		# |
			PipeOp		# |=
			Xor			# ^
			XorOp		# ^=
			AndAnd		# &&
			AndAndOp	# &&=
			OrOr		# ||
			OrOrOp		# ||=

			LParen		# (
			RParen		# )
			LBrack		# {
			RBrack		# }
			LBrace		# [
			RBrace		# ]

			Comma		# ,
			Elipses		# ...
			ElipsesIv	# ..
			Dot			# \.
			Colon		# :
			Semi		# ;
			Comment		# //.*$|/\*.*(?!\*/)\*/
			NewLine		# \n
			WhiteSpace	# \s
			EOF			# end of file/script
			Unknown		# unexpected token

			def self.whitespace
				[Comment,WhiteSpace,Unknown]
			end

			def self.keywords
				[True,False,Null,Require,Namespace,Use,Func,Self,Return,Yield,Type,Struct,
				Try,Rescue,Ensure,Raise,If,Else,Do,While,For,ForEach,Next,Break]
			end

			def self.delimiters
				[NewLine,Semi,EOF]
			end

			def self.op_assigns
				[AmpOp,PipeOp,XorOp,PlusOp,MinusOp,StarOp,SlashOp,ModOp]
			end

			def self.unary_ops
				[Plus,PlusPlus,Minus,MinusMinus,Not,Star,Amp]
			end

			def self.binary_ops
				[Plus,Minus,Star,Slash,Equal,Match,Less,LessEqual,Greater,GreaterEqual,
				NotEqual,EqaulEqual,AndAnd,OrOr,And,Or,Xor]
			end

			def self.kw_map
				{
					"true" => True,"false" => False,"null" => Null,"require" => Require,"namespace" => Namespace,
					"use" => Use,"fn" => Func,"self" => Self,"return" => Return,"yield" => Yield,"type" => Type,"struct" => Struct,
					"try" => Try,"rescue" => Rescue,"ensure" => Ensure,"raise" => Raise,"if" => If,"else" => Else,
					"do" => Do,"while" => While,"foreach" => ForEach,"for" => For,"next" => Next,"break" => Break,
				}
			end

			def whitespace?
				self.whitespace.includes? self
			end

			def keyword?
				self.class.keywords.includes? self
			end

			def delimiter?
				self.class.delimiters.includes? self
			end

			def op_assign?
				self.class.op_assigns.includes? self
			end

			def unary_op?
				self.class.unary_ops.includes? self
			end

			def binary_op?
				self.class.binary_ops.includes? self
			end

			def operator?
				unary_op?||binary_op?
			end
		end

		property type : Type
		property loc : Location
		property raw : String
		property value : String?

		def initialize(@type=Type::Unknown,@value=nil,@raw="",@loc=Location.new);end

		def value
			@value||raw
		end

		def to_s
			@value
		end

		def to_s(io : IO)
			io<<to_s
		end

		def inspect(io : IO)
			io<<"#{@type}:#{raw.dump}"
		end
	end
end
