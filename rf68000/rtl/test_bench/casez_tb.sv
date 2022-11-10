module casez_tb();

reg clk = 'd0;
reg [3:0] cnt = 'd0;
wire [7:0] ir = {cnt[2],7'b0};
wire [3:0] ea = cnt[3:0];
reg [3:0] sel_o;

always #5 clk <= ~clk;

always @(posedge clk)
	cnt <= cnt + 2'd1;
	
always_comb
	casez({ir[7],ea[1:0]+2'd2})
	3'b0??:	sel_o <= 4'b1111;
	3'b100:	sel_o <= 4'b0001;
	3'b101:	sel_o <= 4'b0010;
	3'b110:	sel_o <= 4'b0100;
	3'b111:	sel_o <= 4'b1000;
	endcase

endmodule
