#ifndef ASMBUF_HPP
#define ASMBUF_HPP

#ifndef BUF_HPP
#include <buf.hpp>
#endif

typedef struct
{
   __int64 value;
   char size;
   unsigned int fLabel : 1;
   unsigned int fForcedSize : 1;
   unsigned int fForwardRef : 1;	// True if expression possibly
									// contains forward reference
} SValue;

class CAsmBuf : public CBuf
{
   void Relational(SValue *);
   void OrExpr(SValue *);
   void AndExpr(SValue *);
   void Expr(SValue *);
   void Term(SValue *);
   void Factor(SValue *);
   void Func(SValue *, int);
   void Constant(SValue *);
public:
   char *GetArg();
   int GetParmList(char **);
   SValue expeval(char **);
};

SValue expeval(char *, char **);

#endif

