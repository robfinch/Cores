#	code
_main:
	      	   #    	int main()
	      	   push 	r13
	      	   #    		printf("Hello World!");
	      	   push 	r8
	      	   mov  	r5,r0,TestTry_1
	      	   mov  	r8,r5
	      	   jsr  	r13,r0,_printf
	      	   pop  	r8
	      	   pop  	r13
	      	   mov  	r15,r13




#	rodata
	align	2
TestTry_1:	# Hello World!
	word	72,101,108,108,111,32,87,111
	word	114,108,100,33,0
#	global	_main
#	extern	_printf
