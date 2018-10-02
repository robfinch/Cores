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
`define ABITS	31:0

module AudioController(rst_i,
	s_clk_i, s_cyc_i, s_stb_i, s_ack_o, s_we_i, s_sel_i, s_adr_i, s_dat_o, s_dati, s_cs_i,
	m_clk_i, m_cyc_o, m_stb_o, m_ack_i, m_we_o, m_sel_o, m_adr_o, m_dat_i, m_dat_o,
	aud0_out, aud1_out, aud2_out, aud3_out, audi_in, record_i, playback_i
);
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

wire cs = s_cs_i & s_cyc_i & s_stb_i;

reg [3:0] state;
reg [3:0] stkstate;
reg [15:0] latched_data;
reg [15:0] irq_status;

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
reg [`ABITS] aud0_eadr;
reg [23:0] aud0_length;
reg [19:0] aud0_period;
reg [15:0] aud0_volume;
reg signed [15:0] aud0_dat;
reg signed [15:0] aud0_dat2;		// double buffering
reg [`ABITS] aud1_adr;
reg [`ABITS] aud1_eadr;
reg [23:0] aud1_length;
reg [19:0] aud1_period;
reg [15:0] aud1_volume;
reg signed [15:0] aud1_dat;
reg signed [15:0] aud1_dat2;
reg [`ABITS] aud2_adr;
reg [`ABITS] aud2_eadr;
reg [23:0] aud2_length;
reg [19:0] aud2_period;
reg [15:0] aud2_volume;
reg signed [15:0] aud2_dat;
reg signed [15:0] aud2_dat2;
reg [`ABITS] aud3_adr;
reg [`ABITS] aud3_eadr;
reg [23:0] aud3_length;
reg [19:0] aud3_period;
reg [15:0] aud3_volume;
reg signed [15:0] aud3_dat;
reg signed [15:0] aud3_dat2;
reg [`ABITS] audi_adr;
reg [`ABITS] audi_eadr;
reg [23:0] audi_length;
reg [19:0] audi_period;
reg [15:0] audi_volume;
reg signed [15:0] audi_dat;
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

wire [15:0] aud0_fifo_o;
wire [15:0] aud1_fifo_o;
wire [15:0] aud2_fifo_o;
wire [15:0] aud3_fifo_o;

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

// Compute end of buffer address
always @(posedge m_clk_i)
begin
	aud0_eadr <= aud0_adr + aud0_length;
	aud1_eadr <= aud1_adr + aud1_length;
	aud2_eadr <= aud2_adr + aud2_length;
	aud3_eadr <= aud3_adr + aud3_length;
	audi_eadr <= audi_adr + audi_length;
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
wire cs_reg = cs & we_i;

AudioRegReadbackRam u1 (
  .a(s_adr_i[7:3]),
  .d(s_dat_i[15:0]),
  .clk(s_clk_i),
  .we(cs_reg),
  .qspo(ardat[15:0])
);
AudioRegReadbackRam u2 (
  .a(s_adr_i[7:3]),
  .d(s_dat_i[31:16]),
  .clk(s_clk_i),
  .we(cs_reg),
  .qspo(ardat[31:16])
);
AudioRegReadbackRam u3 (
  .a(s_adr_i[7:3]),
  .d(s_dat_i[47:32]),
  .clk(s_clk_i),
  .we(cs_reg),
  .qspo(ardat[47:32])
);
AudioRegReadbackRam u4 (
  .a(s_adr_i[7:3]),
  .d(s_dat_i[63:48]),
  .clk(s_clk_i),
  .we(cs_reg),
  .qspo(ardat[63:48])
);
always @(posedge s_clk_i)
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
end
begin
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

	if (cs & s_we_i)
		case(s_adr_i[7:3])
    5'b0000_0:   aud0_adr <= s_dat_i[`ABITS];
    5'b0000_1:
    	begin 
    		if (|sel[3:0]) aud0_length <= s_dat_i[23:0];
    		if (|sel[7:4]) aud0_period <= s_dat_i[41:32];
    	end
    5'b0001_0:
      begin
	      if (|sel[1:0]) aud0_volume <= s_dat_i[15:0];
	      if (|sel[3:2]) aud0_dat <= s_dat_i[31:16];
      end
    5'b0010_0:   aud1_adr <= s_dat_i[`ABITS];
    5'b0010_1:
    	begin
    		if (|sel[3:0]) aud1_length <= s_dat_i[23:0];
    		if (|sel[7:4]) aud1_period <= s_dat_i[41:32];
    	end
    5'b0011_0:
       begin
        if (|sel[1:0]) aud1_volume <= s_dat_i[15:0];
        if (|sel[3:2]) aud1_dat <= s_dat_i[31:16];
      end
    5'b0100_0:   aud2_adr <= s_dat_i[`ABITS];
    5'b0100_1:
    	begin
    		if (|sel[3:0]) aud2_length <= s_dat_i[23:0];
    		if (|sel[7:4]) aud2_period <= s_dat_i[41:32];
    	end
    5'b0101_0:
      begin
        if (|sel[1:0]) aud2_volume <= s_dat_i[15:0];
        if (|sel[3:2]) aud2_dat <= s_dat_i[31:16];
      end
    5'b0110_0:   aud3_adr <= s_dat_i[`ABITS];
    5'b0110_1:
    	begin
    		if (|sel[3:0]) aud3_length <= s_dat_i[23:0];
    		if (|sel[7:4]) aud3_period <= s_dat_i[41:32];
    	end
    5'b0111_0:
      begin
        if (|sel[1:0]) aud3_volume <= s_dat_i[15:0];
        if (|sel[3:2]) aud3_dat <= s_dat_i[31:16];
      end
    5'b1000_0:   audi_adr <= s_dat_i[`ABITS];
    5'b1000_1:
    	begin
    		if (|sel[3:0]) audi_length <= s_dat_i[23:0];
    		if (|sel[7:4]) audi_period <= s_dat_i[41:32];
    	end
    5'b1001_0:
			begin
        if (|sel[1:0]) audi_volume <= s_dat_i[15:0];
        //if (|sel[3:2]) audi_dat <= s_dat_i[31:16];
      end
    5'b1010_0:    aud_ctrl <= s_dat_i;
    default:	;
		endcase    

end

always @(posedge m_clk_i)
if (rst_i) begin
	state <= ST_IDLE;
end begin
wr_aud0 <= `FALSE;
wr_aud1 <= `FALSE;
wr_aud2 <= `FALSE;
wr_aud3 <= `FALSE;
rd_audi <= `FALSE;
// Channel reset
if (aud_ctrl[8])
	aud0_wadr <= aud0_adr;
if (aud_ctrl[9])
	aud1_wadr <= aud1_adr;
if (aud_ctrl[10])
	aud2_wadr <= aud2_adr;
if (aud_ctrl[11])
	aud3_wadr <= aud3_adr;
if (aud_ctrl[12])
	audi_wadr <= audi_adr;

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
			if (aud0_wadr + 32'd2 >= aud0_eadr) begin
				aud0_wadr <= aud0_adr;
				irq_status[8] <= 1'b1;
			end
			if (aud0_wadr < (aud0_eadr >> 1) &&
				(aud0_wadr + 32'd2 >= (aud0_eadr >> 1)))
				irq_status[4] <= 1'b1;
			call(ST_LATCH_DATA,ST_AUD0);
		end
	end
	else if (aud1_fifo_data_count < 4'd4 && aud_ctrl[1])	begin
		if (~m_ack_i) begin
	    m_cyc_o <= `HIGH;
			m_adr_o <= {aud1_wadr[31:1],1'h0};
			aud1_wadr <= aud1_wadr + 32'd2;
			if (aud1_wadr + 32'd2 >= aud1_eadr) begin
				aud1_wadr <= aud1_adr;
				irq_status[9] <= 1'b1;
			end
			if (aud1_wadr < (aud1_eadr >> 1) &&
				(aud1_wadr + 32'd2 >= (aud1_eadr >> 1)))
				irq_status[5] <= 1'b1;
			call(ST_LATCH_DATA,ST_AUD1);
		end
	end
	else if (aud2_fifo_data_count < 4'd4 && aud_ctrl[2]) begin
		if (~m_ack_i) begin
	    m_cyc_o <= `HIGH;
			m_adr_o <= {aud2_wadr[31:1],1'h0};
			aud2_wadr <= aud2_wadr + 32'd2;
			if (aud2_wadr + 32'd2 >= aud2_eadr) begin
				aud2_wadr <= aud2_adr;
				irq_status[10] <= 1'b1;
			end
			if (aud2_wadr < (aud2_eadr >> 1) &&
				(aud2_wadr + 32'd2 >= (aud2_eadr >> 1)))
				irq_status[6] <= 1'b1;
			call(ST_LATCH_DATA,ST_AUD2);
		end
	end
	else if (aud3_fifo_data_count < 4'd4 && aud_ctrl[3])	begin
		if (~m_ack_i) begin
	    m_cyc_o <= `HIGH;
			m_adr_o <= {aud3_wadr[31:1],4'h0};
			aud3_wadr <= aud3_wadr + 32'd2;
			if (aud3_wadr + 32'd2 >= aud3_eadr) begin
				aud3_wadr <= aud3_adr;
				irq_status[11] <= 1'b1;
			end
			if (aud3_wadr < (aud3_eadr >> 1) &&
				(aud3_wadr + 32'd2 >= (aud3_eadr >> 1)))
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
			if (audi_wadr + 32'd2 >= audi_eadr) begin
				audi_wadr <= audi_adr;
				irq_status[12] <= 1'b1;
			end
			if (audi_wadr < (audi_eadr >> 1) &&
				(audi_wadr + 32'd2 >= (audi_eadr >> 1)))
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
