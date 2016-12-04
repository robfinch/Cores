// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2016  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C32 - 'C' derived language compiler
//  - 32 bit CPU
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// ============================================================================
//
#include "stdafx.h"

/*
 *	68000 C compiler
 *
 *	Copyright 1984, 1985, 1986 Matthew Brandt.
 *  all commercial rights reserved.
 *
 *	This compiler is intended as an instructive tool for personal use. Any
 *	use for profit without the written consent of the author is prohibited.
 *
 *	This compiler may be distributed freely for non-commercial use as long
 *	as this notice stays intact. Please forward any enhancements or questions
 *	to:
 *
 *		Matthew Brandt
 *		Box 920337
 *		Norcross, Ga 30092
 */


int bsave_mask;
extern int popcnt(int m);
extern int AllocateRegisterVars();
static void scan_compound(Statement *stmt);
static void repcse_compound(Statement *stmt);

/*
 *      this module will step through the parse tree and find all
 *      optimizable expressions. at present these expressions are
 *      limited to expressions that are valid throughout the scope
 *      of the function. the list of optimizable expressions is:
 *
 *              constants
 *              global and static addresses
 *              auto addresses
 *              contents of auto addresses.
 *
 *      contents of auto addresses are valid only if the address is
 *      never referred to without dereferencing.
 *
 *      scan will build a list of optimizable expressions which
 *      opt1 will replace during the second optimization pass.
 */

CSE *olist;         /* list of optimizable expressions */

/*
 *      equalnode will return 1 if the expressions pointed to by
 *      node1 and node2 are equivalent.
 */
int equalnode(ENODE *node1, ENODE *node2)
{
    if (node1 == NULL || node2 == NULL) {
		return FALSE;
    }
    if (node1->nodetype != node2->nodetype) {
		return FALSE;
    }
    switch (node1->nodetype) {
	case en_fcon:
		return (Float128::IsEqual(&node1->f128,&node2->f128));
//			return (node1->f == node2->f);
	case en_regvar:
	case en_bregvar:
	case en_fpregvar:
      case en_icon:
      case en_labcon:
	  case en_classcon:	// Check type ?
      case en_autocon:
	  case en_autofcon:
		  {
			return (node1->i == node2->i);
	   }
      case en_nacon:{
			return (node1->sp->compare(*node2->sp)==0);
	    }
	  case en_cnacon:
			return (node1->sp->compare(*node2->sp)==0);
      default:
	        if( IsLValue(node1) && equalnode(node1->p[0], node2->p[0])  )
		        return TRUE;
		return FALSE;
    }
}

/*
 *      SearchCSEList will search the common expression table for an entry
 *      that matches the node passed and return a pointer to it.
 */
static CSE *SearchCSEList(ENODE *node)
{
	CSE *csp;

    csp = olist;
    while( csp != (CSE *)NULL ) {
        if( equalnode(node,csp->exp) )
            return csp;
        csp = csp->next;
    }
    return (CSE *)NULL;
}

/*
 *      copy the node passed into a new enode so it wont get
 *      corrupted during substitution.
 */
static ENODE *DuplicateEnode(ENODE *node)
{       
	ENODE *temp;

    if( node == NULL )
        return (ENODE *)NULL;
    temp = allocEnode();
	memcpy(temp,node,sizeof(ENODE));	// copy all the fields
    return temp;
}

/*
 *      InsertNodeIntoCSEList will enter a reference to an expression node into the
 *      common expression table. duse is a flag indicating whether or not
 *      this reference will be dereferenced.
 */
CSE *InsertNodeIntoCSEList(ENODE *node, int duse)
{
	CSE *csp;

    if( (csp = SearchCSEList(node)) == NULL ) {   /* add to tree */
        csp = allocCSE();
        csp->next = olist;
        csp->uses = 1;
        csp->duses = (duse != 0);
        csp->exp = DuplicateEnode(node);
        csp->voidf = 0;
		csp->reg = 0;
		if (node->tp)
			csp->isfp = node->tp->IsFloatType();
		else
			csp->isfp = false;
        olist = csp;
        return csp;
    }
    ++(csp->uses);
    if( duse )
            ++(csp->duses);
    return csp;
}

/*
 *      voidauto will void an auto dereference node which points to
 *      the same auto constant as node.
 */
CSE *voidauto(ENODE *node)
{
	CSE *csp;

	csp = (CSE *)olist;
    while( csp != NULL ) {
        if( IsLValue(csp->exp) && equalnode(node,csp->exp->p[0]) ) {
            if( csp->voidf )
                 return (CSE *)NULL;
            csp->voidf = 1;
            return csp;
        }
        csp = csp->next;
    }
    return (CSE *)NULL;
}

// voidauto2 searches the entire CSE list for auto dereferenced node which
// point to the passed node. There might be more than one LValue that matches.
//      voidauto will void an auto dereference node which points to
//      the same auto constant as node.
//
int voidauto2(ENODE *node)
{
	CSE *csp;
    int uses;
    int voided;
 
    uses = 0;
    voided = 0;
	csp = (CSE *)olist;
    while( csp != NULL ) {
        if( IsLValue(csp->exp) && equalnode(node,csp->exp->p[0]) ) {
            csp->voidf = 1;
            voided = 1;
            uses += csp->uses;
        }
        csp = csp->next;
    }
    return voided ? uses : -1;
}

/*
 *      scanexpr will scan the expression pointed to by node for optimizable
 *      subexpressions. when an optimizable expression is found it is entered
 *      into the tree. if a reference to an autocon node is scanned the
 *      corresponding auto dereferenced node will be voided. duse should be
 *      set if the expression will be dereferenced.
 */
static void scanexpr(ENODE *node, int duse)
{
	CSE *csp, *csp1;
	int first;
	int nn;

    if( node == NULL )
        return;

	switch( node->nodetype ) {
	  case en_regvar:
	    break;
		case en_cnacon:
		case en_clabcon:
		case en_fcon:
        case en_icon:
        case en_labcon:
        case en_nacon:
                InsertNodeIntoCSEList(node,duse);
                break;
		case en_autofcon:
        case en_autocon:
		case en_classcon:
        case en_tempfpref:
        case en_tempref:
                csp1 = InsertNodeIntoCSEList(node,duse);
                if ((nn = voidauto2(node)) > 0)
                    csp1->uses = (csp1->duses += nn);
//                if( (csp = voidauto(node)) != NULL ) {
//                    csp1->uses = (csp1->duses += csp->uses);
//                    }
                break;
        case en_b_ref:
		case en_c_ref:
		case en_h_ref:
        case en_w_ref:
        case en_ub_ref:
		case en_uc_ref:
		case en_uh_ref:
        case en_uw_ref:
		case en_flt_ref:
		case en_dbl_ref:
		case en_quad_ref:
		case en_bfieldref:
		case en_ubfieldref:
		case en_cfieldref:
		case en_ucfieldref:
		case en_hfieldref:
		case en_uhfieldref:
		case en_wfieldref:
		case en_uwfieldref:
        case en_struct_ref:
                // There is something wrong with the following code that causes
                // it to remove zero extension conversion from a byte to a word.
                if( node->p[0]->nodetype == en_autocon || node->p[0]->nodetype==en_autofcon
					|| node->p[0]->nodetype == en_classcon) {
					first = (SearchCSEList(node)==NULL);	// Detect if this is the first insert
                    csp = InsertNodeIntoCSEList(node,duse);
					if (csp->voidf)
						scanexpr(node->p[0], 1);
					// take care: the non-derereferenced use of the autocon node may
					// already be in the list. In this case, set voidf to 1
					if (SearchCSEList(node->p[0]) != NULL) {
						csp->voidf = 1;
						scanexpr(node->p[0], 1);
					}
					else {
//                        if( csp->voidf )
//                             scanexpr(node->p[0],1);
					    if (first) {
							///* look for register nodes */
							//int i = 0;
							//long j = node->p[0]->i;
							//if ((node->p[0]->nodetype== en_regvar || node->p[0]->nodetype==en_bregvar) &&
							//	(j >= 11 && j < 18))
							//{
							//	csp->voidf--;	/* this is not in auto_lst */
							//	//csp->uses += 90 * (100 - i);
							//	//csp->duses += 30 * (100 - i);
							//	break;
							//}
							///* set voidf if the node is not in autolst */
							//csp->voidf++;
							//i = 0;
							//while (i < autoptr) {
							//	if (autolst[i] == j) {
							//		csp->voidf--;
							//		break;
							//	}
							//	++i;
							//}
						/*
						* even if that item must not be put in a register,
								* it is legal to put its address therein
								*/
							//if (csp->voidf)
							//	scanexpr(node->p[0], 1);
						//}

                        //if( csp->voidf )
                        //        scanexpr(node->p[0],1);
                        }
                    }
				}
                else
                        scanexpr(node->p[0],1);
                break;
		case en_cbc: case en_cubw:
		case en_cbh: case en_cucw:
		case en_cbw: case en_cuhw:
		case en_cbu: case en_ccu: case en_chu:
		case en_cubu: case en_cucu: case en_cuhu:
		case en_cch:
		case en_ccw:
		case en_chw:
        case en_uminus:
        case en_compl:  case en_ainc:
        case en_adec:   case en_not:
        case en_chk:
        case en_i2d:
        case en_d2i:
		case en_q2i:
		case en_s2q:
                scanexpr(node->p[0],duse);
                break;
        case en_asadd:  case en_assub:
        case en_add:    case en_sub:
                scanexpr(node->p[0],duse);
                scanexpr(node->p[1],duse);
                break;
		case en_mul:    case en_mulu:   case en_div:	case en_udiv:
		case en_shl:    case en_shlu:	case en_shr:	case en_shru:	case en_asr:
        case en_mod:    case en_umod:   case en_and:
        case en_or:     case en_xor:
        case en_lor:    case en_land:
        case en_eq:     case en_ne:
        case en_gt:     case en_ge:
        case en_lt:     case en_le:
        case en_ugt:    case en_uge:
        case en_ult:    case en_ule:
                case en_feq:    case en_fne:
                case en_flt:    case en_fle:
                case en_fgt:    case en_fge:
                case en_fdmul:  case en_fddiv:
                case en_fdadd:  case en_fdsub:
				case en_fadd: case en_fsub:
				case en_fmul: case en_fdiv:
		case en_asmul:  case en_asmulu:
		case en_asdiv:	case en_asdivu:
        case en_asmod:  case en_aslsh:
		case en_asrsh:
		case en_asand:	case en_asxor: case en_asor:
		case en_cond:
        case en_void:   case en_assign:
                scanexpr(node->p[0],0);
                scanexpr(node->p[1],0);
                break;
        case en_fcall:
                scanexpr(node->p[0],1);
                scanexpr(node->p[1],0);
                break;
        default: dfs.printf("Uncoded node in scanexpr():%d\r\n", node->nodetype);
        }
}

/*
 *      scan will gather all optimizable expressions into the expression
 *      list for a block of statements.
 */
void scan(Statement *block)
{
	while( block != NULL ) {
        switch( block->stype ) {
			case st_compound:
					scan(block->prolog);
					scan_compound(block);
					scan(block->epilog);
					break;
			case st_check:
            case st_return:
			case st_throw:
            case st_expr:
                    opt_const(&block->exp);
                    scanexpr(block->exp,0);
                    break;
            case st_while:
			case st_until:
            case st_do:
			case st_dountil:
                    opt_const(&block->exp);
                    scanexpr(block->exp,0);
			case st_doloop:
			case st_forever:
                    scan(block->s1);
                    break;
            case st_for:
                    opt_const(&block->initExpr);
                    scanexpr(block->initExpr,0);
                    opt_const(&block->exp);
                    scanexpr(block->exp,0);
                    scan(block->s1);
                    opt_const(&block->incrExpr);
                    scanexpr(block->incrExpr,0);
                    break;
            case st_if:
                    opt_const(&block->exp);
                    scanexpr(block->exp,0);
                    scan(block->s1);
                    scan(block->s2);
                    break;
            case st_switch:
                    opt_const(&block->exp);
                    scanexpr(block->exp,0);
                    scan(block->s1);
                    break;
            case st_firstcall:
            case st_case:
			case st_default:
                    scan(block->s1);
                    break;
            case st_spinlock:
                    scan(block->s1);
                    scan(block->s2);
                    break;
            // nothing to process for these statement
            case st_break:
            case st_continue:
            case st_goto:
                    break;
            default:      ;// printf("Uncoded statement in scan():%d\r\n", block->stype);
        }
        block = block->next;
    }
}

static void scan_compound(Statement *stmt)
{
	SYM *sp;

	sp = sp->GetPtr(stmt->ssyms.GetHead());
	while (sp) {
		if (sp->initexp) {
			opt_const(&sp->initexp);
            scanexpr(sp->initexp,0);
		}
		sp = sp->GetNextPtr();
	}
    scan(stmt->s1);
}

/*
 *      exchange will exchange the order of two expression entries
 *      following c1 in the linked list.
 */
static void exchange(CSE **c1)
{
	CSE *csp1, *csp2;

    csp1 = *c1;
    csp2 = csp1->next;
    csp1->next = csp2->next;
    csp2->next = csp1;
    *c1 = csp2;
}

/*
 *      returns the desirability of optimization for a subexpression.
 */
int OptimizationDesireability(CSE *csp)
{
	if( csp->voidf || (csp->exp->nodetype == en_icon &&
                       csp->exp->i < 128 && csp->exp->i >= -128))
        return 0;
 /* added this line to disable register optimization of global variables.
    The compiler would assign a register to a global variable ignoring
    the fact that the value might change due to a subroutine call.
  */
	if (csp->exp->nodetype == en_nacon)
		return 0;
	if (csp->exp->isVolatile)
		return 0;
    if( IsLValue(csp->exp) )
	    return 2 * csp->uses;
    return csp->uses;
}

/*
 *      bsort implements a bubble sort on the expression list.
 */
int bsort(CSE **list)
{
	CSE *csp1, *csp2;
    int i;

    csp1 = *list;
    if( csp1 == NULL || csp1->next == NULL )
        return FALSE;
    i = bsort( &(csp1->next));
    csp2 = csp1->next;
    if( OptimizationDesireability(csp1) < OptimizationDesireability(csp2) ) {
        exchange(list);
        return TRUE;
    }
    return FALSE;
}


/*
 *      repexpr will replace all allocated references within an expression
 *      with tempref nodes.
 */
void repexpr(ENODE *node)
{
	struct cse      *csp;
        if( node == NULL )
                return;
        switch( node->nodetype ) {
				case en_fcon:
				case en_autofcon:
                case en_tempfpref:
					if( (csp = SearchCSEList(node)) != NULL ) {
						if( csp->reg > 0 ) {
							node->nodetype = en_fpregvar;
							node->i = csp->reg;
						}
					}
					break;
                case en_icon:
                case en_nacon:
                case en_labcon:
                case en_autocon:
				case en_classcon:
				case en_cnacon:
				case en_clabcon:
                case en_tempref:
					if( (csp = SearchCSEList(node)) != NULL ) {
						if( csp->reg > 0 ) {
							node->nodetype = en_regvar;
							node->i = csp->reg;
						}
					}
					break;
                case en_b_ref:
				case en_c_ref:
				case en_h_ref:
                case en_w_ref:
                case en_ub_ref:
				case en_uc_ref:
				case en_uh_ref:
                case en_uw_ref:
				case en_bfieldref:
				case en_ubfieldref:
				case en_cfieldref:
				case en_ucfieldref:
				case en_hfieldref:
				case en_uhfieldref:
				case en_wfieldref:
				case en_uwfieldref:
                case en_struct_ref:
					if( (csp = SearchCSEList(node)) != NULL ) {
						if (csp->reg > 1000) {
							node->nodetype = en_bregvar;
							node->i = csp->reg - 1000;
							node->sp = csp->exp->sp;	// retain the symbol pointer
						}
						else if( csp->reg > 0 ) {
							node->nodetype = en_regvar;
							node->i = csp->reg;
						}
						else
							repexpr(node->p[0]);
					}
					else
						repexpr(node->p[0]);
					break;
				case en_dbl_ref:
				case en_quad_ref:
					if( (csp = SearchCSEList(node)) != NULL ) {
						if( csp->reg > 0 ) {
							node->nodetype = en_fpregvar;
							node->i = csp->reg;
						}
						else
							repexpr(node->p[0]);
					}
					else
						repexpr(node->p[0]);
					break;
				case en_cbc: case en_cubw:
				case en_cbh: case en_cucw:
				case en_cbw: case en_cuhw:
				case en_cbu: case en_ccu: case en_chu:
				case en_cubu: case en_cucu: case en_cuhu:
				case en_cch:
				case en_ccw:
				case en_chw:
                case en_uminus:
                case en_not:    case en_compl:
                case en_ainc:   case en_adec:
                case en_chk:
                case en_i2d:
                case en_d2i:
				case en_q2i:
				case en_s2q:
                        repexpr(node->p[0]);
                        break;
                case en_add:    case en_sub:
				case en_mul:    case en_mulu:   case en_div:	case en_udiv:
				case en_mod:    case en_umod:
				case en_shl:	case en_shlu:	case en_shru:	case en_asr:
                case en_shr:
				case en_and:
                case en_or:     case en_xor:
                case en_land:   case en_lor:
                case en_eq:     case en_ne:
                case en_lt:     case en_le:
                case en_gt:     case en_ge:
				case en_ult:	case en_ule:
				case en_ugt:	case en_uge:
                case en_feq:    case en_fne:
                case en_flt:    case en_fle:
                case en_fgt:    case en_fge:
                case en_fdmul:  case en_fddiv:
                case en_fdadd:  case en_fdsub:
				case en_fadd: case en_fsub:
				case en_fmul: case en_fdiv:
                case en_cond:   case en_void:
                case en_asadd:  case en_assub:
				case en_asmul:  case en_asmulu:
				case en_asdiv:  case en_asdivu:
                case en_asor:   case en_asand:    case en_asxor:
                case en_asmod:  case en_aslsh:
                case en_asrsh:  case en_fcall:
                case en_assign:
                        repexpr(node->p[0]);
                        repexpr(node->p[1]);
                        break;
                case en_regvar:
                  break;
                default:
                        dfs.printf("Uncoded node in repexr():%d\r\n",node->nodetype);
                }
}

/*
 *      repcse will scan through a block of statements replacing the
 *      optimized expressions with their temporary references.
 */
void repcse(Statement *block)
{    
	while( block != NULL ) {
        switch( block->stype ) {
			case st_compound:
					repcse(block->prolog);
					repcse_compound(block);
					repcse(block->epilog);
					break;
			case st_return:
			case st_throw:
					repexpr(block->exp);
					break;
			case st_check:
                    repexpr(block->exp);
                    break;
			case st_expr:
					repexpr(block->exp);
					break;
			case st_while:
			case st_until:
			case st_do:
			case st_dountil:
					repexpr(block->exp);
			case st_doloop:
			case st_forever:
					repcse(block->s1);
					repcse(block->s2);
					break;
			case st_for:
					repexpr(block->initExpr);
					repexpr(block->exp);
					repcse(block->s1);
					repexpr(block->incrExpr);
					break;
			case st_if:
					repexpr(block->exp);
					repcse(block->s1);
					repcse(block->s2);
					break;
			case st_switch:
					repexpr(block->exp);
					repcse(block->s1);
					break;
			case st_try:
			case st_catch:
			case st_case:
			case st_default:
            case st_firstcall:
					repcse(block->s1);
					break;
       }
        block = block->next;
    }
}

static void repcse_compound(Statement *stmt)
{
	SYM *sp;

	sp = sp->GetPtr(stmt->ssyms.GetHead());
	while (sp) {
		if (sp->initexp) {
			repexpr(sp->initexp);
		}
		sp = sp->GetNextPtr();
	}
	repcse(stmt->s1);
}

/*
 *      opt1 is the externally callable optimization routine. it will
 *      collect and allocate common subexpressions and substitute the
 *      tempref for all occurrances of the expression within the block.
 *
 *		optimizer is currently turned off...
 */
int opt1(Statement *block)
{
	int nn;

    nn = 0;
	olist = (CSE *)NULL;
    if (opt_noregs==FALSE) {
	    scan(block);            /* collect expressions */
        nn = AllocateRegisterVars();
    	repcse(block);          /* replace allocated expressions */
    }
	return nn;
}
