using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace fasm
{
	internal class PrintExpr
	{
		enum pxtype { HEX, SDEC, UDEC, BIN, ASC };
		System.Collections.Generic.List<Expr>? print_exp;
		pxtype type;
		short size;
	}
}
