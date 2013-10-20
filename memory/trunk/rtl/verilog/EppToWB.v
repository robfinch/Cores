`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2013  Robert Finch, Stratford
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
//  EppToWB 
//  - Interface EPP port to WISHBONE bus
//
//	Verilog 1995
//  
// ============================================================================
//
module EppToWB(rst_i, clk_i, eppWr, eppRd, eppAdr, eppDati, eppDato, eppHSReq, eppDone, eppStart,
	cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o
);
parameter IDLE = 2'd1;
parameter WB_NACK = 2'd2;
parameter EPP_NACK = 2'd3;

input rst_i;
input clk_i;
// Epp interface
input eppWr;
input eppRd;
input [7:0] eppAdr;
input [7:0] eppDati;
output reg [7:0] eppDato;
output eppHSReq;
output eppDone;
input eppStart;

output reg cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [3:0] sel_o;
output reg [31:0] adr_o;
input [31:0] dat_i;
output reg [31:0] dat_o;

reg [1:0] state;
reg [7:0] ectl;
reg [31:0] eadr;
reg [31:0] edat;
reg [31:0] edato;
reg eppDone1;
assign eppHSReq = eppAdr==8'h0E || eppAdr==8'h0F;
wire eppCycle = (eppAdr==8'h0E || eppAdr==8'h0F) && eppStart;
wire eppDudCycle = (!ectl[0] ? eadr[1:0]!=2'b11 : eadr[1:0]!=2'b00);
assign eppDone = eppDone1 & eppCycle;

always @(posedge clk_i)
if (rst_i) begin
	state <= IDLE;
	wb_nack();
	eppDone1 <= 1'b0;
end
else begin
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// Epp control register access
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	//
	if (eppWr) begin
		case(eppAdr)
		8'h08:	ectl <= eppDati;
		8'h09:	eadr[7:0] <= eppDati;
		8'h0A:	eadr[15:8] <= eppDati;
		8'h0B:	eadr[23:16] <= eppDati;
		8'h0C:	eadr[31:24] <= eppDati;
		8'h0D:	;
		8'h0E,8'h0F:
			case(eadr[1:0])
			2'b00:	edat[7:0] <= eppDati;
			2'b01:	edat[15:8] <= eppDati;
			2'b10:	edat[23:16] <= eppDati;
			2'b11:	edat[31:24] <= eppDati;
			endcase
		endcase
	end

	case(state)
	IDLE:	
		if (eppCycle & eppDudCycle) begin
			state <= EPP_NACK;
			eppDone1 <= 1'b1;
		end
		else if (eppCycle) begin
			eppDone1 <= 1'b0;
			if (ectl[0]) begin
				wb_read({2'b00,eadr[29:2],2'b00});
				state <= WB_NACK;
			end
			else begin
				wb_write({2'b00,eadr[29:2],2'b00},edat);
				state <= WB_NACK;
			end
		end
	WB_NACK:
		if (ack_i) begin
			wb_nack();
			eppDone1 <= 1'b1;
			state <= EPP_NACK;
		end
	EPP_NACK:
		if (eppCycle==1'b0) begin
			state <= IDLE;
			eppDone1 <= 1'b0;
			eadr <= eadr + 32'd1;
		end
	endcase
end


always @(eppAdr,ectl,eadr,edato)
begin
	case(eppAdr)
	8'h08:	eppDato <= ectl;
	8'h09:	eppDato <= eadr[ 7: 0];
	8'h0A:	eppDato <= eadr[15: 8];
	8'h0B:	eppDato <= eadr[23:16];
	8'h0C:	eppDato <= eadr[31:24];
	8'h0D:	eppDato <= 8'hFF;
	8'h0E,8'h0F:
		case(eadr[1:0])
		2'b00:	eppDato <= edato[7:0];
		2'b01:	eppDato <= edato[15:8];
		2'b10:	eppDato <= edato[23:16];
		2'b11:	eppDato <= edato[31:24];
		endcase
	default:	eppDato <= 8'h00;
	endcase
end

task wb_read;
input [31:0] adr;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	sel_o <= 4'hF;
	adr_o <= {2'b00,adr[29:2],2'b00};
end
endtask

task wb_write;
input [31:0] adr;
input [31:0] dat;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b1;
	sel_o <= 4'hF;
	adr_o <= {2'b00,adr[29:2],2'b00};
	dat_o <= dat;
end
endtask

task wb_nack;
begin
	cyc_o <= 1'b0;
	stb_o <= 1'b0;
	we_o <= 1'b0;
	sel_o <= 4'h0;
	adr_o <= 32'h0;
	dat_o <= 32'd0;
	edato <= dat_i;
end
endtask

endmodule
