module ClkgenTop(sysclk, ph2, rw, vda, ad, ba, TxD, RxD, cts, rts, uart_txd_in, uart_rxd_out, ckmul, wsq, irq, vreset, vprog, aud);
input sysclk;
input ph2;
input rw;
input vda;
input [12:0] ad;
inout tri [7:0] ba;
output TxD;
input RxD;
input cts;
output rts;
output reg [7:0] ckmul;
input uart_txd_in;
output uart_rxd_out;
output [3:0] wsq;
output irq;
output vreset;
output vprog;
output aud;

reg [23:0] adr;
wire clk50, clk100;
wire locked;
reg [7:0] ba100;

(* ram_style="block" *)
reg [7:0] waveTable0L [0:4095];
(* ram_style="block" *)
reg [3:0] waveTable0H [0:4095];
(* ram_style="block" *)
reg [7:0] waveTable1L [0:4095];
(* ram_style="block" *)
reg [3:0] waveTable1H [0:4095];
(* ram_style="block" *)
reg [7:0] waveTable2L [0:4095];
(* ram_style="block" *)
reg [3:0] waveTable2H [0:4095];
(* ram_style="block" *)
reg [7:0] waveTable3L [0:4095];
(* ram_style="block" *)
reg [3:0] waveTable3H [0:4095];

reg [23:0] rstcnt = 24'h0;
always_ff @(posedge sysclk)
	rstcnt <= rstcnt + 2'd1;
wire xrst = ~rstcnt[15];

ClkgenClkwiz ucw1
(
  // Clock out ports
  .clk100(clk100),
  .clk50(clk50),
  // Status and control signals
  .reset(xrst),
  .locked(locked),
 // Clock in ports
  .sysclk(sysclk)
);

wire rst = !locked;

always_ff @(posedge clk100)
if (~ph2)
	ba100 <= ba;
wire csWvtbl0L = ba100==8'hD8 && vda && ~ad[0];
wire csWvtbl0H = ba100==8'hD8 && vda &&  ad[0];
wire csWvtbl1L = ba100==8'hD9 && vda && ~ad[0];
wire csWvtbl1H = ba100==8'hD9 && vda &&  ad[0];
wire csWvtbl2L = ba100==8'hDA && vda && ~ad[0];
wire csWvtbl2H = ba100==8'hDA && vda &&  ad[0];
wire csWvtbl3L = ba100==8'hDB && vda && ~ad[0];
wire csWvtbl3H = ba100==8'hDB && vda &&  ad[0];
wire cs6551a = ba100==8'hDF && vda && ad[12:5]==8'h00;		// $DF0000
wire cs6551b = ba100==8'hDF && vda && ad[12:5]==8'h01;		// $DF0020
wire csWsq   = ba100==8'hDF && vda && ad[12:8]==5'h01;		// $DF01xx
wire csPSG	 = ba100==8'hDF && vda && ad[12:9]==4'h1;			// $DF0200 to $DF03FF
wire csCkmul = ba100==8'hDF && vda && ad[12:0]==13'h1FFF;	// $DFFFFF

wire irqa, irqb;
wire [7:0] baoa, baob, psgo;
wire [17:0] psgdaco;
assign ba = (cs6551a & rw) ? baoa : 8'bz;
assign ba = (cs6551b & rw) ? baob : 8'bz;
assign ba = (csCkmul & rw) ? ckmul : 8'bz;
assign ba = (csPSG & rw) ? psgo : 8'bz;
assign irq = ~(irqa|irqb);
assign vreset = 1'b1;
assign vprog = 1'b1;

// 
always_ff @(negedge ph2)
	if (csWvtbl0L & ~rw)
		waveTable0L[ad[12:1]][7:0] <= ba;
always_ff @(negedge ph2)
	if (csWvtbl0H & ~rw)
		waveTable0H[ad[12:1]][3:0] <= ba;
always_ff @(negedge ph2)
	if (csWvtbl1L & ~rw)
		waveTable1L[ad[12:1]][7:0] <= ba;
always_ff @(negedge ph2)
	if (csWvtbl1H & ~rw)
		waveTable1H[ad[12:1]][3:0] <= ba;
always_ff @(negedge ph2)
	if (csWvtbl2L & ~rw)
		waveTable2L[ad[12:1]][7:0] <= ba;
always_ff @(negedge ph2)
	if (csWvtbl2H & ~rw)
		waveTable2H[ad[12:1]][3:0] <= ba;
always_ff @(negedge ph2)
	if (csWvtbl3L & ~rw)
		waveTable3L[ad[12:1]][7:0] <= ba;
always_ff @(negedge ph2)
	if (csWvtbl3H & ~rw)
		waveTable3H[ad[12:1]][3:0] <= ba;
reg [12:0] wta;
always_ff @(posedge ph2)
	wta <= ad;
assign ba = (csWvtbl0L & rw) ? waveTable0L[wta[12:1]][7:0] : 8'bz;
assign ba = (csWvtbl0H & rw) ? {4'h0,waveTable0H[wta[12:1]][3:0]} : 8'bz;
assign ba = (csWvtbl1L & rw) ? waveTable1L[wta[12:1]][7:0] : 8'bz;
assign ba = (csWvtbl1H & rw) ? {4'h0,waveTable1H[wta[12:1]][3:0]} : 8'bz;
assign ba = (csWvtbl2L & rw) ? waveTable2L[wta[12:1]][7:0] : 8'bz;
assign ba = (csWvtbl2H & rw) ? {4'h0,waveTable2H[wta[12:1]][3:0]} : 8'bz;
assign ba = (csWvtbl3L & rw) ? waveTable3L[wta[12:1]][7:0] : 8'bz;
assign ba = (csWvtbl3H & rw) ? {4'h0,waveTable3H[wta[12:1]][3:0]} : 8'bz;

uart6551sbi uuart1
(
	.rst_i(rst),
	.refclk_i(clk50),
	.ph2_i(ph2),
	.cs_i(cs6551a),
	.irq_o(irqa),
	.rw_i(rw),
	.adr_i(ad[4:0]),
	.dat_i(ba),
	.dat_o(baoa),
	.cts_ni(1'b0),
	.rts_no(),
	.dsr_ni(1'b0),
	.dcd_ni(1'b0),
	.dtr_no(),
	.ri_ni(1'b0),
	.rxd_i(uart_txd_in),
	.txd_o(uart_rxd_out),
	.data_present(),
	.rxDRQ_o(),
	.txDRQ_o(),
	.xclk_i(1'b0),
	.RxC_i(1'b0)
);

// Keyboard / Mouse interface
uart6551sbi uuart2
(
	.rst_i(rst),
	.refclk_i(clk50),
	.ph2_i(ph2),
	.cs_i(cs6551b),
	.irq_o(irqb),
	.rw_i(rw),
	.adr_i(ad[4:0]),
	.dat_i(ba),
	.dat_o(baob),
	.cts_ni(cts),
	.rts_no(rts),
	.dsr_ni(1'b0),
	.dcd_ni(1'b0),
	.dtr_no(),
	.ri_ni(1'b0),
	.rxd_i(RxD),
	.txd_o(TxD),
	.data_present(),
	.rxDRQ_o(),
	.txDRQ_o(),
	.xclk_i(1'b0),
	.RxC_i(1'b0)
);

// clock multiplier reg
always_ff @(negedge ph2)
	if (csCkmul & ~rw)
		ckmul <= ba;

// clock stretching parameters
reg [7:0] hiloClocks [0:255];
assign wsq = (ba100[7:4] == 4'hD) ? (ph2 ? hiloClocks[{ba100[3:0],3'b0,ad[12]}][3:0] : hiloClocks[{ba100[3:0],3'b0,ad[12]}][7:4]) : 4'hF;
always_ff @(negedge ph2)
	if (csWsq & ~rw)
		hiloClocks[ad[7:0]] <= ba;
assign ba = (csWsq & rw) ? hiloClocks[ad[7:0]] : 8'bz;

wire [13:0] psgwta;
reg [13:0] wta2;
reg [11:0] psgwtd0, psgwtd1, psgwtd2, psgwtd3, psgwtd;
always_ff @(posedge clk50)
	wta2 <= psgwta;
always_ff @(posedge clk50)
	psgwtd0 <= {waveTable0H[wta2[11:0]],waveTable0L[wta2[11:0]]};
always_ff @(posedge clk50)
	psgwtd1 <= {waveTable1H[wta2[11:0]],waveTable1L[wta2[11:0]]};
always_ff @(posedge clk50)
	psgwtd2 <= {waveTable2H[wta2[11:0]],waveTable2L[wta2[11:0]]};
always_ff @(posedge clk50)
	psgwtd3 <= {waveTable3H[wta2[11:0]],waveTable3L[wta2[11:0]]};
always_ff @(posedge clk50)
	case(wta2[13:12])
	2'b00:	psgwtd <= psgwtd0;
	2'b01:	psgwtd <= psgwtd1;
	2'b10:	psgwtd <= psgwtd2;
	2'b11:	psgwtd <= psgwtd3;
	endcase

PSG8 upsg1
(
	.rst_i(rst),
	.ph2(ph2),
	.clk50_i(clk50),
	.cs_i(csPSG),
	.rw_i(rw),
	.adr_i(ad[8:0]),
	.dat_i(ba),
	.dat_o(psgo),
	.m_adr_o(psgwta),
	.m_dat_i(psgwtd),
	.o(psgdaco)
);

PSGPWMDac udac1
(
	.rst(rst),
	.clk(clk100),
	.i(psgdaco[17:6]),
	.o(aud)
);

endmodule