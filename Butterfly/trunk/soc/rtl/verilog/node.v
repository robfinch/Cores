
module node(id, rst_i, clk_i, rxdX, txdX, rxdY, txdY, cyc, stb, ack, we, adr, dati, dato);
input [7:0] id;
input rst_i;
input clk_i;
input rxdX;
input rxdY;
output txdX;
output txdY;
output cyc;
output stb;
input ack;
output we;
output [15:0] adr;
input [7:0] dati;
output [7:0] dato;

wire [7:0] uxDato,uyDato;
wire uxAck,uyAck;
wire brAck;
wire ramAck;

wire cs_rom = adr[15:14]==2'b11 && cyc && stb;
wire cs_ram = adr[15:12]==4'h0 && cyc && stb; 
wire uxCs = adr[15:4]==12'hB00;
wire uyCs = adr[15:4]==12'hB01;

wire [7:0] romo,ramo;
reg [7:0] rommem [0:16383];
reg [15:0] radr;
always @(posedge clk_i)
    radr <= adr;
assign romo = rommem[radr];
initial begin
$readmemh("C:\\Cores4\\Butterfly\\trunk\\software\\bfasm\\debug\\noc_boot.mem",rommem);
end
reg romrdy,ramrdy1,ramrdy2;
always @(posedge clk_i)
    romrdy <= cs_rom;
always @(posedge clk_i)
    ramrdy1 <= cs_ram;
always @(posedge clk_i)
    ramrdy2 <= ramrdy1 & cs_ram;
assign brAck = cs_rom ? romrdy : 1'b0;
assign ramAck = cs_ram ? ramrdy2 : 1'b0;

node_ram uram1 (
  .clka(clk_i),   // input wire clka
  .ena(cs_ram),   // input wire ena
  .wea(we),      // input wire [0 : 0] wea
  .addra(adr[11:0]),  // input wire [11 : 0] addra
  .dina(dato),    // input wire [7 : 0] dina
  .douta(ramo)  // output wire [7 : 0] douta
);

bcSimpleUart uX
(
	// WISHBONE Slave interface
	.rst_i(rst_i),		// reset
	.clk_i(clk_i),		// eg 100.7MHz
	.cs_i(uxCs),
	.cyc_i(cyc),		// cycle valid
	.stb_i(stb),		// strobe
	.we_i(we),			// 1 = write
	.adr_i(adr[3:0]),		// register address
	.dat_i(dato),		// data input bus
	.dat_o(uxDato),	// data output bus
	.ack_o(uxAck),		// transfer acknowledge
	.vol_o(),		// volatile register selected
	.irq_o(),		// interrupt request
	//----------------
	.cts_ni(1'b0),		// clear to send - active low - (flow control)
	.rts_no(),	// request to send - active low - (flow control)
	.dsr_ni(1'b0),		// data set ready - active low
	.dcd_ni(1'b0),		// data carrier detect - active low
	.dtr_no(),	// data terminal ready - active low
	.rxd_i(rxdX),			// serial data in
	.txd_o(txdX),			// serial data out
	.data_present_o()
);

bcSimpleUart uY
(
	// WISHBONE Slave interface
	.rst_i(rst_i),		// reset
	.clk_i(clk_i),		// eg 100.7MHz
	.cs_i(uyCs),
	.cyc_i(cyc),		// cycle valid
	.stb_i(stb),		// strobe
	.we_i(we),			// 1 = write
	.adr_i(adr[3:0]),		// register address
	.dat_i(dato),		// data input bus
	.dat_o(uyDato),	// data output bus
	.ack_o(uyAck),		// transfer acknowledge
	.vol_o(),		// volatile register selected
	.irq_o(),		// interrupt request
	//----------------
	.cts_ni(1'b0),		// clear to send - active low - (flow control)
	.rts_no(),	// request to send - active low - (flow control)
	.dsr_ni(1'b0),		// data set ready - active low
	.dcd_ni(1'b0),		// data carrier detect - active low
	.dtr_no(),	// data terminal ready - active low
	.rxd_i(rxdY),			// serial data in
	.txd_o(txdY),			// serial data out
	.data_present_o()
);

wire iack = uxAck|uyAck|brAck|ramAck|ack; 
reg [7:0] idati;

always @*
casex({cs_rom,cs_ram,uxCs,uyCs})
4'b1xxx:    idati <= romo;
4'b01xx:    idati <= ramo;
4'b001x:    idati <= uxDato;
4'b0001:    idati <= uyDato;
default:    idati <= dati;
endcase

Butterfly16 ucpu1
(
	.id(id),		// cpu id (which cpu am I?)
	.nmi(1'b0),			// non-maskable interrupt
	.irq(1'b0),			// irq inputs
	.go(1'b1),			// exit stop state if active
	// Bus master interface
	.rst_i(rst_i),			// reset
	.clk_i(clk_i),			// clock
	.soc_o(),		// start of cyc_ole
	.cyc_o(cyc),		// cyc_ole valid
	.ack_i(iack),			// bus transfer complete
	.ird_o(),		// instruction read cyc_ole
	.we_o(we),		// write cycle
	.adr_o(adr),	// address
	.dat_i(idati),		// instruction / data input bus
	.dat_o(dato),	// data output bus
	.soc_nxt_o(),		// start of cyc_ole is next
	.cyc_nxt_o(),		// next cyc_ole will be valid
	.ird_nxt_o(),			// next cyc_ole will be an instruction read
	.we_nxt_o(),			// next cyc_ole will be a we_oite
	.adr_nxt_o(),	// address for next cyc_ole
	.dat_nxt_o()	// data output for next cyc_ole
);

assign stb = cyc;

endmodule

