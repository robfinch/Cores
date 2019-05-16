// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_pti2.v
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
module FT64_pti2(rst_i, clk_i, rxf_ni, txe_ni, spien_i, rd_no, wr_no, siwu_no, oe_no, dat_io,
	cs_i, wb_clk_i, wb_cyc_i, wb_stb_i, wb_ack_o, wb_we_i, wb_adr_i, wb_dat_i, wb_dat_o);
input rst_i;
input clk_i;				// 60 MHz clock
input rxf_ni;				// data available to read (read full)
input txe_ni;				// data can be written to fifo (transmit empty)
input spien_i;
output rd_no;
output wr_no;
output siwu_no;
output oe_no;
inout [7:0] dat_io;
input cs_i;
input wb_clk_i;
input wb_cyc_i;
input wb_stb_i;
output reg wb_ack_o;
input wb_we_i;
input [3:0] wb_adr_i;
input [7:0] wb_dat_i;
output reg [7:0] wb_dat_o;

wire [11:0] of_wr_count;
wire [11:0] if_rd_count;
reg wr_done, rd_done;
wire [7:0] if_dat_o;
reg [7:0] rdl, rdh;	// read data count hold registers
reg [7:0] wcl, wch;	// write count low and high
reg of_wr, if_rd;
reg rdd1, rdd2, rdd3;			// read delays
wire of_almost_full, if_almost_empty;
reg swrst;
reg [7:0] rstffs;
reg [7:0] dil;				// data latch
reg [7:0] dol;
reg loopback;
wire of_full, if_empty;
wire rwen = !of_full && !if_empty;

dpti_ctrl udpti1
(
	.rst(rstffs[7]),	// Asynchronously resets the entire component. Must be held high for at least 100ns, or 6 clock cycles of the slowest fifo clock if that is longer

	// Output fifo signals
	.wr_clk(wb_clk_i),
	.wr_en(loopback ? rwen : of_wr),
	.wr_full(of_full),
	.wr_afull(of_almost_full),
	.wr_err(),
	.wr_count(of_wr_count),
	.wr_di(loopback ? if_dat_o : dol),

	// Input fifo signals
	.rd_clk(wb_clk_i),
	.rd_en(loopback ? rwen : if_rd),
	.rd_empty(if_empty),
	.rd_aempty(if_almost_empty),
	.rd_err(),
	.rd_count(if_rd_count),
	.rd_do(if_dat_o),

	// Port signals
  .prog_clko(clk_i),
  .prog_rxen(rxf_ni),
  .prog_txen(txe_ni),
  .prog_spien(spien_i),
  .prog_rdn(rd_no),
  .prog_wrn(wr_no),
  .prog_oen(oe_no),
  .prog_siwun(siwu_no),
  .prog_d(dat_io)
);

always @(posedge wb_clk_i)
if (rst_i)
	rstffs <= 8'hFF;
else begin
	if (swrst)
		rstffs <= 8'hFF;
	else
		rstffs <= {rstffs[6:0],1'b0};
end
always @(posedge wb_clk_i)
	if (if_rd)
		dil <= if_dat_o;

always @(posedge wb_clk_i)
if (rst_i) begin
	of_wr <= 1'b0;
	if_rd <= 1'b0;
	wr_done <= 1'b0;
	rd_done <= 1'b0;
	wb_ack_o <= 1'b0;
	swrst <= 1'b1;
	rdd1 <= 1'b0;
	rdd2 <= 1'b0;
	rdl <= 8'h00;
	rdh <= 8'h00;
	wcl <= 8'h00;
	wch <= 8'h00;
	loopback <= 1'b1;
end
else begin
	of_wr <= 1'b0;
	if_rd <= 1'b0;
	swrst <= 1'b0;
	if (cs_i & wb_cyc_i & wb_stb_i) begin
		if (wb_we_i) begin
			case(wb_adr_i[2:0])
			// To do a write, wait until the fifo is no longer full. The purpose
			// of the wr_done flag is to limit the of_wr signal to a single clock
			// cycle pulse.
			3'd0:
				if (!wr_done) begin
					if (!of_full) begin
						of_wr <= 1'b1;
						dol <= wb_dat_i;
						wr_done <= 1'b1;
						wb_ack_o <= 1'b1;
					end
				end
			// The following reg is setup so that writing a zero to the register
			// both disables loopback mode and resets the fifo.
			3'd1:
				begin
					swrst <= ~wb_dat_i[7];
					loopback <= wb_dat_i[0];
					wb_ack_o <= 1'b1;
				end
			3'd2:
				begin
					wb_ack_o <= 1'b1;
					rdl <= if_rd_count[7:0];
					rdh <= {if_empty,if_almost_empty,2'b00,if_rd_count[11:8]};
					wcl <= of_wr_count[7:0];
					wch <= {of_full,of_almost_full,2'b00,of_wr_count[11:8]};
				end
			// Like the wr_done signal, limit the if_rd to a single clock pulse.
			3'd6:
				if (!if_empty) begin
					if (!rd_done) begin
						if_rd <= 1'b1;
						rd_done <= 1'b1;
						wb_ack_o <= 1'b1;
					end
				end
				else
					wb_ack_o <= 1'b1;
			
			default:	
				// So things don't hang on write to unsupported reg.
				wb_ack_o <= 1'b1;
			endcase
		end
		// Any read results in an ack. Give data time to be clocked to the wb
		// output. 
		else begin
			rdd1 <= 1'b1;
			rdd2 <= rdd1;
			rdd3 <= rdd2;
			wb_ack_o <= rdd3;
		end
	end
	else begin
		wb_ack_o <= 1'b0;
		wr_done <= 1'b0;
		rd_done <= 1'b0;
		rdd1 <= 1'b0;
		rdd2 <= 1'b0;
		rdd3 <= 1'b0;
	end
end

always @(posedge wb_clk_i)
case(wb_adr_i[2:0])
3'd0:		wb_dat_o <= dil;
3'd2:		wb_dat_o <= rdl;
3'd3:		wb_dat_o <= rdh;
3'd4:		wb_dat_o <= wcl;
3'd5:		wb_dat_o <= wch;
default:	wb_dat_o <= dil;
endcase

endmodule
