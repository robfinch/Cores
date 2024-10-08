// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  Parallel transfer interface
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
module pti(rst_i, clk_i, rxf_ni, txe_ni, rd_no, wr_no, siwu_no, oe_no, dat_i, dat_o,
	cs_i, wb_clk_i, wb_cyc_i, wb_stb_i, wb_ack_o, wb_we_i, wb_adr_i, wb_dat_i, wb_dat_o);
input rst_i;
input clk_i;				// 60 MHz clock
input rxf_ni;				// data available to read
input txe_ni;				// data can be written to fifo
output reg rd_no;
output reg wr_no;
output siwu_no;
output reg oe_no;
input [7:0] dat_i;
output [7:0] dat_o;
input cs_i;
input wb_clk_i;
input wb_cyc_i;
input wb_stb_i;
output reg wb_ack_o;
input wb_we_i;
input [31:0] wb_adr_i;
input [63:0] wb_dat_i;
output reg [63:0] wb_dat_o;

parameter IDLE = 3'd0;
parameter RD_XFIFO = 3'd1;
parameter WR_IFIFO = 3'd2;
parameter OE_ON = 3'd3;
parameter RD_IFIFO = 3'd4;

assign siwu_no = 1'b1;
reg if_wr, if_rd;
reg of_wr, of_rd;
wire if_full, of_full;
wire [9:0] of_rd_data_count;
wire [7:0] if_rd_data_count;
wire if_almost_full, of_almost_full;
wire [63:0] if_dat_o;

FT64_pti_ififo uif0
(
  .rst(rst_i),
  .wr_clk(clk_i),
  .rd_clk(wb_clk_i),
  .din(dat_i),
  .wr_en(if_wr),
  .rd_en(if_rd),
  .dout(if_dat_o),
  .full(),
  .almost_full(if_almost_full),
  .empty(),
  .almost_empty(),
  .valid(),
  .rd_data_count(if_rd_data_count),
  .wr_rst_busy(),
  .rd_rst_busy()
);

FT64_pti_ofifo uof0 (
  .rst(rst_i),
  .wr_clk(wb_clk_i),
  .rd_clk(clk_i),
  .din(wb_dat_i),
  .wr_en(of_wr),
  .rd_en(of_rd),
  .dout(dat_o),
  .full(),
  .almost_full(of_almost_full),
  .empty(),
  .almost_empty(),
  .valid(),
  .rd_data_count(of_rd_data_count),
  .wr_data_count(),
  .wr_rst_busy(),
  .rd_rst_busy()
);

reg [2:0] x_state;
always @(posedge clk_i)
if (rst_i) begin
	x_state <= IDLE;
	oe_no <= 1'b1;
	rd_no <= 1'b1;
	wr_no <= 1'b1;
	if_wr <= 1'b0;
	of_rd <= 1'b0;
end
else begin
	rd_no <= 1'b1;
	if_wr <= 1'b0;
	wr_no <= 1'b1;
	of_rd <= 1'b0;
	case(x_state)
	IDLE:
		if (rxf_ni==1'b0 && !if_almost_full) begin
			oe_no <= 1'b0;
			x_state <= RD_XFIFO;
		end
		else if (txe_ni==1'b0) begin
			if (of_rd_data_count > 1'b0) begin
				wr_no <= 1'b0;
				x_state <= RD_IFIFO;
			end
		end
	RD_XFIFO:
		begin
			rd_no <= 1'b0;
			x_state <= WR_IFIFO;
		end
	WR_IFIFO:
		begin
			if_wr <= 1'b1;
			x_state <= OE_ON;	
		end
	OE_ON:
		begin
			oe_no <= 1'b1;
			x_state <= IDLE;
		end
	RD_IFIFO:
		begin
			of_rd <= 1'b1;
			x_state <= IDLE;
		end
	default:
		x_state <= IDLE;
	endcase
end

reg wr_done, rd_done;

always @(posedge wb_clk_i)
if (rst_i) begin
	of_wr <= 1'b0;
	if_rd <= 1'b0;
	wr_done <= 1'b0;
	rd_done <= 1'b0;
	wb_ack_o <= 1'b0;
end
else begin
	of_wr <= 1'b0;
	if_rd <= 1'b0;
	if (cs_i & wb_cyc_i & wb_stb_i) begin
		if (wb_we_i && !wr_done) begin
			if (!of_almost_full) begin
				of_wr <= 1'b1;
				wr_done <= 1'b1;
				wb_ack_o <= 1'b1;
			end
		end
		if (!wb_we_i && wb_adr_i[4:3]==2'b10 && !rd_done) begin
			if_rd <= 1'b1;
			rd_done <= 1'b1;
			wb_ack_o <= 1'b1;
		end
		if (!wb_we_i && wb_adr_i[4:3]==2'b01)
			wb_ack_o <= 1'b1;
		if (!wb_we_i && wb_adr_i[4:3]==2'b00)
			wb_ack_o <= 1'b1;
	end
	else begin
		wb_ack_o <= 1'b0;
		wr_done <= 1'b0;
		rd_done <= 1'b0;
	end
end

always @(posedge wb_clk_i)
case(wb_adr_i[4:3])
2'b01:	wb_dat_o <= if_rd_data_count;
default:	wb_dat_o <= if_dat_o;
endcase

endmodule
