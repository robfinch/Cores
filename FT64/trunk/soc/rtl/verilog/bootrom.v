module bootrom(clk, cs, cyc, ack, adr, o);
input clk;
input cs;
input cyc;
output ack;
input [17:0] adr;
output reg [63:0] o;

reg [63:0] rommem [0:32767]; 
reg [17:0] radr;

initial begin
`include "c:\\cores5\\FT64\\trunk\\software\\boot\\boot.ve0";
end

reg rdy1, rdy2;
always @(posedge clk)
    rdy1 <= cs & cyc;
always @(posedge clk)
    rdy2 <= rdy1 & cs & cyc;

assign ack = (cs & cyc) ? rdy2 : 1'b0;
        
always @(posedge clk)
    radr <= adr;
always @(posedge clk)
    o <= rommem[radr[17:3]];

endmodule
