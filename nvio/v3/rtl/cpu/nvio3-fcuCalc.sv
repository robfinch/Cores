// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// FCU_Calc.v
// - flow control calcs
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
//
`include ".\nvio3-defines.sv"

module FCU_Calc(ol, instr, tvec, a, nextpc, im, waitctr, bus);
parameter WID = 128;
parameter AMSB = 127;
input [1:0] ol;
input [39:0] instr;
input [WID-1:0] tvec;
input [WID-1:0] a;
input [AMSB:0] nextpc;
input [3:0] im;
input [WID-1:0] waitctr;
output reg [WID-1:0] bus;

always @*
begin
  case(instr[`OPCODE])
  `BMISC:
  	case(instr[`BFUNCT4])
  	`BRK:   bus <= {120'd0,a[7:0]} | {120'b0,instr[29:22]};
  	default:	bus <= {32{4'hC}};
  	endcase
  `JRL:		bus <= nextpc;
  `JSR:		bus <= nextpc;
  `RTS:		bus <= a + {instr[39:23],4'h0};
  `REX:
    case(ol)
    `OL_USER:   bus <= bus <= {32{4'hC}};
    // ToDo: fix im test
    default:    bus <= (im < ~{ol,2'b00}) ? tvec : nextpc;
    endcase
  `BMISC2:
  	case(instr[`BFUNCT4])
  	`RTI:		bus <= {32{4'hC}};	// RTI
  	`WAIT:  bus <= waitctr==64'd1;
		`CRLOG:
			begin
				bus <= a;
				case(instr[`CRLOGFN])
				`CRAND:		bus[instr[13:8]] <=   a[instr[19:14]] & a[instr[25:20]];
				`CROR:		bus[instr[13:8]] <=   a[instr[19:14]] | a[instr[25:20]];
				`CRXOR:		bus[instr[13:8]] <=   a[instr[19:14]] ^ a[instr[25:20]];
				`CRANDC:	bus[instr[13:8]] <=   a[instr[19:14]] & ~a[instr[25:20]];
				`CRAND:		bus[instr[13:8]] <= ~(a[instr[19:14]] & a[instr[25:20]]);
				`CRNOR:		bus[instr[13:8]] <= ~(a[instr[19:14]] | a[instr[25:20]]);
				`CRXNOR:	bus[instr[13:8]] <= ~(a[instr[19:14]] ^ a[instr[25:20]]);
				`CRORC:		bus[instr[13:8]] <=   a[instr[19:14]] | ~a[instr[25:20]];
				default:	bus <= {32{4'hC}};
				endcase
			end
  	default:	bus <= {32{4'hC}};
  	endcase
  default:    bus <= {32{4'hC}};
  endcase
end

endmodule

