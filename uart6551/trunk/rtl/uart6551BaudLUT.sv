// ============================================================================
//        __
//   \\__/ o\    (C) 2005-2023  Robert Finch, Waterloo
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
// ============================================================================
//
module uart6551BaudLUT(a, o);
parameter pClkFreq = 100;
parameter pCounterBits = 24;
input [4:0] a;
output reg [pCounterBits-1:0] o;

// table for a 50.000MHz reference clock
// value = 50,000,000 / (baud * 16)
always_comb
case(pClkFreq)
20:
	case (a)	// synopsys full_case parallel_case
	5'd0:	o <= 0;
	5'd1:	o <= 24'd25000;	// 50 baud
	5'd2:	o <= 24'd16667;	// 75 baud
	5'd3:	o <= 24'd11372;	// 109.92 baud
	5'd4:	o <= 24'd9270;	// 134.58 baud
	5'd5:	o <= 24'd8333;	// 150 baud
	5'd6:	o <= 24'd4167;	// 300 baud
	5'd7:	o <= 24'd2083;	// 600 baud
	5'd8:	o <= 24'd1042;	// 1200 baud
	5'd9:	o <= 24'd694;	// 1800 baud
	5'd10:	o <= 24'd521;	// 2400 baud
	5'd11:	o <= 24'd347;	// 3600 baud
	5'd12:	o <= 24'd260;	// 4800 baud
	5'd13:	o <= 24'd174;	// 7200 baud
	5'd14:	o <= 24'd130;	// 9600 baud
	5'd15:	o <= 24'd65;	// 19200 baud

	5'd16:	o <= 24'd33;	// 38400 baud
	5'd17:	o <= 24'd22;	// 57600 baud
	5'd18:	o <= 24'd11;	// 115200 baud
	5'd19:	o <= 24'd5;	// 230400 baud
	5'd20:	o <= 24'd3;	// 460800 baud
	5'd21:	o <= 24'd1;	// 921600 baud
	default:	o <= 24'd130;	// 9600 baud
	endcase
40:
	case (a)	// synopsys full_case parallel_case
	5'd0:	o <= 0;
	5'd1:	o <= 24'd50000;	// 50 baud
	5'd2:	o <= 24'd33333;	// 75 baud
	5'd3:	o <= 24'd22744;	// 109.92 baud
	5'd4:	o <= 24'd18576;	// 134.58 baud
	5'd5:	o <= 24'd16667;	// 150 baud
	5'd6:	o <= 24'd8333;	// 300 baud
	5'd7:	o <= 24'd4167;	// 600 baud
	5'd8:	o <= 24'd2083;	// 1200 baud
	5'd9:	o <= 24'd1389;	// 1800 baud
	5'd10:	o <= 24'd1042;	// 2400 baud
	5'd11:	o <= 24'd694;	// 3600 baud
	5'd12:	o <= 24'd521;	// 4800 baud
	5'd13:	o <= 24'd347;	// 7200 baud
	5'd14:	o <= 24'd260;	// 9600 baud
	5'd15:	o <= 24'd130;	// 19200 baud

	5'd16:	o <= 24'd65;	// 38400 baud
	5'd17:	o <= 24'd43;	// 57600 baud
	5'd18:	o <= 24'd22;	// 115200 baud
	5'd19:	o <= 24'd11;	// 230400 baud
	5'd20:	o <= 24'd5;	// 460800 baud
	5'd21:	o <= 24'd3;	// 921600 baud
	default:	o <= 24'd260;	// 9600 baud
	endcase
50:
	case (a)	// synopsys full_case parallel_case
	5'd0:	o <= 0;
	5'd1:	o <= 24'd62500;	// 50 baud
	5'd2:	o <= 24'd41667;	// 75 baud
	5'd3:	o <= 24'd28617;	// 109.92 baud
	5'd4:	o <= 24'd23220;	// 134.58 baud
	5'd5:	o <= 24'd20833;	// 150 baud
	5'd6:	o <= 24'd10417;	// 300 baud
	5'd7:	o <= 24'd5208;	// 600 baud
	5'd8:	o <= 24'd2604;	// 1200 baud
	5'd9:	o <= 24'd1736;	// 1800 baud
	5'd10:	o <= 24'd1302;	// 2400 baud
	5'd11:	o <= 24'd868;	// 3600 baud
	5'd12:	o <= 24'd651;	// 4800 baud
	5'd13:	o <= 24'd434;	// 7200 baud
	5'd14:	o <= 24'd326;	// 9600 baud
	5'd15:	o <= 24'd163;	// 19200 baud

	5'd16:	o <= 24'd81;	// 38400 baud
	5'd17:	o <= 24'd54;	// 57600 baud
	5'd18:	o <= 24'd27;	// 115200 baud
	5'd19:	o <= 24'd14;	// 230400 baud
	5'd20:	o <= 24'd7;	// 460800 baud
	5'd21:	o <= 24'd3;	// 921600 baud
	default:	o <= 24'd326;	// 9600 baud
	endcase
80:
	case (a)	// synopsys full_case parallel_case
	5'd0:	o <= 0;
	5'd1:	o <= 24'd100000;	// 50 baud
	5'd2:	o <= 24'd66667;	// 75 baud
	5'd3:	o <= 24'd45488;	// 109.92 baud
	5'd4:	o <= 24'd37153;	// 134.58 baud
	5'd5:	o <= 24'd33333;	// 150 baud
	5'd6:	o <= 24'd16667;	// 300 baud
	5'd7:	o <= 24'd8333;	// 600 baud
	5'd8:	o <= 24'd4167;	// 1200 baud
	5'd9:	o <= 24'd2778;	// 1800 baud
	5'd10:	o <= 24'd2083;	// 2400 baud
	5'd11:	o <= 24'd1389;	// 3600 baud
	5'd12:	o <= 24'd1042;	// 4800 baud
	5'd13:	o <= 24'd694;	// 7200 baud
	5'd14:	o <= 24'd521;	// 9600 baud
	5'd15:	o <= 24'd260;	// 19200 baud

	5'd16:	o <= 24'd130;	// 38400 baud
	5'd17:	o <= 24'd87;	// 57600 baud
	5'd18:	o <= 24'd43;	// 115200 baud
	5'd19:	o <= 24'd22;	// 230400 baud
	5'd20:	o <= 24'd11;	// 460800 baud
	5'd21:	o <= 24'd5;	// 921600 baud
	default:	o <= 24'd521;	// 9600 baud
	endcase
100:
	case (a)	// synopsys full_case parallel_case
	5'd0:	o <= 0;
	5'd1:	o <= 24'd125000;	// 50 baud
	5'd2:	o <= 24'd83333;	// 75 baud
	5'd3:	o <= 24'd56860;	// 109.92 baud
	5'd4:	o <= 24'd46441;	// 134.58 baud
	5'd5:	o <= 24'd41667;	// 150 baud
	5'd6:	o <= 24'd20833;	// 300 baud
	5'd7:	o <= 24'd10417;	// 600 baud
	5'd8:	o <= 24'd5208;	// 1200 baud
	5'd9:	o <= 24'd3472;	// 1800 baud
	5'd10:	o <= 24'd2604;	// 2400 baud
	5'd11:	o <= 24'd1736;	// 3600 baud
	5'd12:	o <= 24'd1302;	// 4800 baud
	5'd13:	o <= 24'd868;	// 7200 baud
	5'd14:	o <= 24'd651;	// 9600 baud
	5'd15:	o <= 24'd326;	// 19200 baud

	5'd16:	o <= 24'd163;	// 38400 baud
	5'd17:	o <= 24'd109;	// 57600 baud
	5'd18:	o <= 24'd54;	// 115200 baud
	5'd19:	o <= 24'd27;	// 230400 baud
	5'd20:	o <= 24'd14;	// 460800 baud
	5'd21:	o <= 24'd7;	// 921600 baud
	default:	o <= 24'd651;	// 9600 baud
	endcase
default:
	case (a)	// synopsys full_case parallel_case
	5'd0:	o <= 0;
	5'd1:	o <= (pClkFreq*1e6)/(16*50);	// 50 baud
	5'd2:	o <= (pClkFreq*1e6)/(16*75);	// 75 baud
	5'd3:	o <= (pClkFreq*1e6)/(16*109.92);	// 109.92 baud
	5'd4:	o <= (pClkFreq*1e6)/(16*134.58);	// 134.58 baud
	5'd5:	o <= (pClkFreq*1e6)/(16*150);	// 150 baud
	5'd6:	o <= (pClkFreq*1e6)/(16*300);	// 300 baud
	5'd7:	o <= (pClkFreq*1e6)/(16*600);	// 600 baud
	5'd8:	o <= (pClkFreq*1e6)/(16*1200);	// 1200 baud
	5'd9:	o <= (pClkFreq*1e6)/(16*1800);	// 1800 baud
	5'd10:	o <= (pClkFreq*1e6)/(16*2400);	// 2400 baud
	5'd11:	o <= (pClkFreq*1e6)/(16*3600);	// 3600 baud
	5'd12:	o <= (pClkFreq*1e6)/(16*4800);	// 4800 baud
	5'd13:	o <= (pClkFreq*1e6)/(16*7200);	// 7200 baud
	5'd14:	o <= (pClkFreq*1e6)/(16*9600);	// 9600 baud
	5'd15:	o <= (pClkFreq*1e6)/(16*19200);	// 19200 baud

	5'd16:	o <= (pClkFreq*1e6)/(16*38400);	// 38400 baud
	5'd17:	o <= (pClkFreq*1e6)/(16*57600);	// 57600 baud
	5'd18:	o <= (pClkFreq*1e6)/(16*115200);	// 115200 baud
	5'd19:	o <= (pClkFreq*1e6)/(16*230400);	// 230400 baud
	5'd20:	o <= (pClkFreq*1e6)/(16*406800);	// 460800 baud
	5'd21:	o <= (pClkFreq*1e6)/(16*921600);	// 921600 baud
	default:	o <= (pClkFreq*1e6)/(16*9600);	// 9600 baud
	endcase
endcase

endmodule


