#include "stdafx.h"

extern int loop_active;

// voidauto2 searches the entire CSE list for auto dereferenced node which
// point to the passed node. There might be more than one LValue that matches.
// voidauto will void an auto dereference node which points to
// the same auto constant as node.
//
int CSEList::voidauto(ENODE *node)
{
    int uses;
    int voided;
	int cnt;

    uses = 0;
    voided = 0;
	for (cnt = 0; cnt < csendx; cnt++) {
        if( CSETable[cnt].exp->IsLValue(true) && ENODE::IsEqual(node,CSETable[cnt].exp->p[0]) ) {
            CSETable[cnt].voidf = TRUE;
            voided = TRUE;
            uses += CSETable[cnt].uses;
        }
	}
    return voided ? uses : -1;
}

// InsertNodeIntoCSEList will enter a reference to an expression node into the
// common expression table. duse is a flag indicating whether or not
// this reference will be dereferenced.

CSE *CSEList::Insert(ENODE *node, int duse)
{
	CSE *csp;

    if( (csp = Find(node)) == NULL ) {   /* add to tree */
		if (csendx > 499)
			throw new C64PException(ERR_CSETABLE,0x01);
		csp = &CSETable[csendx];
		csendx++;
        csp->uses = loop_active;
        csp->duses = (duse != 0) * loop_active;
        csp->exp = node->Duplicate();
        csp->voidf = 0;
		csp->reg = 0;
        return csp;
    }
    (csp->uses) += loop_active;
    if( duse )
       (csp->duses) += loop_active;
    return csp;
}

//
// SearchCSEList will search the common expression table for an entry
// that matches the node passed and return a pointer to it.
//
CSE *CSEList::Find(ENODE *node)
{
	int cnt;

	for (cnt = 0; cnt < csendx; cnt++) {
        if( ENODE::IsEqual(node,CSETable[cnt].exp) )
            return &CSETable[cnt];
	}
    return (CSE *)NULL;
}


void CSEList::Dump()
{
	int nn;
	CSE *csp;

	dfs.printf("<CSETable>\n");
	dfs.printf("N Uses DUses Void Reg\n");
	for (nn = 0; nn < csendx; nn++) {
		csp = &CSETable[nn];
		dfs.printf("%d: %d  ",nn,csp->uses);
		dfs.printf("%d   ",csp->duses);
		dfs.printf("%d   ",(int)csp->voidf);
		dfs.printf("%d   ",csp->reg);
#ifdef __GNUC__
      // GCC needs a case otherwise you get:
      // CSEList.cpp:88:67: error: call of overloaded ‘printf(const char [6], const char [4])’ is ambiguous
		dfs.printf("%s   ",(char *)(csp->exp->nodetype == en_icon ? "imm" : "   "));
#else
		dfs.printf("%s   ",csp->exp->nodetype == en_icon ? "imm" : "   ");
#endif
		dfs.printf("\n");
	}
	dfs.printf("</CSETable>\n");
}

//
// Returns the desirability of optimization for a subexpression.
//
int CSE::OptimizationDesireability()
{
	if( voidf)
        return 0;
 /* added this line to disable register optimization of global variables.
    The compiler would assign a register to a global variable ignoring
    the fact that the value might change due to a subroutine call.
  */
	if (exp->nodetype == en_nacon)
		return 0;
	if (exp->isVolatile)
		return 0;
    if( exp->IsLValue(true) )
	    return 2 * uses;
    return uses;
}

