#include "stdafx.h"

bool OCODE::HasSourceReg(int regno) const
{
	if (oper1 && !oper1->isTarget) {
		if (oper1->preg==regno)
			return (true);
		if (oper1->sreg==regno)
			return (true);
	}
	if (oper2 && oper2->preg==regno)
		return (true);
	if (oper2 && oper2->sreg==regno)
		return (true);
	if (oper3 && oper3->preg==regno)
		return (true);
	if (oper3 && oper3->sreg==regno)
		return (true);
	if (oper4 && oper4->preg==regno)
		return (true);
	if (oper4 && oper4->sreg==regno)
		return (true);
	return (false);
}
