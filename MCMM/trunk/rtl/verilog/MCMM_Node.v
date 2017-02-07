
module MCMM_Node(num, rst_i, clk_i, clk50_i, net_i, net_o);
input [5:0] num;
input rst_i;
input clk_i;
input clk50_i;
input [95:0] net_i;
output [95:0] net_o;

wire cyc;
wire stb;
wire we;
wire [3:0] sel;
wire [31:0] adr;
wire [31:0] dato;
reg [31:0] dati;

wire net_ack;
wire [31:0] net_dato;
wire br_ack;
wire [31:0] br_dato;
wire psg0_ack;
wire [31:0] psg0_dato;
wire psg1_ack;
wire [31:0] psg1_dato;
wire ram_ack;
wire [31:0] ram_dato;

wire cs_ram = (adr[31:16]==16'h0000);
wire cs_br = (adr[31:20]==12'hFFC); 
wire cs_net = (adr[31:8]==24'hFFD800);
wire cs_psg0 = (adr[31:12]==20'hFFD50);
wire cs_psg1 = (adr[31:12]==20'hFFD51);

netctrl unet1
(
    .num(num),
    .rst_i(rst_i),
    .clk_i(clk_i),
    .cs_i(cs_net),
    .cyc_i(cyc),
    .stb_i(stb),
    .ack_o(net_ack),
    .we_i(we),
    .adr_i(adr),
    .dat_i(dato),
    .dat_o(net_dato),
    .net_i(net_i),
    .net_o(net_o)
);

PSG32 upsg0
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .clk50_i(clk50_i),
    .cs_i(cs_psg0),
    .cyc_i(cyc),
    .stb_i(stb),
    .ack_o(psg0_ack),
    .rdy_o(),
    .we_i(we),
    .adr_i(adr[8:0]),
    .dat_i(dato),
    .dat_o(psg0_dato),
	.m_adr_o(),
	.m_dat_i(),
	.o()
);

PSG32 upsg1
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .clk50_i(clk50_i),
    .cs_i(cs_psg1),
    .cyc_i(cyc),
    .stb_i(stb),
    .ack_o(psg1_ack),
    .rdy_o(),
    .we_i(we),
    .adr_i(adr[8:0]),
    .dat_i(dato),
    .dat_o(psg1_dato),
	.m_adr_o(),
	.m_dat_i(),
	.o()
);

bootrom ubr1
(
    .clk_i(clk_i),
    .cs_i(cs_br),
    .cyc_i(cyc),
    .stb_i(stb),
    .ack_o(br_ack),
    .adr_i(adr[15:0]),
    .dat_o(br_dato)
);

scratchram2 uscr1
(
    .clk_i(clk_i),
    .cs_i(cs_ram),
    .cyc_i(cyc),
    .stb_i(stb),
    .ack_o(ram_ack),
    .we_i(we),
    .sel_i(sel),
    .adr_i(adr),
    .dat_i(dato),
    .dat_o(ram_dato)
);

always @*
casex({cs_br,cs_net,cs_psg1,cs_psg0,cs_ram})
5'b1xxxx:  dati <= br_dato;
5'b01xxx:  dati <= net_dato;
5'b001xx:  dati <= psg1_dato;
5'b0001x:  dati <= psg0_dato;
5'b00001:  dati <= ram_dato;
default:    dati <= 32'h0;
endcase

FT68000 ucpu1
(
    .rst_i(rst_i),
    .rst_o(),
    .clk_i(clk_i),
    .nmi_i(),
    .ipl_i(),
    .lock_o(),
    .cyc_o(cyc),
    .stb_o(stb),
    .ack_i(net_ack|br_ack|psg0_ack|psg1_ack|ram_ack),
    .err_i(),
    .we_o(we),
    .sel_o(sel),
    .fc_o(),
    .adr_o(adr),
    .dat_i(dati),
    .dat_o(dato)
);

endmodule
