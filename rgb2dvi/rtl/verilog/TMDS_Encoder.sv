// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//
// Ported to System Verilog from the Digilent rgb2dvi project
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

import DVI_Constants::*;

module TMDS_Encoder(rst, PixelClk, SerialClk, pDataOutRaw, pDataOut, pC0, pC1, de);
parameter kBitsIn = 8;
parameter kEncodedBits = 10;
input rst;
input PixelClk;
input SerialClk;		// 5x clock
output reg [kEncodedBits-1:0] pDataOutRaw;
input [kBitsIn-1:0] pDataOut;
input pC0;
input pC1;
input de;

integer i;
wire [3:0] popcnt, popcnt_qm;
reg de_1, de_2;
reg [kBitsIn-1:0] pDataOut_1;
reg [kEncodedBits-2:0] q_m_xor_1, q_m_xnor_1, q_m_1, q_m_2;
reg [3:0] n1d_1, n1q_m_1, n1q_m_2, n0q_m_2;	// range is from 0 to 8
reg pC0_1, pC1_1;
reg pC0_2, pC1_2;
reg cond_not_balanced_2, cond_balanced_2;
reg signed [4:0] dc_bias_2, cnt_t_2, cnt_t_3;		// range -8 to +8 plus sign bit
reg [kEncodedBits-1:0] control_token_2, q_out_2;

cntpop8 ucntpop1
(
	.i(pDataOut),
	.o(popcnt)
);

cntpop8 ucntpop2
(
	.i(q_m_1[7:0]),
	.o(popcnt_qm)
);

//--------------------------------------------------------------------------------
// DVI 1.0 Specs Figure 3-5
// Pipeline stage 1, minimise transitions
//--------------------------------------------------------------------------------
always_ff @(posedge PixelClk)
begin
	de_1 <= de;
	n1d_1 <= popcnt;
	pDataOut_1 <= pDataOut;
	pC0_1 <= pC0;
	pC1_1 <= pC1;
end

//--------------------------------------------------------------------------------
// Choose one of the two encoding options based on n1d_1
//--------------------------------------------------------------------------------
assign q_m_xor_1[0] = pDataOut_1[0];
assign q_m_xnor_1[0] = pDataOut_1[0];

always_comb
	for (i = 1; i < 8; i = i + 1) begin
		q_m_xor_1[i] = q_m_xor_1[i-1] ^ pDataOut_1[i];
		q_m_xnor_1[i] = ~(q_m_xnor_1[i-1] ^ pDataOut_1[i]);
	end

assign q_m_xor_1[8] = 1'b1;
assign q_m_xnor_1[8] = 1'b0;

always_comb
	q_m_1 = (n1d_1 > 4 || (n1d_1 == 4 && pDataOut_1[0] == 1'b0)) ? q_m_xnor_1 : q_m_xor_1;

always_comb
	n1q_m_1 = popcnt_qm;
		
//--------------------------------------------------------------------------------
// Pipeline stage 2, balance DC
//--------------------------------------------------------------------------------
always_ff @(posedge PixelClk)
begin
	n1q_m_2 <= n1q_m_1;
	n0q_m_2 <= 4'd8 - n1q_m_1;
	q_m_2 <= q_m_1;
	pC0_2 <= pC0_1;
	pC1_2 <= pC1_1;
	de_2 <= de_1;
end

// DC balanced output
always_comb
	cond_balanced_2 = (cnt_t_3 == 0 || n1q_m_2 == 4);
always_comb
	cond_not_balanced_2 = (cnt_t_3 > 0 && n1q_m_2 > 4) || // too many 1's
									 			(cnt_t_3 < 0 && n1q_m_2 < 4); // too many 0's

always_comb
	case({pC1_2,pC0_2})
	2'b00:	control_token_2 = kCtlTkn0;
	2'b01:	control_token_2 = kCtlTkn1;
	2'b10:	control_token_2 = kCtlTkn2;
	2'b11:	control_token_2 = kCtlTkn3;
	endcase

always_comb
	if (de_2) begin
		casez({cond_not_balanced_2,cond_balanced_2,q_m_2[8]})
		3'b010:	q_out_2 = {~q_m_2[8],q_m_2[8],~q_m_2[7:0]};
		3'b011:	q_out_2 = {~q_m_2[8],q_m_2[8], q_m_2[7:0]};
		3'b1??:	q_out_2 = {1'b1,q_m_2[8],~q_m_2[7:0]};
		default:	q_out_2 = {1'b0,q_m_2[8],q_m_2[7:0]};		// DC balanced
		endcase
	end
	else
		q_out_2 = control_token_2;

always_comb
	dc_bias_2 = {1'b0,n0q_m_2} - {1'b0,n1q_m_2};

always_comb
	if (de_2) begin
		casez({cond_not_balanced_2,cond_balanced_2,q_m_2[8]})
		3'b010:	cnt_t_2 = cnt_t_3 + dc_bias_2;
		3'b011:	cnt_t_2 = cnt_t_3 - dc_bias_2;
		3'b1??:	cnt_t_2 = {1'b0, q_m_2[8], 1'b0} + dc_bias_2;
		default:	cnt_t_2 = {1'b0, ~q_m_2[8], 1'b0} - dc_bias_2;
		endcase
	end
	else
		cnt_t_2 = 'd0;
	
//--------------------------------------------------------------------------------
// Pipeline stage 3, registered output
//--------------------------------------------------------------------------------
always_ff @(posedge PixelClk)
if (rst) begin
	cnt_t_3 <= 'd0;
	pDataOutRaw <= 'd0;
end
else begin
  cnt_t_3 <= cnt_t_2;
  pDataOutRaw <= q_out_2; // encoded, ready to be serialized
end
		
endmodule

