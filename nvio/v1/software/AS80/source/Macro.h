#ifndef _MACRO_H
#define _MACRO_H

class Macro
{
public:
	char *SubArg(char *bdy, int n, char *sub);
	char *GetArg();
	char *GetBody(char *parmlist[]);
	int GetParmList(char *[]);
	void Substitute(char *, int);
};

#endif
