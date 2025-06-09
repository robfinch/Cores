`include "timescale.v"
// ============================================================================
//        __
//   \\__/ o\    (C) 2025  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
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
import const_pkg::*;

`include "spiMaster_defines.v"

module readWriteSPIWireData (rst, clk, clkDelay, rxDataOut, rxDataRdySet, spiClkOut, spiDataIn, spiDataOut, txDataEmpty, txDataFull, txDataFullClr, txDataIn);
input rst;
input clk;
input [7:0] clkDelay;
input spiDataIn;
input txDataFull;
input [7:0] txDataIn;
output reg [7:0] rxDataOut;
output reg rxDataRdySet;
output reg spiClkOut;
output reg spiDataOut;
output reg txDataEmpty;
output reg txDataFullClr;

// diagram signals declarations
reg [3:0] bitCnt;
reg [7:0] clkDelayCnt;
reg [7:0] rxDataShiftReg;
reg [7:0] txDataShiftReg;

typedef enum logic [1:0]
{
	WT_TX_DATA = 2'd0,
	CLK_HI,
	CLK_LO,
	ST_RW_WIRE
} wire_state_e;
reg [3:0] CurrState_rwSPISt;

always_ff @(posedge clk)
if (rst)
	clkDelayCnt <= 8'd0;
else begin
	case(1'b1)
	CurrState_rwSPISt[CLK_HI]:
    if (clkDelayCnt == clkDelay)
      clkDelayCnt <= 8'h00;
    else
    	clkDelayCnt <= clkDelayCnt + 8'd1;
	CurrState_rwSPISt[CLK_LO]:
    if (clkDelayCnt == clkDelay)
      clkDelayCnt <= 8'h00;
    else
    	clkDelayCnt <= clkDelayCnt + 8'd1;
  default:
		clkDelayCnt <= 8'd0;
  endcase
end
	
always_ff @(posedge clk)
if (rst)
	bitCnt <= 4'd0;
else begin
	if (CurrState_rwSPISt[WT_TX_DATA])
		bitCnt <= 4'd0;
	else if(CurrState_rwSPISt[CLK_LO] && clkDelayCnt == clkDelay) begin
		if (bitCnt == 4'd8)
			bitCnt <= 4'd0;
		else
			bitCnt <= bitCnt + 4'd1;
	end
end

always_comb
	spiClkOut = CurrState_rwSPISt[CLK_HI] && bitCnt > 4'd0;

always_ff @(posedge clk)
if (rst)
	spiDataOut <= HIGH;
else begin
  case (1'b1)
  CurrState_rwSPISt[WT_TX_DATA]:
		spiDataOut <= HIGH;
  CurrState_rwSPISt[CLK_HI]:
    if (clkDelayCnt == clkDelay)
      spiDataOut <= txDataShiftReg[7];
    else
	  	spiDataOut <= spiDataOut;
  default:
  	spiDataOut <= spiDataOut;
  endcase
end

always_ff @(posedge clk)
if (rst)
	rxDataRdySet <= 1'b0;
else begin
	rxDataRdySet <= 1'b0;
  case (1'b1)
  CurrState_rwSPISt[CLK_LO]:
  	if (bitCnt == 4'd8 && clkDelayCnt==8'd0)
      rxDataRdySet <= 1'b1;
  default:
		rxDataRdySet <= 1'b0;
	endcase
end

always_ff @(posedge clk)
if (rst)
	txDataEmpty <= FALSE;
else begin
  case (1'b1)
  CurrState_rwSPISt[WT_TX_DATA]:
  	begin
	    txDataEmpty <= TRUE;
	    if (txDataFull)
	      txDataEmpty <= FALSE;
    end
  default:
		txDataEmpty <= FALSE;
  endcase
end

reg spitbit;
always_ff @(posedge clk)
if (clkDelayCnt == clkDelay)
	spitbit = (bitCnt == 4'd7 && txDataFull);

always_ff @(posedge clk)
if (rst)
	txDataShiftReg <= 8'hFF;
else begin
  case (1'b1)
  CurrState_rwSPISt[WT_TX_DATA]:
    if (txDataFull)
      txDataShiftReg <= txDataIn;
  CurrState_rwSPISt[CLK_HI]:
    if (clkDelayCnt == clkDelay) begin
    	if (bitCnt == 4'd7 && txDataFull)
      	txDataShiftReg <= txDataIn;
      else if (spitbit)
      	txDataShiftReg <= txDataIn;
      else if (bitCnt==4'd8)
      	txDataShiftReg <= 8'hFF;
      else
      	txDataShiftReg <= {txDataShiftReg[6:0], 1'b0};
    end
  default:
  	txDataShiftReg <= txDataShiftReg;
  endcase
end

always_ff @(posedge clk)
if (rst)
	rxDataShiftReg <= 8'h00;
else begin
  case (1'b1)
  CurrState_rwSPISt[WT_TX_DATA]:
    if (txDataFull)
      rxDataShiftReg <= 8'h00;
  CurrState_rwSPISt[CLK_HI]:
    if (clkDelayCnt == clkDelay && bitCnt > 4'd0)
      rxDataShiftReg <= {rxDataShiftReg[6:0], spiDataIn};
  CurrState_rwSPISt[ST_RW_WIRE]:
    rxDataShiftReg <= 8'h00;
  default:
  	rxDataShiftReg <= rxDataShiftReg;
  endcase
end

always_ff @(posedge clk)
if (rst)
	txDataFullClr <= FALSE;
else begin
  txDataFullClr <= FALSE;
  case (1'b1)
  CurrState_rwSPISt[WT_TX_DATA]:
    if (txDataFull)
      txDataFullClr <= TRUE;
  CurrState_rwSPISt[CLK_HI]:
    if (bitCnt == 4'd7 && txDataFull && clkDelayCnt==clkDelay)
      txDataFullClr <= TRUE;
  endcase
end

always_ff @(posedge clk)
if (rst)
  rxDataOut <= 8'h00;
else begin
  case (1'b1)
  CurrState_rwSPISt[CLK_LO]:
  	if (bitCnt == 4'd8 && clkDelayCnt==8'h00)
      rxDataOut <= rxDataShiftReg;
  CurrState_rwSPISt[ST_RW_WIRE]:
     rxDataOut <= 8'h00;
  default:	
  	rxDataOut <= rxDataOut;
  endcase
end

always_ff @(posedge clk)
begin
  if (rst) begin
  	CurrState_rwSPISt <= 4'd0;
    CurrState_rwSPISt[ST_RW_WIRE] <= 1'b1;
  end
  else begin
  	CurrState_rwSPISt <= 4'd0;

  	case(1'b1)
  	CurrState_rwSPISt[WT_TX_DATA]:
      if (txDataFull) 
      	CurrState_rwSPISt[CLK_HI] <= 1'b1;
      else
      	CurrState_rwSPISt[WT_TX_DATA] <= 1'b1;

  	CurrState_rwSPISt[CLK_HI]:
      if (clkDelayCnt == clkDelay)
        CurrState_rwSPISt[CLK_LO] <= 1'b1;
      else
      	CurrState_rwSPISt[CLK_HI] <= 1'b1;

  	CurrState_rwSPISt[CLK_LO]:
      if (bitCnt == 4'd8 && clkDelayCnt==clkDelay && !txDataFull)
      	CurrState_rwSPISt[WT_TX_DATA] <= 1'b1;
      else if (clkDelayCnt == clkDelay)
        CurrState_rwSPISt[CLK_HI] <= 1'b1;
      else
      	CurrState_rwSPISt[CLK_LO] <= 1'b1;

	  CurrState_rwSPISt[ST_RW_WIRE]:
      CurrState_rwSPISt[WT_TX_DATA] <= 1'b1;

		default:
      CurrState_rwSPISt[ST_RW_WIRE] <= 1'b1;
    endcase
  end
end

endmodule
