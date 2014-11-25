// ============================================================================
// wb_task.v
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
//       ||
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
task wb_burst;
input [5:0] len;
input [31:0] adr;
begin
	bte_o <= 2'b00;
	cti_o <= 3'b001;
	bl_o <= len;
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	sel_o <= 4'hF;
	adr_o <= adr;
end
endtask

task wb_read;
input [31:0] adr;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	sel_o <= 4'hF;
	adr_o <= adr;
end
endtask

task wb_write;
input byt;
input chr;
input [31:0] dat;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b1;
	if (byt) begin
		case(wadr[1:0])
		2'd0:	sel_o <= 4'b0001;
		2'd1:	sel_o <= 4'b0010;
		2'd2:	sel_o <= 4'b0100;
		2'd3:	sel_o <= 4'b1000;
		endcase
		dat_o <= {4{dat[7:0]}};
	end
	else if (chr) begin
		case(wadr[1])
		1'd0:	sel_o <= 4'b0011;
		1'd1:	sel_o <= 4'b1100;
		endcase
		dat_o <= {2{dat[15:0]}};
	end
	else begin
		sel_o <= 4'hf;
		dat_o <= dat;
	end
	adr_o <= wadr;
end
endtask	

task wb_nack;
begin
	cti_o <= 3'b000;
	bl_o <= 6'd0;
	cyc_o <= 1'b0;
	stb_o <= 1'b0;
	sel_o <= 4'h0;
	we_o <= 1'b0;
	adr_o <= 32'd0;
	dat_o <= 32'd0;
end
endtask
