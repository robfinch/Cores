	.text
	.file	"HelloWorld.c"
	.globl	main                            # -- Begin function main
	.p2align	2
	.type	main,@function
main:                                   # @main
.Lfunc_begin0:
# %bb.0:                                # %entry
	mflr 0
	stw 0, 4(1)
	stwu 1, -16(1)
	stw 31, 12(1)
	mr	31, 1
	lis 3, .L.str@ha
	la 3, .L.str@l(3)
	crxor 6, 6, 6
	bl printf
	lwz 0, 20(1)
	lwz 31, 12(1)
	addi 1, 1, 16
	mtlr 0
	blr
.Lfunc_end0:
	.size	main, .Lfunc_end0-.Lfunc_begin0
                                        # -- End function
	.type	.L.str,@object                  # @.str
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"Hello World!"
	.size	.L.str, 13

	.ident	"clang version 11.0.0"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym printf
