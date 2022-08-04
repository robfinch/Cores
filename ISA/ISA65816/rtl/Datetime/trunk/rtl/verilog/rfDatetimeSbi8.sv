`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2007,2012-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rfDatetime.sv
// - Scalar in-order version
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
//	0			read / write jiffies
//	1    	read / write seconds
//	2    	read / write minutes
//  3    	read / write hours
//  4
//	4			read/write day
//	5			read/write month
//	6		  read/write year
//	7			read/write century
//	8 to 15  ALM - alarm register same format as 0 to 7, but contain alarm setting
//  
//
//  16	CR - control register
//    	write - which bytes to match for alarm
//  17  [0]- time of day enable
//      [2: 1] - 00=100 Hz, 01=60Hz, 10=50Hz
//  19  [0] - mars timekeeping
//
//	20
//		writing this register triggers a snapshot
//		- trigger a snapshot before reading the date / time
//		registers
//		- the snapshot allows the date / time value to be
//		read without having to worry about an update occuring
//		during the read
//		- a copy of the current date and time is stored in
//		the output registers
//
//=============================================================================
//
module rfDatetimeSbi8
#(
	parameter pMars = 1'b0
)
(
// Syscon
input rst_i,		// reset
input ph2_i,		// bus clock

// System bus
input cs_i,
input rw_i,			// 0=write
input [4:0] adr_i,	// address
input [7:0] dat_i,	// data input
output reg [7:0] dat_o,	// data output

input tod,			// tod pulse (eg 100 Hz)
output reg alarm		// alarm match
);

reg [1:0] tod_freq;
wire [7:0] max_cnt = tod_freq==2'b00 ? 8'h99 : tod_freq==2'b01 ? 8'h59 : tod_freq==2'b10 ? 8'h49 : 8'h99;
reg tod_en;
reg mars;
reg snapshot;

// internal counters
reg [3:0] dayL, dayH;		// 1-99
reg [3:0] monthL, monthH;	// 1-99
reg [3:0] yearN0, yearN1, yearN2, yearN3;	// 
reg [3:0] jiffyL, secL, minL, hourL;
reg [3:0] jiffyH, secH, minH, hourH;

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
					
reg incMarsMonth;
always_comb
	begin
	case({monthH,monthL})	// synopsys full_case parallel_case
	8'h01:	incMarsMonth = {dayH,dayL}==8'h34;
	8'h02:	incMarsMonth = {dayH,dayL}==8'h32;
	8'h03:	incMarsMonth = {dayH,dayL}==8'h34;
	8'h04:	incMarsMonth = {dayH,dayL}==8'h33;
	8'h05:	incMarsMonth = {dayH,dayL}==8'h34;
	8'h06:	incMarsMonth = {dayH,dayL}==8'h33;
	8'h07:	incMarsMonth = {dayH,dayL}==8'h34;
	8'h08:	incMarsMonth = {dayH,dayL}==8'h33;
	8'h09:	incMarsMonth = {dayH,dayL}==8'h34;
	8'h10:	incMarsMonth = {dayH,dayL}==8'h33;
	8'h11:	incMarsMonth = {dayH,dayL}==8'h34;
	8'h12:	incMarsMonth = {dayH,dayL}==8'h33;
	8'h13:	incMarsMonth = {dayH,dayL}==8'h33;
	8'h14:	incMarsMonth = {dayH,dayL}==8'h34;
	8'h15:	incMarsMonth = {dayH,dayL}==8'h33;
	8'h16:	incMarsMonth = {dayH,dayL}==8'h34;
	8'h17:	incMarsMonth = {dayH,dayL}==8'h33;
	8'h18:	incMarsMonth = {dayH,dayL}==8'h34;
	8'h19:	incMarsMonth = {dayH,dayL}==8'h33;
	8'h20:	incMarsMonth = {dayH,dayL}==8'h34;
	endcase
	end

reg incEarthMonth;
always_comb
	begin
	case({monthH,monthL})	// synopsys full_case parallel_case
	8'h01:	incEarthMonth = {dayH,dayL}==8'h31;
	8'h02:	incEarthMonth = {dayH,dayL}==8'h28;
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


wire cs = cs_i;

// Synchronize external tod signal
wire tods;
sync2s sync0(.rst(rst_i), .clk(ph2_i), .i(tod), .o(tods));

// Edge detect the incoming tod signal.
reg ptod;
reg tod_edge;

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

always_ff @(negedge ph2_i)
	if (rst_i) begin
		oalarm <= 1'b0;
		mars <= pMars;
		tod_en <= 1'b1;
		tod_freq <= 2'b01;	// default to 60Hz

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
		alm_jiffyL <= 4'h0;
		alm_jiffyH <= 4'h0;
		alm_secL <= 4'h0;
		alm_secH <= 4'h0;
		alm_minL <= 4'h0;
		alm_minH <= 4'h0;
		alm_hourL <= 4'h0;
		alm_hourH <= 4'h0;

		alm_dayL <= 4'h0;
		alm_dayH <= 4'h0;
		alm_monthL <= 4'h0;
		alm_monthH <= 4'h0;
		alm_yearN0 <= 4'h0;
		alm_yearN1 <= 4'h0;
		alm_yearN2 <= 4'h0;
		alm_yearN3 <= 4'h0;
		
		snapshot <= 1'b0;
		ptod <= 1'b0;
		tod_edge <= 1'b0;
	end
	else begin

		tod_edge <= 1'b0;
		ptod <= tods;
		if (~ptod & tods)
			tod_edge <= 1'b1;
			
		oalarm <= isAlarm;
		snapshot <= 1'b0;	// ensure it only pulses

		if (isAlarm & !oalarm)
			alarm <= 1'b1;

		// Handle register updates
		if (cs & ~rw_i) begin
			case(adr_i[4:0])
			5'd0:	begin jiffyL <= dat_i[3:0]; jiffyH <= dat_i[7:4]; end
			5'd1: begin secL <= dat_i[3:0]; secH <= dat_i[7:4]; end
			5'd2:	begin minL <= dat_i[3:0]; minH <= dat_i[7:4]; end
			5'd3:	begin hourL <= dat_i[3:0]; hourH <= dat_i[7:4]; end
			5'd4:	begin dayL <= dat_i[3:0]; dayH <= dat_i[7:4]; end
			5'd5:	begin monthL <= dat_i[3:0]; monthH <= dat_i[7:4]; end
			5'd6:	begin yearN0 <= dat_i[3:0]; yearN1 <= dat_i[7:4]; end
			5'd7:	begin yearN2 <= dat_i[3:0]; yearN3 <= dat_i[7:4]; end
			5'd8:	begin alm_jiffyL <= dat_i[3:0]; alm_jiffyH <= dat_i[7:4]; end
			5'd9:	begin alm_secL <= dat_i[3:0]; alm_secH <= dat_i[7:4]; end
			5'd10:	begin alm_minL <= dat_i[3:0]; alm_minH <= dat_i[7:4]; end
			5'd11:	begin alm_hourL <= dat_i[3:0]; alm_hourH <= dat_i[7:4]; end
			5'd12:	begin alm_dayL <= dat_i[3:0]; alm_dayH <= dat_i[7:4]; end
			5'd13:	begin alm_monthL <= dat_i[3:0]; alm_monthH <= dat_i[7:4]; end
			5'd14:	begin alm_yearN0 <= dat_i[3:0]; alm_yearN1 <= dat_i[7:4]; end
			5'd15:	begin alm_yearN2 <= dat_i[3:0]; alm_yearN3 <= dat_i[7:4]; end
			5'd16:	alarm_care <= dat_i[7:0];
			5'd17:	
						begin
							tod_en <= dat_i[0];
							tod_freq <= dat_i[2:1];
						end
			5'd18:	mars <= dat_i[0];

			// writing to register 20 triggers a snapshot
			5'd20:	snapshot <= 1'b1;

			endcase
		end
		// reading alarm register clears alarm
		if (cs & rw_i)
			case(adr_i[4:0])
			5'd8,5'd9,5'd10,5'd11,
			5'd12,5'd13,5'd14,5'd15:	alarm <= 1'b0;
			default:	;
			endcase

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

always_ff @(posedge ph2_i)
begin
	if (cs)
		case(adr_i[4:0])
		5'd0:	dat_o <= {jiffyHo,jiffyLo};
		5'd1:	dat_o <= {secHo,secLo};
		5'd2:	dat_o <= {minHo,minLo};
		5'd3:	dat_o <= {hourHo,hourLo};
		5'd4:	dat_o <= {dayHo,dayLo};
		5'd5:	dat_o <= {monthHo,monthLo};
		5'd6:	dat_o <= {yearN1o,yearN0o};
		5'd7:	dat_o <= {yearN3o,yearN2o};
		5'd8:	dat_o <= {alm_jiffyH,alm_jiffyL};
		5'd9:	dat_o <= {alm_secH,alm_secL};
		5'd10:	dat_o <= {alm_minH,alm_minL};
		5'd11:	dat_o <= {alm_hourH,alm_hourL};
		5'd12:	dat_o <= {alm_dayH,alm_dayL};
		5'd13:	dat_o <= {alm_monthH,alm_monthL};
		5'd14:	dat_o <= {alm_yearN1,alm_yearN0};
		5'd15:	dat_o <= {alm_yearN3,alm_yearN2};
		5'd16:	dat_o <= alarm_care;
		5'd17:	dat_o <= {5'h00,tod_freq,tod_en};
		5'd18:	dat_o <= {7'h0,mars};
		5'd20:	dat_o <= 8'h00;
		default:	dat_o <= 8'h00;
		endcase
	else
		dat_o <= 8'h00;
end

// Take snapshot of date / time
always_ff @(posedge ph2_i)
	if (rst_i) begin
		jiffyLo <= 4'h0;
		jiffyHo <= 4'h0;
		secLo <= 4'h0;
		secHo <= 4'h0;
		minLo <= 4'h0;
		minHo <= 4'h0;
		hourLo <= 4'h0;
		hourHo <= 4'h0;
		dayLo <= 4'h0;
		dayHo <= 4'h0;
		monthLo <= 4'h0;
		monthHo <= 4'h0;
		yearN0o <= 4'h0;
		yearN1o <= 4'h0;
		yearN2o <= 4'h0;
		yearN3o <= 4'h0;
	end
	else if (snapshot) begin
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

endmodule

