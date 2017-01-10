module ColorIO(rst,clk,ri,gi,bi,ro,go,bo);
input rst;
input clk;
input [5:0] ri;
input [5:0] gi;
input [5:0] bi;
output reg [3:0] ro;
output reg [3:0] go;
output reg [3:0] bo;

reg [6:0] power17,power27,power37,power47,power57,power67;
always @(posedge clk)
if (rst) begin
	power17 <= 7'b1000000;
	power27 <= 7'b1000100;
	power37 <= 7'b1010100;
	power47 <= 7'b1010101;
	power57 <= 7'b1101011;
	power67 <= 7'b1111110;
end
else begin
	power17 <= {power17[5:0],power17[6]};
	power27 <= {power27[5:0],power27[6]};
	power37 <= {power37[5:0],power37[6]};
	power47 <= {power47[5:0],power47[6]};
	power57 <= {power57[5:0],power57[6]};
	power67 <= {power67[5:0],power67[6]};
end


always @(posedge clk)
	ro[3:1] <= ri[5:3];
always @(posedge clk)
case(ri[2:0])
3'b000:	ro[0] <= 1'b0;
3'b001: ro[0] <= power17[6];
3'b010: ro[0] <= power27[6];
3'b011:	ro[0] <= power37[6];
3'b100:	ro[0] <= power47[6];
3'b101:	ro[0] <= power57[6];
3'b110:	ro[0] <= power67[6];
3'b111:	ro[0] <= 1'b1;
endcase

always @(posedge clk)
	go[3:1] <= gi[5:3];
always @(posedge clk)
case(gi[2:0])
3'b000:	go[0] <= 1'b0;
3'b001: go[0] <= power17[6];
3'b010: go[0] <= power27[6];
3'b011:	go[0] <= power37[6];
3'b100:	go[0] <= power47[6];
3'b101:	go[0] <= power57[6];
3'b110:	go[0] <= power67[6];
3'b111:	go[0] <= 1'b1;
endcase

always @(posedge clk)
	bo[3:1] <= bi[5:3];
always @(posedge clk)
case(bi[2:0])
3'b000:	bo[0] <= 1'b0;
3'b001: bo[0] <= power17[6];
3'b010: bo[0] <= power27[6];
3'b011:	bo[0] <= power37[6];
3'b100:	bo[0] <= power47[6];
3'b101:	bo[0] <= power57[6];
3'b110:	bo[0] <= power67[6];
3'b111:	bo[0] <= 1'b1;
endcase

endmodule
