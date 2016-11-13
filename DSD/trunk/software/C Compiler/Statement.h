#ifndef _STATEMENT
#define _STATEMENT

/*      statement node descriptions     */

enum e_stmt {
		st_empty, st_funcbody,
        st_expr, st_compound, st_while, 
		st_until, st_forever, st_firstcall, st_asm,
		st_dountil, st_doloop,
		st_try, st_catch, st_throw, st_critical, st_spinlock, st_spinunlock,
		st_for,
		st_do, st_if, st_switch, st_default,
        st_case, st_goto, st_break, st_continue, st_label,
        st_return, st_vortex, st_intoff, st_inton, st_stop, st_check };

typedef struct snode {
	__int8 stype;
	struct snode *outer;	/* outer statement */
	struct snode *next;   /* next statement */
	struct snode *prolog;
	struct snode *epilog;
	int predreg;		 /* assigned predicate register */
	ENODE *exp;           /* condition or expression */
	ENODE *initExpr;      /* initialization expression - for loops */
	ENODE *incrExpr;      /* increment expression - for loops */
	struct snode *s1, *s2;       /* internal statements */
	int *label;         /* label number for goto */
	TABLE ssyms;			/* local symbols associated with statement */
	char *fcname;       // firstcall block var name
	char *lptr;
} Statement;

#endif
