// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// AudioController.v
// - audio interface circuit
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
`define TRUE	1'b1
`define FALSE 1'b0
`define HIGH	1'b1
`define LOW		1'b0
`define ABITS	31:0

module AudioController(rst_i,
	s_clk_i, s_cyc_i, s_stb_i, s_ack_o, s_we_i, s_sel_i, s_adr_i, s_dat_o, s_dat_i, s_cs_i, irq_o,
	m_clk_i, m_cyc_o, m_stb_o, m_ack_i, m_we_o, m_sel_o, m_adr_o, m_dat_i, m_dat_o,
	aud0_out, aud1_out, aud2_out, aud3_out, audi_in, record_i, playback_i
);
input rst_i;
input s_clk_i;
input s_cyc_i;
input s_stb_i;
output s_ack_o;
input s_we_i;
input [7:0] s_sel_i;
input [31:0] s_adr_i;
output reg [63:0] s_dat_o;
input [63:0] s_dat_i;
input s_cs_i;
output reg irq_o;
input m_clk_i;
output reg m_cyc_o;
output m_stb_o;
input m_ack_i;
output reg m_we_o;
output [1:0] m_sel_o;
output reg [31:0] m_adr_o;
input [15:0] m_dat_i;
output reg [15:0] m_dat_o;
output reg [15:0] aud0_out;
output reg [15:0] aud1_out;
output reg [15:0] aud2_out;
output reg [15:0] aud3_out;
input [15:0] audi_in;
input record_i;
input playback_i;

parameter ST_IDLE = 4'd0;
parameter ST_LATCH_DATA = 4'd1;
parameter ST_AUDI = 4'd3;
parameter ST_AUD0 = 4'd4;
parameter ST_AUD1 = 4'd5;
parameter ST_AUD2 = 4'd6;
parameter ST_AUD3 = 4'd7;
assign m_stb_o = m_cyc_o;
assign m_sel_o = 2'b11;

// Register inputs
reg cs;
reg we;
reg [7:0] sel;
reg [31:0] adr;
reg [63:0] dat;
always @(posedge s_clk_i)
	cs <= s_cs_i & s_cyc_i & s_stb_i;
always @(posedge s_clk_i)
	we <= s_we_i;
always @(posedge s_clk_i)
	sel <= s_sel_i;
always @(posedge s_clk_i)
	adr <= s_adr_i;
always @(posedge s_clk_i)
	dat <= s_dat_i;

ack_gen #(
	.READ_STAGES(2),
	.WRITE_STAGES(0),
	.REGISTER_OUTPUT(1)
) uag1
(
	.clk_i(s_clk_i),
	.ce_i(1'b1),
	.i(cs),
	.we_i(we),
	.o(s_ack_o)
);

reg [3:0] state;
reg [3:0] stkstate;
reg [15:0] latched_data;
reg [15:0] irq_enable;
reg [15:0] irq_status;

always @(posedge s_clk_i)
	irq_o <= |(irq_status & irq_enable);

//     i3210   31 i3210
// -t- rrrrr p mm eeeee
//  |    |   |  |   +--- channel enables
//  |    |   |  +------- mix channels 1 into 0, 3 into 2
//  |    |   +---------- input plot mode
//  |    +-------------- channel reset
//  +------------------- test mode
//
// The channel needs to be reset for use as this loads the working address
// register with the audio sample base address.
//
reg [31:0] aud_ctrl;
wire aud_mix1 = aud_ctrl[5];
wire aud_mix3 = aud_ctrl[6];
//
//           3210 3210
// ---- ---- -fff -aaa
//             |    +--- amplitude modulate next channel
//             +-------- frequency modulate next channel
//
reg [`ABITS] aud0_adr;
reg [23:0] aud0_length;
reg [23:0] aud0_half_length;
reg [19:0] aud0_period;
reg [15:0] aud0_volume;
reg [23:0] aud0_acnt;
reg [23:0] aud0_next_acnt;
reg signed [15:0] aud0_dat;
reg signed [15:0] aud0_dat2;		// double buffering
reg [`ABITS] aud1_adr;
reg [23:0] aud1_length;
reg [23:0] aud1_half_length;
reg [19:0] aud1_period;
reg [15:0] aud1_volume;
reg [23:0] aud1_acnt;
reg [23:0] aud1_next_acnt;
reg signed [15:0] aud1_dat;
reg signed [15:0] aud1_dat2;
reg [`ABITS] aud2_adr;
reg [23:0] aud2_length;
reg [23:0] aud2_half_length;
reg [19:0] aud2_period;
reg [15:0] aud2_volume;
reg [23:0] aud2_acnt;
reg [23:0] aud2_next_acnt;
reg signed [15:0] aud2_dat;
reg signed [15:0] aud2_dat2;
reg [`ABITS] aud3_adr;
reg [23:0] aud3_length;
reg [23:0] aud3_half_length;
reg [19:0] aud3_period;
reg [15:0] aud3_volume;
reg [23:0] aud3_acnt;
reg [23:0] aud3_next_acnt;
reg signed [15:0] aud3_dat;
reg signed [15:0] aud3_dat2;
reg [`ABITS] audi_adr;
reg [23:0] audi_length;
reg [23:0] audi_half_length;
reg [19:0] audi_period;
reg [15:0] audi_volume;
reg [23:0] audi_acnt;
reg [23:0] audi_next_acnt;
reg signed [15:0] audi_dat;
reg signed [15:0] audi_dat2;
reg aud0_cross_half;
reg aud1_cross_half;
reg aud2_cross_half;
reg aud3_cross_half;
reg audi_cross_half;
reg aud0_reach_end;
reg aud1_reach_end;
reg aud2_reach_end;
reg aud3_reach_end;
reg audi_reach_end;
reg wr_aud0;
reg wr_aud1;
reg wr_aud2;
reg wr_aud3;
reg wr_audi;
reg rd_aud0;
reg rd_aud1;
reg rd_aud2;
reg rd_aud3;
reg rd_audi;
wire [3:0] aud0_fifo_data_count;
wire [3:0] aud1_fifo_data_count;
wire [3:0] aud2_fifo_data_count;
wire [3:0] aud3_fifo_data_count;
wire [3:0] audi_fifo_data_count;

wire [15:0] aud0_fifo_o;
wire [15:0] aud1_fifo_o;
wire [15:0] aud2_fifo_o;
wire [15:0] aud3_fifo_o;
wire [15:0] audi_fifo_o;

reg [23:0] aud_test;
reg [`ABITS] aud0_wadr, aud1_wadr, aud2_wadr, aud3_wadr, audi_wadr;
reg [19:0] ch0_cnt, ch1_cnt, ch2_cnt, ch3_cnt, chi_cnt;
// The following request signals pulse for 1 clock cycle only.
reg aud0_req2, aud1_req2, aud2_req2, aud3_req2, audi_req2;

AudioFifo u5
(
  .clk(m_clk_i),
  .srst(rst_i),
  .din(latched_data),
  .wr_en(wr_aud0),
  .rd_en(aud_ctrl[0] & rd_aud0),
  .dout(aud0_fifo_o),
  .full(),
  .empty(),
  .almost_empty(),
  .valid(),
  .data_count(aud0_fifo_data_count)
);

AudioFifo u6
(
  .clk(m_clk_i),
  .srst(rst_i),
  .din(latched_data),
  .wr_en(wr_aud1),
  .rd_en(aud_ctrl[1] & rd_aud1),
  .dout(aud1_fifo_o),
  .full(),
  .empty(),
  .almost_empty(),
  .valid(),
  .data_count(aud1_fifo_data_count)
);

AudioFifo u7
(
  .clk(m_clk_i),
  .srst(rst_i),
  .din(latched_data),
  .wr_en(wr_aud2),
  .rd_en(aud_ctrl[2] & rd_aud2),
  .dout(aud2_fifo_o),
  .full(),
  .empty(),
  .almost_empty(),
  .valid(),
  .data_count(aud2_fifo_data_count)
);

AudioFifo u8
(
  .clk(m_clk_i),
  .srst(rst_i),
  .din(latched_data),
  .wr_en(wr_aud3),
  .rd_en(aud_ctrl[3] & rd_aud3),
  .dout(aud3_fifo_o),
  .full(),
  .empty(),
  .almost_empty(),
  .valid(),
  .data_count(aud3_fifo_data_count)
);

AudioFifo u9
(
  .clk(m_clk_i),
  .srst(rst_i),
  .din(audi_in),
  .wr_en(wr_audi),
  .rd_en(aud_ctrl[4] & rd_audi),
  .dout(audi_fifo_o),
  .full(),
  .empty(),
  .almost_empty(),
  .valid(),
  .data_count(audi_fifo_data_count)
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Audio
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

always @(posedge m_clk_i)
	if (ch0_cnt>=aud0_period || aud_ctrl[8])
		ch0_cnt <= 20'd1;
	else if (aud_ctrl[0])
		ch0_cnt <= ch0_cnt + 20'd1;
always @(posedge m_clk_i)
	if (ch1_cnt>= aud1_period || aud_ctrl[9])
		ch1_cnt <= 20'd1;
	else if (aud_ctrl[1])
		ch1_cnt <= ch1_cnt + (aud_ctrl[20] ? aud0_out[15:8] + 20'd1 : 20'd1);
always @(posedge m_clk_i)
	if (ch2_cnt>= aud2_period || aud_ctrl[10])
		ch2_cnt <= 20'd1;
	else if (aud_ctrl[2])
		ch2_cnt <= ch2_cnt + (aud_ctrl[21] ? aud1_out[15:8] + 20'd1 : 20'd1);
always @(posedge m_clk_i)
	if (ch3_cnt>= aud3_period || aud_ctrl[11])
		ch3_cnt <= 20'd1;
	else if (aud_ctrl[3])
		ch3_cnt <= ch3_cnt + (aud_ctrl[22] ? aud2_out[15:8] + 20'd1 : 20'd1);
always @(posedge m_clk_i)
	if (chi_cnt>=audi_period || aud_ctrl[12])
		chi_cnt <= 20'd1;
	else if (aud_ctrl[4])
		chi_cnt <= chi_cnt + 20'd1;

always @(posedge m_clk_i)
	aud0_dat2 <= aud0_fifo_o;
always @(posedge m_clk_i)
	aud1_dat2 <= aud1_fifo_o;
always @(posedge m_clk_i)
	aud2_dat2 <= aud2_fifo_o;
always @(posedge m_clk_i)
	aud3_dat2 <= aud3_fifo_o;
always @(posedge m_clk_i)
	audi_dat2 <= audi_fifo_o;

always @(posedge m_clk_i)
begin
	rd_aud0 <= `FALSE;
	rd_aud1 <= `FALSE;
	rd_aud2 <= `FALSE;
	rd_aud3 <= `FALSE;
	wr_audi <= `FALSE;
// IF channel count == 1
// A count value of zero is not possible so there will be no requests unless
// the audio channel is enabled.
	if (ch0_cnt==aud_ctrl[0] && ~aud_ctrl[8])
		rd_aud0 <= `TRUE;
	if (ch1_cnt==aud_ctrl[1] && ~aud_ctrl[9])
		rd_aud1 <= `TRUE;
	if (ch2_cnt==aud_ctrl[2] && ~aud_ctrl[10])
		rd_aud2 <= `TRUE;
	if (ch3_cnt==aud_ctrl[3] && ~aud_ctrl[11])
		rd_aud3 <= `TRUE;
	if (chi_cnt==aud_ctrl[4] && ~aud_ctrl[12])
		wr_audi <= `TRUE;
end

always @(posedge m_clk_i)
begin
	aud0_half_length <= aud0_length >> 1;
	aud1_half_length <= aud1_length >> 1;
	aud2_half_length <= aud2_length >> 1;
	aud3_half_length <= aud3_length >> 1;
	audi_half_length <= audi_length >> 1;
end
always @(posedge m_clk_i)
begin
	aud0_next_acnt <= aud0_acnt + 24'd1;
	aud1_next_acnt <= aud1_acnt + 24'd1;
	aud2_next_acnt <= aud2_acnt + 24'd1;
	aud3_next_acnt <= aud3_acnt + 24'd1;
	audi_next_acnt <= audi_acnt + 24'd1;
end
always @(posedge m_clk_i)
begin
	aud0_cross_half <= aud0_acnt < aud0_half_length && aud0_next_acnt >= aud0_half_length;
	aud1_cross_half <= aud1_acnt < aud1_half_length && aud1_next_acnt >= aud1_half_length;
	aud2_cross_half <= aud2_acnt < aud2_half_length && aud2_next_acnt >= aud2_half_length;
	aud3_cross_half <= aud3_acnt < aud3_half_length && aud3_next_acnt >= aud3_half_length;
	audi_cross_half <= audi_acnt < audi_half_length && audi_next_acnt >= audi_half_length;
end
always @(posedge m_clk_i)
begin
	aud0_reach_end <= aud0_next_acnt >= aud0_length;
	aud1_reach_end <= aud1_next_acnt >= aud1_length;
	aud2_reach_end <= aud2_next_acnt >= aud2_length;
	aud3_reach_end <= aud3_next_acnt >= aud3_length;
	audi_reach_end <= audi_next_acnt >= audi_length;
end

wire signed [31:0] aud1_tmp;
wire signed [31:0] aud0_tmp = aud_mix1 ? ((aud0_dat2 * aud0_volume + aud1_tmp) >> 1): aud0_dat2 * aud0_volume;
wire signed [31:0] aud3_tmp;
wire signed [31:0] aud2_dat3 = aud_ctrl[17] ? aud2_dat2 * aud2_volume * aud1_dat2 : aud2_dat2 * aud2_volume;
wire signed [31:0] aud2_tmp = aud_mix3 ? ((aud2_dat3 + aud3_tmp) >> 1): aud2_dat3;

assign aud1_tmp = aud_ctrl[16] ? aud1_dat2 * aud1_volume * aud0_dat2 : aud1_dat2 * aud1_volume;
assign aud3_tmp = aud_ctrl[18] ? aud3_dat2 * aud3_volume * aud2_dat2 : aud3_dat2 * aud3_volume;
					

always @(posedge m_clk_i)
begin
	aud0_out <= aud_ctrl[14] ? aud_test[15:0] : aud_ctrl[0] ? aud0_tmp >> 16 : 16'h0000;
	aud1_out <= aud_ctrl[14] ? aud_test[15:0] : aud_ctrl[1] ? aud1_tmp >> 16 : 16'h0000;
	aud2_out <= aud_ctrl[14] ? aud_test[15:0] : aud_ctrl[2] ? aud2_tmp >> 16 : 16'h0000;
	aud3_out <= aud_ctrl[14] ? aud_test[15:0] : aud_ctrl[3] ? aud3_tmp >> 16 : 16'h0000;
end

// Register read-back memory
wire [63:0] ardat;
wire cs_reg = cs & we;

AudioRegReadbackRam u1 (
  .a(adr[7:3]),
  .d(dat[15:0]),
  .clk(s_clk_i),
  .we(cs_reg & |sel[1:0]),
  .qspo(ardat[15:0])
);
AudioRegReadbackRam u2 (
  .a(adr[7:3]),
  .d(dat[31:16]),
  .clk(s_clk_i),
  .we(cs_reg & |sel[3:2]),
  .qspo(ardat[31:16])
);
AudioRegReadbackRam u3 (
  .a(adr[7:3]),
  .d(dat[47:32]),
  .clk(s_clk_i),
  .we(cs_reg & |sel[5:4]),
  .qspo(ardat[47:32])
);
AudioRegReadbackRam u4 (
  .a(adr[7:3]),
  .d(dat[63:48]),
  .clk(s_clk_i),
  .we(cs_reg & |sel[7:6]),
  .qspo(ardat[63:48])
);
always @(posedge s_clk_i)
if (adr[7:3]==5'b1010_0)
	s_dat_o <= {irq_status,irq_enable,aud_ctrl};
else
	s_dat_o <= ardat;

wire ne_record, ne_playback;
wire pe_record, pe_playback;
edge_det u10 (.clk(s_clk_i), .ce(1'b1), .i(record_i), .pe(pe_record), .ne(ne_record), .ee());
edge_det u11 (.clk(s_clk_i), .ce(1'b1), .i(playback_i), .pe(pe_playback), .ne(ne_playback), .ee());

always @(posedge s_clk_i)
if (rst_i) begin
	aud_ctrl <= 32'h0;
	aud0_volume <= 16'h0000;	
	aud1_volume <= 16'h0000;	
	aud2_volume <= 16'h0000;	
	aud3_volume <= 16'h0000;
	irq_enable <= 16'h0;	
end
else begin
	aud_ctrl[12:8] <= 5'h0;
	if (pe_record) begin
		aud_ctrl[12] <= 1'b1;
		aud_ctrl[4] <= 1'b1;
		audi_adr <= 32'h1000000;
		audi_length <= 24'd100000;
		audi_period <= 20'd2000;		// 10kHz sampling at 20MHz master clock
	end
	if (ne_record)
		aud_ctrl[4] <= 1'b0;
	if (pe_playback) begin
		aud_ctrl[8] <= 1'b1;
		aud_ctrl[0] <= 1'b1;
		aud0_adr <= 32'h1000000;
		aud0_length <= 24'd100000;
		aud0_period <= 20'd2000;
		aud0_volume <= 16'hFFFF;
	end
	if (ne_playback) begin
		aud_ctrl[0] <= 1'b0;
		aud0_volume <= 16'h0000;
	end

	if (cs & we)
		case(adr[7:3])
    5'b0000_0:   aud0_adr <= dat[`ABITS];
    5'b0000_1:
    	begin 
    		if (|sel[3:0]) aud0_length <= dat[23:0];
    		if (|sel[7:4]) aud0_period <= dat[41:32];
    	end
    5'b0001_0:
      begin
	      if (|sel[1:0]) aud0_volume <= dat[15:0];
	      if (|sel[3:2]) aud0_dat <= dat[31:16];
      end
    5'b0010_0:   aud1_adr <= dat[`ABITS];
    5'b0010_1:
    	begin
    		if (|sel[3:0]) aud1_length <= dat[23:0];
    		if (|sel[7:4]) aud1_period <= dat[41:32];
    	end
    5'b0011_0:
       begin
        if (|sel[1:0]) aud1_volume <= dat[15:0];
        if (|sel[3:2]) aud1_dat <= dat[31:16];
      end
    5'b0100_0:   aud2_adr <= dat[`ABITS];
    5'b0100_1:
    	begin
    		if (|sel[3:0]) aud2_length <= dat[23:0];
    		if (|sel[7:4]) aud2_period <= dat[41:32];
    	end
    5'b0101_0:
      begin
        if (|sel[1:0]) aud2_volume <= dat[15:0];
        if (|sel[3:2]) aud2_dat <= dat[31:16];
      end
    5'b0110_0:   aud3_adr <= dat[`ABITS];
    5'b0110_1:
    	begin
    		if (|sel[3:0]) aud3_length <= dat[23:0];
    		if (|sel[7:4]) aud3_period <= dat[41:32];
    	end
    5'b0111_0:
      begin
        if (|sel[1:0]) aud3_volume <= dat[15:0];
        if (|sel[3:2]) aud3_dat <= dat[31:16];
      end
    5'b1000_0:   audi_adr <= dat[`ABITS];
    5'b1000_1:
    	begin
    		if (|sel[3:0]) audi_length <= dat[23:0];
    		if (|sel[7:4]) audi_period <= dat[41:32];
    	end
    5'b1001_0:
			begin
        if (|sel[1:0]) audi_volume <= dat[15:0];
        //if (|sel[3:2]) audi_dat <= dat[31:16];
      end
    5'b1010_0:    
    	begin
    		if (|sel[3:0]) aud_ctrl <= dat[31:0];
    		if (|sel[5:4]) irq_enable <= dat[47:32];
    	end
    default:	;
		endcase    

end

always @(posedge m_clk_i)
if (rst_i) begin
	state <= ST_IDLE;
end
else begin
wr_aud0 <= `FALSE;
wr_aud1 <= `FALSE;
wr_aud2 <= `FALSE;
wr_aud3 <= `FALSE;
rd_audi <= `FALSE;
// Writing the irq_status register clears irq status
if (cs && we && |sel[7:6] && adr[7:3]==5'b1010_0)
	irq_status <= 16'h0;

// Channel reset
if (aud_ctrl[8]) begin
	aud0_wadr <= aud0_adr;
	aud0_acnt <= 24'h1;
end
if (aud_ctrl[9]) begin
	aud1_wadr <= aud1_adr;
	aud1_acnt <= 24'h1;
end
if (aud_ctrl[10]) begin
	aud2_wadr <= aud2_adr;
	aud2_acnt <= 24'h1;
end
if (aud_ctrl[11]) begin
	aud3_wadr <= aud3_adr;
	aud3_acnt <= 24'h1;
end
if (aud_ctrl[12]) begin
	audi_wadr <= audi_adr;
	audi_acnt <= 24'h1;
end

// Audio test mode generates about a 600Hz signal for 0.5 secs on all the
// audio channels.
if (aud_ctrl[14])
    aud_test <= aud_test + 24'd1;
if (aud_test==24'hFFFFFF) begin
    aud_test <= 24'h0;
end
case(state)
ST_IDLE:
	if (aud0_fifo_data_count < 4'd4 && aud_ctrl[0]) begin
		if (~m_ack_i) begin
	    m_cyc_o <= `HIGH;
			m_adr_o <= {aud0_wadr[31:1],1'h0};
			aud0_wadr <= aud0_wadr + 32'd2;
			aud0_acnt <= aud0_next_acnt;
			if (aud0_reach_end) begin
				aud0_acnt <= 24'h1;
				aud0_wadr <= aud0_adr;
				irq_status[8] <= 1'b1;
			end
			if (aud0_cross_half)
				irq_status[4] <= 1'b1;
			call(ST_LATCH_DATA,ST_AUD0);
		end
	end
	else if (aud1_fifo_data_count < 4'd4 && aud_ctrl[1])	begin
		if (~m_ack_i) begin
	    m_cyc_o <= `HIGH;
			m_adr_o <= {aud1_wadr[31:1],1'h0};
			aud1_wadr <= aud1_wadr + 32'd2;
			aud1_acnt <= aud1_next_acnt;
			if (aud1_reach_end) begin
				aud1_acnt <= 24'h1;
				aud1_wadr <= aud1_adr;
				irq_status[9] <= 1'b1;
			end
			if (aud1_cross_half)
				irq_status[5] <= 1'b1;
			call(ST_LATCH_DATA,ST_AUD1);
		end
	end
	else if (aud2_fifo_data_count < 4'd4 && aud_ctrl[2]) begin
		if (~m_ack_i) begin
	    m_cyc_o <= `HIGH;
			m_adr_o <= {aud2_wadr[31:1],1'h0};
			aud2_wadr <= aud2_wadr + 32'd2;
			aud2_acnt <= aud2_next_acnt;
			if (aud2_reach_end) begin
				aud2_acnt <= 24'h1;
				aud2_wadr <= aud2_adr;
				irq_status[10] <= 1'b1;
			end
			if (aud2_cross_half)
				irq_status[6] <= 1'b1;
			call(ST_LATCH_DATA,ST_AUD2);
		end
	end
	else if (aud3_fifo_data_count < 4'd4 && aud_ctrl[3])	begin
		if (~m_ack_i) begin
	    m_cyc_o <= `HIGH;
			m_adr_o <= {aud3_wadr[31:1],4'h0};
			aud3_wadr <= aud3_wadr + 32'd2;
			aud3_acnt <= aud3_next_acnt;
			if (aud3_reach_end) begin
				aud3_acnt <= 24'h1;
				aud3_wadr <= aud3_adr;
				irq_status[11] <= 1'b1;
			end
			if (aud3_cross_half)
				irq_status[7] <= 1'b1;
			call(ST_LATCH_DATA,ST_AUD3);
		end
	end
	else if (audi_fifo_data_count > 4'd4 && aud_ctrl[4]) begin
		if (~m_ack_i) begin
	    m_cyc_o <= `HIGH;
	    m_we_o <= `HIGH;
			m_adr_o <= {audi_wadr[31:1],1'h0};
			m_dat_o <= audi_dat2;
			audi_wadr <= audi_wadr + 32'd2;
			audi_acnt <= audi_next_acnt;
			if (audi_reach_end) begin
				audi_acnt <= 24'h1;
				audi_wadr <= audi_adr;
				irq_status[12] <= 1'b1;
			end
			if (audi_cross_half)
				irq_status[3] <= 1'b1;
			goto(ST_AUDI);
		end
	end
ST_AUDI:
	if (m_ack_i||!m_cyc_o) begin
		m_cyc_o <= `LOW;
		m_we_o <= `LOW;
		rd_audi <= `TRUE;
		goto(ST_IDLE);
	end

// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Generic data latching state.
// Implemented as a subroutine.
// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ST_LATCH_DATA:
	if (m_ack_i||!m_cyc_o) begin
		latched_data <= m_dat_i;
		m_cyc_o <= `LOW;
		m_we_o <= `LOW;
		return();
	end

ST_AUD0:
	begin
		wr_aud0 <= `TRUE;
		goto(ST_IDLE);
	end
ST_AUD1:
	begin
		wr_aud1 <= `TRUE;
		goto(ST_IDLE);
	end
ST_AUD2:
	begin
		wr_aud2 <= `TRUE;
		goto(ST_IDLE);
	end
ST_AUD3:
	begin
		wr_aud3 <= `TRUE;
		goto(ST_IDLE);
	end
default:	goto(ST_IDLE);
endcase
end

task goto;
input [3:0] tgt;
begin
	state <= tgt;
end
endtask

task call;
input [3:0] tgt;
input [3:0] ret;
begin
	stkstate <= ret;
	state <= tgt;
end
endtask

task return;
begin
	state <= stkstate;
end
endtask

endmodule
