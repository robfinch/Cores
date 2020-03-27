`ifndef FT2021_CONST_SV
`define FT2021_CONST_SV

`define VAL		1'b1
`define INV		1'b0
`define TRUE	1'b1
`define FALSE	1'b0

`define cBRK	7'h00

`define cJSR	7'h30
`define cJSRR	7'h31
`define cRTS	7'h32

`define cBEQ	7'h38
`define cBNE	7'h39
`define cBRA	7'h3A
`define cBUN	7'h3B
`define cBLT	7'h3C
`define cBGE	7'h3D
`define cBLE	7'h3E
`define cBGT	7'h3F

`define PANIC_NONE		4'd0
`define PANIC_INVALIDIQSTATE	4'd1

`endif
