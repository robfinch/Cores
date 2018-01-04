#include "stdafx.h"

//
// Returns the desirability of optimization for a subexpression.
//
// Immediate constants have low priority because small constants
// can be directly encoded in the instruction. There's no value to
// placing them in registers.

int CSE::OptimizationDesireability()
{
	if (exp==nullptr)
		return (0);
	if( voidf || (exp->nodetype == en_icon &&
                       exp->i < 32768 && exp->i >= -32768))
        return (0);
 /* added this line to disable register optimization of global variables.
    The compiler would assign a register to a global variable ignoring
    the fact that the value might change due to a subroutine call.
  */
	if (exp->nodetype == en_nacon)
		return (0);
	// No value to optimizing function call names, the called function
	// address will typically fit in a single 32 bit opcode.
	if (exp->nodetype == en_cnacon)
		return (0);
	if (exp->isVolatile)
		return (0);
	// Prevent Inline code from being allocated a pointer in a register.
	if (exp->sym) {
		if (exp->sym->IsInline)
			return (0);
	}
	// Left values are worth more to optimization than right values.
    if( IsLValue(exp) )
	    return (2 * uses);
    return (uses);
}

