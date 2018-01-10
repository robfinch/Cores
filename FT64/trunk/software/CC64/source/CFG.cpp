#include "stdafx.h"

extern OCODE *peep_head;
extern OCODE *FindLabel(int64_t);

void CreateControlFlowGraph()
{
	OCODE *ip, *ip1;
	int nn;
	struct scase *cs;

	for (ip = peep_head; ip; ip = ip->fwd) {
		if (ip->leader) {
		if (ip->back) {
		// if not unconditional control transfer
			if (ip->back->opcode != op_ret && ip->back->opcode != op_bra && ip->back->opcode!=op_jmp) {
				ip->back->bb->MakeOutputEdge(ip->bb);
				ip->bb->MakeInputEdge(ip->back->bb);
			}
		}
		}
		//}
		switch(ip->opcode) {
		case op_bra:
		case op_jmp:
		case op_beq:
		case op_bne:
		case op_blt:
		case op_bge:
		case op_ble:
		case op_bgt:
		case op_bltu:
		case op_bgeu:
		case op_bleu:
		case op_bgtu:
		case op_bbs:
		case op_bbc:
		case op_beqi:
			if (ip->oper1->offset) {
				if (ip1 = FindLabel(ip->oper1->offset->i)) {
					ip->bb->MakeOutputEdge(ip1->bb);
					ip1->bb->MakeInputEdge(ip->bb);
				}
			}
			else {
				if (0) {
					if (ip->oper1->mode==am_reg && ip->back && ip->back->oper3) {
						if (ip1 = FindLabel(ip->back->oper3->offset->i)) {
							ip->bb->MakeOutputEdge(ip1->bb);
							ip1->bb->MakeInputEdge(ip->bb);
						}
					}
				}
				else {
					if (ip1 = FindLabel(ip->oper3->offset->i)) {
						ip->bb->MakeOutputEdge(ip1->bb);
						ip1->bb->MakeInputEdge(ip->bb);
					}
				}
			}
			break;
		case op_jal:
			// Was it a switch statement ?
			if (ip->oper3) {
				for (nn = 1; nn < ((struct scase *)(ip->oper3))->label; nn++) {
					cs = &((struct scase *)(ip->oper3))[1];
					ip1 = FindLabel(cs->label);
					if (ip1) {
						ip->bb->MakeOutputEdge(ip1->bb);
						ip1->bb->MakeInputEdge(ip->bb);
					}
				}
			}
			else {
				// Could be a jal [LR] for a ret statement in which case there's
				// only one operand.
				if (ip->oper2) {
					if (ip->oper2->mode != am_reg) {
						if (ip1 = FindLabel(ip->oper2->offset->i)) {
							ip->bb->MakeOutputEdge(ip1->bb);
							ip1->bb->MakeInputEdge(ip->bb);
						}
					}
				}
			}
			break;
		}
	}
}

