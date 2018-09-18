module icache_ram(wclk, wce, wr, wa, d, rclk, rce, ra, q);
input wclk;
input wce;
input wr;
input [12:0] wa;
input [31:0] d;
input rclk;
input rce;
input [10:0] ra;
output [127:0] q;

reg [127:0] mem [0:2047];
reg [10:0] rra;

always @(posedge wclk)
    if (wce & wr & wa[1:0]==2'b00)  mem[wa[12:2]][31:0] <= d;
always @(posedge wclk)
    if (wce & wr & wa[1:0]==2'b01)  mem[wa[12:2]][63:32] <= d;
always @(posedge wclk)
    if (wce & wr & wa[1:0]==2'b10)  mem[wa[12:2]][95:64] <= d;
always @(posedge wclk)
    if (wce & wr & wa[1:0]==2'b11)  mem[wa[12:2]][127:96] <= d;

always @(posedge wclk)
    rra <= ra;

assign q = mem[rra];
    
endmodule
