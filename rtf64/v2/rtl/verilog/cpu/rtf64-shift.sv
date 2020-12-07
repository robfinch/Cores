// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rtf64-shift.sv
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//                                                                          
// ============================================================================

import rtf64pkg::*;

module rtf64_shift(ir, ia, ib, id, imm, cds, res);
parameter WID=64;
input [31:0] ir;
input [WID-1:0] ia;
input [WID-1:0] ib;
input [WID-1:0] id;
input [WID-1:0] imm;
input [31:0] cds;
output reg [WID-1:0] res;

wire [128: 0] shlr = {ia,ir[27:24]==`ASLX ? cds[0] : 1'b0} << ib[5:0];
wire [128:-1] shrr = {ir[27:24]==`LSRX ? cds[0] : 1'b0,ia,65'd0} >> ib[5:0];
wire [129: 0] shli = {ia,ir[27:24]==`ASLXI  ? cds[0] : 1'b0} << imm[5:0];
wire [128:-1] shri = {ir[27:24]==`LSRXI ? cds[0] : 1'b0,ia,65'd0} >> imm[5:0];

always @*
begin
  case(ir[27:24])
  `ASL:  
    case(ir[30:28])
    3'd0:  res <= shlr[65:1];
    3'd1:  res <= {id[63:32],shlr[32:1]};
    3'd2:  res <= {id[63:16],shlr[16:1]};
    3'd3:  res <= {id[63:8],shlr[8:1]};
    default: res <= shlr[64:1];
    endcase
  `LSR:
    case(ir[30:28])
    3'd0: res <= {shrr[63],ia} >> ib[5:0];
    3'd1: res <= {id[63:32],fnTrim32(ia[31:0] >> ib[5:0])};
    3'd2: res <= {id[63:16],fnTrim16(ia[15:0] >> ib[5:0])};
    3'd3: res <= {id[63:8],fnTrim8(ia[7:0] >> ib[5:0])};
    default:  res <= {shrr[63],ia} >> ib[5:0];
    endcase
  `ROL:  res <= shlr[64:1]|shlr[128:65];
  `ROR:  res <= shrr[127:64]|shrr[63:0];
  `ASR:  
    case(ir[30:28])
    3'd0: res <= ia[63] ? {{64{1'b1}},ia} >> ib[5:0] : ia >> ib[5:0];
    3'd1: res <= {id[63:32],fnTrim32(ia[31] ? ({{96{1'b1}},ia[31:0]} >> ib[5:0]) : ia[31:0] >> ib[5:0])};
    3'd2: res <= {id[63:16],fnTrim16(ia[31] ? ({{112{1'b1}},ia[15:0]} >> ib[5:0]) : ia[15:0] >> ib[5:0])};
    3'd3: res <= {id[63:8],fnTrim8(ia[31] ? ({{120{1'b1}},ia[7:0]} >> ib[5:0]) : ia[7:0] >> ib[5:0])};
    default:  res <= ia[63] ? {{64{1'b1}},ia} >> ib[5:0] : shrr[63:0];
    endcase
  `LSRX: res <= {shrr[63],shrr[127:64]};
  `ASLX: res <= shlr[63:0];
  `ASLI:
    case(ir[30:28])
    3'd0:  res <= shli[65:1];
    3'd1:  res <= {id[63:32],shli[32:1]};
    3'd2:  res <= {id[63:16],shli[16:1]};
    3'd3:  res <= {id[63:8],shli[8:1]};
    default: res <= shli[64:1];
    endcase
  `LSRI:
    case(ir[30:28])
    3'd0: res <= {shrr[63],ia >> imm[5:0]};
    3'd1: res <= {id[63:32],fnTrim32(ia[31:0] >> imm[5:0])};
    3'd2: res <= {id[63:16],fnTrim16(ia[15:0] >> imm[5:0])};
    3'd3: res <= {id[63:8],fnTrim8(ia[7:0] >> imm[5:0])};
    default:  res <= {shrr[63],ia} >> imm[5:0];
    endcase
  `ROLI: res <= shli[64:1]|shli[128:65];
  `RORI: res <= shri[127:64]|shri[63:0];
  `ASRI: 
    case(ir[30:28])
    3'd0: res <= ia[63] ? {{64{1'b1}},ia} >> imm[5:0] : ia >> imm[5:0];
    3'd1: res <= {id[63:32],fnTrim32(ia[31] ? ({{96{1'b1}},ia[31:0]} >> imm[5:0]) : ia[31:0] >> imm[5:0])};
    3'd2: res <= {id[63:16],fnTrim16(ia[31] ? ({{112{1'b1}},ia[15:0]} >> imm[5:0]) : ia[15:0] >> imm[5:0])};
    3'd3: res <= {id[63:8],fnTrim8(ia[31] ? ({{120{1'b1}},ia[7:0]} >> imm[5:0]) : ia[7:0] >> imm[5:0])};
    default:  res <= ia[63] ? {{64{1'b1}},ia} >> imm[5:0] : ia >> imm[5:0];
    endcase
  `ASLXI: res <= shli[65:1];
  `LSRXI: res <= {shri[63],shri[127:64]};
  default:  ;
  endcase
end

endmodule
