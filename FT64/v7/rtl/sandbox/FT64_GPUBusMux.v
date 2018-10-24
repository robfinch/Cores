module FT64_GPUBusMux(rst_i, clk_i, ce_i, grnt_i,
	s1_req_i, s1_cyc_i, s1_stb_i, s1_ack_o, s1_we_i, s1_sel_i, s1_adr_i, s1_dat_o, s1_dat_i,
	s2_req_i, s2_cyc_i, s2_stb_i, s2_ack_o, s2_we_i, s2_sel_i, s2_adr_i, s2_dat_o, s2_dat_i,
	m1_req_o, m1_rsp_i, m1_cyc_o, m1_stb_o, m1_ack_i, m1_we_o, m1_sel_o, m1_adr_o, m1_dat_o, m1_dat_i
);
input rst_i;
input clk_i;
input ce_i;
input grnt_i;
input [14:0] s1_req_i;
input s1_cyc_i;
input s1_stb_i;
output reg s1_ack_o;
input s1_we_i;
input [3:0] s1_sel_i;
input [31:0] s1_adr_i;
output reg [31:0] s1_dat_o;
input [31:0] s1_dat_i;
input [14:0] s2_req_i;
input s2_cyc_i;
input s2_stb_i;
output reg s2_ack_o;
input s2_we_i;
input [3:0] s2_sel_i;
input [31:0] s2_adr_i;
output reg [31:0] s2_dat_o;
input [31:0] s2_dat_i;
output reg [14:0] m1_req_o;
input [14:0] m1_rsp_i;
output reg m1_cyc_o;
output reg m1_stb_o;
input m1_ack_i;
output reg m1_we_o;
output reg [3:0] m1_sel_o;
output reg [31:0] m1_adr_o;
output reg [31:0] m1_dat_o;
input [31:0] m1_dat_i;

wire pe_s2, ne_s2;
edge_det ued2 (.clk(clk_i), .ce(1'b1), .i(s2_cyc_i), .pe(pe_s2), .ne(ne_s2), .ee());

always @(posedge clk_i)
if (rst_i) begin
		m1_req_o <= 15'h7ffe;
		m1_cyc_o <= 1'b0;
		m1_stb_o <= 1'b0;
		m1_we_o <= 1'b0;
		m1_sel_o <= 4'h0;
		m1_adr_o <= 32'h0;
		m1_dat_o <= 32'h0;
		s2_ack_o <= 1'b0;
end
else begin
	begin
		if (grnt_i) begin
			m1_req_o <= s2_req_i;
			m1_cyc_o <= s2_cyc_i;
			m1_stb_o <= s2_stb_i;
			m1_we_o <= s2_we_i;
			m1_sel_o <= s2_sel_i;
			m1_adr_o <= s2_adr_i;
			m1_dat_o <= s2_dat_o;
		end
		else begin
			m1_req_o <= s1_req_i;
			m1_cyc_o <= s1_cyc_i;
			m1_stb_o <= s1_stb_i;
			m1_we_o <= s1_we_i;
			m1_sel_o <= s1_sel_i;
			m1_adr_o <= s1_adr_i;
			m1_dat_o <= s1_dat_o;
		end
	end
	if (m1_ack_i && m1_rsp_i==s2_req_i) begin
		s2_dat_o <= m1_dat_i;
		s2_ack_o <= 1'b1;
	end
	if (ne_s2)
		s2_ack_o <= 1'b0;
end

endmodule
