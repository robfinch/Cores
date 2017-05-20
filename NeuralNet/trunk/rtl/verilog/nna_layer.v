module nna_layer(clk,xa0,xa1,xa2,xa3,xa4,xa5,xa6,ws,wb0,wb1,wb2,wb3,wb4,wb5,wb6,latch_res,clear,
    o1,o2,o3,o4,o5,o6,o7,o8);
input clk;
input [31:0] xa0,xa1,xa2,xa3,xa4,xa5,xa6;
input [2:0] ws;
input [31:0] wb0,wb1,wb2,wb3,wb4,wb5,wb6;
input latch_res;
input clear;
output [31:0] o1,o2,o3,o4,o5,o6,o7,o8;

reg [31:0] wb00,wb10,wb20,wb30,wb40,wb50,wb60;
reg [31:0] wb01,wb11,wb21,wb31,wb41,wb51,wb61;
reg [31:0] wb02,wb12,wb22,wb32,wb42,wb52,wb62;
reg [31:0] wb03,wb13,wb23,wb33,wb43,wb53,wb63;
reg [31:0] wb04,wb14,wb24,wb34,wb44,wb54,wb64;
reg [31:0] wb05,wb15,wb25,wb35,wb45,wb55,wb65;
reg [31:0] wb06,wb16,wb26,wb36,wb46,wb56,wb66;

always @(posedge clk)
case (ws)
3'd0:   wb00 <= wb0;
3'd1:   wb10 <= wb0;
3'd2:   wb20 <= wb0;
3'd3:   wb30 <= wb0;
3'd4:   wb40 <= wb0;
3'd5:   wb50 <= wb0;
3'd6:   wb60 <= wb0;
endcase

always @(posedge clk)
case (ws)
3'd0:   wb01 <= wb1;
3'd1:   wb11 <= wb1;
3'd2:   wb21 <= wb1;
3'd3:   wb31 <= wb1;
3'd4:   wb41 <= wb1;
3'd5:   wb51 <= wb1;
3'd6:   wb61 <= wb1;
endcase

always @(posedge clk)
case (ws)
3'd0:   wb02 <= wb2;
3'd1:   wb12 <= wb2;
3'd2:   wb22 <= wb2;
3'd3:   wb32 <= wb2;
3'd4:   wb42 <= wb2;
3'd5:   wb52 <= wb2;
3'd6:   wb62 <= wb2;
endcase

always @(posedge clk)
case (ws)
3'd0:   wb03 <= wb3;
3'd1:   wb13 <= wb3;
3'd2:   wb23 <= wb3;
3'd3:   wb33 <= wb3;
3'd4:   wb43 <= wb3;
3'd5:   wb53 <= wb3;
3'd6:   wb63 <= wb3;
endcase

always @(posedge clk)
case (ws)
3'd0:   wb04 <= wb4;
3'd1:   wb14 <= wb4;
3'd2:   wb24 <= wb4;
3'd3:   wb34 <= wb4;
3'd4:   wb44 <= wb4;
3'd5:   wb54 <= wb4;
3'd6:   wb64 <= wb4;
endcase

always @(posedge clk)
case (ws)
3'd0:   wb05 <= wb5;
3'd1:   wb15 <= wb5;
3'd2:   wb25 <= wb5;
3'd3:   wb35 <= wb5;
3'd4:   wb45 <= wb5;
3'd5:   wb55 <= wb5;
3'd6:   wb65 <= wb5;
endcase

always @(posedge clk)
case (ws)
3'd0:   wb06 <= wb6;
3'd1:   wb16 <= wb6;
3'd2:   wb26 <= wb6;
3'd3:   wb36 <= wb6;
3'd4:   wb46 <= wb6;
3'd5:   wb56 <= wb6;
3'd6:   wb66 <= wb6;
endcase

nna_neuron u1 (clk,xa0,xa1,xa2,xa3,xa4,xa5,xa6,wb00,wb01,wb02,wb03,wb04,wb05,wb06,latch_res,clear,o1);
nna_neuron u2 (clk,xa0,xa1,xa2,xa3,xa4,xa5,xa6,wb10,wb11,wb12,wb13,wb14,wb15,wb16,latch_res,clear,o2);
nna_neuron u3 (clk,xa0,xa1,xa2,xa3,xa4,xa5,xa6,wb20,wb21,wb22,wb23,wb24,wb25,wb26,latch_res,clear,o3);
nna_neuron u4 (clk,xa0,xa1,xa2,xa3,xa4,xa5,xa6,wb30,wb31,wb32,wb33,wb34,wb35,wb36,latch_res,clear,o4);
nna_neuron u5 (clk,xa0,xa1,xa2,xa3,xa4,xa5,xa6,wb40,wb41,wb42,wb43,wb44,wb45,wb46,latch_res,clear,o5);
nna_neuron u6 (clk,xa0,xa1,xa2,xa3,xa4,xa5,xa6,wb50,wb51,wb52,wb53,wb54,wb55,wb56,latch_res,clear,o6);
nna_neuron u7 (clk,xa0,xa1,xa2,xa3,xa4,xa5,xa6,wb60,wb61,wb62,wb63,wb64,wb65,wb66,latch_res,clear,o7);
nna_neuron u8 (clk,xa0,xa1,xa2,xa3,xa4,xa5,xa6,wb70,wb71,wb72,wb73,wb74,wb75,wb76,latch_res,clear,o8);

endmodule
