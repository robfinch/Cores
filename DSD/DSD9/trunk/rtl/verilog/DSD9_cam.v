
module DSD9_cam6x32(clk, we, wr_addr, din, cmp_din, match_addr, match);
input clk;
input we;
input [31:0] wr_addr;
input [5:0] din;
input [5:0] cmp_din;
output [31:0] match_addr;
output match;

reg [31:0] mem [0:63];

always @(posedge clk)
    if (we)
        mem[din] <= wr_addr;

assign match_addr = mem[cmp_din];
assign match = |match_addr;

endmodule

module DSD9_cam36x32(clk, we, wr_addr, din, cmp_din, match_addr, match);
input clk;
input we;
input [31:0] wr_addr;
input [35:0] din;
input [35:0] cmp_din;
output [31:0] match_addr;
output match;

wire [31:0] match_addr0, match_addr1, match_addr2, match_addr3, match_addr4, match_addr5;
wire [31:0] match_addr = match_addr0 & match_addr1 & match_addr2 & match_addr3 & match_addr4 & match_addr5;

DSD9_cam6x32 u1 (clk, we, wr_addr, din[ 5: 0], cmp_din[ 5: 0], match_addr0);
DSD9_cam6x32 u2 (clk, we, wr_addr, din[11: 6], cmp_din[11: 6], match_addr1);
DSD9_cam6x32 u3 (clk, we, wr_addr, din[17:12], cmp_din[17:12], match_addr2);
DSD9_cam6x32 u4 (clk, we, wr_addr, din[23:18], cmp_din[23:18], match_addr3);
DSD9_cam6x32 u5 (clk, we, wr_addr, din[29:24], cmp_din[29:24], match_addr4);
DSD9_cam6x32 u6 (clk, we, wr_addr, din[35:30], cmp_din[35:30], match_addr5);

assign match = |match_addr;

endmodule
