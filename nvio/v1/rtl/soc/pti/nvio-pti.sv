// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	nvio-pti.sv
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
//
// The core uses a 128-bit bus master for performance reasons. This helps
// reduce the rate at which bus master cycles are required. It's 1/16 the
// rate that data is input or output to the fifo's.
// ============================================================================
//
`define SIM		1'b1

module nvio_pti(rst_i,
	clk_i, rxf_ni, txe_ni, spien_i, rd_no, wr_no, siwu_no, oe_no, dat_io,
	cs_i, w_clk_i, sirq_o, dirq_o,
	s_cyc_i, s_stb_i, s_ack_o, s_we_i, s_sel_i, s_adr_i, s_dat_i, s_dat_o,
	m_cyc_o, m_stb_o, m_ack_i, m_we_o, m_sel_o, m_adr_o, m_dat_i, m_dat_o);
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
input w_clk_i;
output sirq_o;
output dirq_o;
input s_cyc_i;
input s_stb_i;
output s_ack_o;
input s_we_i;
input [7:0] s_sel_i;
input [7:0] s_adr_i;
input [63:0] s_dat_i;
output reg [63:0] s_dat_o;
output reg m_cyc_o;
output reg m_stb_o;
input m_ack_i;
output reg m_we_o;
output reg [15:0] m_sel_o;
output reg [31:0] m_adr_o;
input [127:0] m_dat_i;
output reg [127:0] m_dat_o;

wire cs = cs_i & s_cyc_i & s_stb_i;
assign s_ack_o = cs;

reg [31:0] dstadr, srcadr;
reg [31:0] dstcnt, srccnt;
reg [31:0] dstthres, srcthres;
reg [7:0] rdbuf [0:31];
reg [127:0] wrbuf [0:1];
reg [4:0] rdbufndx, prdbufndx;
reg [4:0] wrbufndx;
reg rmrc, rmwc;
reg [1:0] wrDataValid;
reg rdStream, wrStream;
reg sirq, dirq;
reg sirq_en, dirq_en;

wire [11:0] of_wr_count;
wire [11:0] if_rd_count;
wire [7:0] if_dat_o;
reg of_wr, if_rd;
wire of_almost_full, if_almost_empty;
reg swrst;
reg [7:0] rstffs;
reg [7:0] dil;				// data latch
reg [7:0] dol;
reg loopback;
wire of_full, if_empty;
wire rwen = !of_full && !if_empty;

parameter HIGH = 1'b1;
parameter LOW = 1'b0;

wire clk;
BUFH ucb1 (.I(w_clk_i), .O(clk));

dpti_ctrl udpti1
(
	.rst(rstffs[7]),	// Asynchronously resets the entire component. Must be held high for at least 100ns, or 6 clock cycles of the slowest fifo clock if that is longer

	// Output fifo signals
	.wr_clk(clk),
	.wr_en(loopback ? rwen : of_wr),
	.wr_full(of_full),
	.wr_afull(of_almost_full),
	.wr_err(),
	.wr_count(of_wr_count),
	.wr_di(loopback ? if_dat_o : dol),

	// Input fifo signals
	.rd_clk(clk),
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

// A single clock cycle pulse is generated to read the fifo if it isn't empty
// and read streaming is enabled.
always @(posedge clk)
begin
	if_rd <= 1'b0;
	if (!if_empty && rdStream)
		if_rd <= 1'b1;
end

always @(posedge clk)
	if (if_rd)
		rdbuf[rdbufndx] <= if_dat_o;

// Read buffer index just increments with every input fifo read.
always @(posedge clk)
if (rst_i|rstffs)
	rdbufndx <= 1'd0;
else begin
	if (if_rd)
		rdbufndx <= rdbufndx + 2'd1;
end

// Track previous read buffer index so we can tell when the read buffer input
// passes the halfway mark. Once one half of the buffer is full it can be
// written out to memory while the other half is loading.
always @(posedge clk)
	prdbufndx <= rdbufndx;

// Detect when to run bus master cycles. For the read buffer this occurs when
// input reaches the halfway mark. For write cycles this occurs whenever there
// is an empty buffer.
wire runMasterRdCycle = wrDataValid != 2'b11 && wrStream;
wire runMasterWrCycle = (rdbufndx[3:0]==4'd0 && prdbufndx[3:0]==4'hF) && rdStream;

// rmrc, rmwc are flags indicating the need to run a bus master cycle. It might not
// be possible to run the cycle immediately as determined by the combo logic above,
// so we need to record the occurance of the bus cycle demand.
always @(posedge clk)
if (rst_i|rstffs)
	rmrc <= 1'b0;
else begin
	if (runMasterRdCycle)
		rmrc <= 1'b1;
	if (m_cyc_o & m_ack_i & ~m_we_o)
		rmrc <= 1'b0;
end

always @(posedge clk)
if (rst_i|rstffs)
	rmwc <= 1'b0;
else begin
	if (runMasterWrCycle)
		rmwc <= 1'b1;
	if (m_cyc_o & m_ack_i & m_we_o)
		rmwc <= 1'b0;
end

// ----------------------------------------------------------------------------
// WISHBONE bus master section.
// ----------------------------------------------------------------------------

// Get the write data in parallel from the read buffer. Since it's the only
// data being output during a master cycle it can be connected to the data
// output directly.
always @(posedge clk)
if (rmwc)
begin
	m_dat_o[ 7: 0] <= rdbuf[{~rdbufndx[4],4'h0}];
	m_dat_o[15: 8] <= rdbuf[{~rdbufndx[4],4'h1}];
	m_dat_o[23:16] <= rdbuf[{~rdbufndx[4],4'h2}];
	m_dat_o[31:24] <= rdbuf[{~rdbufndx[4],4'h3}];
	m_dat_o[39:32] <= rdbuf[{~rdbufndx[4],4'h4}];
	m_dat_o[47:40] <= rdbuf[{~rdbufndx[4],4'h5}];
	m_dat_o[55:48] <= rdbuf[{~rdbufndx[4],4'h6}];
	m_dat_o[63:56] <= rdbuf[{~rdbufndx[4],4'h7}];
	m_dat_o[71:64] <= rdbuf[{~rdbufndx[4],4'h8}];
	m_dat_o[79:72] <= rdbuf[{~rdbufndx[4],4'h9}];
	m_dat_o[87:80] <= rdbuf[{~rdbufndx[4],4'hA}];
	m_dat_o[95:88] <= rdbuf[{~rdbufndx[4],4'hB}];
	m_dat_o[103:96] <= rdbuf[{~rdbufndx[4],4'hC}];
	m_dat_o[111:104] <= rdbuf[{~rdbufndx[4],4'hD}];
	m_dat_o[119:112] <= rdbuf[{~rdbufndx[4],4'hE}];
	m_dat_o[127:120] <= rdbuf[{~rdbufndx[4],4'hF}];
end

// Load the fifo output buffer with incoming data from a master read cycle.
always @(posedge clk)
`ifdef SIM
if (rst_i|rstffs) begin
	wrbuf[0] <= 1'd0;
	wrbuf[1] <= 1'd0;
end
else
`endif
begin
	if (rmrc) begin
		if (m_cyc_o & m_ack_i & ~m_we_o)
			wrbuf[wrdv] <= m_dat_i;
	end
end

// Bus master controls.
always @(posedge clk)
if (rst_i)
	m_cyc_o <= LOW;
else begin
	if (rmrc|rmwc)
		m_cyc_o <= HIGH;
	if (m_cyc_o & m_ack_i)
		m_cyc_o <= LOW;
end

// This signal is a clone of the cyc_o signal. The bus spec says it must be
// present. But in this case it isn't different from the cyc_o signal.
always @*
	m_stb_o <= m_cyc_o;
	
always @(posedge clk)
if (rst_i)
	m_we_o <= LOW;
else begin
	if (rmrc|rmwc)
		m_we_o <= rmwc;
	if (m_stb_o & m_ack_i)
		m_we_o <= LOW;
end

// This signal doesn't really need to be registered since only 128-bit cycles
// are taking place.	
always @*
	m_sel_o <= 16'hFFFF;
	
always @(posedge clk)
if (rst_i)
	m_adr_o <= 32'h0000;
else begin
	if (rmrc|rmwc)
		m_adr_o <= rmwc ? dstadr : srcadr;
	if (m_stb_o & m_ack_i)
		m_adr_o <= 32'h0000;
end
	
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

wire pe_wack;

// We need to detect an edge on the ack_i cycle so the address doesn't
// increment more than once. The bus spec says that the ack_i may be more than
// one clock wide, the master doesn't have to release the strobe line until
// it's ready to do so, which may be multiple clocks after an ack.

edge_det ued1 (
	.rst(rst_i),
	.clk(clk),
	.ce(1'b1),
	.i(m_we_o & m_stb_o & m_ack_i),
	.pe(pe_wack),
	.ne(),
	.ee()
);

// Bus master destination address generation. Increment on completion of
// write cycle. The address generator does not automatically reload at the
// end of a transfer. It must be reset programatically by the cpu.
always @(posedge clk)
if (rst_i)
	dstadr <= 32'h0;
else begin
	if (pe_wack && dstcnt != 1'd0)
		dstadr <= dstadr + 6'd16;
	if (cs && s_we_i && s_adr_i[6:4]==3'd0 && &s_sel_i[3:0]) begin
		dstadr <= s_dat_i;
		dstadr[3:0] <= 4'h0;
	end
end

// Transfer count for bus master write cycles.
always @(posedge clk)
if (rst_i)
	dstcnt <= 32'hfff;
else begin
	if (pe_wack && dstcnt != 1'd0)
		dstcnt <= dstcnt - 6'd16;
	if (cs && s_we_i && s_adr_i[6:4]==3'd1 && &s_sel_i[3:0]) begin
		dstcnt <= s_dat_i;
		dstcnt[3:0] <= 4'h0;
	end
end

// Read streaming active bit.
// Read stream automatically shuts off once the count has expired.
always @(posedge clk)
if (rst_i)
	rdStream <= 1'b0;
else begin
	if (dstcnt==1'd0)
		rdStream <= 1'b0;
	if (cs && s_we_i && s_adr_i[6:4]==3'd4 && s_sel_i[0])
		rdStream <= s_dat_i[0];
end

// Write streaming active bit. Controlled by a bus master (the cpu).
// Does not shut off automatically.
always @(posedge clk)
if (rst_i)
	wrStream <= 1'b0;
else begin
	if (cs && s_we_i && s_adr_i[6:4]==3'd4 && s_sel_i[1])
		wrStream <= s_dat_i[8];
end

// Once again we need to detect when the ack signal transitions, only a
// pulse is required.
wire pe_rack;
edge_det ued2 (
	.rst(rst_i),
	.clk(clk),
	.ce(1'b1),
	.i(~m_we_o & m_stb_o & m_ack_i),
	.pe(pe_rack),
	.ne(),
	.ee()
);

// Bus master source address generation. Used for performing bus master read
// cycles. The source address does not automatically reset, it must be 
// controlled by the cpu.
always @(posedge clk)
if (rst_i)
	srcadr <= 32'h0;
else begin
	if (pe_rack && srccnt != 1'd0)
		srcadr <= srcadr + 6'd16;
	if (cs && s_we_i && s_adr_i[6:4]==2'd2 && &s_sel_i[3:0]) begin
		srcadr <= s_dat_i[31:0];
		srcadr[3:0] <= 4'h0;
	end
end

// Bus master source counter.
always @(posedge clk)
if (rst_i)
	srccnt <= 32'hfff;
else begin
	if (pe_rack && srccnt != 1'd0)
		srccnt <= srccnt - 6'd16;
	if (cs && s_we_i && s_adr_i[6:4]==3'd3 && &s_sel_i[3:0]) begin
		srccnt <= s_dat_i;
		srccnt[3:0] <= 4'h0;
	end
end

// Load up the data output latch.
always @(posedge clk)
if (!of_almost_full) begin
	if (wrDataValid[wrbufndx[4]])
		case(wrbufndx[3:0])
		4'h0:	dol <= wrbuf[wrbufndx[4]][ 7: 0];
		4'h1:	dol <= wrbuf[wrbufndx[4]][15: 8];
		4'h2:	dol <= wrbuf[wrbufndx[4]][23:16];
		4'h3:	dol <= wrbuf[wrbufndx[4]][31:24];
		4'h4:	dol <= wrbuf[wrbufndx[4]][39:32];
		4'h5:	dol <= wrbuf[wrbufndx[4]][47:40];
		4'h6:	dol <= wrbuf[wrbufndx[4]][55:48];
		4'h7:	dol <= wrbuf[wrbufndx[4]][63:56];
		4'h8:	dol <= wrbuf[wrbufndx[4]][71:64];
		4'h9:	dol <= wrbuf[wrbufndx[4]][79:72];
		4'hA:	dol <= wrbuf[wrbufndx[4]][87:80];
		4'hB:	dol <= wrbuf[wrbufndx[4]][95:88];
		4'hC:	dol <= wrbuf[wrbufndx[4]][103:96];
		4'hD:	dol <= wrbuf[wrbufndx[4]][111:104];
		4'hE:	dol <= wrbuf[wrbufndx[4]][119:112];
		4'hF:	dol <= wrbuf[wrbufndx[4]][127:120];
		endcase
end

// Output fifo write pulse.
always @(posedge clk)
begin
	of_wr <= 1'b0;
	if (!of_almost_full && wrStream) begin
		if (wrDataValid[wrbufndx[4]])
			of_wr <= 1'b1;
	end
end

// Output write buffer index.
always @(posedge clk)
if (rst_i|rstffs)
	wrbufndx <= 2'd0;
else begin
	if (!of_almost_full && wrStream) begin
		if (wrDataValid[wrbufndx[4]])
			wrbufndx <= wrbufndx + 2'd1;
	end
end

// Buffer select signal of output buffer.
reg wrdv;
always @(posedge clk)
if (rst_i|rstffs)
	wrdv <= 1'b0;
else begin
	if (pe_rack)
		wrdv <= ~wrdv;
end

// Data valid in output buffer signal. Reset to zero as the write buffer is
// emptied out. Set true when data from a bus master read cycle is available.
always @(posedge clk)
if (rst_i|rstffs)
	wrDataValid <= 2'b0;
else begin
	if (!of_almost_full && wrStream) begin
		if (wrDataValid[wrbufndx[4]]) begin
			if (wrbufndx[3:0]==4'hF)
				wrDataValid[wrbufndx[4]] <= 1'b0;
		end
	end
	if (pe_rack)
		wrDataValid[wrdv] <= 1'b1;
end

// Software reset control ffs. Setting a reset via software triggers a reset
// pulse that is at least six clock cycles long.
always @(posedge clk)
if (rst_i)
	rstffs <= 8'hFF;
else begin
	if (swrst)
		rstffs <= 8'hFF;
	else
		rstffs <= {rstffs[6:0],1'b0};
end

// Loopback control, for testing interface.
always @(posedge clk)
if (rst_i)
	loopback <= 1'b1;
else begin
	if (cs && s_we_i && s_adr_i[5:4]==2'd4 && s_sel_i[2])
		loopback <= s_dat_i[16];
end

// Software reset automatically resets.
always @(posedge clk)
if (rst_i)
	swrst <= 1'b1;
else begin
	swrst <= 1'b0;
	if (cs && s_we_i && s_adr_i[5:4]==2'd4 && s_sel_i[3])
		swrst <= s_dat_i[24];
end

// Transfer complete irq bits.
always @(posedge clk)
if (rst_i)
	sirq <= 1'b0;
else begin
	if (srccnt==srcthres)
		sirq <= 1'b1;
	if (cs && s_we_i && s_adr_i[6:4]==3'd4)
		sirq <= 1'b0;
end
assign sirq_o = sirq & sirq_en;

always @(posedge clk)
if (rst_i)
	dirq <= 1'b0;
else begin
	if (dstcnt==dstthres)
		dirq <= 1'b1;
	if (cs && s_we_i && s_adr_i[6:4]==3'd4)
		dirq <= 1'b0;
end
assign dirq_o = dirq & dirq_en;

always @(posedge clk)
if (rst_i) begin
	dstthres <= 1'd0;
	srcthres <= 1'd0;
end
else begin
	if (cs && s_we_i && s_adr_i[6:4]==3'd5) begin
		dstthres <= s_dat_i[63:32];
		srcthres <= s_dat_i[31: 0];
	end
end

always @(posedge clk)
if (rst_i) begin
	sirq_en <= 1'd0;
	dirq_en <= 1'd0;
end
else begin
	if (cs && s_we_i && s_adr_i[6:4]==3'd4) begin
		if (s_sel_i[4]) sirq_en <= s_dat_i[32];
		if (s_sel_i[5]) dirq_en <= s_dat_i[40];
	end
end

// Slave data output
always @(posedge clk)
if (rst_i)
	s_dat_o <= 1'd0;
else begin
	case(s_adr_i[6:4])
	3'd0:	s_dat_o <= dstadr;
	3'd1:	s_dat_o <= dstcnt;
	3'd2:	s_dat_o <= srcadr;
	3'd3:	s_dat_o <= srccnt;
	// Control reg
	3'd4:	s_dat_o <= {dirq_en,7'd0,sirq_en,15'd0,loopback,7'd0,wrStream,7'd0,rdStream};
	3'd5:	s_dat_o <= {dstthres,srcthres};
	// Status reg
	3'd7:	s_dat_o <= {of_full,of_almost_full,2'b00,of_wr_count[11:0],
										if_empty,if_almost_empty,2'b00,if_rd_count[11:0]};
	default:	s_dat_o <= 1'd0;
	endcase
end

endmodule
