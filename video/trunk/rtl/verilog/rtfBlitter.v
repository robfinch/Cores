// Regno
// Image Descriptors
// 0x000   [11: 0] image x position in source
//         [27:16] image y position in source
// 0x004   [11: 0] image width in pixels
//         [27:16] image height in pixels
// 0x008   [31: 0] image transparent color
// 0x00C   [ 3: 0] image source bitmap descriptor index
//
// 0x010   [11: 0] image x position in target
//         [27:16] image y position in target
// 0x014   [31: 0] reserved
// 0x018   [31: 0] reserved
// 0x01C   [31: 0] reserved
//
// 0x020 to 0x7FC	repeat of 0x000 to 0x01C for 63 more images
//
// Source Bitmap Desciptors
// 0x800   [11: 0] source image width
//         [27:16] source image height
// 0x804   [31: 0] source image base address
// 0x808   [ 3: 0] source color depth
//
// 0x810 to 0x8FC
//			Same as 0x800-0x80C but for 15 more source bitmap descriptors
// 
// Target Bitmap Descriptor
// 0x900   [11: 0] target width
//         [27:16] target height
// 0x904   [31: 0] target base address
// 0x908   [ 3: 0] target color depth
//
// GLobal Registers
// 0x910   [31: 0] status reg
// 0x914   [ 5: 0] number of images to process

module rtfBlitter(rst_i,
	s_clk_i, s_cyc_i, s_stb_i, s_ack_o, s_we_i, s_sel_i, s_adr_i, s_dat_i, s_dat_o,
	m_clk_i, m_bte_o, m_cti_o, m_cyc_o, m_stb_o, m_ack_i, m_err_i, m_we_o, m_sel_o, m_adr_o, m_dat_i, m_dat_o
);
input rst_i;

input s_clk_i;
input s_cyc_i;
input s_stb_i;
output s_ack_o;
input s_we_i;
input [3:0] s_sel_i;
input [31:0] s_adr_i;
input [31:0] s_dat_i;
output reg [31:0] s_dat_o;

input m_clk_i;
output [1:0] m_bte_o;
output [2:0] m_cti_o;
output reg m_cyc_o;
output m_stb_o;
input m_ack_i;
input m_err_i;
output m_we_o;
output [15:0] m_sel_o;
output [31:0] m_adr_o;
input [127:0] m_dat_i;
output reg [127:0] m_dat_o;

reg [31:0] source_base [15:0];
reg [11:0] source_width [15:0];
reg [11:0] source_height [15:0];
reg [3:0] source_color_depth [15:0];

reg [11:0] image_x [63:0];
reg [11:0] image_y [63:0];
reg [11:0] image_width [63:0];
reg [11:0] image_height [63:0];
reg [31:0] image_tc [63:0];		// transparent color
reg [3:0]  image_source_desc;
reg [11:0] image_tx;
reg [11:0] image_ty;

reg [31:0] target_base;
reg [11:0] target_width;
reg [11:0] target_height;
reg [3:0] target_cd;

reg [7:0] imagenum;
reg [7:0] maxImagenum;

reg [31:0] base_addr;
reg [3:0] color_depth;
reg [11:0] hdisplayed;
reg [11:0] x_coord, y_coord;
wire [31:0] addr;

wire cs = s_cyc_i && s_stb_i && (s_adr_i[31:12]==20'hFFDAF);

always @(posedge s_clk_i)
if (rst_i) begin
	s_dat_o <= 32'd0;
end
else begin
	if (cs) begin
		if (s_we_i) begin
			casex(adr_i[11:0])
			12'b0xxx_xxx0_00xx:
				begin
				if (s_sel_i[0]) image_x[s_adr_i[10:5]] <= s_dat_i[11: 0];
				if (s_sel_i[2]) image_y[s_adr_i[10:5]] <= s_dat_i[27:16];
				end
			12'b0xxx_xxx0_01xx:
				begin
				if (s_sel_i[0]) image_width[s_adr_i[10:5]] <= s_dat_i[11: 0];
				if (s_sel_i[2]) image_height[s_adr_i[10:5]] <= s_dat_i[27:16];
				end
			12'b0xxx_xxx0_10xx:
				image_tc[s_adr_i[10:5]] <= s_dat_i;
			12'b0xxx_xxx0_11xx:
				image_source_desc[s_adr_i[10:5]] <= s_dat_i[3:0];
			12'b0xxx_xxx1_00xx:
				begin
				if (s_sel_i[0]) image_tx[s_adr_i[10:5]] <= s_dat_i[11:0];
				if (s_sel_i[2]) image_ty[s_adr_i[10:5]] <= s_dat_i[27:16];
				end
			12'b1000_xxxx_00xx:
				begin
				if (s_sel_i[0]) source_width[s_adr_i[7:4]] <= s_dat_i[11:0];
				if (s_sel_i[2]) source_height(s_adr_i[7:4]) <= s_dat_i[27:16];
				end
			12'b1000_xxxx_01xx:
				source_base[s_adr_i[7:4]] <= s_dat_i;
			12'b1000_xxxx_10xx:
				source_color_depth[s_adr_i[7:4]] <= s_dat_i[3:0];
			12'h900:
				begin
				if (s_sel_i[0]) target_width <= s_dat_i[11:0];
				if (s_sel_i[1]) target_height <= s_dat_i[27:16];
				end
			12'h904:	target_base <= {s_dat_i[31:4],4'h0};
			12'h908:	target_cd <= s_dat_i[3:0];
			12'h914:	maxImagenum <= s_dat_i[5:0];
			endcase
		end
	end
	else
		s_dat_o <= 32'd0;
end

gfx_CalcAddress u1
(
	.clk(m_clk_i),
	.base_address_i(base_addr),
	.color_depth_i(color_depth),
	.hdisplayed_i(hdisplayed),
	.x_coord_i(x_coord),
	.y_coord_i(y_coord),
	.address_o(addr),
	.mb_o(mb),
	.me_o(me)
);

reg [127:0] mem_dat;
wire [31:0] pixel;
reg [31:0] color;

mem2color um2c
(
	.mem_i(mem_dat),
	.mb_i(mb),
	.me_i(me),
	.color_o(pixel)
);

wire [127:0] memo_dat;
color2mem uc2m
(
	.mem_i(mem_dat),
	.mb_i(mb),
	.me_i(me),
	.color_i(color),
	.mem_o(memo_dat)
);

assign m_bte_o = 2'b00;
assign m_cti_o = 3'b000;
assign m_stb_o = 1'b1;
assign m_sel_o = 16'hFFFF;

wire [3:0] source_ndx = image_source_desc[imagenum];

reg [5:0] state;
parameter IDLE = 6'd1;
parameter SET_LADDR = 6'd2;
parameter FETCH_IMAGE_PIXEL = 6'd3;
parameter FETCH_IP_ACK = 6'd4;
parameter SET_SADDR = 6'd5;
parameter S2 = 6'd6;
parameter S3 = 6'd7;
parameter S4 = 6'd8;
parameter S5 = 6'd9;
parameter NEXT_PIXEL = 6'd10;

always @(posedge m_clk_i)
if (rst_i) begin
	state <= IDLE;
end
else begin
case(state)
IDLE:
	begin
		imagenum <= 6'd0;
		x_count <= 12'd0;
		y_count <= 12'd0;
	end
SET_LADDR:
	begin
		base_addr <= source_base[source_ndx];
		color_depth <= source_color_depth[source_ndx];
		hdisplayed <= source_width[source_ndx];
		x_coord <= image_x[imagenum] + x_count;
		y_coord <= image_y[imagenum] + y_count;
		state <= FETCH_IMAGE_PIXEL;
	end
FETCH_IMAGE_PIXEL:
	begin
		m_cyc_o <= 1'b1;
		m_adr_o <= addr;
		state <= FETCH_IP_ACK;
	end
FETCH_IP_ACK:
	if (m_ack_i) begin
		m_cyc_o <= 1'b0;
		mem_dat <= m_dat_i;
		state <= SET_SADDR;
	end
SET_SADDR:
	begin
		color <= pixel;
		if (pixel==image_tc[imagenum])
			state <= NEXT_PIXEL;
		else
			state <= S2;
		base_addr <= target_base;
		color_depth <= target_cd;
		hdisplayed <= target_width;
		x_coord <= image_tx[imagenum] + x_count;
		y_coord <= image_ty[imagenum] + y_count;
	end
S2:
	begin
		if ((x_coord >= target_width) || (y_coord >= target_height))
			state <= NEXT_PIXEL;
		else begin
			m_cyc_o <= 1'b1;
			m_adr_o <= addr;
			state <= S3;
		end
	end
S3:
	if (m_ack_i) begin
		m_cyc_o <= 1'b0;
		mem_dat <= m_dat_i;
		state <= S4;
	end
S4:
	begin
		m_cyc_o <= 1'b1;
		m_we_o <= 1'b1;
		m_adr_o <= addr;
		m_dat_o <= memo_dat;
		state <= S5;
	end
S5:
	if (m_ack_i) begin
		m_cyc_o <= 1'b0;
		m_we_o <= 1'b0;
		state <= NEXT_PIXEL;
	end

NEXT_PIXEL:
	if (x_count==image_width[imagenum]) begin
		x_count <= 12'd0;
		if (y_count==image_height[imagenum]) begin
			imagenum = imagenum + 1;
			x_count <= 12'd0;
			y_count <= 12'd0;
			if (imagenum==maxImagenum)
				state <= IDLE;
			else
				state <= SET_LADDR;
		end
		else begin
			y_count <= y_count + 12'd1;
			state <= SET_LADDR;
		end
	end
	else begin
		x_count <= x_count + 12'd1;
		state <= SET_LADDR;
	end
endcase
end

endmodule

