module rtfPlanerFrameBuffer(
input s_clk_i,
input s_cyc_i,
input s_stb_i,
output s_ack_o,
input s_we_i,
input [7:0] s_sel_i,
input [31:0] s_adr_i,
input [63:0] s_dat_i,
output reg [63:0] s_dat_o,
// Bus Master
input m_clk_i,
output reg m_cyc_o,
output m_stb_o,
input m_ack_i,
output [15:0] m_sel_o,
output reg [31:0] m_adr_o,
input [127:0] m_dat_i,
// Video
input dot_clk_i,
input hsync_i,
input vsync_i,
input blank_i,
input [11:0] hctr_i,
output reg [31:0] zrgb_o
);

wire vclk = dot_clk_i;
assign m_stb_o = m_cyc_o;
assign m_sel_o = 16'hFFFF;

reg state;
parameter WAIT_SYNC = 1'b0;
parameter FETCH = 1'b1;

reg [11:0] hctr;
reg [11:0] hoffset = 12'h0;

reg [3:0] max_fetches = 4'd4;
reg [3:0] max_plane = 4'd11;
reg [3:0] fetchcnt;
reg [3:0] plane;
reg buffer = 1'b0;

reg [127:0] planeR7_mem [0:31];
reg [127:0] planeG7_mem [0:31];
reg [127:0] planeB7_mem [0:31];
reg [127:0] planeR6_mem [0:31];
reg [127:0] planeG6_mem [0:31];
reg [127:0] planeB6_mem [0:31];
reg [127:0] planeR5_mem [0:31];
reg [127:0] planeG5_mem [0:31];
reg [127:0] planeB5_mem [0:31];
reg [127:0] planeR4_mem [0:31];
reg [127:0] planeG4_mem [0:31];
reg [127:0] planeB4_mem [0:31];
reg [31:0] planeR7_base_addr = 32'h0200000;
reg [31:0] planeG7_base_addr = 32'h0204000;
reg [31:0] planeB7_base_addr = 32'h0208000;
reg [31:0] planeR6_base_addr = 32'h020C000;
reg [31:0] planeG6_base_addr = 32'h0210000;
reg [31:0] planeB6_base_addr = 32'h0214000;
reg [31:0] planeR5_base_addr = 32'h0218000;
reg [31:0] planeG5_base_addr = 32'h021C000;
reg [31:0] planeB5_base_addr = 32'h0220000;
reg [31:0] planeR4_base_addr = 32'h0224000;
reg [31:0] planeG4_base_addr = 32'h0228000;
reg [31:0] planeB4_base_addr = 32'h022C000;
reg [31:0] planeR7_addr;
reg [31:0] planeG7_addr;
reg [31:0] planeB7_addr;
reg [31:0] planeR6_addr;
reg [31:0] planeG6_addr;
reg [31:0] planeB6_addr;
reg [31:0] planeR5_addr;
reg [31:0] planeG5_addr;
reg [31:0] planeB5_addr;
reg [31:0] planeR4_addr;
reg [31:0] planeG4_addr;
reg [31:0] planeB4_addr;

always @(m_clk_i)
begin
	if (cs & we_i) begin
		case(s_adr_i[6:3])
		4'h0:	planeR7_base_addr <= dat_i[31:0];
		4'h1:	planeG7_base_addr <= dat_i[31:0];
		4'h2:	planeB7_base_addr <= dat_i[31:0];
		4'h3:	planeR6_base_addr <= dat_i[31:0];
		4'h4:	planeG6_base_addr <= dat_i[31:0];
		4'h5:	planeB6_base_addr <= dat_i[31:0];
		4'h6:	planeR5_base_addr <= dat_i[31:0];
		4'h7:	planeG5_base_addr <= dat_i[31:0];
		4'h8:	planeB5_base_addr <= dat_i[31:0];
		4'h9:	planeR4_base_addr <= dat_i[31:0];
		4'h10:	planeG4_base_addr <= dat_i[31:0];
		4'h11:	planeB4_base_addr <= dat_i[31:0];
		endcase
	end
end

always @(m_clk_i)
case(state)
WAIT_SYNC:
	begin
		if (vsync_i) begin
			planeR7_addr <= planeR7_base_addr;
			planeG7_addr <= planeG7_base_addr;
			planeB7_addr <= planeB7_base_addr;
			planeR6_addr <= planeR6_base_addr;
			planeG6_addr <= planeG6_base_addr;
			planeB6_addr <= planeB6_base_addr;
			planeR5_addr <= planeR5_base_addr;
			planeG5_addr <= planeG5_base_addr;
			planeB5_addr <= planeB5_base_addr;
			planeR4_addr <= planeR4_base_addr;
			planeG4_addr <= planeG4_base_addr;
			planeB4_addr <= planeB4_base_addr;
		end
		if (hsync_i) begin
			fetchcnt <= 4'd0;
			plane <= 4'd0;
			m_cyc_o <= `HIGH;
			m_adr_o <= planeR7_addr;
			state <= FETCH;
		end
	end
FETCH:
	begin
		if (vsync_i) begin
			planeR7_addr <= planeR7_base_addr;
			planeG7_addr <= planeG7_base_addr;
			planeB7_addr <= planeB7_base_addr;
			planeR6_addr <= planeR6_base_addr;
			planeG6_addr <= planeG6_base_addr;
			planeB6_addr <= planeB6_base_addr;
			planeR5_addr <= planeR5_base_addr;
			planeG5_addr <= planeG5_base_addr;
			planeB5_addr <= planeB5_base_addr;
			planeR4_addr <= planeR4_base_addr;
			planeG4_addr <= planeG4_base_addr;
			planeB4_addr <= planeB4_base_addr;
		end
		if (hsync_i) begin
			fetchcnt <= 4'd0;
			plane <= 4'd0;
			m_cyc_o <= `HIGH;
			m_adr_o <= planeR7_base_addr;
		end
		else begin
			case({m_cyc_o,m_ack_i})
			2'b00:	m_cyc_o <= `HIGH;
			2'b01:	;	// wait for nack
			2'b10:	;	// wait for ack
			2'b11:
				begin
					m_cyc_o <= `LOW;
					case(plane)
					4'd0: planeR7_addr <= planeR7_addr + 32'd16 * max_fetches;
					4'd1: planeG7_addr <= planeG7_addr + 32'd16 * max_fetches;
					4'd2: planeB7_addr <= planeB7_addr + 32'd16 * max_fetches;
					4'd3: planeR6_addr <= planeR6_addr + 32'd16 * max_fetches;
					4'd4: planeG6_addr <= planeG6_addr + 32'd16 * max_fetches;
					4'd5: planeB6_addr <= planeB6_addr + 32'd16 * max_fetches;
					4'd6: planeR5_addr <= planeR5_addr + 32'd16 * max_fetches;
					4'd7: planeG5_addr <= planeG5_addr + 32'd16 * max_fetches;
					4'd8: planeB5_addr <= planeB5_addr + 32'd16 * max_fetches;
					4'd9: planeR4_addr <= planeR4_addr + 32'd16 * max_fetches;
					4'd10: planeG4_addr <= planeG4_addr + 32'd16 * max_fetches;
					4'd11: planeB4_addr <= planeB4_addr + 32'd16 * max_fetches;
					endcase
					case(plane)
					4'd0:	planeR7_mem[{buffer,fetchcnt}] <= m_dat_i;
					4'd1:	planeG7_mem[{buffer,fetchcnt}] <= m_dat_i;
					4'd2:	planeB7_mem[{buffer,fetchcnt}] <= m_dat_i;
					4'd3:	planeR6_mem[{buffer,fetchcnt}] <= m_dat_i;
					4'd4:	planeG6_mem[{buffer,fetchcnt}] <= m_dat_i;
					4'd5:	planeB6_mem[{buffer,fetchcnt}] <= m_dat_i;
					4'd6:	planeR5_mem[{buffer,fetchcnt}] <= m_dat_i;
					4'd7:	planeG5_mem[{buffer,fetchcnt}] <= m_dat_i;
					4'd8:	planeB5_mem[{buffer,fetchcnt}] <= m_dat_i;
					4'd9:	planeR4_mem[{buffer,fetchcnt}] <= m_dat_i;
					4'd10:	planeG4_mem[{buffer,fetchcnt}] <= m_dat_i;
					4'd11:	planeB4_mem[{buffer,fetchcnt}] <= m_dat_i;
					default:	;
					endcase
					if (fetchcnt==max_fetches) begin
						fetchcnt <= 4'd0;
						if (plane==max_plane) begin
							buffer <= ~buffer;
							state <= WAIT_HSYNC;
						end
						else begin
							plane <= plane + 4'd1;
							case(plane)
							4'd0:	m_adr_o <= planeG7_addr;
							4'd1:	m_adr_o <= planeB7_addr;
							4'd2:	m_adr_o <= planeR6_addr;
							4'd3:	m_adr_o <= planeG6_addr;
							4'd4:	m_adr_o <= planeB6_addr;
							4'd5:	m_adr_o <= planeR5_addr;
							4'd6:	m_adr_o <= planeG5_addr;
							4'd7:	m_adr_o <= planeB5_addr;
							4'd8:	m_adr_o <= planeR4_addr;
							4'd9:	m_adr_o <= planeG4_addr;
							4'd10:	m_adr_o <= planeB4_addr;
							default: ;
							endcase
						end
					end
					else begin
						m_adr_o <= m_adr_o + 32'd16;
						fetchcnt <= fetchcnt + 4'd1;
					end
				end
			end
		endcase
	end
endcase

always @(posedge vclk)
	hctr <= hctr_i + hoffset;

always @(posedge vclk)
begin
	case({blank_i})
	1'b0:
		zrgb_o <= {	planeR7_mem[{~buffer,hctr[10:7]}][hctr[6:0]],
								planeR6_mem[{~buffer,hctr[10:7]}][hctr[6:0]],
								planeR5_mem[{~buffer,hctr[10:7]}][hctr[6:0]],
								planeR4_mem[{~buffer,hctr[10:7]}][hctr[6:0]],
								4'h0,
								planeG7_mem[{~buffer,hctr[10:7]}][hctr[6:0]],
								planeG6_mem[{~buffer,hctr[10:7]}][hctr[6:0]],
								planeG5_mem[{~buffer,hctr[10:7]}][hctr[6:0]],
								planeG4_mem[{~buffer,hctr[10:7]}][hctr[6:0]],
								4'h0,
								planeB7_mem[{~buffer,hctr[10:7]}][hctr[6:0]],
								planeB6_mem[{~buffer,hctr[10:7]}][hctr[6:0]],
								planeB5_mem[{~buffer,hctr[10:7]}][hctr[6:0]],
								planeB4_mem[{~buffer,hctr[10:7]}][hctr[6:0]],
								4'h0	
						 	};
	default:	zrgb_o <= 32'h0;
	endcase
end

endmodule
