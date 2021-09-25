// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// CC64 - 'C' derived language compiler
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

static void opt0(ENODE** node);
static void fold_const(ENODE **node);
extern int NumericLiteral(ENODE*);
/*
 *      dooper will execute a constant operation in a node and
 *      modify the node to be the result of the operation.
 */
void dooper(ENODE *node)
{
	ENODE *ep;

  ep = node;
  switch( ep->nodetype ) {
	case en_abs:
    ep->nodetype = en_icon;
    ep->i = (ep->p[0]->i >= 0) ? ep->p[0]->i : -ep->p[0]->i;
		break;
  case en_add:
		if (ep->p[0]->nodetype == en_icon) {
			ep->nodetype = en_icon;
			ep->i = ep->p[0]->i + ep->p[1]->i;
		}
		if (ep->p[0]->nodetype == en_pcon) {
			ep->nodetype = en_pcon;
			ep->posit.Add(ep->p[0]->posit, ep->p[1]->posit);
		}
    break;
	case en_ptrdif:
		ep->nodetype = en_icon;
		ep->i = (ep->p[0]->i - ep->p[1]->i) >> ep->p[4]->i;
		break;
	case en_sub:
		if (ep->p[0]->nodetype == en_icon) {
			ep->nodetype = en_icon;
			ep->i = ep->p[0]->i - ep->p[1]->i;
		}
		if (ep->p[0]->nodetype == en_pcon) {
			ep->nodetype = en_pcon;
			ep->posit.Sub(ep->p[0]->posit, ep->p[1]->posit);
		}
		break;
	case en_mul:
	case en_mulu:
		ep->nodetype = en_icon;
		ep->i = ep->p[0]->i * ep->p[1]->i;
		break;
	case en_mulf:
		ep->nodetype = en_icon;
		ep->i = ep->p[0]->i * ep->p[1]->i;
		break;
	case en_div:
	case en_udiv:
		ep->nodetype = en_icon;
		ep->i = ep->p[0]->i / ep->p[1]->i;
		break;

	case en_i2d:
		ep->nodetype = en_fcon;
		ep->f = (double)ep->p[0]->i;
		ep->tp = &stddouble;// ep->p[0]->tp;
		Float128::IntToFloat(&ep->f128, ep->p[0]->i);
		//ep->i = quadlit(&ep->f128);
		ep->i = NumericLiteral(ep);
		ep->SetType(ep->tp);
		break;
	case en_i2p:
		ep->nodetype = en_pcon;
		ep->f = (double)ep->p[0]->i;
		ep->tp = &stdposit;// ep->p[0]->tp;
		ep->posit.IntToPosit(ep->p[0]->i);
		ep->SetType(ep->tp);
		break;

	case en_fadd:
		ep->nodetype = en_fcon;
		ep->f = ep->p[0]->f + ep->p[1]->f;
		ep->tp = ep->p[0]->tp;
		Float128::Add(&ep->f128, &ep->p[0]->f128, &ep->p[1]->f128);
		//ep->i = quadlit(&ep->f128);
		ep->i = NumericLiteral(ep);
		ep->SetType(ep->tp);
		break;
	case en_fsub:
		ep->nodetype = en_fcon;
		ep->f = ep->p[0]->f - ep->p[1]->f;
		ep->tp = ep->p[0]->tp;
		Float128::Sub(&ep->f128, &ep->p[0]->f128, &ep->p[1]->f128);
		ep->i = NumericLiteral(ep);
		//ep->i = quadlit(&ep->f128);
		ep->SetType(ep->tp);
		break;
	case en_fmul:
		ep->nodetype = en_fcon;
		ep->f = ep->p[0]->f * ep->p[1]->f;
		ep->tp = ep->p[0]->tp;
		Float128::Mul(&ep->f128, &ep->p[0]->f128, &ep->p[1]->f128);
		ep->i = NumericLiteral(ep);
//		ep->i = quadlit(&ep->f128);
		ep->SetType(ep->tp);
		break;
	case en_fdiv:
		ep->nodetype = en_fcon;
		ep->f = ep->p[0]->f / ep->p[1]->f;
		ep->tp = ep->p[0]->tp;
		Float128::Div(&ep->f128, &ep->p[0]->f128, &ep->p[1]->f128);
		ep->i = NumericLiteral(ep);
//		ep->i = quadlit(&ep->f128);
		ep->SetType(ep->tp);
		break;

	case en_padd:
		ep->nodetype = en_pcon;
		ep->tp = ep->p[0]->tp;
		ep->posit.Add(ep->p[0]->posit, ep->p[1]->posit);
		break;
	case en_psub:
		ep->nodetype = en_pcon;
		ep->tp = ep->p[0]->tp;
		ep->posit.Sub(ep->p[0]->posit, ep->p[1]->posit);
		break;
	case en_pmul:
		ep->nodetype = en_pcon;
		ep->tp = ep->p[0]->tp;
		ep->posit.Multiply(ep->p[0]->posit, ep->p[1]->posit);
		break;
	case en_pdiv:
		ep->nodetype = en_pcon;
		ep->tp = ep->p[0]->tp;
		ep->posit.Divide(ep->p[0]->posit, ep->p[1]->posit);
		break;

	case en_asl:
  case en_shl:
	case en_shlu:
    ep->nodetype = en_icon;
    ep->i = ep->p[0]->i << ep->p[1]->i;
    break;
	case en_asr:
		ep->nodetype = en_icon;
		ep->i = ep->p[0]->i >> ep->p[1]->i;
		break;
	case en_shr:
    ep->nodetype = en_icon;
    ep->i = (unsigned)ep->p[0]->i >> (unsigned)ep->p[1]->i;
    break;
  case en_shru:
    ep->nodetype = en_icon;
    ep->i = (unsigned)ep->p[0]->i >> (unsigned)ep->p[1]->i;
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
	case en_land_safe:
	case en_land:
		ep->nodetype = en_icon;
		ep->i = ep->p[0]->i && ep->p[1]->i;
		break;
	case en_lor_safe:
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

	case en_feq:
		ep->nodetype = en_icon;
		ep->i = Float128::IsEqual(&ep->p[0]->f128, &ep->p[1]->f128);
		break;
	case en_fne:
		ep->nodetype = en_icon;
		ep->i = !Float128::IsEqual(&ep->p[0]->f128, &ep->p[1]->f128);
		break;
	case en_flt:
		ep->nodetype = en_icon;
//		ep->i = ep->p[0]->f < ep->p[1]->f;
		ep->i = Float128::IsLessThan(&ep->p[0]->f128, &ep->p[1]->f128);
		break;
	case en_fle:
		ep->nodetype = en_icon;
		ep->i = Float128::IsLessThan(&ep->p[0]->f128, &ep->p[1]->f128)
						|| Float128::IsEqual(&ep->p[0]->f128, &ep->p[1]->f128);
		break;
	case en_fgt:
		ep->nodetype = en_icon;
		ep->i = Float128::IsLessThan(&ep->p[1]->f128, &ep->p[0]->f128);
		break;
	case en_fge:
		ep->nodetype = en_icon;
		ep->i = Float128::IsLessThan(&ep->p[1]->f128, &ep->p[0]->f128)
						|| Float128::IsEqual(&ep->p[0]->f128, &ep->p[1]->f128);
		break;

	case en_safe_cond:
	case en_cond:
		ep->nodetype = ep->p[1]->p[0]->nodetype;
		ep->i = ep->p[0]->i ? ep->p[1]->p[0]->i : ep->p[1]->p[1]->i;
		ep->sp = ep->p[0]->i ? ep->p[1]->p[0]->sp : ep->p[1]->p[1]->sp;
		break;
	case en_sxb:
		ep->nodetype = en_icon;
		ep->i = (ep->p[0]->i & 0x100LL) ? ep->p[0]->i | 0xffffffffffffff00LL : ep->p[0]->i;
		break;
	case en_sxc:
		ep->nodetype = en_icon;
		ep->i = (ep->p[0]->i & 0x10000LL) ? ep->p[0]->i | 0xffffffffffff0000LL : ep->p[0]->i;
		break;
	case en_sxh:
		ep->nodetype = en_icon;
		ep->i = (ep->p[0]->i & 0x100000000LL) ? ep->p[0]->i | 0xffffffff00000000LL : ep->p[0]->i;
		break;
	case en_zxb:
		ep->nodetype = en_icon;
		ep->i = ep->p[0]->i & 0xffLL;
		break;
	case en_zxc:
		ep->nodetype = en_icon;
		ep->i = ep->p[0]->i & 0xffffLL;
		break;
	case en_zxh:
		ep->nodetype = en_icon;
		ep->i = ep->p[0]->i & 0xffffffffLL;
		break;

	case en_isnullptr:
		ep->nodetype = en_icon;
		ep->i = ep->p[0]->i == 0 || ep->p[0]->i == 0xFFF0100000000000LL;
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

    q = 1;
    p = 0;
    while( q > 0 )
    {
		if( q == i )
			return (p);
		q <<= 1LL;
		++p;
    }
    return (-1);
}

/*
 *      make a mod mask for a power of two.
 */
int mod_mask(int i)
{   
	int m;
    m = 0;
    while( i-- )
        m = (m << 1) | 1;
    return (m);
}

static void Opt0_addsub(ENODE** node)
{
	ENODE* ep;

	ep = *node;
	if (ep == (ENODE*)NULL)
		return;
	opt0(&(ep->p[0]));
	opt0(&(ep->p[1]));
	if (ep->p[0]->nodetype == en_icon) {
		if (ep->p[1]->nodetype == en_icon) {
			dooper(*node);
			return;
		}
		if (ep->p[0]->i == 0) {
			if (ep->nodetype == en_sub)
			{
				ep->p[0] = ep->p[1];
				ep->nodetype = en_uminus;
			}
			else
				*node = ep->p[1];
			return;
		}
		if (ep->p[0]->nodetype == en_pcon) {
			if (ep->p[1]->nodetype == en_pcon) {
				dooper(*node);
				return;
			}
		}
		// Place the constant node second in the add to allow
		// use of immediate mode instructions.
		if (ep->nodetype == en_add)
			swap_nodes(ep);
	}
	// Add or subtract of zero gets eliminated.
	else if (ep->p[1]->nodetype == en_icon) {
		if (ep->p[1]->i == 0) {
			*node = ep->p[0];
			return;
		}
	}
	return;
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
  int sc;
	int64_t val;

  ep = *node;
  if( ep == (ENODE *)NULL )
    return;
  switch( (*node)->nodetype ) {
  case en_ref:
	case en_ccwp:
	case en_cucwp:
		opt0(&((*node)->p[0]));
		return;
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
    opt0( &(ep->p[0]));
		if (ep->p[0]->nodetype == en_icon) {
			ep->nodetype = en_icon;
			ep->i = ep->p[0]->i;
		}
    return;
	case en_sxb:
	case en_sxc:
	case en_sxh:
	case en_zxb: case en_zxc: case en_zxh:
	case en_abs:
    opt0( &(ep->p[0]));
    if( ep->p[0]->nodetype == en_icon )
			dooper(*node);
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
										else if (ep->constflag) {
											ep->nodetype = en_icon;
										}
                    return;
            case en_tempfpref:
              opt0( &(ep->p[0]));
              if( ep->p[0] && ep->p[0]->nodetype == en_fcon )
              {
                ep->nodetype = en_fcon;
                ep->f = ep->p[0]->f;
								Float128::Assign(&ep->f128,&ep->p[0]->f128);
              }
              return;
						case en_temppref:
							opt0(&(ep->p[0]));
							if (ep->p[0] && ep->p[0]->nodetype == en_pcon)
							{
								ep->nodetype = en_pcon;
								ep->posit = ep->p[0]->posit;
							}
							return;
						case en_vadd:
						case en_vsub:
            case en_add:
            case en_sub:
							Opt0_addsub(node);
							return;
							/*
              opt0(&(ep->p[0]));
              opt0(&(ep->p[1]));
              if(ep->p[0]->nodetype == en_icon) {
                if(ep->p[1]->nodetype == en_icon) {
                  dooper(*node);
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
								if (ep->p[0]->nodetype == en_pcon) {
									if (ep->p[1]->nodetype == en_pcon) {
										dooper(*node);
										return;
									}
								}
						// Place the constant node second in the add to allow
						// use of immediate mode instructions.
						if (ep->nodetype==en_add)
							swap_nodes(ep);
                    }
					// Add or subtract of zero gets eliminated.
                    else if( ep->p[1]->nodetype == en_icon ) {
                        if( ep->p[1]->i == 0 ) {
                            *node = ep->p[0];
                            return;
                        }
                    }
                    return;
										*/
						case en_ptrdif:
							opt0(&(ep->p[0]));
							opt0(&(ep->p[1]));
							opt0(&(ep->p[4]));
							if (ep->p[0]->nodetype == en_icon) {
								if (ep->p[1]->nodetype == en_icon && ep->p[4]->nodetype == en_icon) {
									dooper(*node);
									return;
								}
							}
							break;
						case en_i2p:
						case en_i2d:
				opt0(&(ep->p[0]));
				if (ep->p[0]->nodetype == en_icon) {
					dooper(*node);
					return;
				}
				break;
			case en_d2i:
				opt0(&(ep->p[0]));
				if (ep->p[0]->nodetype == en_fcon) {
					ep->i = (long)ep->p[0]->f;
					ep->nodetype = en_icon;
					return;
				}
				break;
			case en_fadd:
			case en_fsub:
				opt0(&(ep->p[0]));
				opt0(&(ep->p[1]));
				if (ep->p[0]->nodetype == en_fcon) {
					if (ep->p[1]->nodetype == en_fcon) {
						dooper(*node);
						return;
					}
				}
				break;
			case en_fmul:
				opt0(&(ep->p[0]));
				opt0(&(ep->p[1]));
				if (ep->p[0]->nodetype == en_fcon) {
					if (ep->p[1]->nodetype == en_fcon) {
						dooper(*node);
						return;
					}
					//else if (ep->p[1]->nodetype == en_icon) {
					//	ep->nodetype = en_fcon;
					//	ep->f = ep->p[0]->f * ep->p[1]->i;
					//	return;
					//}
				}
				//else if (ep->p[0]->nodetype == en_icon) {
				//	if (ep->p[1]->nodetype == en_fcon) {
				//		ep->nodetype = en_fcon;
				//		ep->f = ep->p[0]->i * ep->p[1]->f;
				//		return;
				//	}
				//}
				break;
			case en_fdiv:
				opt0(&(ep->p[0]));
				opt0(&(ep->p[1]));
				if (ep->p[0]->nodetype == en_fcon) {
					if (ep->p[1]->nodetype == en_fcon) {
						dooper(*node);
						return;
					}
					//else if (ep->p[1]->nodetype == en_icon) {
					//	ep->nodetype = en_fcon;
					//	ep->f = ep->p[0]->f / ep->p[1]->i;
					//	return;
					//}
				}
				break;

			case en_padd:
			case en_psub:
				opt0(&(ep->p[0]));
				opt0(&(ep->p[1]));
				if (ep->p[0]->nodetype == en_pcon) {
					if (ep->p[1]->nodetype == en_pcon) {
						dooper(*node);
						return;
					}
				}
				break;
			case en_pmul:
				opt0(&(ep->p[0]));
				opt0(&(ep->p[1]));
				if (ep->p[0]->nodetype == en_pcon) {
					if (ep->p[1]->nodetype == en_pcon) {
						dooper(*node);
						return;
					}
				}
				break;
			case en_pdiv:
				opt0(&(ep->p[0]));
				opt0(&(ep->p[1]));
				if (ep->p[0]->nodetype == en_pcon) {
					if (ep->p[1]->nodetype == en_pcon) {
						dooper(*node);
						return;
					}
				}
				break;

			case en_isnullptr:
				opt0(&(ep->p[0]));
				if (ep->p[0]->nodetype == en_icon)
					dooper(*node);
				return;
			case en_wydendx:
			case en_bytendx:
				opt0(&(ep->p[0]));
				opt0(&(ep->p[1]));
				return;
			case en_mulf:
				opt0(&(ep->p[0]));
				opt0(&(ep->p[1]));
				if (ep->p[0]->nodetype == en_icon && ep->p[1]->nodetype == en_icon)
					dooper(*node);
				return;
			case en_vmul:
			case en_vmuls:
      case en_mul:
			case en_mulu:
        opt0(&(ep->p[0]));
        opt0(&(ep->p[1]));
        if( ep->p[0]->nodetype == en_icon ) {
            if( ep->p[1]->nodetype == en_icon ) {
                dooper(*node);
                return;
            }
						if (ep->p[1]->nodetype == en_fcon) {
							ep->nodetype = en_icon;
							ep->i = ep->p[0]->i * ep->p[1]->f;
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
								return;
            }
						// Place constant as oper2
						swap_nodes(ep);
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
							return;
            }
          }
          break;
      case en_div:
			case en_udiv:
        opt0(&(ep->p[0]));
        opt0(&(ep->p[1]));
        if( ep->p[0]->nodetype == en_icon ) {
          if( ep->p[1]->nodetype == en_icon ) {
            dooper(*node);
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
							ep->nodetype = en_shr;// ep->p[0]->isUnsigned ? en_shru : en_shr;???B
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
                                    dooper(*node);
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
	case en_fieldref:
		opt0(&(ep->p[0]));
		opt0(&(ep->bit_offset));
		opt0(&(ep->bit_width));
		break;
	case en_bitoffset:
	case en_ext:
	case en_extu:
		opt0(&(ep->p[0]));
		opt0(&(ep->p[1]));
		opt0(&(ep->p[2]));
		break;

	case en_and: 
  case en_or:
	case en_xor:    
    opt0(&(ep->p[0]));
    opt0(&(ep->p[1]));
		if (ep->p[0]->nodetype == en_icon &&
			ep->p[1]->nodetype == en_icon)
			dooper(*node);
		else if (ep->p[0]->nodetype == en_icon)
			swap_nodes(ep);
		break;

	case en_shr:	case en_shru:	case en_asr:
	case en_asl:	case en_shl:	case en_shlu:
    opt0(&(ep->p[0]));
    opt0(&(ep->p[1]));
    if( ep->p[0]->nodetype == en_icon &&
      ep->p[1]->nodetype == en_icon )
      dooper(*node);
// Shift by zero....
    else if( ep->p[1]->nodetype == en_icon ) {
      if( ep->p[1]->i == 0 ) {
        *node = ep->p[0];
        return;
      }
    }
    break;

	case en_land_safe:
  case en_land:   
    opt0(&(ep->p[0]));
    opt0(&(ep->p[1]));
		if (ep->p[0]->nodetype==en_icon && ep->p[1]->nodetype==en_icon)
			dooper(*node);
    break;
	case en_lor_safe:
  case en_lor:
    opt0(&(ep->p[0]));
    opt0(&(ep->p[1]));
		if (ep->p[0]->nodetype==en_icon && ep->p[1]->nodetype==en_icon)
			dooper(*node);
    break;

	case en_ult:	case en_ule:
	case en_ugt:	case en_uge:
	case en_lt:		case en_le:
	case en_gt:		case en_ge:
	case en_eq:		case en_ne:
    opt0(&(ep->p[0]));
    opt0(&(ep->p[1]));
		if (ep->p[0]->nodetype==en_icon && ep->p[1]->nodetype==en_icon)
			dooper(*node);
    break;

	case en_feq:
	case en_fne:
	case en_flt:
	case en_fle:
	case en_fgt:
	case en_fge:
		opt0(&(ep->p[0]));
		opt0(&(ep->p[1]));
		if (ep->p[0]->nodetype == en_fcon && ep->p[1]->nodetype == en_fcon)
			dooper(*node);
		break;
                case en_veq:    case en_vne:
                case en_vlt:    case en_vle:
                case en_vgt:    case en_vge:
                    opt0(&(ep->p[0]));
                    opt0(&(ep->p[1]));
                    break;
								case en_safe_cond:
			case en_cond:
                    opt0(&(ep->p[0]));
					opt0(&(ep->p[1]->p[0]));
					opt0(&(ep->p[1]->p[1]));
					if ((ep->p[0]->nodetype==en_icon||ep->p[0]->nodetype==en_cnacon) &&
						 (ep->p[1]->p[0]->nodetype==en_icon || ep->p[1]->p[0]->nodetype==en_cnacon) &&
						 (ep->p[1]->p[1]->nodetype==en_icon || ep->p[1]->p[1]->nodetype==en_cnacon))
						dooper(*node);
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
            case en_fcall:
                    opt0(&(ep->p[0]));
                    opt0(&(ep->p[1]));
                    break;
            case en_assign:
                    opt0(&(ep->p[0]));
                    opt0(&(ep->p[1]));
                    break;
						case en_void:
							opt0(&(ep->p[0]));
							opt0(&(ep->p[1]));
							break;
						// en_tempref comes from typecasting
						// The value for a cast is really ep->p[1]
						// The type of the cast is from ep->p[0]
						case en_cast:
							opt0(&(ep->p[0]));
							opt0(&(ep->p[1]));
							if (ep->p[0]->nodetype == en_tempref) {
								//(*node)->nodetype = ep->p[1]->nodetype;
								*node = ep->p[1];
								(*node)->tp = ep->p[0]->tp;
								(*node)->nodetype = ep->p[0]->nodetype;
							}
							break;
	case en_addrof:
		opt0(&(ep->p[0]));
		break;
	case en_list:
		for (ep = ep->p[2]; ep; ep = ep->p[2])
			opt0(&(ep->p[0]));
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
								case en_pcon:
									i = node->posit.val;
									node->posit.val = 0;
									return i;
								case en_pregvar:
									if (node->rg == regZero) {
										i = 0;
										node->posit = 0;
										return (i);
									}
									return (0);
								case en_regvar:
									if (node->rg == regZero) {
										i = 0;
										node->i = 0;
										return (i);
									}
									return (0);
				case en_sxb: case en_sxc: case en_sxh:
				case en_zxb: case en_zxc: case en_zxh:
				case en_abs:
				case en_isnullptr:
					return (0);
						return xfold(node->p[0]);
                case en_add:
                  return xfold(node->p[0]) + xfold(node->p[1]);
                case en_sub:
									return xfold(node->p[0]) - xfold(node->p[1]);
								case en_mulf:
                case en_mul:
				case en_mulu:
					return (0);
                        if( node->p[0]->nodetype == en_icon )
                                return xfold(node->p[1]) * node->p[0]->i;
                        else if( node->p[1]->nodetype == en_icon )
                                return xfold(node->p[0]) * node->p[1]->i;
                        else return 0;
				case en_asl:
				case en_shl:	case en_shlu:
                        if( node->p[0]->nodetype == en_icon )
                                return xfold(node->p[1]) << node->p[0]->i;
                        else if( node->p[1]->nodetype == en_icon )
                                return xfold(node->p[0]) << node->p[1]->i;
                        else return 0;
                case en_uminus:
                        return - xfold(node->p[0]);
								case en_ext: case en_extu:
									fold_const(&node->p[0]);
									fold_const(&node->p[1]);
									fold_const(&node->p[2]);
									return 0;
				case en_shr:    case en_div:	case en_udiv:	case en_shru: case en_asr:
				case en_mod:    case en_asadd:	case en_bytendx:	case en_wydendx:
                case en_assub:  case en_asmul:
                case en_asdiv:  case en_asmod:
								case en_and:    case en_land:	case en_land_safe:
								case en_or:		case en_lor:	case en_lor_safe:
                case en_xor:    case en_asand:
								case en_asor:   case en_void:		case en_cast:
                case en_fcall:  case en_assign:
                        fold_const(&node->p[0]);
                        fold_const(&node->p[1]);
                        return 0;
				case en_ref:
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
{       
	ENODE *ep;
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
                        ep->p[1]->i = xfold(ep->p[0]) - ep->p[1]->i;	// ??? other order ??? xfold - p[1]
                        return;
                        }
                }
        i = xfold(ep);
        if( i != 0 )
                {
                ep = makeinode(en_icon,i);
				ep->etype = (*node)->etype;
				ep->tp = (*node)->tp;
                ep = makenode(en_add,ep,*node);
				ep->etype = (*node)->etype;
				ep->tp = (*node)->tp;
				*node = ep;
                }
}

void opt_const_unchecked(ENODE **node)
{
	dfs.printf("<OptConst2>");
	opt0(node);
//	fold_const(node);
	opt0(node);
	opt0(node);
	dfs.printf("</OptConst2>");
}

//
//      apply all constant optimizations.
//
void opt_const(ENODE **node)
{
	dfs.printf("<OptConst>");
    if (opt_noexpr==FALSE) {
    	opt0(node);
//    	fold_const(node);
    	opt0(node);
			opt0(node);
		}
	dfs.printf("</OptConst>");
}

