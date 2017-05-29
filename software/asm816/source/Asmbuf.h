#pragma once

#include "MyString.h"
#include "buf.h"

namespace RTFClasses
{
	typedef struct
	{
		__int64 value;
		char size;
		bool fLabel;
		bool fForcedSize;
		bool fForwardRef;	// True if expression possibly
							// contains forward reference
		bool bDefined;
	} Value;

	class AsmBuf : public Buf
	{
		void relational(Value *);
		void orExpr(Value *);
		void andExpr(Value *);
		void expr(Value *);
		void term(Value *);
		void factor(Value *);
		void func(Value *, int);
		void constant(Value *);
		bool isFunc(char *str) const;
		char getSizeCh(char, char);
	public:
		AsmBuf(int n) : Buf(n) {};
		AsmBuf(char *p, int n) : Buf(p,n) {};
		String *getArg();
		int getParmList(String *[]);
		Value expeval(char **);
		char *ExtractPublicSymbol(char *symName);
	};

	Value expeval(char *, char **);

}
