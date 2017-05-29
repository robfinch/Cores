#pragma once

namespace RTFClasses
{
	class SymbolTable;
	class String;

	class FileInfo
	{
	public:
		String name;       // File name
		int LastLine;     // Line number processed
		int errors;       // Number of errors.
		int warnings;     // Number of warnings
		FILE *fp;			// file pointer for end pseudo-op
		SymbolTable *lst;  // local symbol table
		AsmBuf *buf;
		int length;
		bool bGlobalEquates;
	public:
		AsmBuf *getBuf() { return buf; };
		int load(char *);
		FileInfo(void);
		~FileInfo(void);
	};
}
