// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	xbusPhaseAlign.sv
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

module xbusPhaseAlign(rst_i, clk_i, dat_i,
  idly_ce, idly_inc, idly_cnt, idly_ld, aligned, error, eye_size);
parameter pParallelWidth = 14;
parameter pCtrlTokenCnt = 3;
parameter pCtrlToken = 14'b11010101010100;
input rst_i;
input clk_i;
input [pParallelWidth-1:0] dat_i;
output reg idly_ce;
output reg idly_inc;
input [4:0] idly_cnt;
output reg idly_ld;
output reg aligned;
output reg error;
output reg [4:0] eye_size;

reg [3:0] state;
parameter INIT = 4'd0;
parameter LOOP = 4'd1;
parameter INC_DELAY = 4'd2;
parameter INC_WAIT_TOKEN_FIND = 4'd3;
parameter DEC_DELAY = 4'd4;
parameter DEC_WAIT_TOKEN_FIND = 4'd5;
parameter CALC_CENTER = 4'd6;
parameter MOVE_TO_CENTER = 4'd7;
parameter MTC1 = 4'd8;
parameter MTC2 = 4'd9;
parameter DONE = 4'd10;
parameter LOOK_FOR_TOKEN = 4'd11;
parameter INC_DELAY2 = 4'd12;
parameter INC2 = 4'd13;

reg [3:0] cnt;
reg [3:0] pos_count;
reg [7:0] end_pos, start_pos, center;
reg [5:0] token_cnt;
reg [6:0] timeout_cnt;
reg found_token;
reg reset_found_token;
reg reset_timeout;
reg timeout;

always @(posedge clk_i)
if (rst_i) begin
  timeout_cnt <= 7'd0;
end
else begin
  timeout_cnt <= timeout_cnt + 2'd1;
  if (found_token)
    timeout_cnt <= 7'd0;
  if (reset_timeout)
    timeout <= 1'b0;
  else if (timeout_cnt[6]) begin
    timeout_cnt <= 7'd0;
    timeout <= 1'b1;
  end
end

always @(posedge clk_i)
if (rst_i) begin
  token_cnt <= 6'd0;
  found_token <= 1'b0;
end
else begin
  if (dat_i==pCtrlToken)
    token_cnt <= token_cnt + 2'd1;
  else
    token_cnt <= 6'd0;
  if (reset_found_token)
    found_token <= 1'b0;
  else if (token_cnt==pCtrlTokenCnt)
    found_token <= 1'b1;
end

always @(posedge clk_i)
if (rst_i) begin
  reset_found_token <= 1'b0;
  reset_timeout <= 1'b0;
  idly_ce <= 1'b0;
  idly_inc <= 1'b0;
  idly_ld <= 1'b0;
  goto (INIT);
end
else begin
  // One cycle resets
  reset_found_token <= 1'b0;
  reset_timeout <= 1'b0;
  idly_ce <= 1'b0;
  idly_inc <= 1'b0;
  idly_ld <= 1'b0;

case(state)
INIT:
  begin
    idly_ld <= 1'b1;
    error <= 1'b0;
    pos_count <= 4'd0;
    end_pos <= 8'd0;
    start_pos <= 8'd0;
    goto (LOOK_FOR_TOKEN);
  end

LOOK_FOR_TOKEN:
  begin
    if (!error) begin // hang in this state if error
      if (idly_cnt==5'd31)
        error <= 1'b1;
      if (timeout)
        goto (INC_DELAY2);
      if (found_token)
        goto (LOOP);
    end
  end

INC_DELAY2:
  begin
    reset_timeout <= 1'b1;
    idly_ce <= 1'b1;
    idly_inc <= 1'b1;
    goto (INC2);
  end
INC2:
  goto (LOOK_FOR_TOKEN);

// Loop four time to get average eye.
LOOP:
  begin
    pos_count <= pos_count + 2'd1;
    if (pos_count==4'd3)
      goto (CALC_CENTER);
    else
      goto (INC_DELAY);
  end

// ToDo: fix this for tokens that would always be found (causes infinite loop).
// Increase delay until token can no longer be found. This will give the end
// position of the eye.
INC_DELAY:
  begin
    idly_ce <= 1'b1;
    idly_inc <= 1'b1;
    reset_found_token <= 1'b1;
    cnt <= 4'd0;
    goto (INC_WAIT_TOKEN_FIND);
  end
// Wait for the token to be found again. If the token has not been found
// within a few clock cycles then the increment was too great. Go to the
// decrement state.
INC_WAIT_TOKEN_FIND:
  begin
    cnt <= cnt + 2'd1;
    if (cnt[2]) begin
      end_pos <= end_pos + idly_cnt;
      goto (DEC_DELAY);
    end
    if (found_token)
      goto (INC_DELAY);
  end

// Decrease the delay until the token can no longer be found. This will give
// the start position of the eye.
DEC_DELAY:
  begin
    idly_ce <= 1'b1;
    idly_inc <= 1'b0;
    reset_found_token <= 1'b1;
    cnt <= 4'd0;
    goto (DEC_WAIT_TOKEN_FIND);
  end
DEC_WAIT_TOKEN_FIND:
  begin
    cnt <= cnt + 2'd1;
    if (cnt[3]) begin
      goto (LOOP);
      start_pos <= start_pos + idly_cnt;
    end
    if (found_token)
      goto (DEC_DELAY);
  end

CALC_CENTER:
  begin
    eye_size <= ((end_pos - start_pos) + 2'd1) >> 3'd3;
    center <= ((end_pos - start_pos) + 2'd1) >> 2'd2;
    goto (MOVE_TO_CENTER);
  end
  
MOVE_TO_CENTER:
  begin
    if (idly_cnt == center)
      goto (DONE);
    else begin
      idly_ce <= 1'b1;
      idly_inc <= 1'b1;
      goto (MTC1);
    end
  end
// Delay a couple of clocks between settings of idly.
MTC1:
  begin
    goto (MTC2);
  end
MTC2:
  begin
    goto (MOVE_TO_CENTER);
  end
// Stay in done state unless reset.
DONE:
  begin
    aligned <= 1'b1;
  end
default:  ;
endcase
end

task goto;
input [3:0] nst;
begin
  state <= nst;
end
endtask

endmodule
