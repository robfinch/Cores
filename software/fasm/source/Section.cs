using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace fasm
{
	internal class Section
	{
		enum sectype
		{
			MISS = -1,
			TEXT, DATA, BSS, ABS
		}
		System.Collections.Generic.List<Section>? next;
		string? name;
		string? attr;
		System.Collections.Generic.List<Atom>? first;
		System.Collections.Generic.List<Atom>? last;
		Address? align;
		char[]? pad;
		int padbytes;
		UInt32 flags;
		UInt32 memattr;
		Address? org;
		Address? pc;
		UInt64 idx;
	}
}
