#ifndef _TYPES_H
#define _TYPES_H

class Arg
{
public:
	char text[120];
public:
	void Get();
	void Clear();
};

class Arglist
{
public:
	int count;
	Arg args[10];
public:
	void Get();
};

class Macro
{
public:
	static int inst;
	char *body;	// template for macro body
public:
	char *SubArgs(Arglist *args);
	char *GetArg();
	char *GetBody(char *parmlist[]);
	int GetParmList(char *[]);
	void Substitute(char *, int);
};

#endif
