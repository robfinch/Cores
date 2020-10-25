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

module xbusBridge(rst_i, clk_i, rclk_i, 
  cyc_i, stb_i, ack_o, berr_o, we_i, sel_i, adr_i, dat_i, dat_o,
  xbd_o, xb_de_o, xb_hsync_o, xb_vsync_o, xbd_i);
parameter kParallelWidth = 10;
input rst_i;
input clk_i;    // 43 MHz
input rclk_i;
input cyc_i;
input stb_i;
output ack_o;
output reg berr_o;
input we_i;
input [15:0] sel_i;
input [31:0] adr_i;
input [127:0] dat_i;
output reg [127:0] dat_o;
output reg [((kParallelWidth-2)*2)-1:0] xbd_o;
output reg xb_hsync_o;
output reg xb_vsync_o;
output reg xb_de_o;
input [((kParallelWidth-2)*2)-1:0] xbd_i;

reg [3:0] cnt;
reg [3:0] state;
reg [3:0] istate;
reg [10:0] hsynccnt;
reg [11:0] vsynccnt;
reg [5:0] de_cnt;
reg [8:0] berr_cnt;

parameter IDLE = 4'd0;
parameter XCTRL = 4'd1;
parameter RCV = 4'd2;
parameter XD0_31 = 4'd3;
parameter XD32_63 = 4'd4;
parameter XD64_95 = 4'd5;
parameter XD96_127 = 4'd6;
parameter WAIT_ACK = 4'd7;
parameter XA20_39 = 4'd2;
parameter XD0_15 = 4'd8;
parameter XD16_31 = 4'd9;
parameter XD32_47 = 4'd10;
parameter XD48_63 = 4'd11;
parameter XD64_79 = 4'd12;
parameter XD80_95 = 4'd13;
parameter XD96_111 = 4'd14;
parameter XD112_127 = 4'd15;

// Sync Generator defaults: 800x600 60Hz
// Note these timings are not for VGA. The horizontal sync has been shortened.
parameter phSyncOn  = 40;		//   40 front porch
parameter phSyncOff = 168;		//  128 sync
parameter phBlankOn = 1052;		//   80 border
parameter phBlankOff = 252;	//256	//   88 back porch
//parameter phBorderOff = 336;	//   80 border
parameter phBorderOff = 256;	//   80 border
//parameter phBorderOn = 976;		//  640 display
parameter phBorderOn = 1056;		//  640 display
parameter phTotal = 1056;		// 1056 total clocks
parameter pvSyncOn  = 1;		//    1 front porch
parameter pvSyncOff = 5;		//    4 vertical sync
parameter pvBorderOff = 28;		//   44 border	0
//parameter pvBorderOff = 72;		//   44 border	0
parameter pvBorderOn = 628;		//  512 display
//parameter pvBorderOn = 584;		//  512 display
parameter pvBlankOn = 628;  	//   44 border	0
parameter pvBlankOff = 28;		//   23 back porch
parameter pvTotal = 628;		//  628 total scan lines

reg ackw, ackr = 1'b0;
assign ack_o = ackw|ackr;

// "Fake" some display signals.
wire blank, vblank;
always @(posedge clk_i)
  xb_de_o <= ~blank;
always @(posedge clk_i)
  xb_hsync_o <= hsync;
always @(posedge clk_i)
  xb_vsync_o <= vsync;

VGASyncGen usg1
(
  .rst(rst_i),
  .clk(clk_i),
  .eol(),
  .eof(),
  .hSync(hsync),
  .vSync(vsync),
  .hCtr(),
  .vCtr(),
  .blank(blank),
  .vblank(vblank),
  .vbl_int(),
  .border(),
  .hTotal_i(phTotal),
  .vTotal_i(pvTotal),
  .hSyncOn_i(phSyncOn),
  .hSyncOff_i(phSyncOff),
  .vSyncOn_i(pvSyncOn),
  .vSyncOff_i(pvSyncOff),
  .hBlankOn_i(phBlankOn),
  .hBlankOff_i(phBlankOff),
  .vBlankOn_i(pvBlankOn),
  .vBlankOff_i(pvBlankOff),
  .hBorderOn_i(phBorderOn),
  .vBorderOn_i(pvBorderOn),
  .hBorderOff_i(phBorderOff),
  .vBorderOff_i(pvBorderOff)
);

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
  ackw <= 1'b0;
  state <= IDLE;
end
else begin
if (xb_de_o)
case(state)
IDLE:
  begin
    xbd_o[23:20] <= 4'h0; // Send a NOP
    xbd_o[19:0] <= 20'h0;
    if (xb_cs) begin
      xbd_o[23:20] <= 4'h1; // Send the address
      xbd_o[19: 0] <= adr_i[19:0];
      state <= XA20_39;
    end
  end
XA20_39:
  begin
    xbd_o[23:20] <= 4'h2; // Send the address
    xbd_o[19: 0] <= adr_i[39:20];
    state <= XCTRL;
  end
XCTRL:
  begin
    xbd_o[23:20] <= 4'h3;
    xbd_o[19] <= we_i;
    xbd_o[18:16] <= 3'h0;
    xbd_o[15: 0] <= sel_i;
    if (!we_i)
      state <= WAIT_ACK;
    else if (sel_i[1:0] != 4'h0)
      state <= XD0_15;
    else if (sel_i[3:2] != 4'h0)
      state <= XD16_31;
    else if (sel_i[5:4] != 4'h0)
      state <= XD32_47;
    else if (sel_i[7:6] != 4'h0)
      state <= XD48_63;
    else if (sel_i[9:8] != 4'h0)
      state <= XD64_79;
    else if (sel_i[11:10] != 4'h0)
      state <= XD80_95;
    else if (sel_i[13:12] != 4'h0)
      state <= XD96_111;
    else if (sel_i[15:14] != 4'h0)
      state <= XD112_127;
    else
      state <= WAIT_ACK;
  end
XD0_15:
  begin
    xbd_o[23:20] <= 4'h8;
    xbd_o[15: 0] <= dat_i[15:0];
    if (sel_i[3:2] != 4'h0)
      state <= XD16_31;
    else if (sel_i[5:4] != 4'h0)
      state <= XD32_47;
    else if (sel_i[7:6] != 4'h0)
      state <= XD48_63;
    else if (sel_i[9:8] != 4'h0)
      state <= XD64_79;
    else if (sel_i[11:10] != 4'h0)
      state <= XD80_95;
    else if (sel_i[13:12] != 4'h0)
      state <= XD96_111;
    else if (sel_i[15:14] != 4'h0)
      state <= XD112_127;
    else
      state <= WAIT_ACK;
  end
XD16_31:
  begin
    xbd_o[23:20] <= 4'h9;
    xbd_o[15: 0] <= dat_i[31:16];
    if (sel_i[5:4] != 4'h0)
      state <= XD32_47;
    else if (sel_i[7:6] != 4'h0)
      state <= XD48_63;
    else if (sel_i[9:8] != 4'h0)
      state <= XD64_79;
    else if (sel_i[11:10] != 4'h0)
      state <= XD80_95;
    else if (sel_i[13:12] != 4'h0)
      state <= XD96_111;
    else if (sel_i[15:14] != 4'h0)
      state <= XD112_127;
    else
      state <= WAIT_ACK;
  end
XD32_47:
  begin
    xbd_o[23:20] <= 4'h10;
    xbd_o[15: 0] <= dat_i[47:32];
    if (sel_i[7:6] != 4'h0)
      state <= XD48_63;
    else if (sel_i[9:8] != 4'h0)
      state <= XD64_79;
    else if (sel_i[11:10] != 4'h0)
      state <= XD80_95;
    else if (sel_i[13:12] != 4'h0)
      state <= XD96_111;
    else if (sel_i[15:14] != 4'h0)
      state <= XD112_127;
    else
      state <= WAIT_ACK;
  end
XD48_63:
  begin
    xbd_o[23:20] <= 4'h11;
    xbd_o[15: 0] <= dat_i[63:48];
    if (sel_i[9:8] != 4'h0)
      state <= XD64_79;
    else if (sel_i[11:10] != 4'h0)
      state <= XD80_95;
    else if (sel_i[13:12] != 4'h0)
      state <= XD96_111;
    else if (sel_i[15:14] != 4'h0)
      state <= XD112_127;
    else
      state <= WAIT_ACK;
  end
XD64_79:
  begin
    xbd_o[23:20] <= 4'h12;
    xbd_o[15: 0] <= dat_i[79:64];
    if (sel_i[11:10] != 4'h0)
      state <= XD80_95;
    else if (sel_i[13:12] != 4'h0)
      state <= XD96_111;
    else if (sel_i[15:14] != 4'h0)
      state <= XD112_127;
    else
      state <= WAIT_ACK;
  end
XD80_95:
  begin
    xbd_o[23:20] <= 4'h13;
    xbd_o[15: 0] <= dat_i[95:80];
    if (sel_i[13:12] != 4'h0)
      state <= XD96_111;
    else if (sel_i[15:14] != 4'h0)
      state <= XD112_127;
    else
      state <= WAIT_ACK;
  end
XD96_111:
  begin
    xbd_o[23:20] <= 4'h14;
    xbd_o[15: 0] <= dat_i[111:96];
    if (sel_i[15:14] != 4'h0)
      state <= XD112_127;
    else
      state <= WAIT_ACK;
  end
XD112_127:
  begin
    xbd_o[23:20] <= 4'h15;
    xbd_o[15: 0] <= dat_i[127:112];
    state <= WAIT_ACK;
  end
// Wait for the master to complete cycle.
WAIT_ACK:
  begin
    ackw <= we_i;
    xbd_o[23:20] <= 4'h3; // Send a tran complete
    xbd_o[19:0] <= 20'h0;
    xbd_o[19] <= we_i;
    xbd_o[18] <= 1'b1;
    xbd_o[17] <= 1'b1;    // start slave cycle
    xbd_o[15:0] <= sel_i;
    if (!cyc_i) begin
      xbd_o[23:20] <= 4'h0; // Send a NOP
      xbd_o[19:0] <= 20'h0;
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
      case(xbd_i[23:20])
      4'h3: // Might receive a NOP here, if so ignore
        if (xbd_i[18:17]!=2'b00)
          istate <= WAIT_ACK;
      4'h8: dat_o[15:0] <= xbd_i[15:0];
      4'h9: dat_o[31:16] <= xbd_i[15:0];
      4'h10: dat_o[47:32] <= xbd_i[15:0];
      4'h11: dat_o[63:48] <= xbd_i[15:0];
      4'h12: dat_o[79:64] <= xbd_i[15:0];
      4'h13: dat_o[95:80] <= xbd_i[15:0];
      4'h14: dat_o[111:96] <= xbd_i[15:0];
      4'h15: dat_o[127:112] <= xbd_i[15:0];
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
