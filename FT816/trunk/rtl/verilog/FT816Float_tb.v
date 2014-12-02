module FT816Float_tb();

reg clk;
reg rst;
reg vda;
reg rw;
reg [23:0] ad;
wire [7:0] db;
reg [7:0] dbo;
wire rdy;
reg [7:0] state;

initial begin
	#1 clk <= 1'b0;
	#5 rst <= 1'b1;
	#100 rst <= 1'b0;
end

always #5 clk <= ~clk;

assign db = rw ? {8{1'bz}} : dbo;

FT816Float u1 (
	.rst(rst),
	.clk(clk),
	.vda(vda),
	.rw(rw),
	.ad(ad),
	.db(db),
	.rdy(rdy)
);


always @(posedge clk)
if (rst)
	state <= 8'h00;
else begin
state <= state + 8'd1;
case(state)
8'h00:	b_write(24'hFEA202,8'h34);
8'h01:  if (rdy) b_write(24'hFEA203,8'h12); else state <= state;
8'h02:  if (rdy) b_write(24'hFEA20F,8'h05); else state <= state;// FIX2FLT
8'h04:  if (rdy) b_read(24'hFEA20F); else state <= state;
8'h05:	if (rdy) begin
			if (db==8'h80) state <= state - 1;
		end
		else
			state <= state;
8'h06:  if (rdy) b_write(24'hFEA20F,8'd17); else state <= state;// SWAP
8'h08:  if (rdy) b_read(24'hFEA20F); else state <= state;
8'h09:	if (rdy) begin
			if (db==8'h80) state <= state - 1;
		end
		else
			state <= state;
8'h0A:	if (rdy) b_write(24'hFEA202,8'h78); else state <= state;
8'h0B:  if (rdy) b_write(24'hFEA203,8'h56); else state <= state;
8'h0C:  if (rdy) b_write(24'hFEA20F,8'h05); else state <= state;// FIX2FLT
8'h0E:  if (rdy) b_read(24'hFEA20F); else state <= state;
8'h0F:	if (rdy) begin
			if (db==8'h80) state <= state - 1;
		end
		else
			state <= state;
8'h10:  if (rdy) b_write(24'hFEA20F,8'h03); else state <= state;// MUL
8'h12:  if (rdy) b_read(24'hFEA20F); else state <= state;
8'h13:	if (rdy) begin
			if (db==8'h80) state <= state - 1;
		end
		else
			state <= state;
8'h20:	state <= state;
endcase
end

task b_write;
input [23:0] adr;
input [7:0] dat;
begin
	vda <= 1'b1;
	rw <= 1'b0;
	ad <= adr;
	dbo <= dat;
end
endtask

task b_read;
input [23:0] adr;
begin
	vda <= 1'b1;
	rw <= 1'b1;
	ad <= adr;
end
endtask

endmodule
