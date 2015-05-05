// ============================================================================
//        __
//   \\__/ o\    (C) 2015  Robert Finch, Stratford
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
//	Verilog 1995
//
// ref: XC7a100t-1CSG324
// ============================================================================
//
module gfx_wbm_read (clk_i, rst_i,
  cyc_o, stb_o, cti_o, bte_o, we_o, sel_o, adr_o, ack_i, err_i, dat_i,
  m0_read_request_i, m0_adr_i, m0_ack_o, m0_nack_i, m0_dat_o,
  m1_read_request_i, m1_adr_i, m1_ack_o, m1_nack_i, m1_dat_o,
  m2_read_request_i, m2_adr_i, m2_ack_o, m2_nack_i, m2_dat_o,
  writer_match_i, writer_dat_i
  );

// wishbone signals
input             clk_i;    // master clock input
input             rst_i;    // asynchronous active high reset
output reg        cyc_o;    // cycle output
output            stb_o;    // strobe ouput
output [ 2:0]     cti_o;    // cycle type id
output [ 1:0]     bte_o;    // burst type extension
output            we_o;     // write enable output
output [15:0]     sel_o;
output reg [31:0] adr_o;    // address output
input             ack_i;    // wishbone cycle acknowledge
input             err_i;    // wishbone cycle error
input [127:0]     dat_i;    // wishbone data in

input m0_read_request_i;
input [31:0] m0_adr_i;
output reg m0_ack_o;
input m0_nack_i;
output reg [127:0] m0_dat_o;

input m1_read_request_i;
input [31:0] m1_adr_i;
output reg m1_ack_o;
input m1_nack_i;
output reg [127:0] m1_dat_o;

input m2_read_request_i;
input [31:0] m2_adr_i;
output reg m2_ack_o;
input m2_nack_i;
output reg [127:0] m2_dat_o;

input writer_match_i;
input [127:0] writer_dat_i;

parameter IDLE = 3'd1;
parameter MATCH = 3'd2;
parameter ACK = 3'd3;
parameter NACK = 3'd4;
parameter TEST_MATCH = 3'd5;
//
// variable declarations
//
reg [2:0] state;

//
// module body
//

// This interface is read only
assign we_o   = 1'b0;
assign sel_o  = 16'hFFFF;
assign stb_o  = 1'b1;
assign bte_o  = 2'b00;
assign cti_o  = 3'b000;

reg [1:0] master_sel;

always @(posedge clk_i)
if (rst_i) begin
	cyc_o <= 1'b0;
	adr_o <= 32'h00000000;
	m0_ack_o <= 1'b0;
	m1_ack_o <= 1'b0;
	m2_ack_o <= 1'b0;
	state <= IDLE;
end
else
	begin
    case(state)
	IDLE:
		if (m2_read_request_i) begin
			master_sel <= 2'd2;
			adr_o <= m2_adr_i;
			state <= TEST_MATCH;
		end
		else if (m1_read_request_i) begin
			master_sel <= 2'd1;
			adr_o <= m1_adr_i;
			state <= TEST_MATCH;
		end
		else if (m0_read_request_i) begin
			master_sel <= 2'd0;
			adr_o <= m0_adr_i;
			state <= TEST_MATCH;
		end
	TEST_MATCH:
		if (writer_match_i)
			state <= MATCH;
		else begin
			cyc_o <= 1'b1;
			state <= ACK;
		end
	MATCH:
		begin
			case(master_sel)
			2'd0:	begin m0_ack_o <= 1'b1; m0_dat_o <= writer_dat_i; end
			2'd1:	begin m1_ack_o <= 1'b1; m1_dat_o <= writer_dat_i; end
			2'd2:	begin m2_ack_o <= 1'b1; m2_dat_o <= writer_dat_i; end
			endcase
			state <= NACK;
		end
	ACK:
		if(ack_i|err_i) begin
			cyc_o    <= 1'b0;
			case(master_sel)
			2'd0:	begin m0_ack_o <= 1'b1; m0_dat_o <= dat_i; end
			2'd1:	begin m1_ack_o <= 1'b1; m1_dat_o <= dat_i; end
			2'd2:	begin m2_ack_o <= 1'b1; m2_dat_o <= dat_i; end
			endcase
			state <= NACK;
		end
	NACK:
		if (m0_nack_i|m1_nack_i|m2_nack_i) begin
		    m0_ack_o <= 1'b0;
			m1_ack_o <= 1'b0;
			m2_ack_o <= 1'b0;
			state <= IDLE;
		end
	default:
		begin
			cyc_o <= 1'b0;
			state <= IDLE;
		end
	endcase
end

endmodule
