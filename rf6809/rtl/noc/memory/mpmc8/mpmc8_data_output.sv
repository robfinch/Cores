`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2015-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
import mpmc8_pkg::*;

module mpmc8_data_output(
	clk0, cs0, adr0, ch0_rdat, dato0,
	clk1, cs1, adr1, ch1_rdat, dato1,
	clk2, cs2, adr2, ch2_rdat, dato2,
	clk3, cs3, adr3, ch3_rdat, dato3,
	clk4, cs4, adr4, ch4_rdat, dato4,
	clk5, cs5, adr5, ch5_rdat, dato5,
	clk6, cs6, adr6, ch6_rdat, dato6,
	clk7, cs7, adr7, ch7_rdat, dato7
);
parameter C0W = 128;
parameter C1W = 128;
parameter C2W = 32;
parameter C3W = 16;
parameter C4W = 128;
parameter C5W = 64;
parameter C6W = 128;
parameter C7R = 16;

input clk0;
input clk1;
input clk2;
input clk3;
input clk4;
input clk5;
input clk6;
input clk7;
input cs0;
input cs1;
input cs2;
input cs3;
input cs4;
input cs5;
input cs6;
input cs7;
input [31:0] adr0;
input [31:0] adr1;
input [31:0] adr2;
input [31:0] adr3;
input [31:0] adr4;
input [31:0] adr5;
input [31:0] adr6;
input [31:0] adr7;
input [127:0] ch0_rdat;
input [127:0] ch1_rdat;
input [127:0] ch2_rdat;
input [127:0] ch3_rdat;
input [127:0] ch4_rdat;
input [127:0] ch5_rdat;
input [127:0] ch6_rdat;
input [127:0] ch7_rdat;
output reg [127:0] dato0;
output reg [127:0] dato1;
output reg [127:0] dato2;
output reg [127:0] dato3;
output reg [127:0] dato4;
output reg [127:0] dato5;
output reg [127:0] dato6;
output reg [127:0] dato7;

reg [127:0] ch0_rdatr;
reg [127:0] ch1_rdatr;
reg [127:0] ch2_rdatr;
reg [127:0] ch3_rdatr;
reg [127:0] ch4_rdatr;
reg [127:0] ch5_rdatr;
reg [127:0] ch6_rdatr;
reg [127:0] ch7_rdatr;

// Setting output data. Force output data to zero when not selected to allow
// wire-oring the data.
always_ff @(posedge clk0)
`ifdef RED_SCREEN
if (cs0) begin
	if (C0W==128)
		dato0 <= 128'h7C007C007C007C007C007C007C007C00;
	else if (C0W==64)
		dato0 <= 64'h7C007C007C007C00;
	else if (C0W==32)
		dato0 <= 32'h7C007C00;
	else if (C0W==16)
		dato0 <= 16'h7C00;
	else
		dato0 <= 8'hE0;
end
else
	dato0 <= {C0W{1'b0}};
`else
	tDato(C0W,cs0,adr0[3:0],ch0_rdatr,dato0);
`endif

// Register data outputs back onto their domain.
always_ff @(posedge clk1)
	ch1_rdatr <= ch1_rdat;
always_ff @(posedge clk2)
	ch2_rdatr <= ch2_rdat;
always_ff @(posedge clk3)
	ch3_rdatr <= ch3_rdat;
always_ff @(posedge clk4)
	ch4_rdatr <= ch4_rdat;
always_ff @(posedge clk5)
	ch5_rdatr <= ch5_rdat;
always_ff @(posedge clk6)
	ch6_rdatr <= ch6_rdat;
always_ff @(posedge clk7)
	ch7_rdatr <= ch7_rdat;
always_ff @(posedge clk0)
	ch0_rdatr <= ch0_rdat;

always_ff @(posedge clk1)
	tDato(C1W,cs1,adr1[3:0],ch1_rdatr,dato1);
always_ff @(posedge clk2)
	tDato(C2W,cs2,adr2[3:0],ch2_rdatr,dato2);
always_ff @(posedge clk3)
	tDato(C3W,cs3,adr3[3:0],ch3_rdatr,dato3);
always_ff @(posedge clk4)
	tDato(C4W,cs4,adr4[3:0],ch4_rdatr,dato4);
always_ff @(posedge clk5)
	tDato(C5W,cs5,adr5[3:0],ch5_rdatr,dato5);
always_ff @(posedge clk6)
	tDato(C6W,cs6,adr6[3:0],ch6_rdatr,dato6);
always_ff @(posedge clk7)
	tDato(C7R,cs7,adr7[3:0],ch7_rdatr,dato7);

task tDato;
input [7:0] widi;
input csi;
input [3:0] adri;
input [127:0] dati;
output [127:0] dato;
begin
if (csi) begin
	if (widi==8'd128)
		dato <= dati;
	else if (widi==8'd64)
		dato <= dati >> {adri[3],6'h0};
	else if (widi==8'd32)
		dato <= dati >> {adri[3:2],5'h0};
	else if (widi==8'd16)
		dato <= dati >> {adri[3:1],4'h0};
	else
		dato <= dati >> {adri[3:0],3'h0};
end
else
	dato <= 'b0;
end
endtask

endmodule
