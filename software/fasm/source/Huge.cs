using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace fasm
{
	internal class Huge
	{
		const double MAX_UINT64_FLOAT = 1.8446744073709551616e+19;
		UInt64 hi;
		UInt64 lo;
		int sign(Huge h) { return (int)((h.hi >> 63) & 1); }
	}
}
