`ifndef EXTRA_BITS
`define EXTRA_BITS	0
`endif

// This file contains defintions for fields to ease dealing with different fp
// widths. Some of the code still needs to be modified to support widths
// other than standard 32,64 or 80 bit.
localparam MSB = WID-1+`EXTRA_BITS;
localparam EMSB = WID==128 ? 14 :
          WID==96 ? 14 :
          WID==80 ? 14 :
          WID==64 ? 10 :
				  WID==52 ? 10 :
				  WID==48 ? 10 :
				  WID==44 ? 10 :
				  WID==42 ? 10 :
				  WID==40 ?  9 :
				  WID==32 ?  7 :
				  WID==24 ?  6 : 4;
localparam FMSB = WID==128 ? (111 + `EXTRA_BITS) :
          WID==96 ? (79 + `EXTRA_BITS) :
          WID==80 ? (63 + `EXTRA_BITS) :
          WID==64 ? (51 + `EXTRA_BITS) :
				  WID==52 ? (39 + `EXTRA_BITS) :
				  WID==48 ? (35 + `EXTRA_BITS) :
				  WID==44 ? (31 + `EXTRA_BITS) :
				  WID==42 ? (29 + `EXTRA_BITS) :
				  WID==40 ? (28 + `EXTRA_BITS) :
				  WID==32 ? (22 + `EXTRA_BITS) :
				  WID==24 ? (15 + `EXTRA_BITS) : (9 + `EXTRA_BITS);
localparam FX = (FMSB+2)*2;	// the MSB of the expanded fraction
localparam EX = FX + 1 + EMSB + 1 + 1 - 1;
