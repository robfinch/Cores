#include "stdafx.h"

// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C64 - 'C' derived language compiler
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
extern int pass;
//
// Copy the node passed into a new enode so it wont get corrupted during
// substitution.
//
ENODE *ENODE::Duplicate()
{       
	ENODE *temp;

    if( this == NULL )
        return (ENODE *)NULL;
    temp = ENODE::alloc();
	memcpy(temp,this,sizeof(ENODE));	// copy all the fields
    return (temp);
}


ENODE *ENODE::alloc()
{
	ENODE *p;
	p = (ENODE *)allocx(sizeof(ENODE));
	p->sp = new std::string();
	return p;
};

bool ENODE::IsEqual(ENODE *node1, ENODE *node2)
{
    if (node1 == NULL || node2 == NULL) {
		return false;
    }
    if (node1->nodetype != node2->nodetype) {
		return false;
    }
    switch (node1->nodetype) {
//			return (node1->f == node2->f);
	case en_regvar:
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
		if( node1->IsLValue(true) && IsEqual(node1->p[0], node2->p[0])  )
			return true;
		return false;
	}
}

//
// This function returns true if the node passed is an IsLValue.
// this can be qualified by the fact that an IsLValue must have
// one of the dereference operators as it's top node.
//
// opt indicates if an array reference is an LValue or not.
bool ENODE::IsLValue(bool opt)
{
	if (this==nullptr)
		return false;
	switch( nodetype ) {
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
	case en_wfieldref:
	case en_uwfieldref:
	case en_bfieldref:
	case en_ubfieldref:
	case en_cfieldref:
	case en_ucfieldref:
	case en_hfieldref:
	case en_uhfieldref:
    case en_triple_ref:
	case en_dbl_ref:
	case en_quad_ref:
	case en_flt_ref:
	case en_struct_ref:
	case en_ref32:
	case en_ref32u:
            return true;
	case en_cbc:
	case en_cbh:
    case en_cbw:
	case en_cch:
	case en_ccw:
	case en_chw:
	case en_cfd:
	case en_cubw:
	case en_cucw:
	case en_cuhw:
	case en_cbu:
	case en_ccu:
	case en_chu:
	case en_cubu:
	case en_cucu:
	case en_cuhu:
            return p[0]->IsLValue(opt);
	// Array references typically begin with an add node. This evaluates to an
	// address pointer which is an LValue. Similarly for an array auto. Sometimes
	// it's desirable not to have these as LValues. Seems like a problem with
	// references, but this seems to work.
	case en_add:
		if (tp)
			return tp->type==bt_pointer && tp->isArray && opt;
		else
			return false;
	case en_autocon:
		return etype==bt_pointer && tp->isArray && opt;
    }
    return false;
}


//
// Apply all constant optimizations.
//
extern void opt0(ENODE **);
extern void fold_const(ENODE **);

void ENODE::OptimizeConstants(ENODE **pnode)
{
    if (opt_noexpr==FALSE) {
    	opt0(pnode);
    	fold_const(pnode);
    	opt0(pnode);
    }
}

