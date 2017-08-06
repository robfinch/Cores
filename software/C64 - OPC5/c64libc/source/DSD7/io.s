	code
	align	8
_inhSTKSIZE_ EQU 0
_inhuSTKSIZE_ EQU 0
_inwSTKSIZE_ EQU 0
_outcSTKSIZE_ EQU 0
_outhSTKSIZE_ EQU 0
_outwSTKSIZE_ EQU 0
_getCPUSTKSIZE_ EQU 0
	rodata
	align	16
	align	8
	align	1
	extern	_inhu
	extern	_outc
	extern	_outh
	extern	_outw
;	global	_getCPU
	extern	_inh
	extern	_inw
