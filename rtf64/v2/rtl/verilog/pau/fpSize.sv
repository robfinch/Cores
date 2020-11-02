`ifndef EXTRA_BITS
`define EXTRA_BITS	0
`endif

parameter FPWID2 = 64;
// This file contains defintions for fields to ease dealing with different fp
// widths. Some of the code still needs to be modified to support widths
// other than standard 32,64 or 80 bit.
localparam MSB = FPWID2-1+`EXTRA_BITS;
localparam EMSB = FPWID2==128 ? 14 :
          FPWID2==96 ? 14 :
          FPWID2==80 ? 14 :
          FPWID2==64 ? 10 :
				  FPWID2==52 ? 10 :
				  FPWID2==48 ? 10 :
				  FPWID2==44 ? 10 :
				  FPWID2==42 ? 10 :
				  FPWID2==40 ?  9 :
				  FPWID2==32 ?  7 :
				  FPWID2==24 ?  6 : 4;
localparam FMSB = FPWID2==128 ? (111 + `EXTRA_BITS) :
          FPWID2==96 ? (79 + `EXTRA_BITS) :
          FPWID2==80 ? (63 + `EXTRA_BITS) :
          FPWID2==64 ? (51 + `EXTRA_BITS) :
				  FPWID2==52 ? (39 + `EXTRA_BITS) :
				  FPWID2==48 ? (35 + `EXTRA_BITS) :
				  FPWID2==44 ? (31 + `EXTRA_BITS) :
				  FPWID2==42 ? (29 + `EXTRA_BITS) :
				  FPWID2==40 ? (28 + `EXTRA_BITS) :
				  FPWID2==32 ? (22 + `EXTRA_BITS) :
				  FPWID2==24 ? (15 + `EXTRA_BITS) : (9 + `EXTRA_BITS);
localparam FX = (FMSB+2)*2;	// the MSB of the expanded fraction
localparam EX = FX + 1 + EMSB + 1 + 1 - 1;
