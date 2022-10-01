using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace fasm
{
	internal class Atom
	{
		System.Collections.Generic.List<Atom> atoms;
		enum AtomType
		{
			FASMDEBUG,
			LABEL,
			DATA,
			INSTRUCTION,
			SPACE,
			DATADEF,
			OPTS,
			PRINTTEXT,
			PRINTEXPR,
			ROFFS,
			RORG,
			RORGEND,
			ASSERT,
			NLIST
		}
		AtomType type;
		Address align;
		UInt64 last_size;
		UInt64 changes;
		Source src;
		int line;
		System.Collections.Generic.List<Listing>? list;
		System.Collections.Generic.List<Instruction>? instructions;
		System.Collections.Generic.List<DBlock>? db;
		System.Collections.Generic.List<Symbol>? label;
		System.Collections.Generic.List<SBlock>? sb;
		System.Collections.Generic.List<Defblock>? defb;
		int srcline;
		string? ptext;
		System.Collections.Generic.List<PrintExpr>? pexpr;
		System.Collections.Generic.List<Reloffs>? roffs;
		System.Collections.Generic.List<Address>? rorg;
		System.Collections.Generic.List<Assertion>? assert;
		System.Collections.Generic.List<Aoutnlist>? nlist;
	}
}
