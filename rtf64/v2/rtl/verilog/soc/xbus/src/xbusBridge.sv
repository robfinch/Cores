// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	xbusBridge.sv
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

module xbusBridge(bridge_num_i, rst_i, clk_i, rclk_i, locked_i,
  cyc_i, stb_i, ack_o, berr_o, we_i, sel_i, adr_i, dat_i, dat_o,
  xbd_o, xb_sync_o, xb_de_o, xbd_i, xb_sync_i, xb_de_i);
parameter kParallelWidth = 14;
input [3:0] bridge_num_i;
input rst_i;
input clk_i;    // 43 MHz
input rclk_i;
input locked_i;
input cyc_i;
input stb_i;
output ack_o;
output reg berr_o;
input we_i;
input [15:0] sel_i;
input [31:0] adr_i;
input [127:0] dat_i;
output reg [127:0] dat_o;
output reg [((kParallelWidth-2)*3)-1:0] xbd_o;
output reg xb_sync_o;
output reg xb_de_o;
input [((kParallelWidth-2)*3)-1:0] xbd_i;
input xb_sync_i;
input xb_de_i;

reg [3:0] cnt;
reg [3:0] state;
reg [3:0] istate;
reg [8:0] berr_cnt;

parameter IDLE = 4'd0;
parameter XCTRL = 4'd1;
parameter RCV = 4'd2;
parameter XD0_31 = 4'd3;
parameter XD32_63 = 4'd4;
parameter XD64_95 = 4'd5;
parameter XD96_127 = 4'd6;
parameter WAIT_ACK = 4'd7;
parameter WAIT_LOCK = 4'd8;
parameter XA0_31 = 4'd9;

reg ackw, ackr = 1'b0, ackb;
assign ack_o = ackw|ackb;
reg [127:0] rdat_o;
reg [5:0] ctr;
reg [5:0] synccnt;
reg [5:0] de_cnt;
reg device_ready;
reg [16:0] dev_timeout_cnt;
reg dev_timeout;
reg [5:0] dev_sel;
reg sync_locked;
reg rst_sl;
reg [63:0] dev_ready_flag;
reg [5:0] master_num;

always @(posedge clk_i)
if (rst_sl)
  synccnt <= 6'd0;
else begin
  if (xb_sync_i)
    synccnt <= synccnt + 2'd1;
  else
    synccnt <= 6'd0;
end

always @(posedge clk_i)
if (rst_sl)
  sync_locked <= 1'b0;
else begin
  if (synccnt[5])
    sync_locked <= 1'b1;
end

// Wait up to 65536 (about 1/2 ms @ 100MHz) cycles for device to time out.
always @(posedge clk_i)
if (rst_sl)
  dev_timeout_cnt <= 17'd0;
else begin
  dev_timeout_cnt <= dev_timeout_cnt + 2'd1;
end

always @(posedge clk_i)
if (rst_sl)
  dev_timeout <= 1'b0;
else begin
  if (dev_timeout_cnt[16])
    dev_timeout <= 1'b1;
end

always @(posedge clk_i)
if (rst_sl)
  de_cnt <= 6'd0;
else begin
  if (xb_de_i)
    de_cnt <= de_cnt + 2'd1;
  else
    de_cnt <= 6'd0;
end

always @(posedge clk_i)
if (rst_sl)
  device_ready <= 1'b0;
else begin
  if (de_cnt[5:4]==2'b11)
    device_ready <= 1'b1;
end

// Bridge control port.
wire cs_bridge = cyc_i && stb_i && adr_i[31:4]=={24'hFFDCF0,bridge_num_i};

always @(posedge clk_i)
if (rst_i) begin
  ackb <= 1'b0;
  rst_sl <= 1'b1;
  dev_sel <= 6'd1;  //6'd0;
  master_num <= bridge_num_i;
end
else begin
  rst_sl <= 1'b0;
  if (cs_bridge) begin
    ackb <= 1'b1;
    if (we_i) begin
      if (dat_i[7]) begin
        rst_sl <= 1'b1;
        dev_sel <= 6'd1;//dat_i[5:0];
      end
    end
    else
      dat_o <= dev_ready_flag;
  end
  else begin
    dat_o <= rdat_o;
    ackb <= ackr;
  end
end

// Register signals onto this domain.
reg cyc;
reg stb;
reg [31:0] adr;
always @(posedge clk_i)
begin
  cyc <= cyc_i;
  stb <= stb_i;
  adr <= adr_i;
end
wire xb_cs = cyc && stb && (adr[31:24]==8'hFB);

always @(posedge clk_i)
if (rst_i) begin
  xb_sync_o <= 1'b0;
  xb_de_o <= 1'b0;
  ctr <= 6'd0;
  ackw <= 1'b0;
  dev_ready_flag <= 64'd0;
  state <= WAIT_LOCK;//IDLE;
end
else begin
case(state)

WAIT_LOCK:
  begin
    ctr <= ctr + 2'd1;
    //xb_sync_o <= ctr < 6'd16;
    xb_de_o <= ctr >= 6'd16 && ctr < 6'd60;
    xb_sync_o <= ctr >= 6'd32 && ctr < 6'd48;
    xbd_o[35:32] <= 4'h0; // Send a NOP
    xbd_o[31:4] <= 28'h0;
    xbd_o[7] <= 1'b1;
    xbd_o[29:24] <= master_num;
    xbd_o[5:0] <= dev_sel;
    if (sync_locked & device_ready) begin
      state <= IDLE;
      xb_sync_o <= 1'b0;
      xb_de_o <= 1'b1;
      dev_ready_flag[dev_sel] <= 1'b1;
    end
    else if (dev_timeout) begin
      dev_ready_flag[dev_sel] <= 1'b0;
      state <= IDLE;
    end
  end

IDLE:
  begin
    xbd_o[35:32] <= 4'h0; // Send a NOP
    xbd_o[31:0] <= 32'h0;
    if (rst_sl)
      state <= WAIT_LOCK;
    else if (xb_cs) begin
      xbd_o[35:32] <= 4'h0; // Send select
      xbd_o[29:24] <= master_num;
      xbd_o[5:0] <= dev_sel;
      state <= XA0_31;
    end
  end
XA0_31:
  begin
    xbd_o[35:32] <= 4'h1; // Send the address
    xbd_o[31: 0] <= adr_i[31:0];
    state <= XCTRL;
  end
XCTRL:
  begin
    xbd_o[35:32] <= 4'h3;
    xbd_o[31] <= we_i;
    xbd_o[30:16] <= 15'h0;
    xbd_o[15: 0] <= sel_i;
    if (!we_i)
      state <= WAIT_ACK;
    else if (sel_i[3:0] != 4'h0)
      state <= XD0_31;
    else if (sel_i[7:4] != 4'h0)
      state <= XD32_63;
    else if (sel_i[11:8] != 4'h0)
      state <= XD64_95;
    else if (sel_i[15:12] != 4'h0)
      state <= XD96_127;
    else
      state <= WAIT_ACK;
  end
XD0_31:
  begin
    xbd_o[35:32] <= 4'h4;
    xbd_o[31:0] <= dat_i[31:0];
    if (sel_i[7:4] != 4'h0)
      state <= XD32_63;
    else if (sel_i[11:8] != 4'h0)
      state <= XD64_95;
    else if (sel_i[15:12] != 4'h0)
      state <= XD96_127;
    else
      state <= WAIT_ACK;
  end
XD32_63:
  begin
    xbd_o[35:32] <= 4'h5;
    xbd_o[31:0] <= dat_i[63:32];
    if (sel_i[11:8] != 4'h0)
      state <= XD64_95;
    else if (sel_i[15:12] != 4'h0)
      state <= XD96_127;
    else
      state <= WAIT_ACK;
  end
XD64_95:
  begin
    xbd_o[35:32] <= 4'h6;
    xbd_o[31:0] <= dat_i[95:64];
    if (sel_i[15:12] != 4'h0)
      state <= XD96_127;
    else
      state <= WAIT_ACK;
  end
XD96_127:
  begin
    xbd_o[35:32] <= 4'h7;
    xbd_o[31:0] <= dat_i[127:96];
    state <= WAIT_ACK;
  end
// Wait for the master to complete cycle.
WAIT_ACK:
  begin
    ackw <= we_i;
    xbd_o[35:32] <= 4'h3; // Send a tran complete
    xbd_o[23:0] <= 24'h0;
    xbd_o[31] <= we_i;
    xbd_o[30] <= 1'b1;
    xbd_o[29:24] <= master_num;
    xbd_o[23] <= 1'b1;    // start slave cycle
    xbd_o[15:0] <= sel_i;
    if (!cyc_i) begin
      xbd_o[35:32] <= 4'h0; // Send a deselect
      xbd_o[31:6] <= 26'h0;
      xbd_o[29:24] <= master_num;
      xbd_o[5:0] <= 6'd0;   // deselect
      ackw <= 1'b0;
      state <= IDLE;
    end
  end
endcase  
//else begin
//  xbd_o[35:32] <= 4'h0; // Send a NOP
//  xbd_o[31:0] <= 32'h0;
//end
end

// Register signals onto this domain.
reg rcyc;
reg rstb;
reg [31:0] radr;
always @(posedge rclk_i)
begin
  rcyc <= cyc_i;
  rstb <= stb_i;
  radr <= adr_i;
end
wire rxb_cs = rcyc && rstb && (radr[31:24]==8'hFB);

always @(posedge rclk_i)
if (rst_i) begin
  berr_cnt <= 9'h00;
  ackr <= 1'b0;
  istate <= IDLE;
end
else begin
berr_cnt <= berr_cnt + 2'd1;
case(istate)

IDLE:
  begin
    ackr <= 1'b0;
    if (rxb_cs)
      istate <= RCV;
  end
RCV:
  begin
    if (berr_cnt[8]) begin
      berr_o <= 1'b1;
      istate <= WAIT_ACK;
    end
    else
      case(xbd_i[35:32])
      4'h3: // Might receive a NOP here, if so ignore
        if (xbd_i[30]!=1'b0)
          istate <= WAIT_ACK;
      4'h4: rdat_o[31:0] <= xbd_i[31:0];
      4'h5: rdat_o[63:32] <= xbd_i[31:0];
      4'h6: rdat_o[95:64] <= xbd_i[31:0];
      4'h7: rdat_o[127:96] <= xbd_i[31:0];
      default:  ;
      endcase
  end
WAIT_ACK:
  begin
    ackr <= 1'b1;
    if (!cyc_i) begin
      ackr <= 1'b0;
      istate <= IDLE;
    end
  end
endcase

end

endmodule
