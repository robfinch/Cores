`ifndef EXTRA_BITS
`define EXTRA_BITS	0
`endif

// This file contains defintions for fields to ease dealing with different fp
// FPWIDths. Some of the code still needs to be modified to support FPWIDths
// other than standard 32,64 or 80 bit.
localparam MSB = FPWID-1;
localparam EMSB = FPWID==128 ? 14 :
          FPWID==96 ? 14 :
          FPWID==80 ? 14 :
          FPWID==64 ? 10 :
				  FPWID==52 ? 10 :
				  FPWID==48 ? 10 :
				  FPWID==44 ? 10 :
				  FPWID==42 ? 10 :
				  FPWID==40 ?  9 :
				  FPWID==32 ?  7 :
				  FPWID==24 ?  6 : 4;
localparam FMSB = FPWID==128 ? (111) :
          FPWID==96 ? (79) :
          FPWID==80 ? (63) :
          FPWID==64 ? (51) :
				  FPWID==52 ? (39) :
				  FPWID==48 ? (35) :
				  FPWID==44 ? (31) :
				  FPWID==42 ? (29) :
				  FPWID==40 ? (28) :
				  FPWID==32 ? (22) :
				  FPWID==24 ? (15) : (9);
localparam FX = (FMSB+2)*2;	// the MSB of the expanded fraction
localparam EX = FX + 1 + EMSB + 1 + 1 - 1;
