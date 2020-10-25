// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	xbusSlaveBridge.sv
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

module xbusSlaveBridge(rst_i, clk_i, rclk_i,
  cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_o, dat_i,
  xb_dat_i, xb_dat_o, xb_hsync_o, xb_vsync_o, xb_de_o);
input rst_i;
input clk_i;
input rclk_i;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [15:0] sel_o;
output reg [31:0] adr_o;
output reg [127:0] dat_o;
input [127:0] dat_i;
input [23:0] xb_dat_i;
output reg [23:0] xb_dat_o;
output reg xb_hsync_o;
output reg xb_vsync_o;
output reg xb_de_o;

reg [3:0] state;
reg [3:0] ostate;
parameter IDLE = 4'd0;
parameter WAIT_ACK = 4'd6;
parameter WAIT_NACK = 4'd7;
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
parameter phSyncOff = 50;		//  128 sync
parameter phBlankOff = 252;	//256	//   88 back porch
//parameter phBorderOff = 336;	//   80 border
parameter phBorderOff = 256;	//   80 border
//parameter phBorderOn = 976;		//  640 display
parameter phBorderOn = 1056;		//  640 display
parameter phBlankOn = 1052;		//   80 border
parameter phTotal = 1056;		// 1056 total clocks
parameter pvSyncOn  = 1;		//    1 front porch
parameter pvSyncOff = 5;		//    4 vertical sync
parameter pvBlankOff = 28;		//   23 back porch
parameter pvBorderOff = 28;		//   44 border	0
//parameter pvBorderOff = 72;		//   44 border	0
parameter pvBorderOn = 628;		//  512 display
//parameter pvBorderOn = 584;		//  512 display
parameter pvBlankOn = 628;  	//   44 border	0
parameter pvTotal = 628;		//  628 total scan lines

reg ackw, ackr = 1'b0;
assign ack_o = ackw|ackr;

// "Fake" some display signals.
wire blank, hsync, vsync;
always @(posedge clk_i)
  xb_de_o <= ~hsync;
always @(posedge clk_i)
  xb_hsync_o <= hsync;
always @(posedge clk_i)
  xb_vsync_o <= vsync & hsync;

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
  .vblank(),
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


reg [31:0] adr;
reg [127:0] dath, dat;
reg [15:0] selh, sel;
reg [8:0] synccnt;
reg start_cycle, start_cycle1;
reg we;
reg data_cap;
reg was_write;

always @(posedge rclk_i)
if (rst_i) begin
  we <= 1'b0;
  sel <= 16'h0;
  adr <= 32'h0;
  dat <= 128'h0;
end
else begin
start_cycle <= 1'b0;
start_cycle1 <= start_cycle;
case(xb_dat_i[23:20])
4'h1: adr[19:0] <= xb_dat_i[19:0];
4'h2: adr[31:20] <= xb_dat_i[11:0];
4'h3:
  begin
    start_cycle <= xb_dat_i[18];
    we <= xb_dat_i[19];
    sel <= xb_dat_i[15:0];
  end
4'h8: dat[15:0] <= xb_dat_i[15:0];
4'h9: dat[31:16] <= xb_dat_i[15:0];
4'h10: dat[47:32] <= xb_dat_i[15:0];
4'h11: dat[63:48] <= xb_dat_i[15:0];
4'h12: dat[79:64] <= xb_dat_i[15:0];
4'h13: dat[95:80] <= xb_dat_i[15:0];
4'h14: dat[111:96] <= xb_dat_i[15:0];
4'h15: dat[127:112] <= xb_dat_i[15:0];
endcase
end

always @(posedge clk_i)
if (rst_i) begin
  ostate <= IDLE;
  data_cap <= 1'b0;
  was_write <= 1'b0;
  dath <= 128'd0;
  selh <= 16'h0;
  xb_dat_o[23:20] <= 4'h0;  // send a NOP
  xb_dat_o[19:0] <= 20'h0;
end
else begin
if (start_cycle|start_cycle1) begin
  cyc_o <= 1'b1;
  stb_o <= 1'b1;
  we_o <= we;
  sel_o <= sel;
  adr_o <= adr;
  dat_o <= dat;
end
if (cyc_o & stb_o & ack_i) begin
  // capture data response
  dath <= dat_i;
  selh <= sel_o;
  // Terminate slave bus cycle
  cyc_o <= 1'b0;
  stb_o <= 1'b0;
  we_o <= 1'b0;
  sel_o <= 16'h0;
  data_cap <= 1'b1;
  was_write <= we_o;
end

if (!xb_de_o) begin
  xb_dat_o[23:20] <= 4'h0;  // send a NOP
  xb_dat_o[19:0] <= 20'h0;
end
else
case(ostate)
IDLE:
  begin
    xb_dat_o[23:20] <= 4'h0;  // send a NOP
    xb_dat_o[19:0] <= 20'h0;
    if (data_cap) begin
      data_cap <= 1'b0;
      ostate <= WAIT_ACK;
    end
  end
WAIT_ACK:
  begin
    // If it was a read cycle send the data back
    if (!was_write) begin
      if (selh[1:0]) begin
        xb_dat_o[23:20] <= 4'h8;
        xb_dat_o[15:0] <= dath[31:0];
        ostate <= XD16_31;
      end
      else if (selh[3:2]) begin
        xb_dat_o[23:20] <= 4'h9;
        xb_dat_o[31:0] <= dath[31:16];
        ostate <= XD32_47;
      end
      else if (selh[5:4]) begin
        xb_dat_o[23:20] <= 4'h10;
        xb_dat_o[15:0] <= dath[47:32];
        ostate <= XD48_63;
      end
      else if (selh[7:6]) begin
        xb_dat_o[23:20] <= 4'h11;
        xb_dat_o[15:0] <= dath[63:48];
        ostate <= XD64_79;
      end
      else if (selh[9:8]) begin
        xb_dat_o[23:20] <= 4'h12;
        xb_dat_o[15:0] <= dath[79:64];
        ostate <= XD80_95;
      end
      else if (selh[11:10]) begin
        xb_dat_o[23:20] <= 4'h13;
        xb_dat_o[15:0] <= dath[95:80];
        ostate <= XD96_111;
      end
      else if (selh[13:12]) begin
        xb_dat_o[23:20] <= 4'h14;
        xb_dat_o[15:0] <= dath[111:96];
        ostate <= XD112_127;
      end
      else if (selh[15:14]) begin
        xb_dat_o[23:20] <= 4'h15;
        xb_dat_o[15:0] <= dath[127:112];
        ostate <= WAIT_NACK;
      end
      else
        ostate <= WAIT_NACK;
    end
    else begin
      xb_dat_o[23:20] <= 4'h3;
      xb_dat_o[19:0] <= 20'h0;
      xb_dat_o[18:17] <= 2'b11; // Send read ack / tran complete
      ostate <= IDLE;
    end
  end
XD16_31:
  begin
    if (selh[3:2]) begin
      xb_dat_o[23:20] <= 4'h9;
      xb_dat_o[31:0] <= dath[31:16];
      ostate <= XD32_47;
    end
    else if (selh[5:4]) begin
      xb_dat_o[23:20] <= 4'h10;
      xb_dat_o[15:0] <= dath[47:32];
      ostate <= XD48_63;
    end
    else if (selh[7:6]) begin
      xb_dat_o[23:20] <= 4'h11;
      xb_dat_o[15:0] <= dath[63:48];
      ostate <= XD64_79;
    end
    else if (selh[9:8]) begin
      xb_dat_o[23:20] <= 4'h12;
      xb_dat_o[15:0] <= dath[79:64];
      ostate <= XD80_95;
    end
    else if (selh[11:10]) begin
      xb_dat_o[23:20] <= 4'h13;
      xb_dat_o[15:0] <= dath[95:80];
      ostate <= XD96_111;
    end
    else if (selh[13:12]) begin
      xb_dat_o[23:20] <= 4'h14;
      xb_dat_o[15:0] <= dath[111:96];
      ostate <= XD112_127;
    end
    else if (selh[15:14]) begin
      xb_dat_o[23:20] <= 4'h15;
      xb_dat_o[15:0] <= dath[127:112];
      ostate <= WAIT_NACK;
    end
    else
      ostate <= WAIT_NACK;
  end
XD32_47:
  begin
    if (selh[5:4]) begin
      xb_dat_o[23:20] <= 4'h10;
      xb_dat_o[15:0] <= dath[47:32];
      ostate <= XD48_63;
    end
    else if (selh[7:6]) begin
      xb_dat_o[23:20] <= 4'h11;
      xb_dat_o[15:0] <= dath[63:48];
      ostate <= XD64_79;
    end
    else if (selh[9:8]) begin
      xb_dat_o[23:20] <= 4'h12;
      xb_dat_o[15:0] <= dath[79:64];
      ostate <= XD80_95;
    end
    else if (selh[11:10]) begin
      xb_dat_o[23:20] <= 4'h13;
      xb_dat_o[15:0] <= dath[95:80];
      ostate <= XD96_111;
    end
    else if (selh[13:12]) begin
      xb_dat_o[23:20] <= 4'h14;
      xb_dat_o[15:0] <= dath[111:96];
      ostate <= XD112_127;
    end
    else if (selh[15:14]) begin
      xb_dat_o[23:20] <= 4'h15;
      xb_dat_o[15:0] <= dath[127:112];
      ostate <= WAIT_NACK;
    end
    else
      ostate <= WAIT_NACK;
  end
XD48_63:
  begin
    if (selh[7:6]) begin
      xb_dat_o[23:20] <= 4'h11;
      xb_dat_o[15:0] <= dath[63:48];
      ostate <= XD64_79;
    end
    else if (selh[9:8]) begin
      xb_dat_o[23:20] <= 4'h12;
      xb_dat_o[15:0] <= dath[79:64];
      ostate <= XD80_95;
    end
    else if (selh[11:10]) begin
      xb_dat_o[23:20] <= 4'h13;
      xb_dat_o[15:0] <= dath[95:80];
      ostate <= XD96_111;
    end
    else if (selh[13:12]) begin
      xb_dat_o[23:20] <= 4'h14;
      xb_dat_o[15:0] <= dath[111:96];
      ostate <= XD112_127;
    end
    else if (selh[15:14]) begin
      xb_dat_o[23:20] <= 4'h15;
      xb_dat_o[15:0] <= dath[127:112];
      ostate <= WAIT_NACK;
    end
    else
      ostate <= WAIT_NACK;
  end
XD64_79:
  begin
    if (selh[9:8]) begin
      xb_dat_o[23:20] <= 4'h12;
      xb_dat_o[15:0] <= dath[79:64];
      ostate <= XD80_95;
    end
    else if (selh[11:10]) begin
      xb_dat_o[23:20] <= 4'h13;
      xb_dat_o[15:0] <= dath[95:80];
      ostate <= XD96_111;
    end
    else if (selh[13:12]) begin
      xb_dat_o[23:20] <= 4'h14;
      xb_dat_o[15:0] <= dath[111:96];
      ostate <= XD112_127;
    end
    else if (selh[15:14]) begin
      xb_dat_o[23:20] <= 4'h15;
      xb_dat_o[15:0] <= dath[127:112];
      ostate <= WAIT_NACK;
    end
    else
      ostate <= WAIT_NACK;
  end
XD80_95:
  begin
    if (selh[11:10]) begin
      xb_dat_o[23:20] <= 4'h13;
      xb_dat_o[15:0] <= dath[95:80];
      ostate <= XD96_111;
    end
    else if (selh[13:12]) begin
      xb_dat_o[23:20] <= 4'h14;
      xb_dat_o[15:0] <= dath[111:96];
      ostate <= XD112_127;
    end
    else if (selh[15:14]) begin
      xb_dat_o[23:20] <= 4'h15;
      xb_dat_o[15:0] <= dath[127:112];
      ostate <= WAIT_NACK;
    end
    else
      ostate <= WAIT_NACK;
  end
XD96_111:
  begin
    if (selh[13:12]) begin
      xb_dat_o[23:20] <= 4'h14;
      xb_dat_o[15:0] <= dath[111:96];
      ostate <= XD112_127;
    end
    else if (selh[15:14]) begin
      xb_dat_o[23:20] <= 4'h15;
      xb_dat_o[15:0] <= dath[127:112];
      ostate <= WAIT_NACK;
    end
    else
      ostate <= WAIT_NACK;
  end
XD112_127:
  begin
    if (selh[15:14]) begin
      xb_dat_o[23:20] <= 4'h15;
      xb_dat_o[15:0] <= dath[127:112];
      ostate <= WAIT_NACK;
    end
    else
      ostate <= WAIT_NACK;
  end
WAIT_NACK:
  begin
    ostate <= IDLE;
    xb_dat_o[23:20] <= 4'h3;
    xb_dat_o[19:0] <= 20'h0;
    xb_dat_o[18:17] <= 2'b11; // Send read ack / tran complete
  end
endcase

end

endmodule
