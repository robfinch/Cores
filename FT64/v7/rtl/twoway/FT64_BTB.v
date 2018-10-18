// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_BTB.v
//		
// ============================================================================
//
module FT64_BTB(rst, wclk, wr, wadr, wdat, valid, rclk, pcA, btgtA, pcB, btgtB,
		pcC, btgtC, pcD, btgtD, pcE, btgtE, pcF, btgtF,
    npcA, npcB, npcC, npcD, npcE, npcF);
parameter AMSB = 31;
parameter RSTPC = 32'hFFFC0100;
input rst;
input wclk;
input wr;
input [AMSB:0] wadr;
input [AMSB:0] wdat;
input valid;
input rclk;
input [AMSB:0] pcA;
output [AMSB:0] btgtA;
input [AMSB:0] pcB;
output [AMSB:0] btgtB;
input [AMSB:0] pcC;
output [AMSB:0] btgtC;
input [AMSB:0] pcD;
output [AMSB:0] btgtD;
input [AMSB:0] pcE;
output [AMSB:0] btgtE;
input [AMSB:0] pcF;
output [AMSB:0] btgtF;
input [AMSB:0] npcA;
input [AMSB:0] npcB;
input [AMSB:0] npcC;
input [AMSB:0] npcD;
input [AMSB:0] npcE;
input [AMSB:0] npcF;

integer n;
reg [(AMSB+1)*2+1:0] mem [0:1023];
reg [9:0] radrA, radrB, radrC, radrD, radrE, radrF;
initial begin
    for (n = 0; n < 1024; n = n + 1)
        mem[n] <= RSTPC;
end
always @(posedge wclk)
begin
    if (wr) #1 mem[wadr[9:0]][AMSB:0] <= wdat;
    if (wr) #1 mem[wadr[9:0]][(AMSB+1)*2:AMSB+1] <= wadr;
    if (wr) #1 mem[wadr[9:0]][(AMSB+1)*2+1] <= valid;
end
always @(posedge rclk)
    #1 radrA <= pcA[11:2];
always @(posedge rclk)
    #1 radrB <= pcB[11:2];
always @(posedge rclk)
    #1 radrC <= pcC[11:2];
always @(posedge rclk)
    #1 radrD <= pcD[11:2];
always @(posedge rclk)
    #1 radrE <= pcE[11:2];
always @(posedge rclk)
    #1 radrF <= pcF[11:2];
wire hitA = mem[radrA][(AMSB+1)*2:AMSB+1]==pcA && mem[radrA][(AMSB+1)*2+1];
wire hitB = mem[radrB][(AMSB+1)*2:AMSB+1]==pcB && mem[radrB][(AMSB+1)*2+1];
wire hitC = mem[radrC][(AMSB+1)*2:AMSB+1]==pcC && mem[radrC][(AMSB+1)*2+1];
wire hitD = mem[radrD][(AMSB+1)*2:AMSB+1]==pcD && mem[radrD][(AMSB+1)*2+1];
wire hitE = mem[radrE][(AMSB+1)*2:AMSB+1]==pcE && mem[radrE][(AMSB+1)*2+1];
wire hitF = mem[radrF][(AMSB+1)*2:AMSB+1]==pcF && mem[radrF][(AMSB+1)*2+1];
assign btgtA = hitA ? mem[radrA][AMSB:0] : npcA;
assign btgtB = hitB ? mem[radrB][AMSB:0] : npcB;
assign btgtC = hitC ? mem[radrC][AMSB:0] : npcC;
assign btgtD = hitD ? mem[radrD][AMSB:0] : npcD;
assign btgtE = hitE ? mem[radrE][AMSB:0] : npcE;
assign btgtF = hitF ? mem[radrF][AMSB:0] : npcF;

endmodule
