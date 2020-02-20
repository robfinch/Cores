// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2020  Robert Finch, Waterloo
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

void swap_nodes(ENODE *node)
{
	ENODE *temp;
	temp = node->p[0];
	node->p[0] = node->p[1];
	node->p[1] = temp;
}

bool ENODE::IsEqualOperand(Operand *a, Operand *b)
{
	return (Operand::IsEqual(a, b));
};

char ENODE::fsize()
{
	switch (etype) {
	case bt_float:	return ('d');
	case bt_double:	return ('d');
	case bt_triple:	return ('t');
	case bt_quad:	return ('q');
	default:	return ('d');
	}
}

bool ENODE::HasAssignop()
{
	if (this == nullptr)
		return (false);
	if (nodetype == en_asadd
		|| nodetype == en_asadd
		|| nodetype == en_asdiv
		|| nodetype == en_asdivu
		|| nodetype == en_asmod
		|| nodetype == en_asmodu
		|| nodetype == en_asmul
		|| nodetype == en_asmulu
		|| nodetype == en_asor
		|| nodetype == en_asand
		|| nodetype == en_asxor
		|| nodetype == en_assub
		|| nodetype == en_assign
		|| nodetype == en_fcall
		|| nodetype == en_ifcall
		)
		return (true);
	if (p[0]->HasAssignop())
		return (true);
	if (p[1]->HasAssignop())
		return(true);
	if (p[2]->HasAssignop())
		return (true);
	return(false);
}

bool ENODE::HasCall()
{
	if (this == nullptr)
		return (false);
	if (nodetype == en_fcall)
		return (true);
	if (p[0]->HasCall())
		return (true);
	if (p[1]->HasCall())
		return (true);
	if (p[1]->HasCall())
		return (true);
	return (false);
}

int64_t ENODE::GetReferenceSize()
{
	switch (nodetype)        /* get load size */
	{
	case en_ref:
	case en_fieldref:
		return (tp->size);
	case en_fpregvar:
		if (tp)
			return(tp->size);
		else
			return (sizeOfFPD);
	case en_tempref:
	case en_regvar:
		return (sizeOfWord);
		//			return node->esize;
	}
	return (sizeOfWord);
}
// return the natural evaluation size of a node.

int ENODE::GetNaturalSize()
{
	int siz0, siz1;
	if (this == NULL)
		return 0;
	switch (nodetype)
	{
	case en_fieldref:
		return (tp->size);
	case en_icon:
		if (i >= -128 && i < 128)
			return (1);
		if (-32768 <= i && i <= 32767)
			return (2);
		if (-2147483648LL <= i && i <= 2147483647LL)
			return (4);
		return (sizeOfWord);
	case en_fcon:
		return (tp->precision / 16);
	case en_tcon: return (6);
	case en_labcon: case en_clabcon:
	case en_cnacon: case en_nacon:  case en_autocon: case en_classcon:
	case en_tempref:
	case en_cbw: case en_cubw:
	case en_ccw: case en_cucw:
	case en_chw: case en_cuhw:
	case en_cbu: case en_ccu: case en_chu:
	case en_cubu: case en_cucu: case en_cuhu:
	case en_ccwp: case en_cucwp:
	case en_sxb:	case en_sxc:	case en_sxh:
		return (sizeOfWord);
	case en_fcall:
	case en_regvar:
	case en_fpregvar:
		if (tp)
			return (tp->size);
		else
			return (sizeOfWord);
	case en_autofcon:
		return (sizeOfWord);
	case en_ref:
		return (tp->size);
	case en_cbc:
	case en_cbh:	return (4);
	case en_cch:	return (4);
	case en_autovcon:
	case en_tempfpref:
		if (tp)
			return (tp->precision / 8);
		else
			return (sizeOfWord);
	case en_not:    case en_compl:
	case en_uminus: case en_assign:
		return p[0]->GetNaturalSize();
	case en_fadd:	case en_fsub:
	case en_fmul:	case en_fdiv:
	case en_fsadd:	case en_fssub:
	case en_fsmul:	case en_fsdiv:
	case en_vadd:	case en_vsub:
	case en_vmul:	case en_vdiv:
	case en_vadds:	case en_vsubs:
	case en_vmuls:	case en_vdivs:
	case en_add:    case en_sub:	case en_ptrdif:
	case en_mul:    case en_mulu:
	case en_div:	case en_udiv:
	case en_mod:    case en_umod:
	case en_and:    case en_or:     case en_xor:
	case en_asl:
	case en_shl:    case en_shlu:
	case en_shr:	case en_shru:
	case en_asr:	case en_asrshu:
	case en_feq:    case en_fne:
	case en_flt:    case en_fle:
	case en_fgt:    case en_fge:
	case en_eq:     case en_ne:
	case en_lt:     case en_le:
	case en_gt:     case en_ge:
	case en_ult:	case en_ule:
	case en_ugt:	case en_uge:
	case en_land:   case en_lor:
	case en_land_safe:   case en_lor_safe:
	case en_asadd:  case en_assub:
	case en_asmul:  case en_asmulu:
	case en_asdiv:	case en_asdivu:
	case en_asmod:  case en_asmodu: case en_asand:
	case en_asor:   case en_asxor:	case en_aslsh:
	case en_asrsh:
		siz0 = p[0]->GetNaturalSize();
		siz1 = p[1]->GetNaturalSize();
		if (siz1 > siz0)
			return (siz1);
		else
			return (siz0);
	case en_void:   case en_cond:	case en_safe_cond:
		return (p[1]->GetNaturalSize());
	case en_bchk:
		return (p[0]->GetNaturalSize());
	case en_chk:
		return 8;
	case en_q2i:
	case en_t2i:
		return (sizeOfWord);
	case en_i2d:
		return (sizeOfWord);
	case en_i2t:
	case en_d2t:
		return (sizeOfFPT);
	case en_i2q:
	case en_d2q:
	case en_t2q:
		return (sizeOfFPQ);
	case en_object_list:
		return (p[0]->GetNaturalSize());
	case en_addrof:
		return (sizeOfPtr);
	default:
		printf("DIAG - natural size error %d.\n", nodetype);
		break;
	}
	return (0);
}


bool ENODE::IsBitfield()
{
	return (nodetype == en_fieldref);
}

bool ENODE::IsSameType(ENODE *node1, ENODE *node2)
{
	if (node1 == nullptr && node2 == nullptr)
		return (true);
	// If we have a null pointer for the expression it may be a
	// void pointer.
	if (node1 == nullptr || node2 == nullptr)
		return (true);
	if (node1->nodetype == en_icon && node2->nodetype == en_icon)
		return (true);
	return (TYP::IsSameType(node1->tp, node2->tp, false));
}

//
// equalnode will return 1 if the expressions pointed to by
// node1 and node2 are equivalent.
//
bool ENODE::IsEqual(ENODE *node1, ENODE *node2, bool lit)
{
	ENODE *ep1, *ep2;

	if (node1 == nullptr && node2 == nullptr)
		return (true);
	if (!lit) {
		if (node1 == nullptr || node2 == nullptr) {
			return (false);
		}
	}
	else {
		if (node1 == nullptr || node2 == nullptr)
			return (true);
	}
	if (node1->nodetype != node2->nodetype) {
		return (false);
	}
	switch (node1->nodetype) {
	case en_fcon:
		return (Float128::IsEqual(&node1->f128, &node2->f128));
		//			return (node1->f == node2->f);
	case en_regvar:
		return (node1->rg == node2->rg);
	case en_fpregvar:
		return (node1->rg == node2->rg);
	case en_tempref:
	case en_tempfpref:
	case en_icon:
	case en_labcon:
	case en_classcon:	// Check type ?
	case en_autocon:
	case en_autovcon:
	case en_autofcon:
	{
		return (node1->i == node2->i);
	}
	case en_nacon: {
		return (node1->sp->compare(*node2->sp) == 0);
	}
	case en_cnacon:
		return (node1->sp->compare(*node2->sp) == 0);
	case en_aggregate:
		return (IsEqual(node1->p[0], node2->p[0], lit));
	case en_list:
		for (ep1 = node1->p[2],
				 ep2 = node2->p[2];
				 ep1 && ep2; ep1 = ep1->p[2], ep2 = ep2->p[2]) {
			if (!IsEqual(ep1->p[0], ep2->p[0], lit))
				return (false);
			if (!IsEqual(ep1->p[1], ep2->p[1], lit))
				return (false);
		}
		if (ep1 != nullptr && ep2 != nullptr)
			return (true);
		return(false);
	default:
		if (!IsEqual(node1->p[0], node2->p[0], lit))
			return (false);
		if (!IsEqual(node1->p[1], node2->p[1], lit))
			return (false);
		if (!IsEqual(node1->p[2], node2->p[2], lit))
			return (false);
		return (true);
		//if (IsLValue(node1) && IsEqual(node1->p[0], node2->p[0])) {
		//	//	        if( equalnode(node1->p[0], node2->p[0])  )
		//	return (true);
		//}
	}
	return (false);
}


// For purposes of optimization we only care about cloning the node being
// worked on, not the other nodes that are connected to it. So, clone doesn't
// do a full clone in order to improve the compiler's performance. A real
// clone would clone the whole tree, but it's not required in the current
// compiler.

ENODE *ENODE::Clone()
{
	ENODE *temp;

	if (this == nullptr)
		return (ENODE *)nullptr;
	temp = allocEnode();
	memcpy(temp, this, sizeof(ENODE));	// copy all the fields
//	temp->p[0] = p[0]->Clone();
//	temp->p[1] = p[1]->Clone();
//	temp->p[2] = p[2]->Clone();
	return (temp);
}

// ============================================================================
// ============================================================================
// Parsing
// ============================================================================
// ============================================================================

// Assign a type to a whole list.

bool ENODE::AssignTypeToList(TYP *tp)
{
	ENODE *ep;
	bool isConst = true;
	TYP *btp;
	int ne, cnt;

	if (nodetype != en_aggregate)
		return (false);

	esize = 0;
	this->tp = tp;
	this->tp->isConst = isConst;
	this->esize = tp->size;
	if (tp->isArray) {
		ne = tp->numele;
		cnt = 0;
		btp = tp->GetBtp();
		for (ep = p[0]->p[2]; ep; ep = ep->p[2]) {
			cnt++;
			ep->tp = btp;
			ep->tp->isConst = isConst;
			ep->esize = btp->size;
			//if (!ep->tp->isConst)
			//	isConst = false;
			if (btp->isArray) {
				if (ep->nodetype == en_aggregate) {
					if (!ep->AssignTypeToList(btp))
						isConst = false;
				}
			}
			else if (btp->IsAggregateType()) {
				if (ep->nodetype == en_aggregate) {
					if (!ep->AssignTypeToList(btp))
						isConst = false;
				}
			}
		}
		//if (cnt < tp->numele) {
		//	esize += (tp->numele - cnt) * btp->size;
		//}
	}
	else if (tp->IsAggregateType()) {
		SYM *thead;

		thead = SYM::GetPtr(tp->lst.GetHead());
		for (ep = p[0]->p[2]; thead && ep; ) {
			ep->tp = thead->tp;
			ep->tp->isConst = isConst;
			ep->esize = thead->tp->size;
			if (thead->tp->IsAggregateType()) {
				if (ep->nodetype == en_aggregate) {
					if (!ep->AssignTypeToList(thead->tp))
						isConst = false;
				}
			}
			ep = ep->p[2];
			thead = SYM::GetPtr(thead->next);
		}
	}
	return (isConst);
}


// ============================================================================
// ============================================================================
// Optimization
// ============================================================================
// ============================================================================

//	repexpr will replace all allocated references within an expression
//	with tempref nodes.

void ENODE::repexpr()
{
	CSE *csp;
	ENODE *ep;

	if (this == nullptr)
		return;
	switch (nodetype) {
	case en_fcon:
	case en_tempfpref:
		if ((csp = currentFn->csetbl->Search(this)) != nullptr) {
			csp->isfp = TRUE; //**** a kludge
			if (csp->reg > 0) {
				nodetype = en_fpregvar;
				rg = csp->reg;
			}
		}
		break;
	// Autofcon resolve to *pointers* which are stored in integer registers.
	case en_autofcon:
		if ((csp = currentFn->csetbl->Search(this)) != nullptr) {
			csp->isfp = FALSE; //**** a kludge
			if (csp->reg > 0) {
				nodetype = en_fpregvar;
				rg = csp->reg;
			}
		}
		break;
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
	case en_autovcon:
	case en_autocon:
	case en_classcon:
	case en_cnacon:
	case en_clabcon:
	case en_tempref:
		if ((csp = currentFn->csetbl->Search(this)) != NULL) {
			if (!csp->voidf) {
				if (csp->reg > 0) {
					nodetype = en_regvar;
					rg = csp->reg;
				}
			}
		}
		break;
	/*
	case en_c_ref:
	case en_uc_ref:
	case en_w_ref:
	case en_wp_ref:
		if (p[0]->IsAutocon()) {
			if ((csp = currentFn->csetbl->Search(this)) != NULL) {
				if (!csp->voidf) {
					if (csp->reg > 0) {
						new_nodetype = en_regvar;
						rg = csp->reg;
						p[0]->repexpr();
					}
					else
						p[0]->repexpr();
				}
				else
					p[0]->repexpr();
				//while (csp = currentFn->csetbl->SearchNext(this)) {
				//	if (!csp->voidf) {
				//		if (csp->reg > 0) {
				//			new_nodetype = en_regvar;
				//			rg = csp->reg;
				//		}
				//		else
				//			p[0]->repexpr();
				//	}
				//}
			}
			else
				p[0]->repexpr();
			break;
		}
		p[0]->repexpr();
		p[1]->repexpr();
		break;
	*/
	case en_ref:
	case en_fieldref:
		if ((csp = currentFn->csetbl->Search(this)) != NULL) {
			if (csp->reg > 0) {
				nodetype = en_regvar;
				rg = csp->reg;
			}
			else
				p[0]->repexpr();
		}
		else
			p[0]->repexpr();
		break;
	case en_cbc: case en_cubw:
	case en_cbh: case en_cucw:
	case en_cbw: case en_cuhw:
	case en_cbu: case en_ccu: case en_chu:
	case en_cubu: case en_cucu: case en_cuhu:
	case en_ccwp: case en_cucwp:
	case en_cch:
	case en_ccw:
	case en_chw:
	case en_uminus:
	case en_abs:
	case en_sxb: case en_sxh: case en_sxc:
	case en_not:    case en_compl:
	case en_chk:
		p[0]->repexpr();
		p[1]->repexpr();
		break;
	case en_i2d:
		p[0]->repexpr();
		p[1]->repexpr();
		break;
	case en_i2q:
	case en_d2i:
	case en_q2i:
	case en_s2q:
	case en_d2q:
	case en_t2q:
		p[0]->repexpr();
		break;
	case en_asadd:
	case en_add:    
		p[0]->repexpr();
		p[1]->repexpr();
		break;
	case en_sub:
	case en_mulf:   case en_mul:    case en_mulu:   case en_div:	case en_udiv:
	case en_mod:    case en_umod:
	case en_shl:	case en_asl:
	case en_shlu:	case en_shru:	case en_asr:
	case en_shr:
	case en_and:
	case en_or:     case en_xor:
	case en_land:   case en_lor:
	case en_land_safe:   case en_lor_safe:
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

	case en_veq:    case en_vne:
	case en_vlt:    case en_vle:
	case en_vgt:    case en_vge:
	case en_vadd: case en_vsub:
	case en_vmul: case en_vdiv:
	case en_vadds: case en_vsubs:
	case en_vmuls: case en_vdivs:

	case en_safe_cond:
	case en_assub:
	case en_asmul:  case en_asmulu:
	case en_asdiv:  case en_asdivu:
	case en_asor:   case en_asand:    case en_asxor:
	case en_asmod:  case en_aslsh:
	case en_asrsh:  case en_fcall:
	case en_aggregate:
	case en_void:
		p[0]->repexpr();
		p[1]->repexpr();
		break;
	case en_assign:
		p[0]->repexpr();
		p[1]->repexpr();
		break;
	case en_cond:
		p[0]->repexpr();
		p[1]->repexpr();
		break;
	case en_list:
		for (ep = p[2]; ep; ep = ep->p[2]) {
			ep->p[0]->repexpr();
			ep->p[1]->repexpr();
		}
		break;
	case en_regvar:
	case en_fpregvar:
		p[0]->repexpr();
		p[1]->repexpr();
		break;
	case en_ptrdif:
	case en_bchk:
		p[0]->repexpr();
		p[1]->repexpr();
		p[2]->repexpr();
		break;
	case en_isnullptr:
	case en_addrof:
		p[0]->repexpr();
		break;
	default:
		dfs.printf("Uncoded node in repexr():%d\r\n", nodetype);
	}
	if (pfl)
		pfl->repexpr();
}


CSE *ENODE::OptInsertAutocon(int duse)
{
	int nn;
	CSE *csp;
	bool first;

	if (this == nullptr)
		return (nullptr);
	nn = currentFn->csetbl->voidauto2(this);
	csp = currentFn->csetbl->InsertNode(this, duse, &first);
	if (nn >= 0) {
		csp->duses += loop_active + nn;
		csp->uses = csp->duses - loop_active;
	}
	return (csp);
}

CSE *ENODE::OptInsertRef(int duse)
{
	CSE *csp;
	bool first;
	ENODE *ep;

	csp = nullptr;
	// Search the chain of refs.
	for (ep = p[0]; ep->IsRefType(); ep = ep->p[0])
		;
	ep = p[0];
	if (ep->IsAutocon()) {
		csp = currentFn->csetbl->InsertNode(this, duse, &first);
		// take care: the non-derereferenced use of the autocon node may
		// already be in the list. In this case, set voidf to 1
		if (currentFn->csetbl->Search(p[0]) != NULL) {
			csp->voidf = 1;
			p[0]->scanexpr(1);
			if (pfl)
				pfl->scanexpr(1);
		}
		else {
			if (csp->voidf) {
				p[0]->scanexpr(1);
				if (pfl)
					pfl->scanexpr(1);
			}
			if (first) {
				// look for register nodes
				int j = p[0]->rg;
				if ((p[0]->nodetype == en_regvar) &&
					(j >= regFirstRegvar && j <= regLastRegvar))
				{
					csp->voidf = false;
					csp->AccUses(3);
					csp->AccDuses(1);
				}
				if ((p[0]->nodetype == en_regvar) &&
					(j >= regFirstArg && j <= regLastArg))
				{
					csp->voidf = false;
				}
				// even if that item must not be put in a register,
				// it is legal to put its address therein
				if (csp->voidf)
				  p[0]->scanexpr(1);
			}
		}
	}
	else
	{
	//	//			csp = currentFn->csetbl->InsertNode(this, duse);
		p[0]->scanexpr(1);
		p[1]->scanexpr(1);
		p[2]->scanexpr(1);
		if (pfl)
			pfl->scanexpr(1);
	}
	return (csp);
}

/*
*      scanexpr will scan the expression pointed to by node for optimizable
*      subexpressions. when an optimizable expression is found it is entered
*      into the tree. if a reference to an autocon node is scanned the
*      corresponding auto dereferenced node will be voided. duse should be
*      set if the expression will be dereferenced.
*/
void ENODE::scanexpr(int duse)
{
	CSE *csp;
	bool first;
	ENODE *ep;

	if (this == nullptr)
		return;

	switch (nodetype) {
	case en_fpregvar:
	case en_regvar:
		currentFn->csetbl->InsertNode(this, duse, &first);
		break;
	case en_cnacon:
	case en_clabcon:
	case en_fcon:
	case en_icon:
	case en_labcon:
	case en_nacon:
		currentFn->csetbl->InsertNode(this, duse, &first);
		break;
	case en_autofcon:
	case en_tempfpref:
		csp = OptInsertAutocon(duse);
		csp->isfp = FALSE;
		break;
	case en_autovcon:
	case en_autocon:
	case en_classcon:
	case en_tempref:
		OptInsertAutocon(duse);
		break;
	case en_cbc: case en_cubw:
	case en_cbh: case en_cucw:
	case en_cbw: case en_cuhw:
	case en_cbu: case en_ccu: case en_chu:
	case en_cubu: case en_cucu: case en_cuhu:
	case en_ccwp: case en_cucwp:
	case en_cch:
	case en_ccw:
	case en_chw:
		p[0]->scanexpr(duse);
		break;
	case en_ref:
	case en_fieldref:
		OptInsertRef(duse);
		break;
	case en_uminus:
	case en_abs:
	case en_sxb: case en_sxc: case en_sxh:
	case en_zxb: case en_zxc: case en_zxh:
	case en_compl:
	case en_not:
	case en_chk:
		p[0]->scanexpr(duse);
		break;
	case en_i2d:
		p[0]->scanexpr(duse);
		break;
	case en_i2q:
	case en_d2i:
	case en_q2i:
	case en_s2q:
	case en_d2q:
	case en_t2q:
		p[0]->scanexpr(duse);
		break;
	case en_asadd:  
	case en_assub:
	case en_add:    case en_sub:
		p[0]->scanexpr(duse);
		p[1]->scanexpr(duse);
		break;
	case en_mulf:
	case en_mul:    case en_mulu:   case en_div:	case en_udiv:
	case en_shl:    case en_asl:	case en_shlu:	case en_shr:	case en_shru:	case en_asr:
	case en_mod:    case en_umod:   case en_and:
	case en_or:     case en_xor:
	case en_lor:    case en_land:
	case en_lor_safe:    case en_land_safe:
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

	case en_veq:    case en_vne:
	case en_vlt:    case en_vle:
	case en_vgt:    case en_vge:
	case en_vadd: case en_vsub:
	case en_vmul: case en_vdiv:
	case en_vadds: case en_vsubs:
	case en_vmuls: case en_vdivs:

	case en_asmul:  case en_asmulu:
	case en_asdiv:	case en_asdivu:
	case en_asmod:  case en_aslsh:
	case en_asrsh:
	case en_asand:	case en_asxor: case en_asor:
	case en_cond:	case en_safe_cond:
	case en_void:
	case en_aggregate:
		p[0]->scanexpr(0);
		p[1]->scanexpr(0);
		break;
	case en_list:
		for (ep = p[2]; ep; ep = ep->p[2]) {
			ep->p[0]->scanexpr(0);
			ep->p[1]->scanexpr(0);
		}
		break;
	case en_assign:
		p[0]->scanexpr(0);
		p[1]->scanexpr(0);
		break;
	case en_fcall:
		p[0]->scanexpr(1);
		p[1]->scanexpr(0);
		break;
	case en_ptrdif:
	case en_bchk:
		p[0]->scanexpr(0);
		p[1]->scanexpr(0);
		p[2]->scanexpr(0);
		break;
	case en_isnullptr:
	case en_addrof:
		p[0]->scanexpr(0);
		break;
	default: dfs.printf("Uncoded node in ENODE::scanexpr():%d\r\n", nodetype);
	}
	if (pfl)
		pfl->scanexpr(0);
}

// Debugging use
void ENODE::update()
{
	if (this == nullptr)
		return;
	if (IsAutocon() || IsRefType())
	{
		if (new_nodetype != en_unknown)
			nodetype = new_nodetype;
	}
	p[0]->update();
	p[1]->update();
	p[2]->update();
	if (pfl)
		pfl->update();
}

// ============================================================================
// ============================================================================
// Code Generation
// ============================================================================
// ============================================================================

Operand *ENODE::MakeDataLabel(int lab)
{
	return (compiler.of.MakeDataLabel(lab));
}

Operand *ENODE::MakeCodeLabel(int lab)
{
	return (compiler.of.MakeCodeLabel(lab));
}

Operand *ENODE::MakeStringAsNameConst(char *s)
{
	return (compiler.of.MakeStringAsNameConst(s));
}

Operand *ENODE::MakeString(char *s)
{
	return (compiler.of.MakeString(s));
}

Operand *ENODE::MakeImmediate(int64_t i)
{
	return (compiler.of.MakeImmediate(i));
}

Operand *ENODE::MakeIndirect(int i)
{
	return (compiler.of.MakeIndirect(i));
}

Operand *ENODE::MakeIndexed(int64_t o, int i)
{
	return (compiler.of.MakeIndexed(o, i));
}

Operand *ENODE::MakeDoubleIndexed(int i, int j, int scale)
{
	return (compiler.of.MakeDoubleIndexed(i, j, scale));
}

Operand *ENODE::MakeDirect(ENODE *node)
{
	return (compiler.of.MakeDirect(node));
}

Operand *ENODE::MakeIndexed(ENODE *node, int rg)
{
	return (compiler.of.MakeIndexed(node, rg));
}

void ENODE::GenerateHint(int num)
{
	GenerateMonadic(op_hint, 0, MakeImmediate(num));
}

void ENODE::GenLoad(Operand *ap3, Operand *ap1, int ssize, int size)
{
	cg.GenLoad(ap3, ap1, ssize, size);
}
void ENODE::GenStore(Operand *ap1, Operand *ap3, int size)
{
	cg.GenStore(ap1, ap3, size);
}

void ENODE::GenMemop(int op, Operand *ap1, Operand *ap2, int ssize)
{
	cg.GenMemop(op, ap1, ap2, ssize);
}

void ENODE::GenRedor(Operand *ap1, Operand *ap2)
{
	GenerateDiadic(op_not, 0, ap1, ap2);
	GenerateDiadic(op_not, 0, ap1, ap1);
}

// ----------------------------------------------------------------------------
// Generate code to evaluate an index node (^+) and return the addressing mode
// of the result. This routine takes no flags since it always returns either
// am_ind or am_indx.
//
// No reason to ReleaseTempReg() because the registers used are transported
// forward.
// ----------------------------------------------------------------------------
Operand *ENODE::GenIndex()
{
	Operand *ap1, *ap2, *ap3;
	int rg, rg1, rg2;

	if ((p[0]->nodetype == en_tempref || p[0]->nodetype == en_regvar)
		&& (p[1]->nodetype == en_tempref || p[1]->nodetype == en_regvar))
	{       /* both nodes are registers */
			// Don't need to free ap2 here. It is included in ap1.
		GenerateHint(8);
		ap3 = GetTempRegister();
		ap1 = p[0]->Generate(am_reg, sizeOfWord);
		ap2 = p[1]->Generate(am_reg, sizeOfWord);
		if (scale > 1) {
			GenerateTriadic(op_sll, 0, ap3, ap2, MakeImmediate(scale));
			GenerateTriadic(op_add, 0, ap3, ap1, ap3);
		}
		else
			GenerateTriadic(op_add, 0, ap3, ap2, ap1);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		//GenerateHint(9);
		//ap1->mode = am_indx2;
		ap3->mode = am_indx;
		ap3->offset = makeinode(en_icon, 0);
		//ap1->scale = scale;
		return (ap3);
	}
	GenerateHint(8);
	ap1 = p[0]->Generate(am_reg | am_imm, sizeOfWord);
	if (ap1->mode == am_imm)
	{
		ap2 = p[1]->Generate(am_reg | am_imm, sizeOfWord);
		if (ap2->mode == am_reg && ap2->preg==0) {	// value is zero
			ap1->mode = am_direct;
			if (ap1->offset)
				DataLabels[ap1->offset->i] = true;
			return (ap1);
		}
		ap2->isConst = ap2->mode==am_imm;
		if (ap2->mode == am_imm && ap2->offset->i != 0)
			ap2->offset2 = ap2->offset;
		else
			ap2->offset2 = nullptr;
		GenerateHint(9);
		ap2->mode = am_indx;
		ap2->offset = ap1->offset;
		ap2->isUnsigned = ap1->isUnsigned;
		ReleaseTempRegister(ap1);
		return (ap2);
	}
	ap2 = p[1]->Generate(am_all, sizeOfWord);   /* get right op */
	GenerateHint(9);
	if (ap2->mode == am_imm && ap1->mode == am_reg) /* make am_indx */
	{
		ap1->mode = am_indx;
		//ap2->preg = ap1->preg;
		//ap2->deep = ap1->deep;
		ap1->offset = ap2->offset;
		ap1->offset2 = ap2->offset2;
		return (ap1);
	}
	if (ap2->mode == am_ind && ap1->mode == am_reg) {
		ap3 = GetTempRegister();
		GenerateTriadic(op_add, 0, ap3, makereg(ap2->preg), makereg(ap1->preg));
		rg = ap2->preg;
		ap2->preg = ap3->preg;
		ap3->preg = rg;
		ReleaseTempRegister(ap3);
		//ap2->mode = am_indx2;
		//ap2->sreg = ap1->preg;
		//ap2->deep2 = ap1->deep;
		return (ap2);
	}
	if (ap2->mode == am_direct && ap1->mode == am_reg) {
		ap2->mode = am_indx;
		ap2->preg = ap1->preg;
		ap2->deep = ap1->deep;
		return ap2;
	}
	// ap1->mode must be am_reg
	ap3 = GetTempRegister();
	ap2->MakeLegal( am_reg, sizeOfWord);
	rg1 = ap1->preg;
	rg2 = ap2->preg;
	if (scale > 1) {
		GenerateTriadic(op_sll, 0, ap3, ap2, MakeImmediate(scale));
		GenerateTriadic(op_add, 0, ap1, ap1, ap3);
		ReleaseTempRegister(ap3);
	}
	else
		GenerateTriadic(op_add, 0, ap1, ap2, ap1);
	ReleaseTempRegister(ap3);
	ReleaseTempRegister(ap2);
	/*
	ap1->mode = am_indx2;            // make indexed
	ap1->sreg = ap2->preg;
	ap1->deep2 = ap2->deep;
	ap1->offset = makeinode(en_icon, 0);
	ap1->scale = scale;
	*/
	return (ap1);                     /* return indexed */
}


//
// Generate code to evaluate a condition operator node (??:)
//
Operand *ENODE::GenSafeHook(int flags, int size)
{
	Operand *ap1, *ap2, *ap3, *ap4;
	int false_label, end_label;
	OCODE *ip1;
	int n1;
	ENODE *node;

	false_label = nextlabel++;
	end_label = nextlabel++;
	//flags = (flags & am_reg) | am_volatile;
	flags |= am_volatile;
	/*
	if (p[0]->constflag && p[1]->constflag) {
	GeneratePredicateMonadic(hook_predreg,op_op_ldi,MakeImmediate(p[0]->i));
	GeneratePredicateMonadic(hook_predreg,op_ldi,MakeImmediate(p[0]->i));
	}
	*/
	ip1 = currentFn->pl.tail;
	// cmovenz integer only
	if (!opt_nocgo) {
		ap4 = GetTempRegister();
		ap1 = p[0]->Generate(am_reg, size);
		ap2 = p[1]->p[0]->Generate(am_reg | am_fpreg, size);
		ap3 = p[1]->p[1]->Generate(am_reg | am_fpreg | am_imm, size);
		//if (ap2->mode == am_fpreg || ap3->mode == am_fpreg)
			goto j1;
		n1 = currentFn->pl.Count(ip1);
		if (n1 < 20 && !currentFn->pl.HasCall(ip1)) {
			Generate4adic(op_cmovenz, 0, ap4, ap1, ap2, ap3);
			ReleaseTempReg(ap3);
			ReleaseTempReg(ap2);
			ReleaseTempReg(ap1);
			ap4->MakeLegal(flags,size);
			return (ap4);
		}
j1:
		ReleaseTempReg(ap3);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		ReleaseTempReg(ap4);
		currentFn->pl.tail = ip1;
		currentFn->pl.tail->fwd = nullptr;
	}
	ap2 = p[1]->p[1]->Generate(flags, size);
	n1 = currentFn->pl.Count(ip1);
	if (opt_nocgo)
		n1 = 9999;
	if (n1 > 4 || currentFn->pl.HasCall(ip1))
	{
		ReleaseTempReg(ap2);
		currentFn->pl.tail = ip1;
		currentFn->pl.tail->fwd = nullptr;
		cg.GenerateFalseJump(p[0], false_label, 0);
		node = p[1];
		ap1 = node->p[0]->Generate(flags, size);
		GenerateDiadic(op_bra, 0, MakeCodeLabel(end_label), 0);
		GenerateLabel(false_label);
		ap2 = node->p[1]->Generate(flags, size);
		if (!IsEqualOperand(ap1, ap2))
		{
			GenerateMonadic(op_hint, 0, MakeImmediate(2));
			switch (ap1->mode)
			{
			case am_reg:
				switch (ap2->mode) {
				case am_reg:
					GenerateDiadic(op_mov, 0, ap1, ap2);
					break;
				case am_imm:
					cg.GenLoadConst(ap2, ap1);
					if (ap2->isPtr)
						ap1->isPtr = true;
					break;
				default:
					GenLoad(ap1, ap2, size, size);
					break;
				}
				break;
			case am_fpreg:
				switch (ap2->mode) {
				case am_fpreg:
					GenerateDiadic(op_mov, 0, ap1, ap2);
					break;
				case am_imm:
					ap4 = GetTempRegister();
					GenerateDiadic(op_ldi, 0, ap4, ap2);
					GenerateDiadic(op_mov, 0, ap1, ap4);
					if (ap2->isPtr)
						ap1->isPtr = true;
					break;
				default:
					GenLoad(ap1, ap2, size, size);
					break;
				}
				break;
			case am_imm:
				break;
			default:
				GenStore(ap2, ap1, size);
				break;
			}
		}
		GenerateLabel(end_label);
		ap1->MakeLegal(flags, size);
		return (ap1);
	}
	// N1 <= 4
	cg.GenerateFalseJump(p[0], false_label, 0);
	node = p[1];
	ap1 = node->p[0]->Generate(flags, size);
	GenerateDiadic(op_bra, 0, MakeCodeLabel(end_label), 0);
	GenerateLabel(false_label);
	if (!IsEqualOperand(ap1, ap2))
	{
		GenerateMonadic(op_hint, 0, MakeImmediate(2));
		switch (ap1->mode)
		{
		case am_reg:
			switch (ap2->mode) {
			case am_reg:
				GenerateDiadic(op_mov, 0, ap1, ap2);
				break;
			case am_imm:
				cg.GenLoadConst(ap2, ap1);
				if (ap2->isPtr)
					ap1->isPtr = true;
				break;
			default:
				GenLoad(ap1, ap2, size, size);
				break;
			}
			break;
		case am_fpreg:
			switch (ap2->mode) {
			case am_fpreg:
				GenerateDiadic(op_mov, 0, ap1, ap2);
				break;
			case am_imm:
				ap4 = GetTempRegister();
				GenerateDiadic(op_ldi, 0, ap4, ap2);
				GenerateDiadic(op_mov, 0, ap1, ap4);
				if (ap2->isPtr)
					ap1->isPtr = true;
				break;
			default:
				GenLoad(ap1, ap2, size, size);
				break;
			}
			break;
		case am_imm:
			break;
		default:
			GenStore(ap2, ap1, size);
			break;
		}
	}
	GenerateLabel(end_label);
	ap1->MakeLegal(flags, size);
	return (ap1);
}

//
// Generate code to evaluate a condition operator node (?:)
//
Operand *ENODE::GenHook(int flags, int size)
{
	Operand *ap1, *ap2, *ap3;
	int false_label, end_label;
	ENODE *node;
	bool voidResult;

	false_label = nextlabel++;
	end_label = nextlabel++;
	//flags = (flags & am_reg) | am_volatile;
	flags |= am_volatile;
	/*
	if (p[0]->constflag && p[1]->constflag) {
	GeneratePredicateMonadic(hook_predreg,op_op_ldi,MakeImmediate(p[0]->i));
	GeneratePredicateMonadic(hook_predreg,op_ldi,MakeImmediate(p[0]->i));
	}
	*/
	//ip1 = currentFn->pl.tail;
	//ap2 = cg.GenerateExpression(p[1]->p[1], flags, size);
	//n1 = currentFn->pl.Count(ip1);
	//if (opt_nocgo)
	//	n1 = 9999;
	//ReleaseTempReg(ap2);
	//currentFn->pl.tail = ip1;
	//currentFn->pl.tail->fwd = nullptr;
	voidResult = p[0]->etype == bt_void;
	cg.GenerateFalseJump(p[0], false_label, 0);
	node = p[1];
	ap3 = GetTempRegister();
	ap1 = node->p[0]->Generate(flags, size);
	ReleaseTempRegister(ap1);
	GenerateDiadic(op_bra, 0, MakeCodeLabel(end_label), 0);
	GenerateLabel(false_label);
	ap2 = node->p[1]->Generate(flags, size);
	if (!Operand::IsSameType(ap1, ap2) && !voidResult)
		error(ERR_MISMATCH);
	//{
	//	GenerateMonadic(op_hint, 0, MakeImmediate(2));
	//	switch (ap1->mode)
	//	{
	//	case am_reg:
	//		switch (ap2->mode) {
	//		case am_reg:
	//			GenerateDiadic(op_mov, 0, ap1, ap2);
	//			break;
	//		case am_imm:
	//			GenerateDiadic(op_ldi, 0, ap1, ap2);
	//			if (ap2->isPtr)
	//				ap1->isPtr = true;
	//			break;
	//		default:
	//			GenLoad(ap1, ap2, size, size);
	//			break;
	//		}
	//		break;
	//	case am_fpreg:
	//		switch (ap2->mode) {
	//		case am_fpreg:
	//			GenerateDiadic(op_mov, 0, ap1, ap2);
	//			break;
	//		case am_imm:
	//			ap4 = GetTempRegister();
	//			GenerateDiadic(op_ldi, 0, ap4, ap2);
	//			GenerateDiadic(op_mov, 0, ap1, ap4);
	//			if (ap2->isPtr)
	//				ap1->isPtr = true;
	//			break;
	//		default:
	//			GenLoad(ap1, ap2, size, size);
	//			break;
	//		}
	//		break;
	//	case am_imm:
	//		break;
	//	default:
	//		GenStore(ap2, ap1, size);
	//		break;
	//	}
	//}
	GenerateLabel(end_label);
	ap2->MakeLegal(flags, size);
	return (ap2);
}

Operand *ENODE::GenShift(int flags, int size, int op)
{
	Operand *ap1, *ap2, *ap3;
	unsigned int Rs1mode, Rs2mode;

	Rs1mode = opl[op_ins[op]].amclass2;
	Rs2mode = opl[op_ins[op]].amclass3;

	ap3 = GetTempRegister();
	ap1 = p[0]->Generate(Rs1mode, size);
	ap2 = p[1]->Generate(Rs2mode, sizeOfWord);
	GenerateTriadic(op, 0, ap3, ap1, ap2);
	// Rotates automatically sign extend
	if ((op == op_rol || op == op_ror) && ap2->isUnsigned)
		switch (size) {
		case 1:	GenerateTriadic(op_and, 0, ap3, ap3, MakeImmediate(0xFF)); break;
		case 2:	GenerateTriadic(op_and, 0, ap3, ap3, MakeImmediate(0xFFFF)); break;
		case 4:	GenerateDiadic(op_zxh, 0, ap3, ap3); break;
		default:;
		}
	ReleaseTempRegister(ap2);
	ReleaseTempRegister(ap1);
	ap3->MakeLegal(flags, size);
	return (ap3);
}


Operand *ENODE::GenAssignShift(int flags, int size, int op)
{
	Operand *ap1, *ap2, *ap3;
	MachineReg *mr;
	unsigned int Rs1mode, Rs2mode;

	Rs1mode = opl[op_ins[op]].amclass2;
	Rs2mode = opl[op_ins[op]].amclass3;

	//size = GetNaturalSize(node->p[0]);
	ap3 = p[0]->Generate(am_all & ~am_imm, size);
	ap2 = p[1]->Generate(Rs2mode, size);
	if (ap3->mode == am_reg) {
		GenerateTriadic(op, size, ap3, ap3, ap2);
		mr = &regs[ap3->preg];
		if (mr->assigned)
			mr->modified = true;
		mr->assigned = true;
		mr->isConst = ap3->isConst && ap2->isConst;
		ReleaseTempRegister(ap2);
		ap3->MakeLegal(flags, size);
		return (ap3);
	}
	ap1 = GetTempRegister();
	GenLoad(ap1, ap3, size, size);
	GenerateTriadic(op, size, ap1, ap1, ap2);
	GenStore(ap1, ap3, size);
	ReleaseTempRegister(ap1);
	ReleaseTempRegister(ap2);
	ap3->MakeLegal(flags, size);
	return (ap3);
}


//
//      generate code to evaluate a mod operator or a divide
//      operator.
//
Operand *ENODE::GenDivMod(int flags, int size, int op)
{
	Operand *ap1, *ap2, *ap3;
	unsigned int Rs1mode, Rs2mode;

	Rs1mode = opl[op_ins[op]].amclass2;
	Rs2mode = opl[op_ins[op]].amclass3;

	//if( node->p[0]->nodetype == en_icon ) //???
	//	swap_nodes(node);
	if (op == op_fdiv) {
		ap3 = GetTempFPRegister();
	}
	else {
		ap3 = GetTempRegister();
	}
	ap1 = p[0]->Generate(Rs1mode, sizeOfWord);
	ap2 = p[1]->Generate(Rs2mode, sizeOfWord);
	if (op == op_fdiv) {
		// Generate a convert operation ?
		if (ap1->fpsize() != ap2->fpsize()) {
			if (ap2->fpsize() == 's')
				GenerateDiadic(op_fcvtsq, 0, ap2, ap2);
		}
		GenerateTriadic(op, ap1->fpsize(), ap3, ap1, ap2);
	}
	else
		GenerateTriadic(op, 0, ap3, ap1, ap2);
	//    GenerateDiadic(op_ext,0,ap3,0);
	ap3->MakeLegal( flags, 2);
	ReleaseTempReg(ap2);
	ReleaseTempReg(ap1);
	return (ap3);
}


//
//      generate code to evaluate a multiply node.
//
Operand *ENODE::GenMultiply(int flags, int size, int op)
{
	Operand *ap1, *ap2, *ap3;
	bool square = false;
	unsigned int Rs1mode, Rs2mode;

	Rs1mode = opl[op_ins[op]].amclass2;
	Rs2mode = opl[op_ins[op]].amclass3;

	//Enter("Genmul");
	if (p[0]->nodetype == en_icon)
		swap_nodes(this);
	if (IsEqual(p[0], p[1]))
		square = !opt_nocgo;
	if (op == op_fmul) {
		ap3 = GetTempFPRegister();
		ap1 = p[0]->Generate(Rs1mode, size);
		if (!square)
			ap2 = p[1]->Generate(Rs2mode, size);
	}
	else {
		ap3 = GetTempRegister();
		ap1 = p[0]->Generate(Rs1mode, sizeOfWord);
		if (!square)
			ap2 = p[1]->Generate(Rs2mode, sizeOfWord);
	}
	if (op == op_fmul) {
		// Generate a convert operation ?
		if (ap1->fpsize() != ap2->fpsize()) {
			if (ap2->fpsize() == 's')
				GenerateDiadic(op_fcvtsq, 0, ap2, ap2);
		}
		if (square)
			GenerateTriadic(op, ap1->fpsize(), ap3, ap1, ap1);
		else
			GenerateTriadic(op, ap1->fpsize(), ap3, ap1, ap2);
	}
	else {
		if (square)
			GenerateTriadic(op, 0, ap3, ap1, ap1);
		else
			GenerateTriadic(op, 0, ap3, ap1, ap2);
	}
	if (!square)
		ReleaseTempReg(ap2);
	ReleaseTempReg(ap1);
	ap3->MakeLegal(flags, 2);
	//Leave("Genmul", 0);
	return (ap3);
}


//
// Generate code to evaluate a unary minus or complement.
//
Operand *ENODE::GenUnary(int flags, int size, int op)
{
	Operand *ap, *ap2;
	unsigned int Rs1mode;

	Rs1mode = opl[op_ins[op]].amclass2;

	if (IsFloatType()) {
		ap2 = GetTempFPRegister();
		ap = p[0]->Generate(Rs1mode, size);
		if (op == op_neg)
			op = op_fneg;
		GenerateDiadic(op, fsize(), ap2, ap);
	}
	else if (IsVectorType()) {
		ap2 = GetTempVectorRegister();
		ap = p[0]->Generate(am_vreg, size);
		GenerateDiadic(op, 0, ap2, ap);
	}
	else {
		ap2 = GetTempRegister();
		ap = p[0]->Generate(Rs1mode, size);
		GenerateHint(3);
		GenerateDiadic(op, 0, ap2, ap);
	}
	ReleaseTempReg(ap);
	ap2->MakeLegal(flags, size);
	return (ap2);
}

// Generate code for a binary expression

Operand *ENODE::GenBinary(int flags, int size, int op)
{
	Operand *ap1 = nullptr, *ap2 = nullptr, *ap3, *ap4;
	bool dup = false;
	unsigned int Rs1mode, Rs2mode;

	Rs1mode = opl[op_ins[op]].amclass2;
	Rs2mode = opl[op_ins[op]].amclass3;

	if (IsFloatType())
	{
		ap3 = GetTempFPRegister();
		if (IsEqual(p[0], p[1]))
			dup = !opt_nocgo;
		ap1 = p[0]->Generate(am_fpreg, size);
		if (!dup)
			ap2 = p[1]->Generate(am_fpreg, size);
		// Generate a convert operation ?
		if (!dup) {
			if (ap1->fpsize() != ap2->fpsize()) {
				if (ap2->fpsize() == 's')
					GenerateDiadic(op_fcvtsq, 0, ap2, ap2);
			}
		}
		if (dup)
			GenerateTriadic(op, ap1->fpsize(), ap3, ap1, ap1);
		else
			GenerateTriadic(op, ap1->fpsize(), ap3, ap1, ap2);
		ap3->type = ap1->type;
	}
	else if (op == op_vex) {
		ap3 = GetTempRegister();
		ap1 = p[0]->Generate(am_reg, size);
		ap2 = p[1]->Generate(am_reg, size);
		GenerateTriadic(op, 0, ap3, ap1, ap2);
	}
	else if (IsVectorType()) {
		ap3 = GetTempVectorRegister();
		if (ENODE::IsEqual(p[0], p[1]) && !opt_nocgo) {
			ap1 = p[0]->Generate(am_vreg, size);
			ap2 = vmask->Generate(am_vmreg, size);
			Generate4adic(op, 0, ap3, ap1, ap1, ap2);
		}
		else {
			ap1 = p[0]->Generate(am_vreg, size);
			ap2 = p[1]->Generate(am_vreg, size);
			ap4 = vmask->Generate(am_vmreg, size);
			Generate4adic(op, 0, ap3, ap1, ap2, ap4);
			ReleaseTempReg(ap4);
		}
		// Generate a convert operation ?
		//if (fpsize(ap1) != fpsize(ap2)) {
		//	if (fpsize(ap2)=='s')
		//		GenerateDiadic(op_fcvtsq, 0, ap2, ap2);
		//}
	}
	else {
		ap3 = GetTempRegister();
		if (ENODE::IsEqual(p[0], p[1]) && !opt_nocgo) {
			// Duh, subtract operand from itself, result would be zero.
			if (op == op_sub || op == op_ptrdif)
				GenerateDiadic(op_mov, 0, ap3, makereg(0));
			else {
				ap1 = p[0]->Generate(am_reg, size);
				GenerateTriadic(op, 0, ap3, ap1, ap1);
			}
		}
		else {
			ap1 = p[0]->Generate(Rs1mode, size);
			// modu/ptrdif does not have an immediate mode
			ap2 = p[1]->Generate(Rs2mode, size);
			if (Instruction::Get(op)->amclass4) {	// op_ptrdif
				ap4 = p[4]->Generate(Instruction::Get(op)->amclass4, size);
				Generate4adic(op, 0, ap3, ap1, ap2, ap4);
			}
			else {
				if (ap2->mode == am_imm) {
					switch (op) {
					case op_and:
						GenerateTriadic(op, 0, ap3, ap1, MakeImmediate(ap2->offset->i));
						/*
						if (ap2->offset->i & 0xFFFF0000LL)
						GenerateDiadic(op_andq1,0,ap3,MakeImmediate((ap2->offset->i >> 16) & 0xFFFFLL));
						if (ap2->offset->i & 0xFFFF00000000LL)
						GenerateDiadic(op_andq2,0,ap3,MakeImmediate((ap2->offset->i >> 32) & 0xFFFFLL));
						if (ap2->offset->i & 0xFFFF000000000000LL)
						GenerateDiadic(op_andq3,0,ap3,MakeImmediate((ap2->offset->i >> 48) & 0xFFFFLL));
						*/
						break;
					case op_or:
						GenerateTriadic(op, 0, ap3, ap1, MakeImmediate(ap2->offset->i));
						/*
						if (ap2->offset->i & 0xFFFF0000LL)
						GenerateDiadic(op_orq1,0,ap3,MakeImmediate((ap2->offset->i >> 16) & 0xFFFFLL));
						if (ap2->offset->i & 0xFFFF00000000LL)
						GenerateDiadic(op_orq2,0,ap3,MakeImmediate((ap2->offset->i >> 32) & 0xFFFFLL));
						if (ap2->offset->i & 0xFFFF000000000000LL)
						GenerateDiadic(op_orq3,0,ap3,MakeImmediate((ap2->offset->i >> 48) & 0xFFFFLL));
						*/
						break;
					// If there is a pointer plus a constant we really wanted an address calc.
					case op_add:
					case op_sub:
						if (ap1->isPtr && ap2->isPtr)
							GenerateTriadic(op, 0, ap3, ap1, ap2);
						else if (ap2->isPtr)
							GenerateDiadic(op_lea, 0, ap3, op==op_sub ? compiler.of.MakeNegIndexed(ap2->offset, ap1->preg) : MakeIndexed(ap2->offset, ap1->preg));
						else
							GenerateTriadic(op, 0, ap3, ap1, ap2);
						break;
						// Most ops handle a max 16 bit immediate operand. If the operand is over 16 bits
						// it has to be loaded into a register.
					default:
						//if (ap2->offset->i < -32768LL || ap2->offset->i > 32767LL) {
							//ap4 = GetTempRegister();
							//GenerateTriadic(op_or, 0, ap4, makereg(regZero), MakeImmediate(ap2->offset->i));
							/*
							if (ap2->offset->i & 0xFFFF0000LL)
							GenerateDiadic(op_orq1,0,ap4,MakeImmediate((ap2->offset->i >> 16) & 0xFFFFLL));
							if (ap2->offset->i & 0xFFFF00000000LL)
							GenerateDiadic(op_orq2,0,ap4,MakeImmediate((ap2->offset->i >> 32) & 0xFFFFLL));
							if (ap2->offset->i & 0xFFFF000000000000LL)
							GenerateDiadic(op_orq3,0,ap4,MakeImmediate((ap2->offset->i >> 48) & 0xFFFFLL));
							*/
							//GenerateTriadic(op, 0, ap3, ap1, ap4);
							//ReleaseTempReg(ap4);
						//}
						//else
						GenerateTriadic(op, 0, ap3, ap1, ap2);
					}
				}
				else
					GenerateTriadic(op, 0, ap3, ap1, ap2);
			}
		}
	}
	if (ap2)
		ReleaseTempReg(ap2);
	if (ap1)
		ReleaseTempReg(ap1);
	ap3->MakeLegal( flags, size);
	return (ap3);
}


Operand *ENODE::GenerateAssignAdd(int flags, int size, int op)
{
	Operand *ap1, *ap2, *ap3, *ap4;
	int ssize;
	bool negf = false;
	bool intreg = false;
	MachineReg *mr;

	ssize = p[0]->GetNaturalSize();
	if (ssize > size)
		size = ssize;
	if (p[0]->IsBitfield()) {
		ap3 = GetTempRegister();
		ap4 = GetTempRegister();
		ap1 = cg.GenerateBitfieldDereference(p[0], am_reg | am_mem, size, 1);
		//		GenerateDiadic(op_mov, 0, ap3, ap1);
		//ap1 = cg.GenerateExpression(p[0], am_reg | am_mem, size);
		ap2 = p[1]->Generate(am_reg | am_imm, size);
		if (ap1->mode == am_reg) {
			GenerateTriadic(op, 0, ap1, ap1, ap2);
			cg.GenerateBitfieldInsert(ap3, ap1, ap1->offset->bit_offset, ap1->offset->bit_width);
		}
		else {
			GenLoad(ap3, ap1, size, size);
			Generate4adic(op_bfext, 0, ap4, ap3, MakeImmediate(ap1->offset->bit_offset), MakeImmediate(ap1->offset->bit_width-1));
			GenerateTriadic(op, 0, ap4, ap4, ap2);
			cg.GenerateBitfieldInsert(ap3, ap4, ap1->offset->bit_offset, ap1->offset->bit_width);
			GenStore(ap3, ap1, ssize);
		}
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		ReleaseTempReg(ap4);
		ap3->MakeLegal( flags, size);
		return (ap3);
	}
	if (IsFloatType()) {
		ap1 = p[0]->Generate(am_fpreg | am_mem, ssize);
		ap2 = p[1]->Generate(am_fpreg, size);
		if (op == op_add)
			op = op_fadd;
		else if (op == op_sub)
			op = op_fsub;
	}
	else if (etype == bt_vector) {
		ap1 = p[0]->Generate(am_reg | am_mem, ssize);
		ap2 = p[1]->Generate(am_reg, size);
		if (op == op_add)
			op = op_vadd;
		else if (op == op_sub)
			op = op_vsub;
	}
	else {
		ap1 = p[0]->Generate(am_all, ssize);
		ap2 = p[1]->Generate(Instruction::Get(op)->amclass3, size);
		intreg = true;
	}
	if (ap1->mode == am_reg) {
		GenerateTriadic(op, 0, ap1, ap1, ap2);
		if (intreg) {
			mr = &regs[ap1->preg];
			if (mr->assigned)
				mr->modified = true;
			mr->assigned = true;
			mr->isConst = ap1->isConst && ap2->isConst;
		}
	}
	else if (ap1->mode == am_fpreg) {
		GenerateTriadic(op, ap1->fpsize(), ap1, ap1, ap2);
		ReleaseTempReg(ap2);
		ap1->MakeLegal( flags, size);
		return (ap1);
	}
	else {
		GenMemop(op, ap1, ap2, ssize);
	}
	ReleaseTempReg(ap2);
	//if (ap1->type != stddouble.GetIndex() && !ap1->isUnsigned)
	//	ap1 = ap1->GenSignExtend(ssize, size, flags);
	ap1->MakeLegal( flags, size);
	return (ap1);
}

//
//      generate a *= node.
//
Operand *ENODE::GenerateAssignMultiply(int flags, int size, int op)
{
	Operand *ap1, *ap2, *ap3;
	int ssize;
	MachineReg *mr;

	ssize = p[0]->GetNaturalSize();
	if (ssize > size)
		size = ssize;
	if (p[0]->IsBitfield()) {
		ap3 = GetTempRegister();
		ap1 = cg.GenerateBitfieldDereference(p[0], am_reg | am_mem, size, 1);
		GenerateDiadic(op_mov, 0, ap3, ap1);
		ap2 = p[1]->Generate(am_reg | am_imm, size);
		GenerateTriadic(op, 0, ap1, ap1, ap2);
		cg.GenerateBitfieldInsert(ap3, ap1, ap1->offset->bit_offset, ap1->offset->bit_width);
		GenStore(ap3, ap1->next, ssize);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1->next);
		ReleaseTempReg(ap1);
		ap3->MakeLegal(flags, size);
		return (ap3);
	}
	if (etype == bt_double || etype == bt_quad || etype == bt_float || etype == bt_triple) {
		ap1 = p[0]->Generate(am_fpreg | am_mem, ssize);
		ap2 = p[1]->Generate(am_fpreg, size);
		op = op_fmul;
	}
	else if (etype == bt_vector) {
		ap1 = p[0]->Generate(am_reg | am_mem, ssize);
		ap2 = p[1]->Generate(am_reg, size);
		op = ap2->type == stdvector.GetIndex() ? op_vmul : op_vmuls;
	}
	else {
		ap1 = p[0]->Generate(am_all & ~am_imm, ssize);
		ap2 = p[1]->Generate(am_reg | am_imm, size);
	}
	if (ap1->mode == am_reg) {
		GenerateTriadic(op, 0, ap1, ap1, ap2);
		if (op == op_mulu || op == op_mul) {
			mr = &regs[ap1->preg];
			if (mr->assigned)
				mr->modified = true;
			mr->assigned = true;
			mr->isConst = ap1->isConst && ap2->isConst;
		}
	}
	else if (ap1->mode == am_fpreg) {
		GenerateTriadic(op, ssize == 4 ? 's' : ssize == 8 ? 'd' : ssize == 12 ? 't' : ssize == 16 ? 'q' : 'd', ap1, ap1, ap2);
		ReleaseTempReg(ap2);
		ap1->MakeLegal(flags, size);
		return (ap1);
	}
	else {
		GenMemop(op, ap1, ap2, ssize);
	}
	ReleaseTempReg(ap2);
	ap1 = ap1->GenSignExtend(ssize, size, flags);
	ap1->MakeLegal(flags, size);
	return (ap1);
}

/*
 *      generate /= and %= nodes.
 */
Operand *ENODE::GenerateAssignModiv(int flags, int size, int op)
{
	Operand *ap1, *ap2, *ap3;
	int             siz1;
	int isFP;
	MachineReg *mr;
	bool cnst = false;

	siz1 = p[0]->GetNaturalSize();
	if (p[0]->IsBitfield()) {
		ap3 = GetTempRegister();
		ap1 = cg.GenerateBitfieldDereference(p[0], am_reg | am_mem, size, 1);
		GenerateDiadic(op_mov, 0, ap3, ap1);
		ap2 = p[1]->Generate(am_reg | am_imm, size);
		GenerateTriadic(op, 0, ap1, ap1, ap2);
		cg.GenerateBitfieldInsert(ap3, ap1, ap1->offset->bit_offset, ap1->offset->bit_width);
		GenStore(ap3, ap1->next, siz1);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1->next);
		ReleaseTempReg(ap1);
		ap3->MakeLegal(flags, size);
		return (ap3);
	}
	isFP = etype == bt_double || etype == bt_float || etype == bt_triple || etype == bt_quad;
	if (isFP) {
		if (op == op_div || op == op_divu)
			op = op_fdiv;
		ap1 = p[0]->Generate(am_fpreg, siz1);
		ap2 = p[1]->Generate(am_fpreg, size);
		GenerateTriadic(op, siz1 == 4 ? 's' : siz1 == 8 ? 'd' : siz1 == 12 ? 't' : siz1 == 16 ? 'q' : 'd', ap1, ap1, ap2);
		ReleaseTempReg(ap2);
		ap1->MakeLegal(flags, size);
		return (ap1);
		//        else if (op==op_mod || op==op_modu)
		//           op = op_fdmod;
	}
	else {
		ap1 = GetTempRegister();
		ap2 = p[0]->Generate(am_all & ~am_imm, siz1);
	}
	if (ap2->mode == am_reg && ap2->preg != ap1->preg)
		GenerateDiadic(op_mov, 0, ap1, ap2);
	else if (ap2->mode == am_fpreg && ap2->preg != ap1->preg)
		GenerateDiadic(op_mov, 0, ap1, ap2);
	else
		GenLoad(ap1, ap2, siz1, siz1);
	//GenerateSignExtend(ap1,siz1,2,flags);
	if (isFP)
		ap3 = p[1]->Generate(am_fpreg, 8);
	else {
		// modu doesn't support immediate mode
		ap3 = p[1]->Generate(op == op_modu ? am_reg : am_reg | am_imm, 8);
	}
	if (op == op_fdiv) {
		GenerateTriadic(op, siz1 == 4 ? 's' : siz1 == 8 ? 'd' : siz1 == 12 ? 't' : siz1 == 16 ? 'q' : 'd', ap1, ap1, ap3);
	}
	else {
		GenerateTriadic(op, 0, ap1, ap1, ap3);
		cnst = ap1->isConst && ap3->isConst;
		mr = &regs[ap1->preg];
		if (mr->assigned)
			mr->modified = true;
		mr->assigned = true;
		mr->isConst = cnst;
	}
	ReleaseTempReg(ap3);
	//GenerateDiadic(op_ext,0,ap1,0);
	if (ap2->mode == am_reg) {
		GenerateDiadic(op_mov, 0, ap2, ap1);
		mr = &regs[ap2->preg];
		if (mr->assigned)
			mr->modified = true;
		mr->assigned = true;
		mr->isConst = cnst;
	}
	else if (ap2->mode == am_fpreg)
		GenerateDiadic(op_mov, 0, ap2, ap1);
	else
		GenStore(ap1, ap2, siz1);
	ReleaseTempReg(ap2);
	if (!isFP)
		ap1->MakeLegal(flags, size);
	return (ap1);
}


Operand *ENODE::GenerateAssignLogic(int flags, int size, int op)
{
	Operand *ap1, *ap2, *ap3;
	int ssize;
	MachineReg *mr;

	ssize = p[0]->GetNaturalSize();
	if (ssize > size)
		size = ssize;
	if (p[0]->IsBitfield()) {
		ap3 = GetTempRegister();
		ap1 = cg.GenerateBitfieldDereference(p[0], am_reg | am_mem, size, 1);
		GenerateDiadic(op_mov, 0, ap3, ap1);
		ap2 = p[1]->Generate(am_reg | am_imm, size);
		GenerateTriadic(op, 0, ap1, ap1, ap2);
		cg.GenerateBitfieldInsert(ap3, ap1, ap1->offset->bit_offset, ap1->offset->bit_width);
		GenStore(ap3, ap1->next, ssize);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1->next);
		ReleaseTempReg(ap1);
		ap3->MakeLegal( flags, size);
		return (ap3);
	}
	ap1 = p[0]->Generate(am_all & ~am_fpreg, ssize);
	// Some of the logic operations don't support immediate mode, so we check
	ap2 = p[1]->Generate(Instruction::Get(op)->amclass3, size);
	if (ap1->mode == am_reg) {
		GenerateTriadic(op, 0, ap1, ap1, ap2);
		mr = &regs[ap1->preg];
		if (mr->assigned)
			mr->modified = true;
		mr->assigned = true;
		mr->isConst = ap1->isConst && ap2->isConst;
	}
	else {
		GenMemop(op, ap1, ap2, ssize);
	}
	ReleaseTempRegister(ap2);
	if (!ap1->isUnsigned && !(flags & am_novalue)) {
		if (size > ssize) {
			if (ap1->mode != am_reg) {
				ap1->MakeLegal( am_reg, ssize);
			}
			switch (ssize) {
			case 1:	GenerateDiadic(op_sxb, 0, ap1, ap1); break;
			case 2:	GenerateDiadic(op_sxc, 0, ap1, ap1); break;
			case 4:	GenerateDiadic(op_sxh, 0, ap1, ap1); break;
			}
			ap1->MakeLegal( flags, size);
			return (ap1);
		}
		ap1 = ap1->GenSignExtend(ssize, size, flags);
	}
	ap1->MakeLegal( flags, size);
	return (ap1);
}

Operand *ENODE::GenLand(int flags, int op, bool safe)
{
	Operand *ap1, *ap2, *ap3, *ap4, *ap5;
	int lab0, lab1;

	if (safe) {
		lab0 = nextlabel++;
		ap3 = GetTempRegister();
		ap1 = p[0]->Generate(am_reg, p[0]->GetNaturalSize());
		ap4 = GetTempRegister();
		//if (op == op_and) {
		//	GenerateTriadic(op_beq, 0, ap1, makereg(0), MakeDataLabel(lab0));
		//	ap2 = cg.GenerateExpression(p[1], am_reg, 8);
		//}
		if (!ap1->isBool)
			GenRedor(ap4, ap1);
		else {
			ReleaseTempReg(ap4);
			ap4 = ap1;
		}
		ap2 = p[1]->Generate(am_reg, p[1]->GetNaturalSize());
		ap5 = GetTempRegister();
		if (!ap2->isBool)
			GenRedor(ap5, ap2);
		else {
			ReleaseTempReg(ap5);
			ap5 = ap2;
		}
		GenerateTriadic(op, 0, ap3, ap4, ap5);
		ReleaseTempReg(ap5);
		if (ap5 != ap2)
			ReleaseTempReg(ap2);
		if (ap4 != ap1)
			ReleaseTempReg(ap4);
		ReleaseTempReg(ap1);
		ap3->MakeLegal(flags, 8);
		ap3->isBool = true;
		return (ap3);
	}
	lab0 = nextlabel++;
	lab1 = nextlabel++;
	ap1 = GetTempRegister();
	GenerateDiadic(op_ldi, 0, ap1, MakeImmediate(1));
	cg.GenerateFalseJump(this, lab0, 0);
	GenerateDiadic(op_ldi, 0, ap1, MakeImmediate(0));
	GenerateLabel(lab0);
	ap1->MakeLegal(flags, 8);
	ap1->isBool = true;
	return (ap1);
}

// autocon and autofcon nodes

Operand *ENODE::GenerateAutocon(int flags, int size, int type)
{
	Operand *ap1, *ap2;

	// We always want an address register (GPR) for lea
	ap1 = GetTempRegister();
	ap2 = allocOperand();
	ap2->isPtr = etype == bt_pointer;
	ap2->mode = am_indx;
	ap2->preg = regFP;          // frame pointer
	ap2->offset = this;     /* use as constant node */
	ap2->type = type;
	ap1->type = stdint.GetIndex();
	GenerateDiadic(op_lea, 0, ap1, ap2);
	ap1->MakeLegal(flags, size);
	return (ap1);             /* return reg */
}


//
// General expression evaluation. returns the addressing mode
// of the result.
//
Operand *ENODE::Generate(int flags, int size)
{
	ENODE *node = this;
	Operand *ap1, *ap2, *ap3;
	int natsize, siz1;
	int lab0, lab1;
	static char buf[4][20];
	static int ndx;
	static int numDiags = 0;

//	Enter("<GenerateExpression>");
	if (node == (ENODE *)NULL)
	{
		throw new C64PException(ERR_NULLPOINTER, 'G');
		numDiags++;
		printf("DIAG - null node in GenerateExpression.\n");
		if (numDiags > 100)
			exit(0);
//		Leave("</GenerateExpression>", 2);
		return (Operand *)NULL;
	}
	//size = node->esize;
	GenerateZeradic(op_pfi);
	switch (node->nodetype)
	{
	case en_aggregate:
		ap1 = p[0]->Generate(flags, size);
		ap2 = allocOperand();
		ap2->mode = am_ind;
		ap2->preg = ap1->preg;
		if (node->tp->IsScalar())
			GenLoad(ap1, ap2, size, size);
		else
			ap1->isPtr = true;
		goto retpt;
		//ap1 = allocOperand();
		//ap1->offset = node;
		//ap1->type = 9999;
		goto retpt;
	case en_fcon:
		ap1 = allocOperand();
		ap1->isPtr = node->IsPtr();
		ap1->mode = am_direct;
		ap1->offset = node;
		if (node)
			DataLabels[node->i] = true;
		ap1->type = stddouble.GetIndex();
		// Don't allow the constant to be loaded into an integer register.
		ap1->MakeLegal(flags & ~am_reg, size);
//		Leave("</GenerateExpression>", 2);
		goto retpt;
		/*
						ap1 = allocOperand();
						ap1->mode = am_imm;
						ap1->offset = node;
			ap1->isFloat = TRUE;
						ap1->MakeLegal(flags,size);
				 Leave("GenExperssion",2);
						return ap1;
		*/
	case en_icon:
		ap1 = allocOperand();
		ap1->mode = am_imm;
		ap1->offset = this;
		ap1->MakeLegal(flags, size);
//		Leave("GenExpression", 3);
		goto retpt;

	case en_labcon:
		if (use_gp) {
			ap1 = GetTempRegister();
			ap2 = allocOperand();
			ap2->mode = am_indx;
			switch (segment) {
			case tlsseg:	ap2->preg = regTP; break;
			case dataseg:	ap2->preg = regGP; break;
			default:	ap2->preg = regPP;
			}
			ap2->offset = this;     // use as constant node
			GenerateDiadic(op_lea, 0, ap1, ap2);
			ap1->MakeLegal(flags, size);
			goto retpt;
		}
		ap1 = allocOperand();
		ap1->isPtr = IsPtr();
		/* this code not really necessary, see segments notes
		if (node->etype==bt_pointer && node->constflag) {
			ap1->segment = codeseg;
		}
		else {
			ap1->segment = dataseg;
		}
		*/
		ap1->mode = am_imm;
		ap1->offset = node;
		ap1->isUnsigned = node->isUnsigned;
		ap1->MakeLegal(flags, size);
		goto retpt;

	case en_nacon:
		if (use_gp) {
			ap1 = GetTempRegister();
			ap2 = allocOperand();
			ap2->mode = am_indx;
			ap2->preg = regGP;      // global pointer
			ap2->offset = this;     // use as constant node
			if (node)
				DataLabels[i] = true;
			GenerateDiadic(op_lea, 0, ap1, ap2);
			ap1->MakeLegal(flags, size);
			goto retpt;
		}
		// fallthru
	case en_cnacon:
		ap1 = allocOperand();
		ap1->isPtr = IsPtr();
		ap1->mode = am_imm;
		ap1->offset = this;
		if (i == 0)
			i = -1;
		ap1->isUnsigned = isUnsigned;
		ap1->MakeLegal(flags, size);
		goto retpt;
	case en_clabcon:
		ap1 = allocOperand();
		ap1->mode = am_imm;
		ap1->offset = this;
		ap1->isUnsigned = isUnsigned;
		ap1->MakeLegal(flags, size);
		goto retpt;
	case en_autocon:
		ap1 = cg.GenAutocon(node, flags, size, stdint.GetIndex());
		goto retpt;
	case en_autofcon:
		switch (node->tp->type)
		{
		case bt_float:
			ap1 = GenerateAutocon(flags, size, stdflt.GetIndex());
			goto retpt;
		case bt_double:
			ap1 = GenerateAutocon(flags, size, stddouble.GetIndex());
			goto retpt;
		case bt_triple:	return GenerateAutocon(flags, size, stdtriple.GetIndex());
		case bt_quad:	return GenerateAutocon(flags, size, stdquad.GetIndex());
		case bt_pointer:
			ap1 = cg.GenAutocon(node, flags, size, stdint.GetIndex());
			goto retpt;
		}
		break;
	case en_autovcon:	return GenerateAutocon(flags, size, stdvector.GetIndex());
	case en_autovmcon:	return GenerateAutocon(flags, size, stdvectormask->GetIndex());
	case en_classcon:
		ap1 = GetTempRegister();
		ap2 = allocOperand();
		ap2->mode = am_indx;
		ap2->preg = regCLP;     /* frame pointer */
		ap2->offset = node;     /* use as constant node */
		GenerateDiadic(op_lea, 0, ap1, ap2);
		ap1->MakeLegal(flags, size);
		goto retpt;
	case en_addrof:
		ap1 = GetTempRegister();
		ap2 = node->p[0]->Generate(flags & ~am_fpreg, 8);
		switch (ap2->mode) {
		case am_reg:
			GenerateDiadic(op_mov, 0, ap1, ap2);
			break;
		default:
			GenerateDiadic(op_lea, 0, ap1, ap2);
		}
		ReleaseTempReg(ap2);
		goto retpt;
	case en_ref:
		ap1 = cg.GenerateDereference(node, flags, node->tp->size, !node->isUnsigned);
		ap1->isPtr = TRUE;
		ap1->isUnsigned = node->isUnsigned;
		goto retpt;
	case en_fieldref:
		ap1 = (flags & am_bf_assign) ? cg.GenerateDereference(node, flags & ~am_bf_assign, node->tp->size, !node->isUnsigned)
			: cg.GenerateBitfieldDereference(node, flags, node->tp->size, !node->isUnsigned);
		ap1->isUnsigned = node->isUnsigned;
		goto retpt;
	case en_regvar:
	case en_tempref:
		ap1 = allocOperand();
		ap1->isPtr = node->IsPtr();
		ap1->mode = am_reg;
		ap1->preg = node->rg;
		ap1->tempflag = 0;      /* not a temporary */
		ap1->MakeLegal(flags, size);
		goto retpt;

	case en_tempfpref:
		ap1 = allocOperand();
		ap1->isPtr = node->IsPtr();
		ap1->mode = node->IsPtr() ? am_reg : am_fpreg;
		ap1->preg = node->rg;
		ap1->tempflag = 0;      /* not a temporary */
		if (node->tp)
			switch (node->tp->type) {
			case bt_float:	ap1->type = stdflt.GetIndex(); break;
			case bt_double:	ap1->type = stddouble.GetIndex(); break;
			case bt_triple:	ap1->type = stdtriple.GetIndex(); break;
			case bt_quad:	ap1->type = stdquad.GetIndex(); break;
			default: ap1->type = stdint.GetIndex(); break;
			}
		else
			ap1->type = stddouble.GetIndex();
		ap1->MakeLegal(flags, size);
		goto retpt;

	case en_fpregvar:
		//    case en_fptempref:
		ap1 = allocOperand();
		ap1->isPtr = node->IsPtr();
		ap1->mode = node->IsPtr() ? am_reg : am_fpreg;
		ap1->preg = node->rg;
		ap1->tempflag = 0;      /* not a temporary */
		if (node->tp)
			switch (node->tp->type) {
			case bt_float:	ap1->type = stdflt.GetIndex(); break;
			case bt_double:	ap1->type = stddouble.GetIndex(); break;
			case bt_triple:	ap1->type = stdtriple.GetIndex(); break;
			case bt_quad:	ap1->type = stdquad.GetIndex(); break;
			default: ap1->type = stdint.GetIndex(); break;
			}
		else
			ap1->type = stddouble.GetIndex();
		ap1->MakeLegal(flags, size);
		goto retpt;

	case en_abs:	return node->GenUnary(flags, size, op_abs);
	case en_uminus:
		ap1 = node->GenUnary(flags, size, op_neg);
		goto retpt;
	case en_compl:
		ap1 = node->GenUnary(flags, size, op_com);
		goto retpt;
	case en_not:
		ap1 = (node->GenUnary(flags, 8, op_not));
		goto retpt;
	case en_add:    ap1 = node->GenBinary(flags, size, op_add); goto retpt;
	case en_sub:  ap1 = node->GenBinary(flags, size, op_sub); goto retpt;
	case en_ptrdif:  ap1 = node->GenBinary(flags, size, op_ptrdif); goto retpt;
	case en_i2d:
		ap1 = GetTempFPRegister();
		ap2 = node->p[0]->Generate(am_reg, 8);
		GenerateDiadic(op_itof, 'd', ap1, ap2);
		ReleaseTempReg(ap2);
		goto retpt;
	case en_i2q:
		ap1 = GetTempFPRegister();
		ap2 = node->p[0]->Generate(am_reg, 8);
		GenerateTriadic(op_csrrw, 0, makereg(0), MakeImmediate(0x18), ap2);
		GenerateZeradic(op_nop);
		GenerateZeradic(op_nop);
		GenerateDiadic(op_itof, 'q', ap1, makereg(63));
		ReleaseTempReg(ap2);
		goto retpt;
	case en_i2t:
		ap1 = GetTempFPRegister();
		ap2 = node->p[0]->Generate(am_reg, 8);
		GenerateTriadic(op_csrrw, 0, makereg(0), MakeImmediate(0x18), ap2);
		GenerateZeradic(op_nop);
		GenerateZeradic(op_nop);
		GenerateDiadic(op_itof, 't', ap1, makereg(63));
		ReleaseTempReg(ap2);
		goto retpt;
	case en_d2i:
		ap1 = GetTempRegister();
		ap2 = node->p[0]->Generate(am_fpreg, 8);
		GenerateDiadic(op_ftoi, 'd', ap1, ap2);
		ReleaseTempReg(ap2);
		goto retpt;
	case en_q2i:
		ap1 = GetTempRegister();
		ap2 = node->p[0]->Generate(am_fpreg, 8);
		GenerateDiadic(op_ftoi, 'q', makereg(63), ap2);
		GenerateZeradic(op_nop);
		GenerateZeradic(op_nop);
		GenerateTriadic(op_csrrw, 0, ap1, MakeImmediate(0x18), makereg(0));
		ReleaseTempReg(ap2);
		goto retpt;
	case en_t2i:
		ap1 = GetTempRegister();
		ap2 = node->p[0]->Generate(am_fpreg, 8);
		GenerateDiadic(op_ftoi, 't', makereg(63), ap2);
		GenerateZeradic(op_nop);
		GenerateZeradic(op_nop);
		GenerateTriadic(op_csrrw, 0, ap1, MakeImmediate(0x18), makereg(0));
		ReleaseTempReg(ap2);
		goto retpt;
	case en_s2q:
		ap1 = GetTempFPRegister();
		ap2 = node->p[0]->Generate(am_fpreg, 8);
		GenerateDiadic(op_fcvtsq, 0, ap1, ap2);
		ap1->type = stdquad.GetIndex();
		ReleaseTempReg(ap2);
		goto retpt;
	case en_d2q:
		ap1 = GetTempFPRegister();
		ap2 = node->p[0]->Generate(am_fpreg, 8);
		GenerateDiadic(op_fcvtdq, 0, ap1, ap2);
		ap1->type = stdquad.GetIndex();
		ReleaseTempReg(ap2);
		goto retpt;
	case en_t2q:
		ap1 = GetTempFPRegister();
		ap2 = node->p[0]->Generate(am_fpreg, 8);
		GenerateDiadic(op_fcvttq, 0, ap1, ap2);
		ap1->type = stdquad.GetIndex();
		ReleaseTempReg(ap2);
		goto retpt;

	case en_vadd:	  return node->GenBinary(flags, size, op_vadd);
	case en_vsub:	  return node->GenBinary(flags, size, op_vsub);
	case en_vmul:	  return node->GenBinary(flags, size, op_vmul);
	case en_vadds:	  return node->GenBinary(flags, size, op_vadds);
	case en_vsubs:	  return node->GenBinary(flags, size, op_vsubs);
	case en_vmuls:	  return node->GenBinary(flags, size, op_vmuls);
	case en_vex:      return node->GenBinary(flags, size, op_vex);
	case en_veins:    return node->GenBinary(flags, size, op_veins);

	case en_fadd:	  ap1 = node->GenBinary(flags, size, op_fadd); goto retpt;
	case en_fsub:	  ap1 = node->GenBinary(flags, size, op_fsub); goto retpt;
	case en_fmul:	  ap1 = node->GenBinary(flags, size, op_fmul); goto retpt;
	case en_fdiv:	  ap1 = node->GenBinary(flags, size, op_fdiv); goto retpt;

	case en_fdadd:    return node->GenBinary(flags, size, op_fdadd);
	case en_fdsub:    return node->GenBinary(flags, size, op_fdsub);
	case en_fsadd:    return node->GenBinary(flags, size, op_fsadd);
	case en_fssub:    return node->GenBinary(flags, size, op_fssub);
	case en_fdmul:    return node->GenMultiply(flags, size, op_fmul);
	case en_fsmul:    return node->GenMultiply(flags, size, op_fmul);
	case en_fddiv:    return node->GenMultiply(flags, size, op_fddiv);
	case en_fsdiv:    return node->GenMultiply(flags, size, op_fsdiv);
	case en_ftadd:    return node->GenBinary(flags, size, op_ftadd);
	case en_ftsub:    return node->GenBinary(flags, size, op_ftsub);
	case en_ftmul:    return node->GenMultiply(flags, size, op_ftmul);
	case en_ftdiv:    return node->GenMultiply(flags, size, op_ftdiv);

	case en_land:
		/*
		lab0 = nextlabel++;
		lab1 = nextlabel++;
		GenerateFalseJump(node, lab0, 0);
		ap1 = GetTempRegister();
		GenerateDiadic(op_ld, 0, ap1, MakeImmediate(1));
		GenerateMonadic(op_bra, 0, MakeDataLabel(lab1));
		GenerateLabel(lab0);
		GenerateDiadic(op_ld, 0, ap1, MakeImmediate(0));
		GenerateLabel(lab1);
		return (ap1);
		*/
		ap1 = (node->GenLand(flags, op_and, false));
		goto retpt;
	case en_lor:
		ap1 = (node->GenLand(flags, op_or, false));
		goto retpt;
	case en_land_safe:
		ap1 = (node->GenLand(flags, op_and, true));
		goto retpt;
	case en_lor_safe:
		ap1 = (node->GenLand(flags, op_or, true));
		goto retpt;

	case en_isnullptr:	ap1 = node->GenUnary(flags, size, op_isnullptr); goto retpt;
	case en_and:    ap1 = node->GenBinary(flags, size, op_and); goto retpt;
	case en_or:     ap1 = node->GenBinary(flags, size, op_or); goto retpt;
	case en_xor:	ap1 = node->GenBinary(flags, size, op_xor); goto retpt;
	case en_mulf:    ap1 = node->GenMultiply(flags, size, op_mulf); goto retpt;
	case en_mul:    ap1 = node->GenMultiply(flags, size, op_mul); goto retpt;
	case en_mulu:   ap1 = node->GenMultiply(flags, size, op_mulu); goto retpt;
	case en_div:    ap1 = node->GenDivMod(flags, size, op_div); goto retpt;
	case en_udiv:   ap1 = node->GenDivMod(flags, size, op_divu); goto retpt;
	case en_mod:    ap1 = node->GenDivMod(flags, size, op_rem); goto retpt;
	case en_umod:   ap1 = node->GenDivMod(flags, size, op_remu); goto retpt;
	case en_asl:    ap1 = node->GenShift(flags, size, op_sll); goto retpt;
	case en_shl:    ap1 = node->GenShift(flags, size, op_sll); goto retpt;
	case en_shlu:   ap1 = node->GenShift(flags, size, op_sll); goto retpt;
	case en_asr:	ap1 = node->GenShift(flags, size, op_sra); goto retpt;
	case en_shr:	ap1 = node->GenShift(flags, size, op_sra); goto retpt;
	case en_shru:   ap1 = node->GenShift(flags, size, op_srl); goto retpt;
	case en_rol:   ap1 = node->GenShift(flags, size, op_rol); goto retpt;
	case en_ror:   ap1 = node->GenShift(flags, size, op_ror); goto retpt;
		/*
		case en_asfadd: return GenerateAssignAdd(node,flags,size,op_fadd);
		case en_asfsub: return GenerateAssignAdd(node,flags,size,op_fsub);
		case en_asfmul: return GenerateAssignAdd(node,flags,size,op_fmul);
		case en_asfdiv: return GenerateAssignAdd(node,flags,size,op_fdiv);
		*/
	case en_asadd:	ap1 = node->GenerateAssignAdd(flags, size, op_add); goto retpt;
	case en_assub:  ap1 = node->GenerateAssignAdd(flags, size, op_sub); goto retpt;
	case en_asand:  ap1 = node->GenerateAssignLogic(flags, size, op_and); goto retpt;
	case en_asor:   ap1 = node->GenerateAssignLogic(flags, size, op_or); goto retpt;
	case en_asxor:  ap1 = node->GenerateAssignLogic(flags, size, op_xor); goto retpt;
	case en_aslsh:  ap1 = (node->GenAssignShift(flags, size, op_stpl)); goto retpt;
	case en_asrsh:  ap1 = (node->GenAssignShift(flags, size, op_asr)); goto retpt;
	case en_asrshu: ap1 = (node->GenAssignShift(flags, size, op_stpru)); goto retpt;
	case en_asmul: ap1 = cg.GenerateAssignMultiply(node, flags, size, op_mul); goto retpt;
	case en_asmulu: ap1 = cg.GenerateAssignMultiply(node, flags, size, op_mulu); goto retpt;
	case en_asdiv: ap1 = cg.GenerateAssignModiv(node, flags, size, op_div); goto retpt;
	case en_asdivu: ap1 = cg.GenerateAssignModiv(node, flags, size, op_divu); goto retpt;
	case en_asmod: ap1 = cg.GenerateAssignModiv(node, flags, size, op_rem); goto retpt;
	case en_asmodu: ap1 = cg.GenerateAssignModiv(node, flags, size, op_remu); goto retpt;
	case en_assign:
		ap1 = cg.GenerateAssign(node, flags, size);
		goto retpt;

	case en_chk:
		return (cg.GenExpr(node));

	case en_eq:     case en_ne:
	case en_lt:     case en_le:
	case en_gt:     case en_ge:
	case en_ult:    case en_ule:
	case en_ugt:    case en_uge:
	case en_feq:    case en_fne:
	case en_flt:    case en_fle:
	case en_fgt:    case en_fge:
	case en_veq:    case en_vne:
	case en_vlt:    case en_vle:
	case en_vgt:    case en_vge:
		ap1 = cg.GenExpr(node);
		ap1->isBool = true;
		goto retpt;

	case en_cond:
		ap1 = node->GenHook(flags, size);
		goto retpt;
	case en_safe_cond:
		ap1 = (node->GenSafeHook(flags, size));
		goto retpt;
	case en_void:
		natsize = node->p[0]->GetNaturalSize();
		ap1 = node->p[0]->Generate(am_all | am_novalue, natsize);
		ReleaseTempRegister(node->p[1]->Generate(flags, size));
		ap1->isPtr = node->IsPtr();
		goto retpt;

	case en_fcall:
		ap1 = (cg.GenerateFunctionCall(node, flags));
		goto retpt;

	case en_sxb:
		ap1 = GetTempRegister();
		ap2 = node->p[0]->Generate(am_reg, 1);
		GenerateDiadic(op_sxb, 0, ap1, ap2);
		ReleaseTempReg(ap2);
		ap1->MakeLegal(flags, 8);
		goto retpt;
	case en_sxc:
		ap1 = GetTempRegister();
		ap2 = node->p[0]->Generate(am_reg, 2);
		GenerateDiadic(op_sxc, 0, ap1, ap2);
		ReleaseTempReg(ap2);
		ap1->MakeLegal(flags, 8);
		goto retpt;
	case en_sxh:
		ap1 = GetTempRegister();
		ap2 = node->p[0]->Generate(am_reg, 4);
		GenerateDiadic(op_sxh, 0, ap1, ap2);
		ReleaseTempReg(ap2);
		ap1->MakeLegal(flags, 8);
		goto retpt;
	case en_cubw:
	case en_cubu:
	case en_cbu:
		ap1 = node->p[0]->Generate(am_reg, 1);
		GenerateTriadic(op_and, 0, ap1, ap1, MakeImmediate(0xff));
		goto retpt;
	case en_cucw:
	case en_cucu:
	case en_ccu:
		ap1 = node->p[0]->Generate(am_reg, 2);
		GenerateTriadic(op_and, 0, ap1, ap1, MakeImmediate(0xFFFF));
		//GenerateDiadic(op_zxc,0,ap1,ap1);
		goto retpt;
	case en_ccwp:
		ap1 = node->p[0]->Generate(am_reg, 2);
		ap1->isPtr = TRUE;
		GenerateDiadic(op_sxc, 0, ap1, ap1);
		goto retpt;
	case en_cucwp:
		ap1 = node->p[0]->Generate(am_reg, 2);
		ap1->isPtr = TRUE;	// zxc
		GenerateTriadic(op_and, 0, ap1, ap1, MakeImmediate(0xFFFF));
		goto retpt;
	case en_cuhw:
	case en_cuhu:
	case en_chu:
		ap1 = node->p[0]->Generate(am_reg, 4);
		GenerateDiadic(op_zxh, 0, ap1, ap1);
		goto retpt;
	case en_cbw:
		ap1 = node->p[0]->Generate(am_reg, 1);
		//GenerateDiadic(op_sxb,0,ap1,ap1);
		GenerateDiadic(op_sxb, 0, ap1, ap1);
		goto retpt;
	case en_ccw:
		ap1 = node->p[0]->Generate(am_reg, 2);
		GenerateDiadic(op_sxc, 0, ap1, ap1);
		goto retpt;
	case en_chw:
		ap1 = node->p[0]->Generate(am_reg, 4);
		GenerateDiadic(op_sxh, 0, ap1, ap1);
		goto retpt;
	case en_list:
		ap1 = GetTempRegister();
		GenerateDiadic(op_lea, 0, ap1, MakeDataLabel(node->i));
		ap1->isPtr = true;
		goto retpt;
	case en_object_list:
		ap1 = GetTempRegister();
		GenerateDiadic(op_lea, 0, ap1, MakeIndexed(-8, regFP));
		ap1->MakeLegal(flags, sizeOfWord);
		goto retpt;
	default:
		printf("DIAG - uncoded node (%d) in GenerateExpression.\n", node->nodetype);
		return 0;
	}
	return(0);
retpt:
	if (node->pfl) {
		ReleaseTempRegister(node->pfl->Generate(flags, size));
	}
	return (ap1);
}

// return the natural evaluation size of a node.

int GetNaturalSize(ENODE *node)
{ 
	int siz0, siz1;
	if( node == NULL )
		return 0;
	switch( node->nodetype )
	{
	case en_fieldref:
		return (node->tp->size);
	case en_icon:
		if (node->i >= -128 && node->i < 128)
			return (1);
		if( -32768 <= node->i && node->i <= 32767 )
			return (2);
		if (-2147483648LL <= node->i && node->i <= 2147483647LL)
			return (4);
		return (sizeOfWord);
	case en_fcon:
		return (node->tp->precision / 8);
	case en_tcon: return (6);
	case en_labcon: case en_clabcon:
	case en_cnacon: case en_nacon:  case en_autocon: case en_classcon:
	case en_tempref:
	case en_cbw: case en_cubw:
	case en_ccw: case en_cucw:
	case en_chw: case en_cuhw:
	case en_cbu: case en_ccu: case en_chu:
	case en_cubu: case en_cucu: case en_cuhu:
	case en_ccwp: case en_cucwp:
	case en_sxb:	case en_sxc:	case en_sxh:
		return (sizeOfWord);
	case en_fcall:
	case en_regvar:
	case en_fpregvar:
		if (node->tp)
			return (node->tp->size);
		else
			return (sizeOfWord);
	case en_autofcon:
		return (sizeOfWord);
	case en_ref:
		return (node->tp->size);
	case en_cbc:
	case en_cbh:	return (sizeOfWord/2);
	case en_cch:	return (sizeOfWord/2);
	case en_autovcon:
	case en_tempfpref:
	if (node->tp)
		return (node->tp->precision/16);
	else
		return (sizeOfWord);
	case en_not:    case en_compl:
	case en_uminus: case en_assign:
		return GetNaturalSize(node->p[0]);
	case en_fadd:	case en_fsub:
	case en_fmul:	case en_fdiv:
	case en_fsadd:	case en_fssub:
	case en_fsmul:	case en_fsdiv:
	case en_vadd:	case en_vsub:
	case en_vmul:	case en_vdiv:
	case en_vadds:	case en_vsubs:
	case en_vmuls:	case en_vdivs:
	case en_add:    case en_sub:	case en_ptrdif:
	case en_mul:    case en_mulu:
	case en_div:	case en_udiv:
	case en_mod:    case en_umod:
	case en_and:    case en_or:     case en_xor:
	case en_asl:
	case en_shl:    case en_shlu:
	case en_shr:	case en_shru:
	case en_asr:	case en_asrshu:
	case en_feq:    case en_fne:
	case en_flt:    case en_fle:
	case en_fgt:    case en_fge:
	case en_eq:     case en_ne:
	case en_lt:     case en_le:
	case en_gt:     case en_ge:
	case en_ult:	case en_ule:
	case en_ugt:	case en_uge:
	case en_land:   case en_lor:
	case en_land_safe:   case en_lor_safe:
	case en_asadd:  case en_assub:
	case en_asmul:  case en_asmulu:
	case en_asdiv:	case en_asdivu:
	case en_asmod:  case en_asmodu: case en_asand:
	case en_asor:   case en_asxor:	case en_aslsh:
	case en_asrsh:
		siz0 = GetNaturalSize(node->p[0]);
		siz1 = GetNaturalSize(node->p[1]);
		if( siz1 > siz0 )
			return (siz1);
		else
			return (siz0);
	case en_void:   case en_cond:	case en_safe_cond:
		return (GetNaturalSize(node->p[1]));
	case en_bchk:
		return (GetNaturalSize(node->p[0]));
	case en_chk:
		return 8;
	case en_q2i:
	case en_t2i:
		return (sizeOfWord);
	case en_i2d:
		return (sizeOfWord);
	case en_i2t:
	case en_d2t:
		return (sizeOfFPT);
	case en_i2q:
	case en_d2q:
	case en_t2q:
		return (sizeOfFPQ);
	case en_object_list:
		return (GetNaturalSize(node->p[0]));
	case en_addrof:
		return (sizeOfPtr);
	default:
		printf("DIAG - natural size error %d.\n", node->nodetype);
		break;
	}
	return (0);
}



void ENODE::PutConstant(txtoStream& ofs, unsigned int lowhigh, unsigned int rshift, bool opt)
{
	// ASM statment text (up to 3500 chars) may be placed in the following buffer.
	static char buf[4000];

	// Used only by lea for subtract
	if (isNeg)
		ofs.write("-");
	switch (nodetype)
	{
	case en_autofcon:
		sprintf_s(buf, sizeof(buf), "%lld", i);
		ofs.write(buf);
		break;
	case en_fcon:
		if (!opt)
			goto j1;
		// The following spits out a warning, but is okay.
		sprintf_s(buf, sizeof(buf), "0x%llx", f);
		ofs.write(buf);
		break;
	case en_autovcon:
	case en_autocon:
	case en_icon:
		if (lowhigh == 2) {
			sprintf_s(buf, sizeof(buf), "%lld", i & 0xffff);
			ofs.write(buf);
		}
		else if (lowhigh == 3) {
			sprintf_s(buf, sizeof(buf), "%lld", (i >> 16) & 0xffff);
			ofs.write(buf);
		}
		else {
			sprintf_s(buf, sizeof(buf), "%lld", i);
			ofs.write(buf);
		}
		if (rshift > 0) {
			sprintf_s(buf, sizeof(buf), ">>%d", rshift);
			ofs.write(buf);
		}
		break;
	case en_labcon:
	j1:
		sprintf_s(buf, sizeof(buf), "%s_%lld", GetNamespace(), i);
		DataLabels[i] = true;
		ofs.write(buf);
		if (rshift > 0) {
			sprintf_s(buf, sizeof(buf), ">>%d", rshift);
			ofs.write(buf);
		}
		break;
	case en_clabcon:
		sprintf_s(buf, sizeof(buf), "%s_%lld", GetNamespace(), i);
		DataLabels[i] = true;
		ofs.write(buf);
		if (rshift > 0) {
			sprintf_s(buf, sizeof(buf), ">>%d", rshift);
			ofs.write(buf);
		}
		break;
	case en_nacon:
		sprintf_s(buf, sizeof(buf), "%s", (char *)sp->c_str());
		ofs.write(buf);
		if (lowhigh == 3) {
			sprintf_s(buf, sizeof(buf), ">>16");
			ofs.write(buf);
		}
		if (rshift > 0) {
			sprintf_s(buf, sizeof(buf), ">>%d", rshift);
			ofs.write(buf);
		}
		break;
	case en_scon:
		sprintf_s(buf, sizeof(buf), "\"%s\",0", (char *)sp->c_str());
		ofs.write(buf);
		break;
	case en_cnacon:
		sprintf_s(buf, sizeof(buf), "%s", (char *)msp->c_str());
		ofs.write(buf);
		if (rshift > 0) {
			sprintf_s(buf, sizeof(buf), ">>%d", rshift);
			ofs.write(buf);
		}
		break;
	case en_add:
		p[0]->PutConstant(ofs, 0, 0);
		ofs.write("+");
		p[1]->PutConstant(ofs, 0, 0);
		break;
	case en_sub:
		p[0]->PutConstant(ofs, 0, 0);
		ofs.write("-");
		p[1]->PutConstant(ofs, 0, 0);
		break;
	case en_ptrdif:
		ofs.printf("(");
		p[0]->PutConstant(ofs, 0, 0);
		ofs.write("-");
		p[1]->PutConstant(ofs, 0, 0);
		ofs.printf(") >> ");
		p[4]->PutConstant(ofs, 0, 0);
		break;
	case en_uminus:
		ofs.write("-");
		p[0]->PutConstant(ofs, 0, 0);
		break;
	default:
		printf("DIAG - illegal constant node.\n");
		break;
	}
}

ENODE *ENODE::GetConstantHex(std::ifstream& ifs)
{
	static char buf[4000];
	ENODE *ep;

	ep = allocEnode();
	ifs.read(buf, 2);
	buf[2] = '\0';
	ep->nodetype = (e_node)strtol(buf, nullptr, 16);
	switch (ep->nodetype) {
	case en_autofcon:
		ifs.read(buf, 8);
		buf[8] = '\0';
		ep->i = strtol(buf, nullptr, 16);
		break;
	case en_fcon:
		goto j1;
	case en_autovcon:
	case en_autocon:
	case en_icon:
		ifs.read(buf, 8);
		buf[8] = '\0';
		ep->i = strtol(buf, nullptr, 16);
		break;
	case en_labcon:
j1:		;
	}
	return (ep);
}

void ENODE::PutConstantHex(txtoStream& ofs, unsigned int lowhigh, unsigned int rshift)
{
	// ASM statment text (up to 3500 chars) may be placed in the following buffer.
	static char buf[4000];

	ofs.printf("N%02X", nodetype);
	switch (nodetype)
	{
	case en_autofcon:
		sprintf_s(buf, sizeof(buf), "%08LLX", i);
		ofs.write(buf);
		break;
	case en_fcon:
		sprintf_s(buf, sizeof(buf), "%s_%lld:", GetNamespace(), i);
		ofs.write(buf);
		break;
	case en_autovcon:
	case en_autocon:
	case en_icon:
		sprintf_s(buf, sizeof(buf), "%08llX", i);
		ofs.write(buf);
		break;
	case en_labcon:
		sprintf_s(buf, sizeof(buf), "%s_%lld:", GetNamespace(), i);
		ofs.write(buf);
		break;
	case en_clabcon:
		sprintf_s(buf, sizeof(buf), "%s_%lld:", GetNamespace(), i);
		ofs.write(buf);
		break;
	case en_nacon:
		sprintf_s(buf, sizeof(buf), "%s:", (char *)sp->c_str());
		ofs.write(buf);
		break;
	case en_cnacon:
		sprintf_s(buf, sizeof(buf), "%s:", (char *)msp->c_str());
		ofs.write(buf);
		break;
	case en_add:
		p[0]->PutConstantHex(ofs, 0, 0);
		ofs.write("+");
		p[1]->PutConstantHex(ofs, 0, 0);
		break;
	case en_sub:
		p[0]->PutConstantHex(ofs, 0, 0);
		ofs.write("-");
		p[1]->PutConstantHex(ofs, 0, 0);
		break;
	case en_uminus:
		ofs.write("-");
		p[0]->PutConstantHex(ofs, 0, 0);
		break;
	default:
		printf("DIAG - illegal constant node.\n");
		break;
	}
}

void ENODE::storeHex(txtoStream& ofs)
{
	if (this == nullptr) {
		ofs.puts("x");
		return;
	}
	ofs.puts("X");
	ofs.writeAsHex((char *)this, sizeof(ENODE));
	if (tp)
		ofs.printf("%05X:", tp->typeno);
	else
		ofs.printf("FFFFF:");
	if (sym)
		ofs.printf("%05X:", sym->number);
	else
		ofs.printf("FFFFF:");
	vmask->store(ofs);
	if (sp) {
		ofs.printf("%03X:", (int)sp->length());
		ofs.writeAsHex(sp->c_str(), sp->length());
	}
	else
		ofs.printf("000:");
	if (msp) {
		ofs.printf("%03X:", (int)msp->length());
		ofs.writeAsHex(msp->c_str(), msp->length());
	}
	else
		ofs.printf("000:");
	if (udnm) {
		ofs.printf("%03X:", (int)udnm->length());
		ofs.writeAsHex(udnm->c_str(), udnm->length());
	}
	else
		ofs.printf("000:");
	p[0]->store(ofs);
	p[1]->store(ofs);
	p[2]->store(ofs);
}

void ENODE::loadHex(txtiStream& ifs)
{
	int nn;
	static char buf[8000];

	ifs.readAsHex(this, sizeof(ENODE));
	ifs.read(buf, 6);
	nn = strtoul(buf, nullptr, 16);
	if (nn < 65535)
		tp = &compiler.typeTable[nn];
	ifs.read(buf, 6);
	nn = strtoul(buf, nullptr, 16);
	if (nn < 65535)
		sym = &compiler.symbolTable[nn];
	vmask = allocEnode();
	vmask->load(ifs);
	ifs.read(buf, 4);
	nn = strtoul(buf, nullptr, 16);
	ifs.readAsHex(buf, nn * 2);
	buf[nn * 2] = '\0';
	sp = new std::string(buf);
	ifs.read(buf, 4);
	nn = strtoul(buf, nullptr, 16);
	ifs.readAsHex(buf, nn * 2);
	buf[nn * 2] = '\0';
	msp = new std::string(buf);
	ifs.read(buf, 4);
	nn = strtoul(buf, nullptr, 16);
	ifs.readAsHex(buf, nn * 2);
	buf[nn * 2] = '\0';
	udnm = new std::string(buf);
	ifs.read(buf, 1);	// should be 'X'
	if (buf[0]=='X')
		p[0]->load(ifs);
	ifs.read(buf, 1);
	if (buf[0] == 'X')
		p[1]->load(ifs);
	ifs.read(buf, 1);
	if (buf[0] == 'X')
		p[2]->load(ifs);
}

void ENODE::store(txtoStream& ofs)
{
}

void ENODE::load(txtiStream& ifs)
{
}

int ENODE::PutStructConst(txtoStream& ofs)
{
	int64_t n, k;
	ENODE *ep1;
	ENODE *ep = this;
	bool isStruct;

	if (ep == nullptr)
		return (0);
	if (ep->nodetype != en_aggregate)
		return (0);

	isStruct = ep->tp->IsStructType();
	for (n = 0, ep1 = ep->p[0]->p[2]; ep1; ep1 = ep1->p[2]) {
		if (ep1->nodetype == en_aggregate) {
			k = ep1->PutStructConst(ofs);
		}
		else {
			if (isStruct) {
				switch (ep1->tp->walignment()) {
				case 1:	break;
				default: ofs.printf("align %ld\t", (int)ep1->tp->walignment()); break;
				}
				k = ep1->tp->struct_offset + ep1->esize;
			}
			else
				k = ep1->esize;
			switch (ep1->esize) {
			case 1:	ofs.printf("db\t");	ep1->PutConstant(ofs, 0, 0); ofs.printf("\n"); break;
			case 2:	ofs.printf("dc\t");	ep1->PutConstant(ofs, 0, 0); ofs.printf("\n"); break;
			case 4:	ofs.printf("dh\t");	ep1->PutConstant(ofs, 0, 0); ofs.printf("\n"); break;
			case 8:	ofs.printf("dw\t");	ep1->PutConstant(ofs, 0, 0, true); ofs.printf("\n"); break;
			default:
				ofs.printf("fill.b %ld,0x00\n", ep1->esize - 1);
				ofs.printf("db\t");
				ep1->PutConstant(ofs, 0, 0, true);
				ofs.printf("\n");
				break;
			}
		}
		if (isStruct)
			n = k;
		else
			n = n + k;
	}
	if (n < ep->esize) {
		ofs.printf("fill.b %ld,0x00\n", ep->esize - n);
	}
	return (n);
}

// ============================================================================
// ============================================================================
// Debugging
// ============================================================================
// ============================================================================

std::string ENODE::nodetypeStr()
{
	switch (nodetype) {
	case en_regvar:	return "en_regvar";
	case en_autocon: return "en_autocon";
	case en_cond:	return "en_cond";
	case en_void: return "en_void";
	case en_asadd: return "en_asadd";
	case en_icon: return "en_icon";
	case en_assign: return "en_assign";
	case en_eq: return "en_eq";
	default:
		if (IsRefType()) {
			return "en_ref";
		}
		break;
	}
	return "???";
}

void ENODE::Dump()
{
	int nn;
	static int level = 0;

	//return;
	if (this == nullptr)
		return;
	for (nn = 0; nn < level * 2; nn++)
		dfs.printf(" ");
	dfs.printf("Node:%d\n", number);
	for (nn = 0; nn < level * 2; nn++)
		dfs.printf(" ");
	dfs.printf("nodetype: %d: ", nodetype);
	dfs.printf("%s\n", (char *)nodetypeStr().c_str());
	for (nn = 0; nn < level * 2; nn++)
		dfs.printf(" ");
	dfs.printf("rg: %d\n", rg);
	level++;
	p[0]->Dump();
	p[1]->Dump();
	p[2]->Dump();
	level--;
}
