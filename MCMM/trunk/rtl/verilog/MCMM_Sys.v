
module MCMM_Sys(num, rst_i, clk_i, clk50_i, cyc_o, stb_o, ack_i, err_i, we_o, sel_o, adr_o, dat_i, dat_o);
input [5:0] num;
input rst_i;
input clk_i;
input clk50_i;
output cyc_o;
output stb_o;
input ack_i;
input err_i;
output we_o;
output [3:0] sel_o;
output [31:0] adr_o;
input [31:0] dat_i;
output [31:0] dat_o;

wire [95:0] net1, net2, net3, net4, net5, net6, net7, net8, net62;

soci usoci1
(
    .num(62),
    .rst_i(rst_i),
    .clk_i(clk_i),
    .net_i(net8),
    .net_o(net62),
    .mas(),
    .cyc_o(cyc_o),
    .stb_o(stb_o),
    .ack_i(ack_i),
    .err_i(err_i),
    .we_o(we_o),
    .sel_o(sel_o),
    .adr_o(adr_o),
    .dat_i(dat_i),
    .dat_o(dat_o)
);

MCMM_Node unode1
(
    .num(1),
    .rst_i(rst_i),
    .clk_i(clk_i),
    .clk50_i(clk50_i),
    .net_i(net62),
    .net_o(net1)
);

MCMM_Node unode2
(
    .num(2),
    .rst_i(rst_i),
    .clk_i(clk_i),
    .clk50_i(clk50_i),
    .net_i(net1),
    .net_o(net2)
);

MCMM_Node unode3
(
    .num(3),
    .rst_i(rst_i),
    .clk_i(clk_i),
    .clk50_i(clk50_i),
    .net_i(net2),
    .net_o(net3)
);

MCMM_Node unode4
(
    .num(4),
    .rst_i(rst_i),
    .clk_i(clk_i),
    .clk50_i(clk50_i),
    .net_i(net3),
    .net_o(net4)
);

MCMM_Node unode5
(
    .num(5),
    .rst_i(rst_i),
    .clk_i(clk_i),
    .clk50_i(clk50_i),
    .net_i(net4),
    .net_o(net5)
);

MCMM_Node unode6
(
    .num(6),
    .rst_i(rst_i),
    .clk_i(clk_i),
    .clk50_i(clk50_i),
    .net_i(net5),
    .net_o(net6)
);

MCMM_Node unode7
(
    .num(7),
    .rst_i(rst_i),
    .clk_i(clk_i),
    .clk50_i(clk50_i),
    .net_i(net6),
    .net_o(net7)
);

MCMM_Node unode8
(
    .num(8),
    .rst_i(rst_i),
    .clk_i(clk_i),
    .clk50_i(clk50_i),
    .net_i(net7),
    .net_o(net8)
);

endmodule
