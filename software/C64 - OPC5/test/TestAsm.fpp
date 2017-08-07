
int TestAsm(register int a, register int b)
{
	asm __leafs {
		push	r8
		push	r9
		jsr		a_sub
		inc		r14,2
	};
}

naked int TestAsm2(register int a)
{
	asm {
		add		r8,r0,1
	}
}
