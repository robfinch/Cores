module cs02SoC_tb();
reg clk;
reg rst;
reg [1:0] btn;
wire [7:0] MemDB;
wire [18:0] adr;
wire RamCEn;
wire RamOEn;
wire RamWEn;

reg [7:0] mainmem [0:524287];
always @(posedge clk)
if (!RamCEn && !RamWEn)
	mainmem[adr] <= MemDB;
assign MemDB = (!RamCEn && !RamOEn && RamWEn) ? mainmem[adr] : 8'bz;

initial begin
	rst = 1'b0;
	btn = 2'b00;
	clk = 1'b0;
	#100 btn = 2'b11;
	#1500 btn = 2'b00;
	#20 rst = 1'b1;
	#1000 rst = 1'b0;
end

always #42.6667 clk = ~clk;

SocCS02 usoc1
(
	.sysclk(clk),
	.btn(btn),
	.MemAdr(adr),
	.RamCEn(RamCEn),
	.RamOEn(RamOEn),
	.RamWEn(RamWEn),
	.MemDB(MemDB)
);

endmodule
