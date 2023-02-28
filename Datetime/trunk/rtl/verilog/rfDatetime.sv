`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2007-2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//                                                                          
//
// ============================================================================
//
//
//	BCD representations are used
//	- BCD allows direct visual indication of values without
//	needing to convert hexidecimal values
//
//
//	Reg
//		
//	0	DT - Date/Time register
//		[ 7: 0]	read / write jiffies
//	    [15: 8] read / write seconds
//	    [23:16] read / write minutes
//      [31:24] read / write hours
//  1
//		[7:0] read/write day
//		[15:8] read/write month
//		[31:16] read/write year
//	2   ALM - alarm register same format as 0, but contain alarm setting
//  3
//
//  4	CR - control register
//      [ 7: 0] write - which bytes to match for alarm
//      [8] - time of day enable
//      [10: 9] - 00=100 Hz, 01=60Hz, 10=50Hz
//      [16] - mars timekeeping
//
//	5
//		writing this register triggers a snapshot
//		- trigger a snapshot before reading the date / time
//		registers
//		- the snapshot allows the date / time value to be
//		read without having to worry about an update occuring
//		during the read
//		- a copy of the current date and time is stored in
//		the output registers
//
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|WISHBONE Datasheet
//	|WISHBONE SoC Architecture Specification, Revision B.3
//	|
//	|Description:						Specifications:
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|General Description:				Date/Time keeping core
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|Supported Cycles:					SLAVE,READ/WRITE
//	|									SLAVE,BLOCK READ/WRITE
//	|									SLAVE,RMW
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|Data port, size:					32 bit
//	|Data port, granularity:			32 bit
//	|Data port, maximum operand size:	32 bit
//	|Data transfer ordering:			Undefined
//	|Data transfer sequencing:			Undefined
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|Clock frequency constraints:		tod clock must be 50,60, or 100 Hz
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|Supported signal list and			Signal Name		WISHBONE equiv.
//	|cross reference to equivalent		ack_o				ACK_O
//	|WISHBONE signals					adr_i(33:0)			ADR_I()
//	|									clk_i				CLK_I
//	|									dat_i(15:0)			DAT_I()
//	|									dat_o(15:0)			DAT_O()
//	|									cyc_i				CYC_I
//	|									stb_i				STB_I
//	|									we_i				WE_I
//	|
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|Special requirements:
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//
// 302 LUTs / 324 FFs
//=============================================================================
//
module rfDatetime
(
// Syscon
input rst_i,		// reset
input clk_i,		// system clock

// Circuit selects
input cs_config_i,
input cs_io_i,

// System bus
input cyc_i,		// valid bus cycle
input stb_i,		// data transfer strobe
output ack_o,		// transfer acknowledge
input we_i,			// 1=write
input [3:0] sel_i,	// byte select
input [31:0] adr_i,	// address
input [31:0] dat_i,	// data input
output reg [31:0] dat_o,	// data output

input tod,			// tod pulse (eg 60 Hz)
output irq_o		// alarm match
);
parameter MARS_TIME = 1'b0;
parameter IO_ADDR = 32'hFEF30001;
parameter IO_ADDR_MASK = 32'h00FF0000;

parameter CFG_BUS = 8'd0;
parameter CFG_DEVICE = 5'd7;
parameter CFG_FUNC = 3'd0;
parameter CFG_VENDOR_ID	=	16'h0;
parameter CFG_DEVICE_ID	=	16'h0;
parameter CFG_SUBSYSTEM_VENDOR_ID	= 16'h0;
parameter CFG_SUBSYSTEM_ID = 16'h0;
parameter CFG_ROM_ADDR = 32'hFFFFFFF0;

parameter CFG_REVISION_ID = 8'd0;
parameter CFG_PROGIF = 8'd1;
parameter CFG_SUBCLASS = 8'h80;					// 80 = Other (RTC)
parameter CFG_CLASS = 8'h08;						// 08 = Base system controller
parameter CFG_CACHE_LINE_SIZE = 8'd8;		// 32-bit units
parameter CFG_MIN_GRANT = 8'h00;
parameter CFG_MAX_LATENCY = 8'h00;
parameter CFG_IRQ_LINE = 8'd16;

localparam CFG_HEADER_TYPE = 8'h00;			// 00 = a general device

parameter MSIX = 1'b0;

wire cs_rtc;
reg alarm;

// Register inputs
reg [31:0] dati;
reg we;
reg [3:0] sel;
reg [31:0] adr;

always_ff @(posedge clk_i)
	dati <= dat_i;
always_ff @(posedge clk_i)
	adr <= adr_i;
always_ff @(posedge clk_i)
	we <= we_i;
always_ff @(posedge clk_i)
	sel <= sel_i;

wire [31:0] cfg_out;
wire irq_en;

wire cs_config = cs_config_i & cyc_i & stb_i &&
	adr_i[27:20]==CFG_BUS &&
	adr_i[19:15]==CFG_DEVICE &&
	adr_i[14:12]==CFG_FUNC;
wire cs_io = cs_io_i & cyc_i & stb_i & cs_rtc;

pci32_config #(
	.CFG_BUS(CFG_BUS),
	.CFG_DEVICE(CFG_DEVICE),
	.CFG_FUNC(CFG_FUNC),
	.CFG_VENDOR_ID(CFG_VENDOR_ID),
	.CFG_DEVICE_ID(CFG_DEVICE_ID),
	.CFG_BAR0(IO_ADDR),
	.CFG_BAR0_MASK(IO_ADDR_MASK),
	.CFG_SUBSYSTEM_VENDOR_ID(CFG_SUBSYSTEM_VENDOR_ID),
	.CFG_SUBSYSTEM_ID(CFG_SUBSYSTEM_ID),
	.CFG_ROM_ADDR(CFG_ROM_ADDR),
	.CFG_REVISION_ID(CFG_REVISION_ID),
	.CFG_PROGIF(CFG_PROGIF),
	.CFG_SUBCLASS(CFG_SUBCLASS),
	.CFG_CLASS(CFG_CLASS),
	.CFG_CACHE_LINE_SIZE(CFG_CACHE_LINE_SIZE),
	.CFG_MIN_GRANT(CFG_MIN_GRANT),
	.CFG_MAX_LATENCY(CFG_MAX_LATENCY),
	.CFG_IRQ_LINE(CFG_IRQ_LINE)
)
ucfg1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.irq_i(alarm),
	.irq_o(irq_o),
	.cs_config_i(cs_config), 
	.we_i(we),
	.sel_i(sel),
	.adr_i(adr),
	.dat_i(dati),
	.dat_o(cfg_out),
	.cs_bar0_o(cs_rtc),
	.cs_bar1_o(),
	.cs_bar2_o(),
	.irq_en_o(irq_en)
);

reg [1:0] tod_freq;
wire [7:0] max_cnt = tod_freq==2'b00 ? 8'h99 : tod_freq==2'b01 ? 8'h59 : tod_freq==2'b10 ? 8'h49 : 8'h99;
reg tod_en;
reg mars;
reg [1:0] snapshot;
reg snapshotA;

// internal counters
reg [3:0] dayL, dayH;		// 1-99
reg [3:0] monthL, monthH;	// 1-99
reg [3:0] yearN0, yearN1, yearN2, yearN3;	// 
reg [3:0] jiffyL, secL, minL, hourL;
reg [3:0] jiffyH, secH, minH, hourH;

// Leap year detection
reg [7:0] binYear, binCent;
reg leapCentury;
reg leapYear,duckYear;

always_comb
	binYear = {yearN1,3'b0} + {yearN1,1'b0} + yearN0;
always_comb
	binCent = {yearN3,3'b0} + {yearN3,1'b0} + yearN2;
always_comb
	leapCentury = !(binCent[1:0]==2'd0 && yearN1=='d0 && yearN0=='d0);
always_comb
	leapYear = binYear[1:0]==2'd0 && leapCentury;

always_comb
	duckYear = yearN0==4'h1 || yearN0==4'h3 || yearN0==4'h6 || yearN0==4'h8;

// output latches
reg [3:0] dayLo, dayHo;		// 1-99
reg [3:0] monthLo, monthHo;	// 1-99
reg [3:0] yearN0o, yearN1o, yearN2o, yearN3o;	// 
reg [3:0] jiffyLo, secLo, minLo, hourLo;
reg [3:0] jiffyHo, secHo, minHo, hourHo;

// alarm
reg [7:0] alarm_care;
wire [63:0] alarm_carex = {
	{8{alarm_care[7]}},
	{8{alarm_care[6]}},
	{8{alarm_care[5]}},
	{8{alarm_care[4]}},
	{8{alarm_care[3]}},
	{8{alarm_care[2]}},
	{8{alarm_care[1]}},
	{8{alarm_care[0]}}
};
reg [3:0] alm_dayL, alm_dayH;		// 1-99
reg [3:0] alm_monthL, alm_monthH;	// 1-99
reg [3:0] alm_yearN0, alm_yearN1, alm_yearN2, alm_yearN3;	// 
reg [3:0] alm_jiffyL, alm_secL, alm_minL, alm_hourL;
reg [3:0] alm_jiffyH, alm_secH, alm_minH, alm_hourH;

reg [3:0] alm_dayLo, alm_dayHo;		// 1-99
reg [3:0] alm_monthLo, alm_monthHo;	// 1-99
reg [3:0] alm_yearN0o, alm_yearN1o, alm_yearN2o, alm_yearN3o;	// 
reg [3:0] alm_jiffyLo, alm_secLo, alm_minLo, alm_hourLo;
reg [3:0] alm_jiffyHo, alm_secHo, alm_minHo, alm_hourHo;

// update detects
wire incJiffyH = jiffyL == 4'd9;
wire incSecL = {jiffyH,jiffyL}==max_cnt;
wire incSecH = incSecL && secL==4'h9;
wire incMinL = incSecH && secH==4'h5;
wire incMinH = incMinL && minL==4'h9;
wire incHourL = incMinH && minH==4'h5;
wire incHourH = incHourL && hourL==4'h9;

wire incDayL    = mars ?
					{hourH,hourL,minH,minL,secH,secL,jiffyH,jiffyL} == {24'h243721,max_cnt} :
					{hourH,hourL,minH,minL,secH,secL,jiffyH,jiffyL} == {24'h235959,max_cnt}
					;
wire incDayH = incDayL && dayL==4'h9;
					
// 668.5991	
reg incMarsMonth;
always_comb
	begin
	case({monthH,monthL})	// synopsys full_case parallel_case
	8'h01:	incMarsMonth = {dayH,dayL}==8'h33;
	8'h02:	incMarsMonth = {dayH,dayL}==8'h33;
	8'h03:	incMarsMonth = {dayH,dayL}==8'h33;
	8'h04:	incMarsMonth = {dayH,dayL}==8'h34;
	8'h05:	incMarsMonth = {dayH,dayL}==8'h34;
	8'h06:	incMarsMonth = {dayH,dayL}==8'h33;
	8'h07:	incMarsMonth = {dayH,dayL}==8'h33;
	8'h08:	incMarsMonth = {dayH,dayL}==8'h33;
	8'h09:	incMarsMonth = {dayH,dayL}==8'h34;
	8'h10:	incMarsMonth = {dayH,dayL}==8'h34;
	8'h11:	incMarsMonth = {dayH,dayL}==8'h33;
	8'h12:	incMarsMonth = {dayH,dayL}==8'h33;
	8'h13:	incMarsMonth = {dayH,dayL}==8'h33;
	8'h14:	incMarsMonth = {dayH,dayL}==8'h34;
	8'h15:	incMarsMonth = {dayH,dayL}==8'h34;
	8'h16:	incMarsMonth = {dayH,dayL}==8'h33;
	8'h17:	incMarsMonth = {dayH,dayL}==8'h33;
	8'h18:	incMarsMonth = {dayH,dayL}==8'h33;
	8'h19:	incMarsMonth = {dayH,dayL}==8'h34;
	8'h20:	incMarsMonth = duckYear ? {dayH,dayL}==8'h34 : {dayH,dayL}==8'h35;
	endcase
	end


reg incEarthMonth;
always_comb
	begin
	case({monthH,monthL})	// synopsys full_case parallel_case
	8'h01:	incEarthMonth = {dayH,dayL}==8'h31;
	8'h02:	incEarthMonth = leapYear ? {dayH,dayL}==8'h29 : {dayH,dayL}==8'h28;
	8'h03:	incEarthMonth = {dayH,dayL}==8'h31;
	8'h04:	incEarthMonth = {dayH,dayL}==8'h30;
	8'h05:	incEarthMonth = {dayH,dayL}==8'h31;
	8'h06:	incEarthMonth = {dayH,dayL}==8'h30;
	8'h07:	incEarthMonth = {dayH,dayL}==8'h31;
	8'h08:	incEarthMonth = {dayH,dayL}==8'h31;
	8'h09:	incEarthMonth = {dayH,dayL}==8'h30;
	8'h10:	incEarthMonth = {dayH,dayL}==8'h31;
	8'h11:	incEarthMonth = {dayH,dayL}==8'h30;
	8'h12:	incEarthMonth = {dayH,dayL}==8'h31;
	endcase
	end

wire incMonthL  = incDayH && (mars ? incMarsMonth : incEarthMonth);
wire incMonthH  = incMonthL && monthL==4'd9;
wire incYearN0	= incMonthH && (mars ? {monthH,monthL} == 8'h20 : {monthH,monthL} == 8'h12);
wire incYearN1  = incYearN0 && yearN0 == 4'h9;
wire incYearN2  = incYearN1 && yearN1 == 4'h9;
wire incYearN3  = incYearN2 && yearN2 == 4'h9;


wire cs = cs_io;

reg ack1;
always_ff @(posedge clk_i)
	ack1 <= cs|cs_config;
assign ack_o = (cs|cs_config) ? (we_i ? 1'b1 : ack1) : 1'b0;

// Synchronize external tod signal
wire tods;
sync2s sync0(.rst(rst_i), .clk(clk_i), .i(tod), .o(tods));

// Edge detect the incoming tod signal.
wire tod_edge;
edge_det ed_tod(.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(tods), .pe(tod_edge), .ne(), .ee());

// Output alarm pulse on match
wire isAlarm =
		{
			alm_jiffyH,alm_jiffyL,
			alm_secH,alm_secL,
			alm_minH,alm_minL,
			alm_hourH, alm_hourL,
			alm_dayH,alm_dayL,
			alm_monthH,alm_monthL,
			alm_yearN1,alm_yearN0,
			alm_yearN3,alm_yearN2
		} & alarm_carex ==
		{
			jiffyH,jiffyL,
			secH,secL,
			minH,minL,
			hourH,hourL,
			dayH,dayL,
			monthH,monthL,
			yearN1,yearN0,
			yearN3,yearN3
		} & alarm_carex;


reg oalarm;

always_ff @(posedge clk_i)
if (rst_i) begin
	oalarm <= 1'b0;
	mars <= MARS_TIME;
	tod_en <= 1'b1;
	tod_freq <= 2'b00;	// default to 100Hz

	jiffyL <= 4'h0;
	jiffyH <= 4'h0;
	secL <= 4'h0;
	secH <= 4'h0;
	minL <= 4'h6;
	minH <= 4'h0;
	hourL <= 4'h3;
	hourH <= 4'h1;

	dayL <= 4'h0;
	dayH <= 4'h1;
	monthL <= 4'h6;
	monthH <= 4'h0;
	yearN0 <= 4'h2;
	yearN1 <= 4'h1;
	yearN2 <= 4'h0;
	yearN3 <= 4'h2;

	alarm_care <= 8'hFF;
	alm_jiffyLo <= 4'h0;
	alm_jiffyHo <= 4'h0;
	alm_secLo <= 4'h0;
	alm_secHo <= 4'h0;
	alm_minLo <= 4'h0;
	alm_minHo <= 4'h0;
	alm_hourLo <= 4'h0;
	alm_hourHo <= 4'h0;

	alm_dayLo <= 4'h0;
	alm_dayHo <= 4'h0;
	alm_monthLo <= 4'h0;
	alm_monthHo <= 4'h0;
	alm_yearN0o <= 4'h0;
	alm_yearN1o <= 4'h0;
	alm_yearN2o <= 4'h0;
	alm_yearN3o <= 4'h0;
	
	snapshot <= 2'b0;
	snapshotA <= 'd0;

end
else begin

	oalarm <= isAlarm;
	snapshot <= 2'b0;	// ensure it only pulses
	snapshotA <= 'd0;

	// Take snapshot of date / time
	if (snapshot[0]) begin
		jiffyLo <= jiffyL;
		jiffyHo <= jiffyH;
		secLo <= secL;
		secHo <= secH;
		minLo <= minL;
		minHo <= minH;
		hourLo <= hourL;
		hourHo <= hourH;
		dayLo <= dayL;
		dayHo <= dayH;
		monthLo <= monthL;
		monthHo <= monthH;
		yearN0o <= yearN0;
		yearN1o <= yearN1;
		yearN2o <= yearN2;
		yearN3o <= yearN3;
	end

	if (snapshot[1]) begin
		jiffyL <= jiffyLo;
		jiffyH <= jiffyHo;
		secL <= secLo;
		secH <= secHo;
		minL <= minLo;
		minH <= minHo;
		hourL <= hourLo;
		hourH <= hourHo;
		dayL <= dayLo;
		dayH <= dayHo;
		monthL <= monthLo;
		monthH <= monthHo;
		yearN0 <= yearN0o;
		yearN1 <= yearN1o;
		yearN2 <= yearN2o;
		yearN3 <= yearN3o;
	end

	if (snapshotA) begin
		alm_jiffyL <= alm_jiffyLo;
		alm_jiffyH <= alm_jiffyHo;
		alm_secL <= alm_secLo;
		alm_secH <= alm_secHo;
		alm_minL <= alm_minLo;
		alm_minH <= alm_minHo;
		alm_hourL <= alm_hourLo;
		alm_hourH <= alm_hourHo;
		alm_dayL <= alm_dayLo;
		alm_dayH <= alm_dayHo;
		alm_monthL <= alm_monthLo;
		alm_monthH <= alm_monthHo;
		alm_yearN0 <= alm_yearN0o;
		alm_yearN1 <= alm_yearN1o;
		alm_yearN2 <= alm_yearN2o;
		alm_yearN3 <= alm_yearN3o;
	end

	if (isAlarm & !oalarm)
		alarm <= irq_en;

	// Handle register updates
	if (cs & we) begin
		case(adr[4:2])

		3'd0:	begin
				if (sel[0]) begin jiffyLo <= dati[3:0]; jiffyHo <= dati[7:4]; end
				if (sel[1]) begin secLo <= dati[11:8]; secHo <= dati[15:12]; end
				if (sel[2]) begin minLo <= dati[19:16]; minHo <= dati[23:20]; end
				if (sel[3]) begin hourLo <= dati[27:24]; hourHo <= dati[31:28]; end
				end
		3'd1:	begin
				if (sel[0]) begin dayLo <= dati[3:0]; dayHo <= dati[7:4]; end
				if (sel[1]) begin monthLo <= dati[11:8]; monthHo <= dati[15:12]; end
				if (sel[2]) begin yearN0o <= dati[19:16]; yearN1o <= dati[23:20]; end
				if (sel[3]) begin yearN2o <= dati[27:24]; yearN3o <= dati[31:28]; end
				end
		3'd2:	begin
				if (sel[0]) begin alm_jiffyLo <= dati[3:0]; alm_jiffyHo <= dati[7:4]; end
				if (sel[1]) begin alm_secLo <= dati[11:8]; alm_secHo <= dati[15:12]; end
				if (sel[2]) begin alm_minLo <= dati[19:16]; alm_minHo <= dati[23:20]; end
				if (sel[3]) begin alm_hourLo <= dati[27:24]; alm_hourHo <= dati[31:28]; end
				end
		3'd3:	begin
				if (sel[0]) begin alm_dayLo <= dati[3:0]; alm_dayHo <= dati[7:4]; end
				if (sel[1]) begin alm_monthLo <= dati[11:8]; alm_monthHo <= dati[15:12]; end
				if (sel[2]) begin alm_yearN0o <= dati[19:16]; alm_yearN1o <= dati[23:20]; end
				if (sel[3]) begin alm_yearN2o <= dati[27:24]; alm_yearN3o <= dati[31:28]; end
				end
		3'd4:	begin
				if (sel[0]) alarm_care <= dati[7:0];
				if (sel[1])
					begin
						tod_en <= dati[8];
						tod_freq <= dati[10:9];
					end
				if (sel[2]) mars <= dati[16];
				end

		// writing to register 5 triggers a snapshot
		3'd5:	
			begin
				if (sel[0]) snapshot <= dati[1:0];
				if (sel[1]) snapshotA <= dati[8];
			end

		endcase
	end
	if (cs_config)
		dat_o <= cfg_out;
	else if (cs) begin
		case(adr[4:2])
		3'd0:	dat_o <= {hourHo,hourLo,minHo,minLo,secHo,secLo,jiffyHo,jiffyLo};
		3'd1:	dat_o <= {yearN3o,yearN2o,yearN1o,yearN0o,monthHo,monthLo,dayHo,dayLo};
		3'd2:	begin
					dat_o <= {alm_hourHo,alm_hourLo,alm_minHo,alm_minLo,alm_secHo,alm_secLo,alm_jiffyHo,alm_jiffyLo};
					alarm <= 1'b0;
				end
		3'd3:	begin
					dat_o <= {alm_yearN3o,alm_yearN2o,alm_yearN1o,alm_yearN0o,alm_monthHo,alm_monthLo,alm_dayHo,alm_dayLo};
					alarm <= 1'b0;
				end
		3'd4:	dat_o <= {mars,5'b0,tod_freq,tod_en,alarm_care}; 
		3'd5:	dat_o <= 0;
		endcase
	end
	else
		dat_o <= 32'd0;


	// Clock updates
	if (tod_en & tod_edge) begin

		jiffyL <= jiffyL + 4'h1;

		if (incJiffyH) begin
			jiffyL <= 4'h0;
			jiffyH <= jiffyH + 4'h1;
		end

		// Seconds
		if (incSecL) begin
			jiffyH <= 4'h0;
			secL <= secL + 4'h1;
		end
		if (incSecH) begin
			secL <= 4'h0;
			secH <= secH + 4'h1;
		end

		if (incMinL) begin
			minL <= minL + 4'h1;
			secH <= 4'h0;
		end
		if (incMinH) begin
			minL <= 4'h0;
			minH <= minH + 4'h1;
		end

		if (incHourL) begin
			minH <= 4'h0;
			hourL <= hourL + 4'h1;
		end
		if (incHourH) begin
			hourL <= 4'h0;
			hourH <= hourH + 4'h1;
		end

		// day increment
		// reset the entire time when the day increments
		// - the day may not be exactly 24 hours long
		if (incDayL) begin
			dayL <= dayL + 4'h1;
			jiffyL <= 4'h0;
			jiffyH <= 4'h0;
			secL <= 4'h0;
			secH <= 4'h0;
			minL <= 4'h0;
			minH <= 4'h0;
			hourL <= 4'h0;
			hourH <= 4'h0;
		end
		if (incDayH) begin
			dayL <= 4'h0;
			dayH <= dayH + 4'h1;
		end

		if (incMonthL) begin
			dayL <= 4'h1;
			dayH <= 4'h0;
			monthL <= monthL + 4'h1;
		end
		if (incMonthH) begin
			monthL <= 4'h0;
			monthH <= monthH + 4'h1;
		end

		if (incYearN0) begin
			monthL <= 4'h1;
			monthH <= 4'h0;
		end
		if (incYearN1) begin
			yearN0 <= 4'h0;
			yearN1 <= yearN1 + 4'h1;
		end
		if (incYearN2) begin
			yearN1 <= 4'h0;
			yearN2 <= yearN2 + 4'h1;
		end
		if (incYearN3) begin
			yearN2 <= 4'h0;
			yearN3 <= yearN3 + 4'h1;
		end
	end
end

endmodule

