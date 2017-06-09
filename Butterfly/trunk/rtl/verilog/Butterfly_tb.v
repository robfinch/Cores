
module Butterfly_tb();
reg rst;
reg clk;

wire cyc;
wire we;
wire ack;
wire [15:0] adr;
wire [7:0] dati;
wire [7:0] dato;

initial begin
    #0 rst = 0;
    #0 clk = 0;
    #10 rst = 1;
    #50 rst = 0;
end

reg [7:0] rammem [0:4095];
reg [7:0] rommem [0:4095];
initial begin
$readmemh("C:\\cores4\\Butterfly\\trunk\\software\\bfasm\\debug\\boot_rom16.mem", rommem);
end
wire cs_ram = cyc && adr[15:12]==4'h0;
wire cs_rom = cyc && adr[15:12]==4'hF;
wire ram_ack = cs_ram;
wire rom_ack = cs_rom;
wire [7:0] ramo = rammem[adr[11:0]];
wire [7:0] romo = rommem[adr[11:0]];

assign dati = cs_rom ? romo : 8'bz;
assign dati = cs_ram ? ramo : 8'bz;
assign ack = 1'b1;//cs_rom ? rom_ack : 1'b0;
always @(posedge clk)
    if (cs_ram & we) rammem[adr[11:0]] <= dato;

always
    #5 clk = ~clk;

Butterfly16 ucpu1
(
	.id(8'h01),		// cpu id (which cpu am I?)
	.nmi(1'b0),			// non-maskable interrupt
	.irq(1'b0),			// irq inputs
	.go(1'b0),			// exit stop state if active
	// Bus master interface
	.rst_i(rst),			// reset
	.clk_i(clk),			// clock
	.soc_o(),		// start of cyc_ole
	.cyc_o(cyc),		// cyc_ole valid
	.ack_i(ack),			// bus transfer complete
	.ird_o(),		// instruction read cyc_ole
	.we_o(we),		// write cycle
	.adr_o(adr),	// address
	.dat_i(dati),		// instruction / data input bus
	.dat_o(dato),	// data output bus
	.soc_nxt_o(),		// start of cyc_ole is next
	.cyc_nxt_o(),		// next cyc_ole will be valid
	.ird_nxt_o(),			// next cyc_ole will be an instruction read
	.we_nxt_o(),			// next cyc_ole will be a we_oite
	.adr_nxt_o(),	// address for next cyc_ole
	.dat_nxt_o()	// data output for next cyc_ole
);

endmodule
