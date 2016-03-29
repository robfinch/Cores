// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2016  Robert Finch, Stratford
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

/*	Modified to support 64 bit Raptor64 by
	Robert Finch	robfinch<remove>@opencores.org
*/

static void fold_const(ENODE **node);

/*
 *      dooper will execute a constant operation in a node and
 *      modify the node to be the result of the operation.
 */
void dooper(ENODE **node)
{
	ENODE *ep;

    ep = *node;
    switch( ep->nodetype ) {
    case en_add:
            ep->nodetype = en_icon;
            ep->i = ep->p[0]->i + ep->p[1]->i;
            break;
    case en_sub:
            ep->nodetype = en_icon;
            ep->i = ep->p[0]->i - ep->p[1]->i;
            break;
    case en_mul:
	case en_mulu:
            ep->nodetype = en_icon;
            ep->i = ep->p[0]->i * ep->p[1]->i;
            break;
    case en_div:
	case en_udiv:
            ep->nodetype = en_icon;
            ep->i = ep->p[0]->i / ep->p[1]->i;
            break;
    case en_shl:
	case en_shlu:
            ep->nodetype = en_icon;
            ep->i = ep->p[0]->i << ep->p[1]->i;
            break;
	case en_asr:
    case en_shr:
            ep->nodetype = en_icon;
            ep->i = ep->p[0]->i >> ep->p[1]->i;
            break;
    case en_shru:
            ep->nodetype = en_icon;
            ep->i = (unsigned)ep->p[0]->i >> ep->p[1]->i;
            break;
    case en_and:
            ep->nodetype = en_icon;
            ep->i = ep->p[0]->i & ep->p[1]->i;
            break;
    case en_or:
            ep->nodetype = en_icon;
            ep->i = ep->p[0]->i | ep->p[1]->i;
            break;
    case en_xor:
            ep->nodetype = en_icon;
            ep->i = ep->p[0]->i ^ ep->p[1]->i;
            break;
	case en_land:
		ep->nodetype = en_icon;
		ep->i = ep->p[0]->i && ep->p[1]->i;
		break;
	case en_lor:
		ep->nodetype = en_icon;
		ep->i = ep->p[0]->i || ep->p[1]->i;
		break;
	case en_ult:
		ep->nodetype = en_icon;
		ep->i = (unsigned)ep->p[0]->i < (unsigned)ep->p[1]->i;
		break;
	case en_ule:
		ep->nodetype = en_icon;
		ep->i = (unsigned)ep->p[0]->i <= (unsigned)ep->p[1]->i;
		break;
	case en_ugt:
		ep->nodetype = en_icon;
		ep->i = (unsigned)ep->p[0]->i > (unsigned)ep->p[1]->i;
		break;
	case en_uge:
		ep->nodetype = en_icon;
		ep->i = (unsigned)ep->p[0]->i >= (unsigned)ep->p[1]->i;
		break;
	case en_lt:
		ep->nodetype = en_icon;
		ep->i = (signed)ep->p[0]->i < (signed)ep->p[1]->i;
		break;
	case en_le:
		ep->nodetype = en_icon;
		ep->i = (signed)ep->p[0]->i <= (signed)ep->p[1]->i;
		break;
	case en_gt:
		ep->nodetype = en_icon;
		ep->i = (signed)ep->p[0]->i > (signed)ep->p[1]->i;
		break;
	case en_ge:
		ep->nodetype = en_icon;
		ep->i = (signed)ep->p[0]->i >= (signed)ep->p[1]->i;
		break;
	case en_eq:
		ep->nodetype = en_icon;
		ep->i = (signed)ep->p[0]->i == (signed)ep->p[1]->i;
		break;
	case en_ne:
		ep->nodetype = en_icon;
		ep->i = (signed)ep->p[0]->i != (signed)ep->p[1]->i;
		break;
	case en_cond:
		ep->nodetype = ep->p[1]->p[0]->nodetype;
		ep->i = ep->p[0]->i ? ep->p[1]->p[0]->i : ep->p[1]->p[1]->i;
		ep->sp = ep->p[0]->i ? ep->p[1]->p[0]->sp : ep->p[1]->p[1]->sp;
		break;
    }
}

/*
 *      return which power of two i is or -1.
 */
int pwrof2(int64_t i)
{       
	int p;
	int64_t q;

    q = 2;
    p = 1;
    while( q > 0 )
    {
		if( q == i )
			return p;
		q <<= 1;
		++p;
    }
    return -1;
}

/*
 *      make a mod mask for a power of two.
 */
int64_t mod_mask(int i)
{   
	int64_t m;
    m = 0;
    while( i-- )
        m = (m << 1) | 1;
    return m;
}

/*
 *      opt0 - delete useless expressions and combine constants.
 *
 *      opt0 will delete expressions such as x + 0, x - 0, x * 0,
 *      x * 1, 0 / x, x / 1, x mod 0, etc from the tree pointed to
 *      by node and combine obvious constant operations. It cannot
 *      combine name and label constants but will combine icon type
 *      nodes.
 */
static void opt0(ENODE **node)
{
	ENODE *ep;
    int64_t val, sc;

    ep = *node;
    if( ep == (ENODE *)NULL )
        return;
    switch( (*node)->nodetype ) {
            case en_b_ref:
			case en_c_ref:
			case en_h_ref:
            case en_w_ref:          /* optimize unary node */
            case en_ub_ref:
			case en_uc_ref:
			case en_uh_ref:
            case en_uw_ref:          /* optimize unary node */
			case en_flt_ref:
			case en_dbl_ref:
			case en_cubw:
			case en_cucw:
			case en_cuhw:
			case en_cubu:
			case en_cucu:
			case en_cuhu:
			case en_cbu:
			case en_ccu:
			case en_chu:
			case en_cbc:
			case en_cbh:
			case en_cbw:
			case en_cch:
			case en_ccw:
			case en_chw:
			case en_ainc:
			case en_adec:
                    opt0( &((*node)->p[0]));
                    return;
			case en_compl:
                    opt0( &(ep->p[0]));
                    if( ep->p[0]->nodetype == en_icon )
                    {
                        ep->nodetype = en_icon;
                        ep->i = ~ep->p[0]->i;
                    }
                    return;
			case en_not:
                    opt0( &(ep->p[0]));
                    if( ep->p[0]->nodetype == en_icon )
                    {
                        ep->nodetype = en_icon;
                        ep->i = !ep->p[0]->i;
                    }
                    return;
            case en_uminus:
                    opt0( &(ep->p[0]));
                    if( ep->p[0]->nodetype == en_icon )
                    {
                        ep->nodetype = en_icon;
                        ep->i = -ep->p[0]->i;
                    }
                    return;
            case en_tempref:
                    opt0( &(ep->p[0]));
                    if( ep->p[0] && ep->p[0]->nodetype == en_icon )
                    {
                        ep->nodetype = en_icon;
                        ep->i = ep->p[0]->i;
                    }
                    return;
            case en_tempfpref:
                    opt0( &(ep->p[0]));
                    if( ep->p[0] && ep->p[0]->nodetype == en_fcon )
                    {
                        ep->nodetype = en_fcon;
                        ep->f = ep->p[0]->f;
                    }
                    return;
            case en_add:
            case en_sub:
                    opt0(&(ep->p[0]));
                    opt0(&(ep->p[1]));
                    if( ep->p[0]->nodetype == en_icon ) {
                        if( ep->p[1]->nodetype == en_icon ) {
                            dooper(node);
                            return;
                        }
                        if( ep->p[0]->i == 0 ) {
							if( ep->nodetype == en_sub )
							{
								ep->p[0] = ep->p[1];
                                ep->nodetype = en_uminus;
							}
							else
								*node = ep->p[1];
								return;
                        }
                    }
                    else if( ep->p[1]->nodetype == en_icon ) {
                        if( ep->p[1]->i == 0 ) {
                            *node = ep->p[0];
                            return;
                        }
                    }
                    return;
            case en_mul:
			case en_mulu:
                    opt0(&(ep->p[0]));
                    opt0(&(ep->p[1]));
                    if( ep->p[0]->nodetype == en_icon ) {
                        if( ep->p[1]->nodetype == en_icon ) {
                            dooper(node);
                            return;
                        }
                        val = ep->p[0]->i;
                        if( val == 0 ) {
                            *node = ep->p[0];
                            return;
                        }
                        if( val == 1 ) {
                            *node = ep->p[1];
                            return;
                        }
                        sc = pwrof2(val);
                        if( sc != -1 )
                        {
                            swap_nodes(ep);
                            ep->p[1]->i = sc;
                            ep->nodetype = en_shl;
                        }
                    }
                    else if( ep->p[1]->nodetype == en_icon ) {
                        val = ep->p[1]->i;
                        if( val == 0 ) {
                            *node = ep->p[1];
                            return;
                        }
                        if( val == 1 ) {
                            *node = ep->p[0];
                            return;
                        }
                        sc = pwrof2(val);
                        if( sc != -1 )
                        {
							ep->p[1]->i = sc;
							ep->nodetype = en_shl;
                        }
                    }
                    break;
            case en_div:
			case en_udiv:
                    opt0(&(ep->p[0]));
                    opt0(&(ep->p[1]));
                    if( ep->p[0]->nodetype == en_icon ) {
                            if( ep->p[1]->nodetype == en_icon ) {
                                    dooper(node);
                                    return;
                                    }
                            if( ep->p[0]->i == 0 ) {    /* 0/x */
                                    *node = ep->p[0];
                                    return;
                                    }
                            }
                    else if( ep->p[1]->nodetype == en_icon ) {
                            val = ep->p[1]->i;
                            if( val == 1 ) {        /* x/1 */
                                    *node = ep->p[0];
                                    return;
                                    }
                            sc = pwrof2(val);
                            if( sc != -1 )
                                    {
                                    ep->p[1]->i = sc;
									if ((*node)->nodetype == en_udiv)
										ep->nodetype = en_shru;
									else
										ep->nodetype = ep->p[0]->isUnsigned ? en_shru : en_shr;
                                    }
                            }
                    break;
            case en_mod:
                    opt0(&(ep->p[0]));
                    opt0(&(ep->p[1]));
                    if( ep->p[1]->nodetype == en_icon )
                            {
                            if( ep->p[0]->nodetype == en_icon )
                                    {
                                    dooper(node);
                                    return;
                                    }
                            sc = pwrof2(ep->p[1]->i);
                            if( sc != -1 )
                                    {
                                    ep->p[1]->i = mod_mask(sc);
                                    ep->nodetype = en_and;
                                    }
                            }
                    break;
            case en_and: 
            case en_or:
			case en_xor:    
			case en_shr:	case en_shru:	case en_asr:
			case en_shl:	case en_shlu:
                    opt0(&(ep->p[0]));
                    opt0(&(ep->p[1]));
                    if( ep->p[0]->nodetype == en_icon &&
                            ep->p[1]->nodetype == en_icon )
                            dooper(node);
                    break;
            case en_land:   
                    opt0(&(ep->p[0]));
                    opt0(&(ep->p[1]));
					if (ep->p[0]->nodetype==en_icon && ep->p[1]->nodetype==en_icon) {
						dooper(node);
						break;
                    }
                    break;
            case en_lor:
                    opt0(&(ep->p[0]));
                    opt0(&(ep->p[1]));
					if (ep->p[0]->nodetype==en_icon && ep->p[1]->nodetype==en_icon) {
						dooper(node);
						break;
                    }
                    break;
			case en_ult:	case en_ule:
			case en_ugt:	case en_uge:
			case en_lt:		case en_le:
			case en_gt:		case en_ge:
			case en_eq:		case en_ne:
                    opt0(&(ep->p[0]));
                    opt0(&(ep->p[1]));
					if (ep->p[0]->nodetype==en_icon && ep->p[1]->nodetype==en_icon)
						dooper(node);
                    break;
                case en_feq:    case en_fne:
                case en_flt:    case en_fle:
                case en_fgt:    case en_fge:
                    opt0(&(ep->p[0]));
                    opt0(&(ep->p[1]));
                    break;
			case en_cond:
                    opt0(&(ep->p[0]));
					opt0(&(ep->p[1]->p[0]));
					opt0(&(ep->p[1]->p[1]));
					if ((ep->p[0]->nodetype==en_icon||ep->p[0]->nodetype==en_cnacon) &&
						 (ep->p[1]->p[0]->nodetype==en_icon || ep->p[1]->p[0]->nodetype==en_cnacon) &&
						 (ep->p[1]->p[1]->nodetype==en_icon || ep->p[1]->p[1]->nodetype==en_cnacon))
						dooper(node);
					break;
            case en_chk:
                    opt0(&(ep->p[0]));
					opt0(&(ep->p[1]));
					opt0(&(ep->p[2]));
					break;
            case en_asand:  case en_asor:
            case en_asadd:  case en_assub:
            case en_asmul:  case en_asdiv:
            case en_asmod:  case en_asrsh:
            case en_aslsh:  
            case en_fcall:  case en_void:
                    opt0(&(ep->p[0]));
                    opt0(&(ep->p[1]));
                    break;
            case en_assign:
                    opt0(&(ep->p[0]));
                    opt0(&(ep->p[1]));
                    break;
            }
}

/*
 *      xfold will remove constant nodes and return the values to
 *      the calling routines.
 */
static int64_t xfold(ENODE *node)
{
	int64_t i;

        if( node == NULL )
                return 0;
        switch( node->nodetype )
                {
                case en_icon:
                        i = node->i;
                        node->i = 0;
                        return i;
                case en_add:
                        return xfold(node->p[0]) + xfold(node->p[1]);
                case en_sub:
                        return xfold(node->p[0]) - xfold(node->p[1]);
                case en_mul:
				case en_mulu:
                        if( node->p[0]->nodetype == en_icon )
                                return xfold(node->p[1]) * node->p[0]->i;
                        else if( node->p[1]->nodetype == en_icon )
                                return xfold(node->p[0]) * node->p[1]->i;
                        else return 0;
				case en_shl:	case en_shlu:
                        if( node->p[0]->nodetype == en_icon )
                                return xfold(node->p[1]) << node->p[0]->i;
                        else if( node->p[1]->nodetype == en_icon )
                                return xfold(node->p[0]) << node->p[1]->i;
                        else return 0;
                case en_uminus:
                        return - xfold(node->p[0]);
				case en_shr:    case en_div:	case en_udiv:	case en_shru: case en_asr:
                case en_mod:    case en_asadd:
                case en_assub:  case en_asmul:
                case en_asdiv:  case en_asmod:
                case en_and:    case en_land:
                case en_or:     case en_lor:
                case en_xor:    case en_asand:
                case en_asor:   case en_void:
                case en_fcall:  case en_assign:
                        fold_const(&node->p[0]);
                        fold_const(&node->p[1]);
                        return 0;
				case en_ub_ref: case en_uw_ref:
				case en_uc_ref: case en_uh_ref:
                case en_b_ref:  case en_w_ref:
				case en_c_ref:  case en_h_ref:
                case en_compl:
                case en_not:
                        fold_const(&node->p[0]);
                        return 0;
                }
        return 0;
}

/*
 *      reorganize an expression for optimal constant grouping.
 */
static void fold_const(ENODE **node)
{       ENODE *ep;
        int64_t i;
        ep = *node;
        if( ep == 0 )
                return;
        if( ep->nodetype == en_add )
                {
                if( ep->p[0]->nodetype == en_icon )
                        {
                        ep->p[0]->i += xfold(ep->p[1]);
                        return;
                        }
                else if( ep->p[1]->nodetype == en_icon )
                        {
                        ep->p[1]->i += xfold(ep->p[0]);
                        return;
                        }
                }
        else if( ep->nodetype == en_sub )
                {
                if( ep->p[0]->nodetype == en_icon )
                        {
                        ep->p[0]->i -= xfold(ep->p[1]);
                        return;
                        }
                else if( ep->p[1]->nodetype == en_icon )
                        {
                        ep->p[1]->i -= xfold(ep->p[0]);
                        return;
                        }
                }
        i = xfold(ep);
        if( i != 0 )
                {
                ep = makeinode(en_icon,i);
                ep = makenode(en_add,ep,*node);
                *node = ep;
                }
}

//
//      apply all constant optimizations.
//
void opt_const(ENODE **node)
{
    if (opt_noexpr==FALSE) {
    	opt0(node);
    	fold_const(node);
    	opt0(node);
    }
}
