using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace fasm
{
	internal class SourceFile
	{
		System.Collections.Generic.List<SourceFile>? SourceFiles;
		System.Collections.Generic.List<IncludePath>? IncludePaths;
		int index;
		string? name;
		string? text;
		UInt64 size;
	}
}
