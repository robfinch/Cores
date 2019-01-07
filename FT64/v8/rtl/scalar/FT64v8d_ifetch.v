// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64v8d_ifetch.v
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
//
// ============================================================================
//
IFETCH:
	begin
		$display("\r\n******************************************************");
		$display("time: %d", $time);
		$display("PB:PC %h:%h (%h)", pb, pc, pbpc);
		$display("SP: %h", sp);
		if (pe_nmi) begin
			pe_nmi <= 1'b0;
			cause <= 9'd510;
			goto (BRK1);
		end
		else if (irq_i > im) begin
			cause <= cause_i;
			goto (BRK1);
		end
		else if (ir[7:0]==`I_WAI) begin
			cti_o <= `CTI_WAIT;
		end
		else begin
			memsize <= dword;
			su <= 1'b1;		// signed loads
			ir <= insn;
			Ra <= insn[17:13];
			Rt <= insn[12:8];
			Rb <= insn[22:18];
			Rc <= insn[27:23];
			Sc <= 3'd0;
			bat_ndx <= insn[47:36];
			goto(DECODE);
		end
	end