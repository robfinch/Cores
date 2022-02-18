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

module mpmc8_state_machine(rst, clk, ch, 
	acki0, acki1, acki2, acki3, acki4, acki5, acki6, acki7,
	ch0_taghit, ch1_taghit, ch2_taghit, ch3_taghit, ch4_taghit, ch5_taghit,
	ch6_taghit, ch7_taghit, wdf_rdy, rdy, do_wr, rd_data_valid,
	num_strips, req_strip_cnt, resp_strip_cnt, to,
	cr1, cr7, adr1, adr7,
	resv_ch, resv_adr,
	state
);
input rst;
input clk;
input [3:0] ch;
input acki0;
input acki1;
input acki2;
input acki3;
input acki4;
input acki5;
input acki6;
input acki7;
input ch0_taghit;
input ch1_taghit;
input ch2_taghit;
input ch3_taghit;
input ch4_taghit;
input ch5_taghit;
input ch6_taghit;
input ch7_taghit;
input wdf_rdy;
input rdy;
input do_wr;
input rd_data_valid;
input [2:0] num_strips;
input [2:0] req_strip_cnt;
input [2:0] resp_strip_cnt;
input to;
input cr1;
input cr7;
input [31:0] adr1;
input [31:0] adr7;
input [3:0] resv_ch [0:NAR-1];
input [31:0] resv_adr [0:NAR-1];
output reg [3:0] state;

reg [3:0] next_state;

// State machine
always_ff @(posedge clk)
	state <= next_state;

integer n3;
always_comb
if (rst)
	next_state <= IDLE;
else begin
case(state)
IDLE:
	begin
		next_state <= IDLE;
	  // According to the docs there's no need to wait for calib complete.
	  // Calib complete goes high in sim about 111 us.
	  // Simulation setting must be set to FAST.
		//if (calib_complete)
		case(ch)
		3'd0:	if (!acki0) next_state <= PRESET1;
		3'd1:
			if (!acki1) begin
		    if (cr1) begin
	        next_state <= IDLE;
		    	for (n3 = 0; n3 < NAR; n3 = n3 + 1)
	        	if ((resv_ch[n3]==4'd1) && (resv_adr[n3][31:4]==adr1[31:4]))
	          	next_state <= PRESET1;
		    end
		    else
	        next_state <= PRESET1;
	    end
		3'd2:	if (!acki2) next_state <= PRESET1;
		3'd3:	if (!acki3) next_state <= PRESET1;
		3'd4:	if (!acki4) next_state <= PRESET1;
		3'd5:	if (!acki5) next_state <= PRESET1;
		3'd6:	if (!acki6) next_state <= PRESET1;
		3'd7:
			if (!acki7) begin
		    if (cr7) begin
	        next_state <= IDLE;
		    	for (n3 = 0; n3 < NAR; n3 = n3 + 1)
		        if ((resv_ch[n3]==4'd7) && (resv_adr[n3][31:4]==adr7[31:4]))
	            next_state <= PRESET1;
		    end
		    else
	        next_state <= PRESET1;
	    end
		default:	;	// no channel selected -> stay in IDLE state
		endcase
	end
// If an ack is received during a preset cycle it is likely a read cycle that
// acked a cycle late. Abort the cycle.
PRESET1:
	case(ch)
	4'd0:	if (ch0_taghit) next_state <= IDLE; else next_state <= PRESET2;
	4'd1:	if (ch1_taghit) next_state <= IDLE; else next_state <= PRESET2;
	4'd2:	if (ch2_taghit) next_state <= IDLE; else next_state <= PRESET2;
	4'd3:	if (ch3_taghit) next_state <= IDLE; else next_state <= PRESET2;
	4'd4:	if (ch4_taghit) next_state <= IDLE; else next_state <= PRESET2;
	4'd5:	if (ch5_taghit) next_state <= IDLE; else next_state <= PRESET2;
	4'd6:	if (ch6_taghit) next_state <= IDLE; else next_state <= PRESET2;
	4'd7:	if (ch7_taghit) next_state <= IDLE; else next_state <= PRESET2;
	default:	next_state <= PRESET2;
	endcase
// The valid data, data mask and address are placed in app_wdf_data, app_wdf_mask,
// and memm_addr ahead of time.
PRESET2:
	case(ch)
	4'd0:	if (ch0_taghit) next_state <= IDLE; else next_state <= PRESET3;
	4'd1:	if (ch1_taghit) next_state <= IDLE; else next_state <= PRESET3;
	4'd2:	if (ch2_taghit) next_state <= IDLE; else next_state <= PRESET3;
	4'd3:	if (ch3_taghit) next_state <= IDLE; else next_state <= PRESET3;
	4'd4:	if (ch4_taghit) next_state <= IDLE; else next_state <= PRESET3;
	4'd5:	if (ch5_taghit) next_state <= IDLE; else next_state <= PRESET3;
	4'd6:	if (ch6_taghit) next_state <= IDLE; else next_state <= PRESET3;
	4'd7:	if (ch7_taghit) next_state <= IDLE; else next_state <= PRESET3;
	default:	next_state <= PRESET3;
	endcase
// PRESET3 determines the read or write command
PRESET3:
	if (do_wr && !RMW)
		next_state <= WRITE_DATA0;
	else begin
		next_state <= READ_DATA0;
		case(ch)
		4'd0:	if (ch0_taghit) next_state <= IDLE; else next_state <= READ_DATA0;
		4'd1:	if (ch1_taghit) next_state <= IDLE; else next_state <= READ_DATA0;
		4'd2:	if (ch2_taghit) next_state <= IDLE; else next_state <= READ_DATA0;
		4'd3:	if (ch3_taghit) next_state <= IDLE; else next_state <= READ_DATA0;
		4'd4:	if (ch4_taghit) next_state <= IDLE; else next_state <= READ_DATA0;
		4'd5:	if (ch5_taghit) next_state <= IDLE; else next_state <= READ_DATA0;
		4'd6:	if (ch6_taghit) next_state <= IDLE; else next_state <= READ_DATA0;
		4'd7:	if (ch7_taghit) next_state <= IDLE; else next_state <= READ_DATA0;
		default:	next_state <= READ_DATA0;
		endcase
	end

// Write data to the data fifo
// Write occurs when app_wdf_wren is true and app_wdf_rdy is true
WRITE_DATA0:
	// Issue a write command if the fifo is full.
//	if (!app_wdf_rdy)
//		next_state <= WRITE_DATA1;
//	else 
	if (wdf_rdy)// && req_strip_cnt==num_strips)
		next_state <= WRITE_DATA1;
	else
		next_state <= WRITE_DATA0;
WRITE_DATA1:
	next_state <= WRITE_DATA2;
WRITE_DATA2:
	if (rdy)
		next_state <= WRITE_DATA3;
	else
		next_state <= WRITE_DATA2;
WRITE_DATA3:
	next_state <= IDLE;
	/*
	if (req_strip_cnt==num_strips)
		next_state <= IDLE;
	else
		next_state <= WRITE_DATA0;
	*/
// There could be multiple read requests submitted before any response occurs.
// Stay in the SET_CMD_RD until all requested strips have been processed.
READ_DATA0:
	next_state <= READ_DATA1;
// Could it take so long to do the request that we start getting responses
// back?
READ_DATA1:
	if (rdy && req_strip_cnt==num_strips)
		next_state <= READ_DATA2;
	else
		next_state <= READ_DATA1;
// Wait for incoming responses, but only for so long to prevent a hang.
READ_DATA2:
	if (rd_data_valid && resp_strip_cnt==num_strips)
		next_state <= WAIT_NACK;
	else
		next_state <= READ_DATA2;

WAIT_NACK:
	// If we're not seeing a nack and there is a channel selected, then the
	// cache tag must not have updated correctly.
	// For writes, assume a nack by now.
	next_state <= IDLE;
	/*
	case(ch)
	3'd0:	if (ne_acki0) next_state <= IDLE;
	3'd1:	if (ne_acki1) next_state <= IDLE;
	3'd2:	if (ne_acki2) next_state <= IDLE;
	3'd3:	if (ne_acki3) next_state <= IDLE;
	3'd4:	if (ne_acki4) next_state <= IDLE;
	3'd5:	if (ne_acki5) next_state <= IDLE;
	3'd6:	if (ne_acki6) next_state <= IDLE;
	3'd7:	if (ne_acki7) next_state <= IDLE;
	default:	next_state <= IDLE;
	endcase
	*/
default:	next_state <= IDLE;
endcase

// Is the state machine hung?
if (to)
	next_state <= IDLE;
end

endmodule
