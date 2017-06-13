
module node(rst_i, clk_i, rxdX, txdX, rxdY, txdY, cyc, stb, ack, we, adr, dati, dato);
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
parameter ID = 8'h11;

wire [7:0] uxDato,uyDato,rout_dato;
wire uxAck,uyAck,rout_ack;
wire brAck;
wire ramAck;

wire cs_rom;
wire cs_ram = adr[15:13]==3'h0 && cyc && stb; 
wire routCs = adr[15:8]==8'hB0;
//wire uxCs = adr[15:4]==12'hB00;
//wire uyCs = adr[15:4]==12'hB01;

wire [7:0] romo,ramo;
reg [15:0] radr;
always @(posedge clk_i)
    radr <= adr;
generate begin
if (ID==8'h11 || ID==8'h42) begin
assign cs_rom = adr[15:14]==2'b11 && cyc && stb;
reg [7:0] rommem [0:16383];
assign romo = rommem[radr[13:0]];
initial begin
    $readmemh("C:\\Cores4\\Butterfly\\trunk\\software\\bfasm\\debug\\noc_boot11.mem",rommem);
end
end
else begin
assign cs_rom = adr[15:13]==3'b111 && cyc && stb;
reg [7:0] rommem [0:8191];
assign romo = rommem[radr[12:0]];
if (ID==8'h21)
initial begin
    $readmemh("C:\\Cores4\\Butterfly\\trunk\\software\\bfasm\\debug\\noc_boot21.mem",rommem);
end
else
initial begin
    $readmemh("C:\\Cores4\\Butterfly\\trunk\\software\\bfasm\\debug\\noc_boot.mem",rommem);
end
end
end
endgenerate

node_ramXX uram1 (
  .clka(clk_i),   // input wire clka
  .ena(cs_ram),   // input wire ena
  .wea(we),      // input wire [0 : 0] wea
  .addra(adr[12:0]),  // input wire [11 : 0] addra
  .dina(dato),    // input wire [7 : 0] dina
  .douta(ramo)  // output wire [7 : 0] douta
);

reg romrdy,ramrdy1,ramrdy2;
always @(posedge clk_i)
    romrdy <= cs_rom;
always @(posedge clk_i)
    ramrdy1 <= cs_ram;
always @(posedge clk_i)
    ramrdy2 <= ramrdy1 & cs_ram;
assign brAck = cs_rom ? romrdy : 1'b0;
assign ramAck = cs_ram ? ramrdy2 : 1'b0;

routerTop urout1
(
    .X(ID[7:4]),
    .Y(ID[3:0]),
    .rst_i(rst_i),
    .clk_i(clk_i),
    .cs_i(routCs),
    .cyc_i(cyc),
    .stb_i(stb),
    .ack_o(rout_ack),
    .we_i(we),
    .adr_i(adr[4:0]),
    .dat_i(dato),
    .dat_o(rout_dato),
    .rxdX(rxdX),
    .rxdY(rxdY),
    .txdX(txdX),
    .txdY(txdY)
);
/*
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
*/
wire iack = rout_ack|brAck|ramAck|ack; 
reg [7:0] idati;

always @*
casex({cs_rom,cs_ram,routCs})
3'b1xx:    idati <= romo;
3'b01x:    idati <= ramo;
3'b001:    idati <= rout_dato;
default:   idati <= dati;
endcase

Butterfly16 ucpu1
(
	.id(ID),		// cpu id (which cpu am I?)
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

