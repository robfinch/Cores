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
			ip->back->bb->MakeOutputEdge(ip->bb);
			ip->bb->MakeInputEdge(ip->back->bb);
		}
		if (ip->opcode==op_inc || ip->opcode==op_dec) {
			if (ip->oper1 && ip->oper1->preg==regPC) {
				if (ip->oper2 && ip->oper2->offset) {
					if (ip1 = FindLabel(ip->oper2->offset->i)) {
						ip->bb->MakeOutputEdge(ip1->bb);
						ip1->bb->MakeInputEdge(ip->bb);
					}
				}
			}
		}
		else if (ip->opcode==op_mov && ip->oper1 && ip->oper1->preg==regPC) {
			// Was it a switch statement ?
			// This needs the case labels in a list in oper4
			if (ip->oper4) {
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
				if (ip->oper3) {
					if (ip->oper3->offset) {
						if (ip1 = FindLabel(ip->oper3->offset->i)) {
							ip->bb->MakeOutputEdge(ip1->bb);
							ip1->bb->MakeInputEdge(ip->bb);
						}
					}
				}
			}
		}
	}
}

