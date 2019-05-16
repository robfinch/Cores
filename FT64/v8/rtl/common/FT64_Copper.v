`define HIGH	1'b1
`define LOW		1'b0

module FT64_Copper(
	rst_i, clk_i, s_cs_i, s_cyc_i, s_stb_i, s_ack_o, s_we_i, s_sel_i, s_adr_i, s_dat_o, s_dat_i,
	m_clk_i, m_cyc_o, m_stb_o, m_ack_i, m_we_o, m_sel_o, m_adr_o, m_dat_o, m_dat_i,
	bltdone_i, dot_clk_i, vsync_i, hsync_i);
input rst_i;
input clk_i;
input s_cs_i;
input s_cyc_i;
input s_stb_i;
output s_ack_o;
input s_we_i;
input [7:0] s_sel_i;
input [31:0] s_adr_i;
input [63:0] s_dat_i;
output reg [63:0] s_dat_o;
input m_clk_i;
output reg m_cyc_o;
output reg m_stb_o;
input m_ack_i;
output reg m_we_o;
output reg [7:0] m_sel_o;
output reg [31:0] m_adr_o;
output reg [63:0] m_dat_o;
input [63:0] m_dat_i;
input bltdone_i;
input dot_clk_i;
input vsync_i;
input hsync_i;

parameter ST_IDLE = 6'd0;
parameter ST_IFETCH = 6'd1;

reg [5:0] state;
wire [11:0] vpos, hpos;
wire [5:0] fpos;
reg [1:0] copper_op;
reg copper_b;
reg [5:0] copper_f, copper_mf;
reg [11:0] copper_h, copper_v;
reg [11:0] copper_mh, copper_mv;
reg copper_go;
reg [15:0] copper_ctrl;
wire copper_en = copper_ctrl[0];
reg [127:0] copper_ir;
reg [`ABITS] copper_pc;
reg [1:0] copper_state;
reg [`ABITS] copper_adr [0:15];
reg [7:0] reg_copper_sel;
reg [`ABITS] reg_copper_adr;
reg [63:0] reg_copper_dat;
reg reg_copper;
reg [7:0] reg_copper_rst;
wire [29:0] cmppos = {fpos,vpos,hpos} & {copper_mf,copper_mv,copper_mh};

edge_det ued1 (.clk(vclk), .ce(1'b1), .i(hsync_i), .pe(pe_hsync), .ne(), .ee());
edge_det ued2 (.clk(vclk), .ce(1'b1), .i(vsync_i), .pe(pe_vsync), .ne(), .ee());

VT163 #(12) uhctr (.clk(vclk), .clr_n(!rst_i), .ent(1'b1),     .enp(1'b1), .ld_n(!pe_hsync), .d(12'd0), .q(hpos), .rco());
VT163 #(12) uvctr (.clk(vclk), .clr_n(!rst_i), .ent(pe_hsync), .enp(1'b1), .ld_n(!pe_vsync), .d(12'd0), .q(vpos), .rco());
VT163 # (6) ufctr (.clk(vclk), .clr_n(!rst_i), .ent(pe_vsync), .enp(1'b1), .ld_n(1'b1),  .d( 6'd0), .q(fpos), .rco());


always @(posedge m_clk_i)
if (rst) begin
	state <= ST_IDLE;
end
else begin
case(state)
ST_IDLE:
	if (hpos==12'd1 && vpos==12'd1 && (fpos==4'd1 || copper_ctrl[1])) begin
		copper_pc <= copper_adr[0];
		state <= ST_IFETCH1;
	end
ST_IFETCH1:
	if (~m_ack_i) begin
		m_cyc_o <= `HIGH;
		m_stb_o <= `HIGH;
		m_sel_o <= 8'hFF;
		m_adr_o <= copper_pc;
		copper_pc <= copper_pc + 20'd8;
		state <= ST_IFETCH1_ACK;
	end
ST_IFETCH1_ACK:
	if (m_ack_i) begin
		m_stb_o <= `LOW;
		copper_ir[63:0] <= m_dat_i;
		state <= ST_IFETCH1_NACK;
	end
ST_IFETCH1_NACK:
	if (~m_ack_i) begin
		m_stb_o <= `HIGH;
		m_adr_o <= copper_pc;
		copper_pc <= copper_pc + 20'd8;
		state <= ST_IFETCH2_ACK;
	end
ST_IFETCH2_ACK:
	if (m_ack_i) begin
		m_cyc_o <= `LOW;
		m_stb_o <= `LOW;
		copper_ir[127:64] <= m_dat_i;
		state <= ST_EXECUTE;
	end
ST_EXECUTE:
	begin
		if (hpos==12'd1 && vpos==12'd1 && (fpos==4'd1 || copper_ctrl[1])) begin
			copper_pc <= copper_adr[0];
			state <= ST_IFETCH1;
		end
		else
		case(copper_ir[127:126])
		2'b00:	// WAIT
			begin
				copper_b <= copper_ir[112];
				copper_f <= copper_ir[101:96];
				copper_v <= copper_ir[91:80];
				copper_h <= copper_ir[75:64];
				copper_mf <= copper_ir[37:32];
				copper_mv <= copper_ir[27:26];
				copper_mh <= copper_ir[11:0];
				copper_state <= 2'b10;
				state <= ST_WAIT;
			end
		2'b01:	// MOVE
			if (~m_ack_i) begin
				m_cyc_o <= `HIGH;
				m_stb_o <= `HIGH;
				m_we_o <= `HIGH;
				m_sel_o <= copper_ir[119:112];
				m_adr_o <= copper_ir[95:64];
				m_dat_o <= copper_ir[63:0];
				state <= ST_ACK;
			end
		2'b10:	// SKIP
			begin
				copper_b <= copper_ir[112];
				copper_f <= copper_ir[101:96];
				copper_v <= copper_ir[91:80];
				copper_h <= copper_ir[75:64];
				copper_mf <= copper_ir[37:32];
				copper_mv <= copper_ir[27:26];
				copper_mh <= copper_ir[11:0];
				state <= ST_SKIP;
			end
		2'b11:	// JUMP
			begin
				state <= ST_IFETCH1;
				copper_adr[copper_ir[83:80]] <= copper_pc;
				casez({copper_ir[74:72],bltdone_i})
				4'b000?:	copper_pc <= copper_ir[`ABITS];
				4'b0010:	copper_pc <= copper_pc - 20'd16;
				4'b0011:	copper_pc <= copper_ir[`ABITS];
				4'b0100:	copper_pc <= copper_ir[`ABITS];
				4'b0101:	copper_pc <= copper_pc - 20'd16;
				4'b100?:	copper_pc <= copper_adr[copper_ir[67:64]];
				4'b1010:	copper_pc <= copper_pc - 20'd16;
				4'b1011:	copper_pc <= copper_adr[copper_ir[67:64]];
				4'b1100:	copper_pc <= copper_adr[copper_ir[67:64]];
				4'b1101:	copper_pc <= copper_pc - 20'd16;
				4'b1111:	state <= ST_IDLE;
				default:	copper_pc <= copper_ir[`ABITS];
				endcase
			end
		endcase
	end
ST_SKIP:
	begin
		state <= ST_IFETCH1;
		if (hpos==12'd1 && vpos==12'd1 && (fpos==4'd1 || copper_ctrl[1]))
			copper_pc <= copper_adr[0];
		else if ((cmppos > {copper_f,copper_v,copper_h})&&(copper_b ? bltdone_i : 1'b1))
			copper_pc <= copper_pc + 20'd16;
	end
ST_WAIT:
	if (hpos==12'd1 && vpos==12'd1 && (fpos==4'd1 || copper_ctrl[1])) begin
		copper_pc <= copper_adr[0];
		state <= ST_IFETCH1;
	end
	else if ((cmppos > {copper_f,copper_v,copper_h})&&(copper_b ? bltdone_i : 1'b1))
		state <= ST_IFETCH1;
ST_ACK:
	if (m_ack_i) begin
		m_cyc_o <= `LOW;
		m_stb_o <= `LOW;
		m_we_o <= `LOW;
		state <= ST_IFETCH1;
	end
default:    state <= ST_IDLE;
endcase

end

endmodule
