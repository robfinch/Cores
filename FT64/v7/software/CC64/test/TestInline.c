

naked int TestInline(inline char *str)
{
	__asm {
.0002:
		lc		r1,[lr]
		beq		r1,r0,.0001
		push	lr
		push	r1
		call	_DBGDisplayChar
		lw		lr,8[sp]
		add		sp,sp,#16
		add		lr,lr,#2
		bra		.0002
.0001:
		add		lr,lr,#2
		ret
	}
}

int main(int arg)
{
	TestInline(2,I"Hello World!",I"A second parameter");
}
