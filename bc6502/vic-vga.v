/* ===============================================================
	(C) 2001 Bird Computer
	All rights reserved.

		Please read the licensing agreement contained in the
	document file (vic.doc). Use of this file is subject to the
	license agreement. However, the license says you can do
	basically whatever you want with the source provided it is
	not included in a commercial product.

	VIC
		VGA Video Interface Circuit with the following features:
		- 32x24 text mode display
		- programmable display area
		- programmable border area
		- raster and vertical blank interrupts

	VIC assumes a base clock frequency of 25.175Mhz for timing
	generation. Base timings are NOT programmatically
	controllable.

	Reg
	0	video base address lo
		aaaaaaaa
	1	video bas address hi
		aaaaaaaa
	2	resolution control
		vvvv xhhh
		hres		vres		
		000 = 640	000 = 480
		001 = 320	001 = 240
		010 = 213	010 = 160
		011 = 160	011 = 120
		100 = 128	100	= 96
		101 = 106	101 = 80	
		110 = 91	110 = 68	
		111 = 80	111 = 60
				   1111 = 30

	3	color depth
		xxxx xxcc
			cc  (bits per pixel)
			00 = 1
			01 = 2
			10 = 4
			11 = 8
			
	4	raster compare lo
		rrrrrrrr
	5 	raster compare hi
		xxxxxx rr
	6	irq enable
		xxxxxx r v
	7	irq status / reset
		g xxxxx r v
	8	border color
		xx cccccc

	16	horizontal display on lo
		oooooooo
	17  horizontal display on hi
		xxxxxx oo
	18	horizontal display off lo
		ffffffff
	19	horizontal display off hi
		xxxxxx ff

	9	horizontal border off/on
		xxxxxx ffffffffff xxxxxx oooooooooo
*	10	horizontal total
		xxxxxxxx xxxxxxxx xxxxx nnnnnnnnnnn
	12	vertical display off/on
		xxxxxx ffffffffff xxxxxx oooooooooo
	13	vertical border off/on
		xxxxxx ffffffffff xxxxxx oooooooooo
*	14	vertical total
		xxxxxxxx xxxxxxxx xxxxxx nnnnnnnnnn
		
	28  horizontal total low
		nnnnnnnn
	28  vertical border on
		nnnnnnnn
	30  vertical total low
		nnnnnnnn

	256-288		palette registers			xxxxxxxxxx cccccc
--------------------------------------------------------------- */
module vic_text(reset, clk, ce25, cs, rw, rs, d, cdin, scrin,
	ce50, va, cra,
	irq, hSync, vSync, vdo);
	parameter ABW = 15;
	parameter DBW = 31;
	// these parameters for a 12.5875MHz clock
	parameter phTotal = 10'd799;//10'd399; //10'd799;
	parameter phSyncOn = 10'd658;//10'd329;//10'd658;
	parameter phSyncOff = 10'd754;//10'd377;//10'd754;
	parameter phBlankOn = 10'd639;//10'd319;//10'd639;
	parameter phBlankOff = 10'd799;//10'd399;//10'd799;
	parameter pvTotal = 10'd524;
	parameter pvSyncOn = 10'd493;
	parameter pvSyncOff = 10'd494;
	parameter pvBlankOn = 10'd479;
	parameter pvBlankOff = 10'd524;

	input reset;
	input clk;			// 100.7MHz
	input ce25;			// 25.175MHz (50%)
	input cs;			// chip select (active high)
	input rw;			// read / write
	input [8:0] rs;		// register select
	inout [7:0] d;
	tri [7:0] d;
	input [7:0] cdin;	// char (bitmap) data in
	input [7:0] scrin;	// screen data in
	input ce50;			// 50.35MHz
	output [ABW:0] va;	// video address
	reg [ABW:0] va;
	output [8:0] cra;	// charram address
	reg [8:0] cra;
	output irq;			// interrupt request (active high)
	output hSync, vSync;	// active low
	reg hSync, vSync;
	output [5:0] vdo;	// video data output
	reg [5:0] vdo;

	// Internal registers and signals
	reg [9:0]	hctr, vctr;
	reg hDisplay, vDisplay;
	// synchronizing register
	reg [7:0] din;
	reg [7:0] gdin, gdin1;	// for graphics
	reg [1:0] color;
	// display enable compare registers
	reg [9:0] hDisplayOnC;
	reg [9:0] hDisplayOffC;
	reg [9:0] vDisplayOnC;
	reg [9:0] vDisplayOffC;
	reg [9:0] hBorderOnC;
	reg [9:0] hBorderOffC;
	reg [9:0] vBorderOnC;
	reg [9:0] vBorderOffC;
	reg [5:0] BorderColor;

	wire hReset		= hctr == phTotal;	// 800
	wire hSyncOn	= hctr == phSyncOn;
	wire hSyncOff	= hctr == phSyncOff;
	wire hBlankOn	= hctr == phBlankOn;
	wire hBlankOff	= hctr == phBlankOff;
	wire hBorderOn	= hctr == hBorderOnC;
	wire hBorderOff	= hctr == hBorderOffC;
	wire hDisplayOn	= hctr == hDisplayOnC;
	wire hDisplayOff= hctr == hDisplayOffC;
	wire vReset		= vctr == pvTotal;	// 525
	wire vDisplayOn	= vctr == vDisplayOnC;
	wire vDisplayOff= vctr == vDisplayOffC;
	wire vSyncOn	= vctr == pvSyncOn;
	wire vSyncOff	= vctr == pvSyncOff;
	wire vBlankOn	= vctr == pvBlankOn;
	wire vBlankOff	= vctr == pvBlankOff;
	wire vBorderOn	= vctr == vBorderOnC;
	wire vBorderOff	= vctr == vBorderOffC;

	reg vBlank, hBlank;
	reg hBorder, vBorder;
	reg [7:0] vsr;			// video shift register
	reg [2:0] pt;			// pixel toggle (for clk divide)
	reg [3:0] vrt;			// vertical row toggle
	reg [2:0] bc;			// bit counter
	reg [ABW:0] vba;		// video base address
	reg [1:0] cd;			// color depth
	reg [2:0] hres;			// pixel clock frequency select
	reg [3:0] vres;			// vertical resolution
	reg [ABW:0] vab;			// video address rescan buffer
	reg vbie;				// vertical blank interrupt enable
	reg rie;				// raster interrupt enable
	reg vbi_ff;				// vertical blank interrupt flip flop
	reg ri_ff;				// raster interrupt flip flop
	reg [9:0] rc;			// raster compare register
	assign irq = ((vbie & vbi_ff) | (rie & ri_ff));
	reg [7:0] d0, d1, d2, d3, d4, d5, d6;

	// read registers
	// mux'd to reduces tbuf usage
	always @(rs or vba or vres or hres or cd) begin
		case (rs[1:0])
		0:	d0 <= vba[7:0];
		1:	d0 <= vba[15:8];
		2:	d0 <= {vres,1'b0,hres};
		3:	d0 <= {6'b0,cd};
		endcase
	end
	always @(rs or rie or vbie or vbi_ff or ri_ff or rc or
		BorderColor) begin
		case (rs[1:0])
		0: 	d1 <= {rc[7:0]};
		1:	d1 <= {6'b0,rc[9:8]};
		2:	d1 <= {6'b0,rie,vbie};
		3:	d1 <= {(vbi_ff|ri_ff),5'b0,ri_ff,vbi_ff};
		endcase
	end
	always @(BorderColor) begin
		d2 <= {2'b0,BorderColor};
	end
	always @(rs or hDisplayOffC or hDisplayOnC) begin
		case (rs[0])
		0:	d3 <= hDisplayOnC[7:0];
		1:	d3 <= {6'b0,hDisplayOnC[9:8]};
		2:	d3 <= hDisplayOffC[7:0];
		1:	d3 <= {6'b0,hDisplayOffC[9:8]};
		endcase
	end
	always @(rs or hBorderOffC or hBorderOnC) begin
		case (rs[0])
		0:	d4 <= hBorderOnC[7:0];
		1:	d4 <= {6'b0,hBorderOnC[9:8]};
		2:	d4 <= hBorderOffC[7:0];
		1:	d4 <= {6'b0,hBorderOffC[9:8]};
		endcase
	end
	always @(rs or vDisplayOffC or vDisplayOnC) begin
		case (rs[0])
		0:	d5 <= vDisplayOnC[7:0];
		1:	d5 <= {6'b0,vDisplayOnC[9:8]};
		2:	d5 <= vDisplayOffC[7:0];
		1:	d5 <= {6'b0,vDisplayOffC[9:8]};
		endcase
	end
	always @(rs or vBorderOffC or vBorderOnC) begin
		case (rs[0])
		0:	d6 <= vBorderOnC[7:0];
		1:	d6 <= {6'b0,vBorderOnC[9:8]};
		2:	d6 <= vBorderOffC[7:0];
		1:	d6 <= {6'b0,vBorderOffC[9:8]};
		endcase
	end

	assign d = (cs & rw && (rs[6:0]==7'd0)) ? d0 : 8'bz;
	assign d = (cs & rw && (rs[6:0]==7'd1)) ? d1 : 8'bz;
	assign d = (cs & rw && (rs[6:0]==7'd2)) ? d2 : 8'bz;
	assign d = (cs & rw && (rs[6:0]==7'd3)) ? d3 : 8'bz;
	assign d = (cs & rw && (rs[6:0]==7'd4)) ? d4 : 8'bz;
	assign d = (cs & rw && (rs[6:0]==7'd5)) ? d5 : 8'bz;
	assign d = (cs & rw && (rs[6:0]==7'd6)) ? d6 : 8'bz;

	always @(posedge clk) begin
		if (reset) begin
			vctr <= 0;
			hctr <= 0;
			vSync <= 1;
			hSync <= 1;
			vBlank <= 1;
			hBlank <= 1;
			cra <= 9'h000;
			vba <= 16'hC000;
			vab <= 16'hC000;
			vbie <= 0;
			rie <= 0;
			vbi_ff <= 0;
			ri_ff <= 0;
			cd <= 3;
			rc <= 10'h3ff;
			pt <= 0;
			vrt <= 4'b0;
			bc <= 3'b0;
			hres <= 3'b001;
			vres <= 4'b1111;
			vsr <= 8'h0;
			din <= 8'h0;
			gdin <= 8'h00;
			gdin1 <= 8'h00;
			hDisplayOnC <= 10'd47;//10'd7;//10'd47;	// 759+64
			hDisplayOffC <= 10'd559;//10'd263;//10'd559;// 599-64
			hBorderOnC <= 10'd575;//10'd287;//10'd575;	// 639-64
			hBorderOffC <= 10'd63;//10'd32;//10'd63;	// 799+64
			vDisplayOnC <= 10'd48;//pvTotal;
			vDisplayOffC <= 10'd432;//10'd479;
			vBorderOnC <= 10'd431;//479-48
			vBorderOffC <= 10'd47;//524+48;
			BorderColor <= 6'h30;
			hDisplay <= 1'b0;
			vDisplay <= 1'b0;
		end
		else begin

			if (ce50) begin

				// write registers
				if (cs & ~rw) begin
					case (rs)
					0: 	vba[7:0] <= d;
					1:	vba[15:8] <= d;
					2: 	begin
						hres <= d[2:0];
						vres <= d[7:4];
						end
					3: 	begin
						hres <= d[2:0];
						vres <= d[7:4];
						end
					4:	rc[7:0] <= d[7:0];
					5:	rc[9:8] <= d[1:0];
					6:	begin
						vbie <= d[0];
						rie <= d[1];
						end
					7:	begin
						vbi_ff <= d[0];
						ri_ff <= d[1];
						end
					8:	BorderColor <= d[5:0];
					16:	hDisplayOnC[7:0] <= d[7:0];
					17:	hDisplayOnC[9:8] <= d[1:0];
					18:	hDisplayOffC[7:0] <= d[7:0];
					19:	hDisplayOffC[9:8] <= d[1:0];
					20:	hBorderOnC[7:0] <= d[7:0];
					21:	hBorderOnC[9:8] <= d[1:0];
					22:	hBorderOffC[7:0] <= d[7:0];
					23:	hBorderOffC[9:8] <= d[1:0];
					24:	vDisplayOnC[7:0] <= d[7:0];
					25:	vDisplayOnC[9:8] <= d[1:0];
					26:	vDisplayOffC[7:0] <= d[7:0];
					27:	vDisplayOffC[9:8] <= d[1:0];
					28:	vBorderOnC[7:0] <= d[7:0];
					29:	vBorderOnC[9:8] <= d[1:0];
					30:	vBorderOffC[7:0] <= d[7:0];
					31:	vBorderOffC[9:8] <= d[1:0];
					default:
						;
					endcase
				end
			end

			if (ce25) begin

				// Clock timing counters. This controls basic
				// horizontal and vertical timing including
				// sync, blanking and borders
				if (hReset) begin
					hctr <= 0;
					if (vReset)
						vctr <= 0;
					else
						vctr <= vctr + 1;
	
					if (vctr==rc)
						ri_ff <= rie;
	
					if (vSyncOn) vSync <= 0;
					if (vSyncOff) vSync <= 1;
					if (vBlankOn) vBlank <= 1;
					if (vBlankOff) vBlank <= 0;
					if (vBorderOn) vBorder <= 1;
					if (vBorderOff) vBorder <= 0;
				end
				else
					hctr <= hctr + 1;
	
				if (hSyncOn) hSync <= 0;
				if (hSyncOff) hSync <= 1;
				if (hBlankOff) hBlank <= 0;
				if (hBlankOn) hBlank <= 1;
				if (hBorderOn) hBorder <= 1;
				if (hBorderOff) hBorder <= 0;
	
				// The video address at the start of the previous
				// scan line is reloaded into the address counter
				// for vertical resolution division.
				if (hDisplayOn) begin
					pt <= hres;
					bc <= 0;
					hDisplay <= 1;
					if (vDisplayOn) begin
						vrt <= 0;
						vDisplay <= 1;
						va <= vba;
						vab <= vba;
					end
					if (vDisplayOff) begin
						vDisplay <= 0;
						vbi_ff <= vbie;
					end
					if (vDisplay) begin
						if (vrt == vres) begin
							vrt <= 0;
							vab <= va;
						end
						else begin
							vrt <= vrt + 1;
							va <= vab;
						end
					end
				end
				if (hDisplayOff) begin
					hDisplay <= 0;
				end
	
				if (hDisplay & vDisplay) begin
					if (pt==hres) begin
						pt <= 0;
						// increment bit counter
						bc <= bc + 1;
	
						// load
						if (bc==7) begin
							va <= va + 1;
							// initiate memory request for next
							// pixel latch in current pixel
							vsr <= din;	// load vsr from prev.
							color <= gdin[7:6];
						end
						// shift
						else
							vsr <= {1'b0,vsr[7:1]};
						// capture character number from screen and
						// use to generate bitmap address
						if (bc==0) begin
							cra <= {scrin[5:0],vctr[3:1]};
							gdin1 <= scrin;
						end
						// get char bit pattern
						if (bc==1) begin
							din <= cdin;
							gdin <= gdin1;
//							case(gdin[7:6])
//							2'd0:	din <= cdin;
//							2'd1:	din <= vctr[3] ?
//								{{4{gdin[3]}},{4{gdin[2]}}} :
//								{{4{gdin[1]}},{4{gdin[0]}}};
//							2'd2,2'd3:	din <= ~cdin;
//							endcase
						end
					end
					else
						pt <= pt + 1;
				end
				// shift out any remaining pixel data
				// at the pixel rate
				else begin
					if (pt==hres) begin
						bc <= bc + 1;
						// load
						if (bc==7) begin
//							va <= va + 1;
							// initiate memory request for next
							// pixel latch in current pixel
							vsr <= din;	// load vsr from prev.
							color <= gdin[7:6];
						end
						else
							vsr <= {1'b0,vsr[7:1]};
						if (bc==1) begin
							din <= cdin;
							gdin <= gdin1;
						end
						// capture character number from screen and
						// use to generate bitmap address
						if (bc==0) begin
							cra <= {scrin[5:0],vctr[3:1]};
							gdin1 <= scrin;
						end
						// get char bit pattern
						if (bc==1) begin
							din <= cdin;
							gdin <= gdin1;
//							case(gdin[7:6])
//							2'd0:	din <= cdin;
//							2'd1:	din <= vctr[3] ?
//								{{4{gdin[3]}},{4{gdin[2]}}} :
//								{{4{gdin[1]}},{4{gdin[0]}}};
//							2'd2,2'd3:	din <= ~cdin;
//							endcase
						end
						pt <= 0;
					end
					else
						pt <= pt + 1;
				end
				vdo <= (hBlank | vBlank) ? 6'b0 :
					(hBorder | vBorder) ? BorderColor :
					vsr[0] ? {2'b11,color[1],color[1],color[0],color[0]} : 6'h00;
			end
		end
	end

endmodule


module ram32x6s(clk, wr, a, di, do);
	input clk;
	input wr;
	input [4:0] a;
	input [5:0] di;
	output [5:0] do;

	reg [5:0] ram [31:0];

	always @(posedge clk) begin
		if (wr)
			ram[a] <= di;
	end

	assign do = ram[a];

endmodule
