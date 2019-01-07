// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	ft64v8d_brk.v
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
BRK1:
	begin
		irq_stack_i[ 63:  0] <= status;
		irq_stack_i[127: 64] <= cc;
		irq_stack_i[191:128] <= pc;
		irq_stack_i[255:192] <= prog_base;
		irq_stack_i[319:256] <= sp;
		irq_stack_i[383:320] <= data_base;
		irq_stack_wr <= 1'b1;
		irq_sp <= irq_sp - 4'd1;
		status[`STATUS_IM] <= 3'd7;
		status[`STATUS_OM] <= `OM_MACHINE;
		cti_o <= `CTI_VEC_FETCH;
		cyc_o <= `HIGH;
		stb_o <= `HIGH;
		lock_o <= `HIGH;
		sel_o <= 8'hFF;
		adr_o <= {bat_o,13'd0} + {cause,5'd0};
		goto (BRK2);
	end
BRK2:
	if (ack_i) begin
		stb_o <= `LOW;
		pc <= dat_i;
		goto (BRK3);
	end
BRK3:
	if (~ack_i) begin
		stb_o <= `HIGH;
		adr_o <= {adr_o[63:5],5'd8};
		goto (BRK4);
	end
BRK4:
	if (ack_i) begin
		stb_o <= `LOW;
		prog_base <= dat_i;
		goto (BRK5);
	end
BRK5:
	if (~ack_i) begin
		stb_o <= `HIGH;
		adr_o <= {adr_o[63:5],5'd16};
		goto (BRK6);
	end
BRK6:
	if (ack_i) begin
		stb_o <= `LOW;
		sp <= dat_i;
		goto (BRK7);
	end
BRK7:
	if (~ack_i) begin
		stb_o <= `HIGH;
		adr_o <= {adr_o[63:5],5'd24};
		goto (BRK8);
	end
BRK8:
	if (ack_i) begin
		cti_o <= `CTI_CLASSIC;
		cyc_o <= `LOW;
		stb_o <= `LOW;
		lock_o <= `LOW;
		data_base <= dat_i;
		goto (IFETCH);
	end
