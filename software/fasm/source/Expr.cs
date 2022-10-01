using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace fasm
{
	internal class Expr
	{
		enum etype {
			ADD, SUB, MUL, DIV, MOD, NEG, CPL, LAND, LOR, BAND, BOR,
			XOR, NOT, LSH, RSH, RSHU, LT, GT, LEQ, GEQ, NEQ, EQ, NUM,
			HUG, FLT, SYM
		};
		etype type;
		System.Collections.Generic.List<Expr>? left;
		System.Collections.Generic.List<Expr>? right;
	}
}
