
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// initSD.v                                                 ////
////                                                              ////
//// This file is part of the spiMaster opencores effort.
//// <http://www.opencores.org/cores//>                           ////
////                                                              ////
//// Module Description:                                          ////
//// When SDInitReq asserted, initialise SD card
////  
////  
//// 
////                                                              ////
//// To Do:                                                       ////
//// 
////                                                              ////
//// Author(s):                                                   ////
//// - Steve Fielding, sfielding@base2designs.com                 ////
////																															////
//// Modifications:																								////
////   Robert Finch, robfinch@finitron.ca													////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2004 Steve Fielding and OPENCORES.ORG          ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE. See the GNU Lesser General Public License for more  ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from <http://www.opencores.org/lgpl.shtml>                   ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//
`include "timescale.v"
`include "spiMaster_defines.v"

module initSD (checkSumByte, clk, cmdByte, dataByte1, dataByte2, dataByte3, dataByte4, initError,
	respByte,respByte1,respByte2,respByte3,respByte4,
	respTout, rst, rxDataRdy, rxDataRdyClr, SDInitRdy, SDInitReq, sendCmdRdy, sendCmdReq, spiClkDelayIn, spiClkDelayOut, spiCS_n, txDataEmpty, txDataFull, txDataOut, txDataWen, SDHC);
input clk;
input [7:0]respByte;
input [7:0] respByte1;
input [7:0] respByte2;
input [7:0] respByte3;
input [7:0] respByte4;
input respTout;
input rst;
input rxDataRdy;
input SDInitReq;
input sendCmdRdy;
input [7:0] spiClkDelayIn;
input txDataEmpty;
input txDataFull;
output reg [7:0] checkSumByte;
output reg [7:0] cmdByte;
output reg [7:0] dataByte1;
output reg [7:0] dataByte2;
output reg [7:0] dataByte3;
output reg [7:0] dataByte4;
output reg [1:0] initError;
output reg rxDataRdyClr;
output reg SDInitRdy;
output reg sendCmdReq;
output reg [7:0] spiClkDelayOut;
output reg spiCS_n;
output reg [7:0] txDataOut;
output reg txDataWen;
output reg SDHC;

reg [7:0] next_checkSumByte;
reg [7:0] next_cmdByte;
reg [7:0] next_dataByte1;
reg [7:0] next_dataByte2;
reg [7:0] next_dataByte3;
reg [7:0] next_dataByte4;
reg [1:0] next_initError;
reg next_rxDataRdyClr;
reg next_SDInitRdy;
reg next_sendCmdReq;
reg [7:0] next_spiClkDelayOut;
reg next_spiCS_n;
reg [7:0] next_txDataOut;
reg next_txDataWen;
reg next_SDHC;

// diagram signals declarations
reg  [9:0] delCnt1, next_delCnt1;
reg  [7:0] delCnt2, next_delCnt2;
reg  [15:0] loopCnt, next_loopCnt;

// BINARY ENCODED state machine: initSDSt
// State codes definitions:
typedef enum logic [4:0] {
	START = 5'd0,
	WT_INIT_REQ,
	CLK_SEQ_SEND_FF,
	CLK_SEQ_CHK_FIN,
	RESET_SEND_CMD,
	RESET_DEL,
	RESET_WT_FIN,
	RESET_CHK_FIN,
	INIT_WT_FIN,
	INIT_CHK_FIN,
	INIT_SEND_CMD,
	INIT_DEL1,
	INIT_DEL2,
	CLK_SEQ_WT_DATA_EMPTY,
	CMD8_QRY_CARDTYPE,
	CMD8_DEL,
	CMD8_WT_FIN,
	CMD8_CHK_FIN,
	CMD55_START,
	CMD55_DEL,
	CMD55_WT_FIN,
	CMD55_CHK_FIN,
	INIT_WT_FIN41,
	INIT_CHK_FIN41,
	INIT_SEND_CMD41,
	INIT_DEL41
} initSD_state_e;

initSD_state_e CurrState_initSDSt, NextState_initSDSt;

// Diagram actions (continuous assignments allowed only: assign ...)
// diagram ACTION


// Machine: initSDSt

// NextState logic (combinatorial)
always_comb
begin
  NextState_initSDSt <= CurrState_initSDSt;
  // Set default values for outputs and signals
  next_spiClkDelayOut <= spiClkDelayOut;
  next_SDInitRdy <= SDInitRdy;
  next_spiCS_n <= spiCS_n;
  next_initError <= initError;
  next_txDataOut <= txDataOut;
  next_txDataWen <= txDataWen;
  next_cmdByte <= cmdByte;
  next_dataByte1 <= dataByte1;
  next_dataByte2 <= dataByte2;
  next_dataByte3 <= dataByte3;
  next_dataByte4 <= dataByte4;
  next_checkSumByte <= checkSumByte;
  next_sendCmdReq <= sendCmdReq;
  next_loopCnt <= loopCnt;
  next_delCnt1 <= delCnt1;
  next_delCnt2 <= delCnt2;
  next_rxDataRdyClr <= rxDataRdyClr;
  next_SDHC <= SDHC;
  case (CurrState_initSDSt)  // synopsys parallel_case full_case
  START:
    begin
      next_spiClkDelayOut <= spiClkDelayIn;
      next_SDInitRdy <= 1'b0;
      next_spiCS_n <= 1'b1;
      next_initError <= `INIT_NO_ERROR;
      next_txDataOut <= 8'h00;
      next_txDataWen <= 1'b0;
      next_cmdByte <= 8'h00;
      next_dataByte1 <= 8'h00;
      next_dataByte2 <= 8'h00;
      next_dataByte3 <= 8'h00;
      next_dataByte4 <= 8'h00;
      next_checkSumByte <= 8'h00;
      next_sendCmdReq <= 1'b0;
      next_loopCnt <= 16'h0000;
      next_delCnt1 <= 10'h000;
      next_delCnt2 <= 8'h00;
      next_rxDataRdyClr <= 1'b0;
      NextState_initSDSt <= WT_INIT_REQ;
    end
  WT_INIT_REQ:
    begin
      next_SDInitRdy <= 1'b1;
      next_spiCS_n <= 1'b1;
     	next_spiClkDelayOut <= spiClkDelayIn;
      next_cmdByte <= 8'h00;
      next_dataByte1 <= 8'h00;
      next_dataByte2 <= 8'h00;
      next_dataByte3 <= 8'h00;
      next_dataByte4 <= 8'h00;
      next_checkSumByte <= 8'h00;
      if (SDInitReq) begin
        NextState_initSDSt <= CLK_SEQ_SEND_FF;
        next_SDInitRdy <= 1'b0;
        next_loopCnt <= 16'h00;
        next_spiClkDelayOut <= `SLOW_SPI_CLK;
        next_initError <= `INIT_NO_ERROR;
      end
    end
  CLK_SEQ_SEND_FF:
    begin
     	next_spiClkDelayOut <= `SLOW_SPI_CLK;
      if (txDataFull == 1'b0) begin
        NextState_initSDSt <= CLK_SEQ_CHK_FIN;
        next_txDataOut <= 8'hff;
        next_txDataWen <= 1'b1;
        next_loopCnt <= loopCnt + 1'b1;
      end
    end
  CLK_SEQ_CHK_FIN:
    begin
      next_txDataWen <= 1'b0;
      if (loopCnt == `SD_INIT_START_SEQ_LEN)
      begin
        NextState_initSDSt <= CLK_SEQ_WT_DATA_EMPTY;
      end
      else
      begin
        NextState_initSDSt <= CLK_SEQ_SEND_FF;
      end
    end
  CLK_SEQ_WT_DATA_EMPTY:
    begin
      if (txDataEmpty) begin
        NextState_initSDSt <= RESET_SEND_CMD;
        next_loopCnt <= 8'h00;
				next_spiCS_n <= 1'b0;
      end
    end

	RESET_SEND_CMD:
		begin
			next_cmdByte <= 8'h40;	// CMD0
			next_dataByte1 <= 8'h00;
			next_dataByte2 <= 8'h00;
			next_dataByte3 <= 8'h00;
			next_dataByte4 <= 8'h00;
			next_checkSumByte <= 8'h95;
			next_sendCmdReq <= 1'b1;
			next_loopCnt <= loopCnt + 1'b1;
			next_spiCS_n <= 1'b0;
			NextState_initSDSt <= RESET_DEL;
		end
	RESET_DEL:
		begin
			next_sendCmdReq <= 1'b0;
			NextState_initSDSt <= RESET_WT_FIN;
		end
	RESET_WT_FIN:
		begin
			if (sendCmdRdy) begin
				NextState_initSDSt <= RESET_CHK_FIN;
//				next_spiCS_n <= 1'b1;
			end
		end
	RESET_CHK_FIN:
		begin
			if ((respTout == 1'b1 || respByte != 8'h01) && loopCnt != 16'h0fff)
				NextState_initSDSt <= RESET_SEND_CMD;
			else if (respTout == 1'b1 || respByte != 8'h01) begin
				NextState_initSDSt <= WT_INIT_REQ;
				next_initError <= `INIT_CMD0_ERROR;
			end
			else begin
				next_loopCnt <= 12'h000;
				NextState_initSDSt <= INIT_SEND_CMD41;//CMD8_QRY_CARDTYPE;
			end
		end

	//2.CMD8 (Argument 0x000001AA, CRC 0x87) -> Response 0x01 0x000001AA -> Means it's SDC V2+
	CMD8_QRY_CARDTYPE:
		begin
			next_cmdByte <= 8'h48;		//CMD8
			next_dataByte1 <= 8'h00;
			next_dataByte2 <= 8'h00;
			next_dataByte3 <= 8'h01;
			next_dataByte4 <= 8'hAA;
			next_checkSumByte <= 8'h87;
			next_sendCmdReq <= 1'b1;
			next_loopCnt <= loopCnt + 1'b1;
			next_spiCS_n <= 1'b0;
			NextState_initSDSt <= CMD8_DEL;
		end
  CMD8_DEL:
		begin
			next_sendCmdReq <= 1'b0;
			NextState_initSDSt <= CMD8_WT_FIN;
		end
  CMD8_WT_FIN:
  	begin
			if (sendCmdRdy) begin
				NextState_initSDSt <= CMD8_CHK_FIN;
				next_spiCS_n <= 1'b1;
			end
		end
  CMD8_CHK_FIN:
  	begin
			if ((respByte != 8'h01 && respByte!=8'h00) && loopCnt != 16'hfff)
				NextState_initSDSt <= CMD8_QRY_CARDTYPE;
			else if (respByte == 8'h01 || respByte==8'h00) begin
				if (respByte1==8'h00 && respByte2==8'h00 && respByte3==8'h01 && respByte4==8'hAA)
				begin
					next_loopCnt <= 16'h000;
					NextState_initSDSt <= CMD55_START;
					next_SDHC <= 1'b1;
				end
				else begin
					next_loopCnt <= 16'h000;
					NextState_initSDSt <= CMD55_START;
					next_SDHC <= 1'b0;
				end
			end
			else if (respByte != 8'h01 && respByte != 8'h00) begin
				next_loopCnt <= 16'h000;
				NextState_initSDSt <= CMD55_START;
				next_SDHC <= 1'b0;
			end
			else begin
				next_loopCnt <= 16'h000;
				NextState_initSDSt <= CMD55_START;
			end
		end

	//
	CMD55_START:
		begin
			next_cmdByte <= 8'h77;		// CMD55 = 0x40+d55
			next_dataByte1 <= 8'h00;
			next_dataByte2 <= 8'h00;
			next_dataByte3 <= 8'h00;
			next_dataByte4 <= 8'h00;
			next_checkSumByte <= 8'h65;// 8'h95;
			next_sendCmdReq <= 1'b1;
			next_loopCnt <= loopCnt + 1'b1;
			next_spiCS_n <= 1'b0;
			NextState_initSDSt <= CMD55_DEL;
		end
  CMD55_DEL:
		begin
			next_sendCmdReq <= 1'b0;
			NextState_initSDSt <= CMD55_WT_FIN;
		end
  CMD55_WT_FIN:
    begin
			if (sendCmdRdy) begin
				NextState_initSDSt <= INIT_SEND_CMD41;//`CMD55_CHK_FIN;
				next_spiCS_n <= 1'b1;
			end
		end


	INIT_SEND_CMD41:
		begin
			next_cmdByte <= 8'h69;	//ACMD41
//			if (SDHC)
//				next_dataByte1 <= 8'h40;	// 8'h40
//			else
				next_dataByte1 <= 8'h00;
			next_dataByte2 <= 8'h00;
			next_dataByte3 <= 8'h00;
			next_dataByte4 <= 8'h00;
			next_checkSumByte <= 8'h01;//8'h95;
			next_sendCmdReq <= 1'b1;
			next_spiCS_n <= 1'b0;
			next_delCnt1 <= 10'h000;
			NextState_initSDSt <= INIT_DEL41;
		end
  INIT_DEL41:
		begin
			next_sendCmdReq <= 1'b0;
			NextState_initSDSt <= INIT_WT_FIN41;
		end
  INIT_WT_FIN41:
    begin
      if (sendCmdRdy == 1'b1)
      begin
        NextState_initSDSt <= INIT_CHK_FIN41;
        next_spiCS_n <= 1'b1;
      end
    end
  INIT_CHK_FIN41:
    begin
      if ((respTout == 1'b1 || respByte != 8'h00) && loopCnt != 16'hfff)
      begin
        NextState_initSDSt <= INIT_SEND_CMD41;//CMD55_START;
      end
      else if (respTout == 1'b1 || respByte != 8'h00)
      begin
        NextState_initSDSt <= WT_INIT_REQ;
        next_initError <= `INIT_CMD1_ERROR;
      end
      else
      begin
        NextState_initSDSt <= WT_INIT_REQ;
        next_spiClkDelayOut <= spiClkDelayIn;
      end
    end
//	`INIT_SEND_CMD:
//		begin
//			next_cmdByte <= 8'h41;	//CMD1
//			next_dataByte1 <= 8'h00;
//			next_dataByte2 <= 8'h00;
//			next_dataByte3 <= 8'h00;
//			next_dataByte4 <= 8'h00;
//			next_checkSumByte <= 8'h95;
//			next_sendCmdReq <= 1'b1;
//			next_spiCS_n <= 1'b0;
//			next_delCnt1 <= 10'h000;
//			NextState_initSDSt <= `INIT_DEL1;
//		end
//    `INIT_DEL1:
//    begin
//      next_delCnt1 <= delCnt1 + 1'b1;
//      next_delCnt2 <= 8'h00;
//      next_sendCmdReq <= 1'b0;
//      if (delCnt1 == `TWO_MS)
//      begin
//        NextState_initSDSt <= `INIT_WT_FIN;
//      end
//      else
//      begin
//        NextState_initSDSt <= `INIT_DEL2;
//      end
//    end
//    `INIT_DEL2:
//    begin
//      next_delCnt2 <= delCnt2 + 1'b1;
//      if (delCnt2 == 8'hff)
//      begin
//        NextState_initSDSt <= `INIT_DEL1;
//      end
//    end
  endcase
end

// Current State Logic (sequential)
always_ff @(posedge clk)
if (rst)
  CurrState_initSDSt <= START;
else
  CurrState_initSDSt <= NextState_initSDSt;

// Registered outputs logic
always_ff @(posedge clk)
begin
  if (rst) begin
    spiClkDelayOut <= `SLOW_SPI_CLK;//spiClkDelayIn;
    SDInitRdy <= 1'b0;
    spiCS_n <= 1'b1;
    initError <= `INIT_NO_ERROR;
    txDataOut <= 8'h00;
    txDataWen <= 1'b0;
    cmdByte <= 8'h00;
    dataByte1 <= 8'h00;
    dataByte2 <= 8'h00;
    dataByte3 <= 8'h00;
    dataByte4 <= 8'h00;
    checkSumByte <= 8'h00;
    sendCmdReq <= 1'b0;
    rxDataRdyClr <= 1'b0;
    loopCnt <= 8'h00;
    delCnt1 <= 10'h000;
    delCnt2 <= 8'h00;
	SDHC <= 1'b1;
  end
  else begin
    spiClkDelayOut <= next_spiClkDelayOut;
    SDInitRdy <= next_SDInitRdy;
    spiCS_n <= next_spiCS_n;
    initError <= next_initError;
    txDataOut <= next_txDataOut;
    txDataWen <= next_txDataWen;
    cmdByte <= next_cmdByte;
    dataByte1 <= next_dataByte1;
    dataByte2 <= next_dataByte2;
    dataByte3 <= next_dataByte3;
    dataByte4 <= next_dataByte4;
    checkSumByte <= next_checkSumByte;
    sendCmdReq <= next_sendCmdReq;
    rxDataRdyClr <= next_rxDataRdyClr;
    loopCnt <= next_loopCnt;
    delCnt1 <= next_delCnt1;
    delCnt2 <= next_delCnt2;
	SDHC <= next_SDHC;
  end
end

endmodule