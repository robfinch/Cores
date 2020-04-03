// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// ============================================================================

`include "..\inc\Thor2020-config.sv"
`include "..\inc\Thor2020-const.sv"
`include "..\inc\Thor2020-types.sv"

module segmentRegs(rst, clk, state, expat, po0, po1, po2, ir0, ir1, ir2, s0, s1, s2, cs, rad, rsego, wad, wsego, rg, sego1);
input rst;
input clk;
input [5:0] state;
input [8:0] expat;
input po0;
input po1;
input po2;
input tInstruction ir0;
input tInstruction ir1;
input tInstruction ir2;
input tData s0;
input tData s1;
input tData s2;
output tData cs;
input tAddress rad;
output tData rsego;
input tAddress wad;
output tData wsego;
input [2:0] rg;
output tData sego1;

parameter AMSB=`AMSB;
parameter ST_RUN=6'd2;
parameter R2=7'd2,MFSPR=7'd32,MTSPR=7'd33;

tData seg [0:7];
integer n;

always @(posedge clk)
if (rst) begin
  for (n = 0; n < 8; n = n + 1)
    seg[n] <= 64'hF;
end
else begin
  if (state==ST_RUN) begin
    // Instructions are evaluated in order so that the last MTSPR takes
    // precedence if there are two writes to the same register.
    if (expat[6] & po0)
  	  case(ir0.gen.opcode)
  	  R2:
  	    case(ir0[40:34])
  	    MTSPR:  if (ir0[32:24]==9'b000_001_100) seg[ir0[23:21]] <= s0;
  	    default : ;
  	    endcase
    	default:  ;
      endcase
    if (expat[7] & po1)
  	  case(ir1.gen.opcode)
  	  R2:
  	    case(ir1[40:34])
  	    MTSPR:  if (ir1[32:24]==9'b000_001_100) seg[ir1[23:21]] <= s1;
  	    default : ;
  	    endcase
    	default:  ;
      endcase
    if (expat[8] & po2)
  	  case(ir2.gen.opcode)
  	  R2:
  	    case(ir2[40:34])
  	    MTSPR:  if (ir2[32:24]==9'b000_001_100) seg[ir2[23:21]] <= s2;
  	    default : ;
  	    endcase
    	default:  ;
      endcase
  end
end

assign cs = seg[7];
assign rsego = seg[rad[AMSB:AMSB-2]];
assign wsego = seg[wad[AMSB:AMSB-2]];
assign sego1 = seg[rg];

endmodule
