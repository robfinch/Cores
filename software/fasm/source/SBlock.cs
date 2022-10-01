using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace fasm
{
	internal class SBlock
	{
		UInt64 space;
		Expr? space_exp;
		UInt64 size;
		char[]? fill;
		Expr? fill_exp;
		System.Collections.Generic.List<RList>? relocs;
		Address? maxalignbytes;
		UInt32 flags;
	}
}
