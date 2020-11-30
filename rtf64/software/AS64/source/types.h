#ifndef _TYPES_H
#define _TYPES_H

// Compressed instructions table entry

typedef struct _tagHBLE
{
	int count;
	int64_t opcode;
} HTBLE;

class Arg
{
public:
	std::string text;
public:
	void Get();
	void Clear();
};

class Arglist
{
public:
	int count;
	Arg args[20];
public:
	void Get();
};

class Macro
{
public:
	static int inst;
	char *body;	// template for macro body
	Arglist parms;
public:
	char *SubArgs(Arglist *al);
	//char *GetArg();
	char *GetBody();
	int GetParmList();
	static void Substitute(char *, int);
};

class FileInfo
{
public:
	std::string name;
	int lineno;
};

class FilenameStack
{
public:
	FileInfo stack[21];
	int sp;
public:
	FilenameStack() { sp = 0; };
	void Push(std::string nm, int ln) {
		if (sp > 20) {
			printf("Too many nested files.\n");
			return;
		}
		stack[sp].name = nm;
		stack[sp].lineno = ln;
		sp++;
	}
	void Pop(std::string *nm, int *ln) {
		if (sp == 0) {
			printf("Filename stack underflow.\n");
			return;
		}
		--sp;
		*nm = stack[sp].name;
		*ln = stack[sp].lineno;
	}
	FileInfo *GetTos() {
		return (&stack[sp - 1]);
	}
};

typedef struct _tagInsnStats {
	int loads;
	int stores;
	int pushes;
	int indexed;
	int compares;
	int branches;
	int beqi;
	int bnei;
	int bbc;
	int logbr;
	int calls;
	int rets;
	int adds;
	int subs;
	int ands;
	int ors;
	int xors;
	int bits;
	int tsts;
	int shls;
	int shifts;
	int luis;
	int moves;
	int cmoves;
	int sets;
	int mops;
	int floatops;
	int ptrdif;
	int csrs;
	int bitfields;
	int beqz;
	int total;
} InsnStats;

class CPU {
public:
	virtual int NextToken();
	virtual void ProcessMaster();
};

class rtf64 : public CPU {
	int NextToken();
	void ProcessMaster();
};

#endif
