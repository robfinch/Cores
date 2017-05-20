
module nna_neuron(clk,xa0,xa1,xa2,xa3,xa4,xa5,xa6,wb0,wb1,wb2,wb3,wb4,wb5,wb6,latch_res,clear,o);
parameter WID=32;
localparam MSB = WID-1;
localparam EMSB = WID==128 ? 14 :
                  WID==96 ? 14 :
                  WID==80 ? 14 :
                  WID==64 ? 10 :
				  WID==52 ? 10 :
				  WID==48 ? 10 :
				  WID==44 ? 10 :
				  WID==42 ? 10 :
				  WID==40 ?  9 :
				  WID==32 ?  7 :
				  WID==24 ?  6 : 4;
localparam FMSB = WID==128 ? 111 :
                  WID==96 ? 79 :
                  WID==80 ? 63 :
                  WID==64 ? 51 :
				  WID==52 ? 39 :
				  WID==48 ? 35 :
				  WID==44 ? 31 :
				  WID==42 ? 29 :
				  WID==40 ? 28 :
				  WID==32 ? 22 :
				  WID==24 ? 15 : 9;
localparam EMSBS = 7;
localparam FMSBS = 22;
localparam FX = (FMSB+2)*2-1;	// the MSB of the expanded fraction
localparam EX = FX + 1 + EMSB + 1 + 1 - 1;
localparam FXS = (FMSBS+2)*2-1;	// the MSB of the expanded fraction
localparam EXS = FXS + 1 + EMSBS + 1 + 1 - 1;
input clk;
input [31:0] xa0;
input [31:0] xa1;
input [31:0] xa2;
input [31:0] xa3;
input [31:0] xa4;
input [31:0] xa5;
input [31:0] xa6;
input [31:0] wb0;
input [31:0] wb1;
input [31:0] wb2;
input [31:0] wb3;
input [31:0] wb4;
input [31:0] wb5;
input [31:0] wb6;
input latch_res;
input clear;
output [MSB:0] o;

wire [EX:0] mo0;
wire [EX:0] mo1;
wire [EX:0] mo2;
wire [EX:0] mo3;
wire [EX:0] mo4;
wire [EX:0] mo5;
wire [EX:0] mo6;
reg [EX:0] mo7;
wire [MSB:0] aso0;
wire [MSB:0] aso1;
wire [MSB:0] aso2;
wire [MSB:0] aso3;
wire [MSB:0] aso4;
wire [MSB:0] aso5;
wire [MSB:0] aso6;

fpMulnr #(WID) u1 (.clk(clk), .ce(1'b1), .a(xa0), .b(wb0), .o(mo0), .sign_exe(), .inf(), .overflow(), .underflow());
fpMulnr #(WID) u2 (.clk(clk), .ce(1'b1), .a(xa1), .b(wb1), .o(mo1), .sign_exe(), .inf(), .overflow(), .underflow());
fpMulnr #(WID) u3 (.clk(clk), .ce(1'b1), .a(xa2), .b(wb2), .o(mo2), .sign_exe(), .inf(), .overflow(), .underflow());
fpMulnr #(WID) u4 (.clk(clk), .ce(1'b1), .a(xa3), .b(wb3), .o(mo3), .sign_exe(), .inf(), .overflow(), .underflow());
fpMulnr #(WID) u5 (.clk(clk), .ce(1'b1), .a(xa4), .b(wb4), .o(mo4), .sign_exe(), .inf(), .overflow(), .underflow());
fpMulnr #(WID) u6 (.clk(clk), .ce(1'b1), .a(xa5), .b(wb5), .o(mo5), .sign_exe(), .inf(), .overflow(), .underflow());
fpMulnr #(WID) u7 (.clk(clk), .ce(1'b1), .a(xa6), .b(wb6), .o(mo6), .sign_exe(), .inf(), .overflow(), .underflow());

fpAddsubnr #(WID) uas0(.clk(clk), .ce(1'b1), .rm(3'b000), .op(1'b0), .a(mo0), .b(mo1), .o(aso0) );
fpAddsubnr #(WID) uas1(.clk(clk), .ce(1'b1), .rm(3'b000), .op(1'b0), .a(mo2), .b(mo3), .o(aso1) );
fpAddsubnr #(WID) uas2(.clk(clk), .ce(1'b1), .rm(3'b000), .op(1'b0), .a(mo4), .b(mo5), .o(aso2) );
fpAddsubnr #(WID) uas3(.clk(clk), .ce(1'b1), .rm(3'b000), .op(1'b0), .a(mo6), .b(mo7), .o(aso3) );

fpAddsubnr #(WID) uas4(.clk(clk), .ce(1'b1), .rm(3'b000), .op(1'b0), .a(aso0), .b(aso1), .o(aso4) );
fpAddsubnr #(WID) uas5(.clk(clk), .ce(1'b1), .rm(3'b000), .op(1'b0), .a(aso2), .b(aso3), .o(aso5) );

fpAddsubnr #(WID) uas6(.clk(clk), .ce(1'b1), .rm(3'b000), .op(1'b0), .a(aso4), .b(aso5), .o(aso6) );

always @(posedge clk)
    if (clear)
        mo7 <= 32'h0;
    else if (latch_res)
        mo7 <= aso6;

//assign o = aso6;

sigmoid #(WID) usig1(.clk(clk), .a(aso6), .o(o));

endmodule
