// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64x4_BTB.v
//		
// ============================================================================
//
module FT64x4_BTB(rst, wclk, wr, wadr, wdat, valid, rclk,
	pcA, btgtA, pcB, btgtB, pcC, btgtC, pcD, btgtD,
	pcE, btgtE, pcF, btgtF, pcG, btgtG, pcH, btgtH,
    npcA, npcB, npcC, npcD, npcE, npcF, npcG, npcH);
parameter AMSB = 31;
parameter RSTPC = 32'hFFFC0100;
input rst;
input wclk;
input wr;
input [ANSB:0] wadr;
input [ANSB:0] wdat;
input valid;
input rclk;
input [ANSB:0] pcA;
output [ANSB:0] btgtA;
input [ANSB:0] pcB;
output [ANSB:0] btgtB;
input [ANSB:0] pcC;
output [ANSB:0] btgtC;
input [ANSB:0] pcD;
output [ANSB:0] btgtD;
input [ANSB:0] pcE;
output [ANSB:0] btgtE;
input [ANSB:0] pcF;
output [ANSB:0] btgtF;
input [ANSB:0] pcG;
output [ANSB:0] btgtG;
input [ANSB:0] pcH;
output [ANSB:0] btgtH;
input [ANSB:0] npcA;
input [ANSB:0] npcB;
input [ANSB:0] npcC;
input [ANSB:0] npcD;
input [ANSB:0] npcE;
input [ANSB:0] npcF;
input [ANSB:0] npcG;
input [ANSB:0] npcH;

integer n;
reg [(AMSB+1)*2+1:0] mem [0:1023];
reg [9:0] radrA, radrB, radrC, radrD, radrE, radrF, radrG, radrH;
initial begin
    for (n = 0; n < 1024; n = n + 1)
        mem[n] <= RSTPC;
end
always @(posedge wclk)
begin
    if (wr) mem[wadr[9:0]][ANSB:0] <= wdat;
    if (wr) mem[wadr[9:0]][(AMSB+1)*2:AMSB+1] <= wadr;
    if (wr) mem[wadr[9:0]][(AMSB+1)*2+1] <= valid;
end
always @(posedge rclk)
    radrA <= pcA[11:2];
always @(posedge rclk)
    radrB <= pcB[11:2];
always @(posedge rclk)
    radrC <= pcC[11:2];
always @(posedge rclk)
    radrD <= pcD[11:2];
always @(posedge rclk)
    radrE <= pcE[11:2];
always @(posedge rclk)
    radrF <= pcF[11:2];
always @(posedge rclk)
    radrG <= pcG[11:2];
always @(posedge rclk)
    radrH <= pcH[11:2];
wire hitA = mem[radrA][(AMSB+1)*2:AMSB+1]==pcA && mem[radrA][(AMSB+1)*2+1];
wire hitB = mem[radrB][(AMSB+1)*2:AMSB+1]==pcB && mem[radrB][(AMSB+1)*2+1];
wire hitC = mem[radrC][(AMSB+1)*2:AMSB+1]==pcC && mem[radrC][(AMSB+1)*2+1];
wire hitD = mem[radrD][(AMSB+1)*2:AMSB+1]==pcD && mem[radrD][(AMSB+1)*2+1];
wire hitE = mem[radrE][(AMSB+1)*2:AMSB+1]==pcE && mem[radrE][(AMSB+1)*2+1];
wire hitF = mem[radrF][(AMSB+1)*2:AMSB+1]==pcF && mem[radrF][(AMSB+1)*2+1];
wire hitG = mem[radrG][(AMSB+1)*2:AMSB+1]==pcG && mem[radrG][(AMSB+1)*2+1];
wire hitH = mem[radrH][(AMSB+1)*2:AMSB+1]==pcH && mem[radrH][(AMSB+1)*2+1];
assign btgtA = hitA ? mem[radrA][AMSB:0] : npcA;
assign btgtB = hitB ? mem[radrB][AMSB:0] : npcB;
assign btgtC = hitC ? mem[radrC][AMSB:0] : npcC;
assign btgtD = hitD ? mem[radrD][AMSB:0] : npcD;
assign btgtE = hitE ? mem[radrE][AMSB:0] : npcE;
assign btgtF = hitF ? mem[radrF][AMSB:0] : npcf;
assign btgtG = hitG ? mem[radrG][AMSB:0] : npcG;
assign btgtH = hitH ? mem[radrH][AMSB:0] : npcH;

endmodule
