using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace fasm
{
	internal class Source
	{
		System.Collections.Generic.List<Source>? parent;
		int parent_line;
		System.Collections.Generic.List<SourceFile>? sourceFile;
		string? name;
		string? text;
		UInt64 size;
		System.Collections.Generic.List<Source>? defsrc;
		int defline;
		System.Collections.Generic.List<Macro>? macro;
		UInt64 repeat;
		string? irpname;
	}
}
