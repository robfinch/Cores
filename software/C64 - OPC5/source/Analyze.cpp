// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C64 - 'C' derived language compiler
//  - 64 bit CPU
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
static void repcse_compound(Statement *stmt);
extern int pass;

//CSE CSETable[500];
CSEList CSETable;
short int csendx;
int loop_active;

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
	bool v;

    if( node == NULL )
        return;

	switch( node->nodetype ) {
	  case en_fpregvar:
	  case en_regvar:
	    break;
		case en_cnacon:
		case en_clabcon:
		case en_fcon:
        case en_icon:
        case en_labcon:
        case en_nacon:
                CSETable.Insert(node,duse);
                break;
		case en_autofcon:
        case en_autocon:
		case en_classcon:
        case en_tempfpref:
        case en_tempref:
                csp1 = CSETable.Insert(node,duse);
                if ((nn = CSETable.voidauto(node)) > 0) {
					csp1->voidf = TRUE;
					csp1->duses += 1;
                    csp1->uses = csp1->duses + nn - 1;
				}
                break;
		case en_ref32: case en_ref32u:
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
		case en_lw_ref:
		case en_ulw_ref:
        case en_struct_ref:
                // There is something wrong with the following code that causes
                // it to remove zero extension conversion from a byte to a word.
                if( node->p[0]->nodetype == en_autocon || node->p[0]->nodetype==en_autofcon
					|| node->p[0]->nodetype == en_classcon) {
					//v = CSETable.voidauto(node->p[0]) > 0;
					first = (CSETable.Find(node)==NULL);	// Detect if this is the first insert
                    csp = CSETable.Insert(node,duse);
					if (csp->voidf)
						scanexpr(node->p[0], 1);
					// take care: the non-derereferenced use of the autocon node may
					// already be in the list. In this case, set voidf to 1
					if (CSETable.Find(node->p[0]) != NULL) {
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
		case en_lul:
		case en_clw:	case en_cluw:
        case en_uminus:
        case en_compl:  case en_ainc:
        case en_adec:   case en_not:
        case en_chk:
        case en_i2d:
		case en_i2q:
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
        case en_void:
		case en_list:
		case en_aggregate:
                scanexpr(node->p[0],0);
                scanexpr(node->p[1],0);
                break;
		case en_assign:
                scanexpr(node->p[0],0);
                scanexpr(node->p[1],0);
                break;
        case en_fcall:
                scanexpr(node->p[0],1);
                scanexpr(node->p[1],0);
                break;
        default: dfs.printf("Uncoded node in scanexpr():%d\n", node->nodetype);
        }
}

/*
 *      scan will gather all optimizable expressions into the expression
 *      list for a block of statements.
 */
void Statement::scan()
{
	Statement *block = this;

	loop_active = 1;
	while( block != NULL ) {
        switch( block->stype ) {
			case st_compound:
					block->prolog->scan();
					block->ScanCompound();
					block->epilog->scan();
					break;
			case st_check:
            case st_return:
			case st_throw:
            case st_expr:
                    ENODE::OptimizeConstants(&block->exp);
                    scanexpr(block->exp,0);
                    break;
            case st_while:
			case st_until:
            case st_do:
			case st_dountil:
					loop_active++;
                    ENODE::OptimizeConstants(&block->exp);
                    scanexpr(block->exp,0);
					loop_active--;
			case st_doloop:
			case st_forever:
					loop_active++;
                    block->s1->scan();
					loop_active--;
                    break;
            case st_for:
					loop_active++;
                    ENODE::OptimizeConstants(&block->initExpr);
                    scanexpr(block->initExpr,0);
                    ENODE::OptimizeConstants(&block->exp);
                    scanexpr(block->exp,0);
                    block->s1->scan();
                    ENODE::OptimizeConstants(&block->incrExpr);
                    scanexpr(block->incrExpr,0);
					loop_active--;
                    break;
            case st_if:
                    ENODE::OptimizeConstants(&block->exp);
                    scanexpr(block->exp,0);
                    block->s1->scan();
                    block->s2->scan();
                    break;
            case st_switch:
                    ENODE::OptimizeConstants(&block->exp);
                    scanexpr(block->exp,0);
                    block->s1->scan();
                    break;
            case st_firstcall:
            case st_case:
			case st_default:
                    block->s1->scan();
                    break;
            // nothing to process for these statement
            case st_break:
            case st_continue:
            case st_goto:
                    break;
            default:      ;// printf("Uncoded statement in scan():%d\n", block->stype);
        }
        block = block->next;
    }
}

void Statement::ScanCompound()
{
	SYM *sp;

	sp = sp->GetPtr(ssyms.GetHead());
	while (sp) {
		if (sp->initexp) {
			ENODE::OptimizeConstants(&sp->initexp);
            scanexpr(sp->initexp,0);
		}
		sp = sp->GetNextPtr();
	}
    s1->scan();
}

/*
 *      repexpr will replace all allocated references within an expression
 *      with tempref nodes.
 */
void repexpr(ENODE *node)
{
	CSE *csp;
        if( node == NULL )
                return;
        switch( node->nodetype ) {
				case en_fcon:
				case en_autofcon:
                case en_tempfpref:
					/*
					if( (csp = SearchCSEList(node)) != NULL ) {
						if( csp->reg > 0 ) {
							node->nodetype = en_fpregvar;
							node->i = csp->reg;
						}
					}
					break;
					*/
                case en_icon:
                case en_nacon:
                case en_labcon:
                case en_autocon:
				case en_classcon:
				case en_cnacon:
				case en_clabcon:
                case en_tempref:
					if( (csp = CSETable.Find(node)) != NULL ) {
						if( csp->reg > 0 ) {
							node->nodetype = en_regvar;
							node->i = csp->reg;
						}
					}
					break;
				case en_ref32: case en_ref32u:
                case en_b_ref:
				case en_c_ref:
				case en_h_ref:
                case en_w_ref:
                case en_ub_ref:
				case en_uc_ref:
				case en_uh_ref:
                case en_uw_ref:
				case en_lw_ref:
				case en_ulw_ref:
				case en_bfieldref:
				case en_ubfieldref:
				case en_cfieldref:
				case en_ucfieldref:
				case en_hfieldref:
				case en_uhfieldref:
				case en_wfieldref:
				case en_uwfieldref:
                case en_struct_ref:
					if( (csp = CSETable.Find(node)) != NULL ) {
						if( csp->reg > 0 ) {
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
				case en_flt_ref:
				case en_quad_ref:
					if( (csp = CSETable.Find(node)) != NULL ) {
						if( csp->reg > 0 ) {
							node->nodetype = en_regvar;
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
				case en_lul:
				case en_clw:	case en_cluw:
				case en_cwl:	case en_cuwl:
                case en_uminus:
                case en_not:    case en_compl:
                case en_ainc:   case en_adec:
                case en_chk:
                case en_i2d:
				case en_i2q:
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
				case en_cond:   case en_void:	case en_list:
                case en_asadd:  case en_assub:
				case en_asmul:  case en_asmulu:
				case en_asdiv:  case en_asdivu:
                case en_asor:   case en_asand:    case en_asxor:
                case en_asmod:  case en_aslsh:
                case en_asrsh:  case en_fcall:
				case en_aggregate:
                case en_assign:
                        repexpr(node->p[0]);
                        repexpr(node->p[1]);
                        break;
                case en_regvar:
				case en_fpregvar:
                  break;
                default:
                        dfs.printf("Uncoded node in repexr():%d\n",node->nodetype);
                }
}

//
// Repcse will scan through a block of statements replacing the
// optimized expressions with their temporary references.
//
void Statement::repcse()
{    
	Statement *block = this;

	while( block != NULL ) {
        switch( block->stype ) {
			case st_compound:
					block->prolog->repcse();
					block->repcseCompound();
					block->epilog->repcse();
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
					block->s1->repcse();
					block->s2->repcse();
					break;
			case st_for:
					repexpr(block->initExpr);
					repexpr(block->exp);
					block->s1->repcse();
					repexpr(block->incrExpr);
					break;
			case st_if:
					repexpr(block->exp);
					block->s1->repcse();
					block->s2->repcse();
					break;
			case st_switch:
					repexpr(block->exp);
					block->s1->repcse();
					break;
			case st_try:
			case st_catch:
			case st_case:
			case st_default:
            case st_firstcall:
					block->s1->repcse();
					break;
       }
        block = block->next;
    }
}

void Statement::repcseCompound()
{
	SYM *sp;

	sp = sp->GetPtr(ssyms.GetHead());
	while (sp) {
		if (sp->initexp) {
			repexpr(sp->initexp);
		}
		sp = sp->GetNextPtr();
	}
	s1->repcse();
}

/*
 *      opt1 is the externally callable optimization routine. it will
 *      collect and allocate common subexpressions and substitute the
 *      tempref for all occurrances of the expression within the block.
 *
 *		optimizer is currently turned off...
 */
int Statement::CSEOptimize()
{
	int nn;

	nn = 0;
	if (pass==1) {
		csendx = 0;
		ZeroMemory(CSETable.CSETable,sizeof(CSETable.CSETable));
	}
	if (opt_noregs==FALSE) {
		if (pass==1)
		scan();         /* collect expressions */
		nn = AllocateRegisterVars();
		if (pass==2)
    	repcse();			/* replace allocated expressions */
	}
	return nn;
}

