
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// sendCmd.v                                           ////
////                                                              ////
//// This file is part of the spiMaster opencores effort.
//// <http://www.opencores.org/cores//>                           ////
////                                                              ////
//// Module Description:                                          ////
////  If sendCmdReq asserted, then send command to 
////  SD card. Command consists of command byte,
////  4 data bytes, and a checksum byte. 
//// Waits for response byte from SD card
////  or times out if no response
////                                                              ////
//// To Do:                                                       ////
//// 
////                                                              ////
//// Author(s):                                                   ////
//// - Steve Fielding, sfielding@base2designs.com                 ////
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


module sendCmd (checkSumByte_1, checkSumByte_2, clk, cmdByte_1, cmdByte_2, dataByte1_1, dataByte1_2, dataByte2_1, dataByte2_2, dataByte3_1, dataByte3_2, dataByte4_1, dataByte4_2,
	respByte, respByte1, respByte2, respByte3, respByte4,
	respTout, rst, rxDataIn, rxDataRdy, rxDataRdyClr, sendCmdRdy, sendCmdReq1, sendCmdReq2, txDataEmpty, txDataFull, txDataOut, txDataWen);
input   [7:0]checkSumByte_1;
input   [7:0]checkSumByte_2;
input   clk;
input   [7:0]cmdByte_1;
input   [7:0]cmdByte_2;
input   [7:0]dataByte1_1;
input   [7:0]dataByte1_2;
input   [7:0]dataByte2_1;
input   [7:0]dataByte2_2;
input   [7:0]dataByte3_1;
input   [7:0]dataByte3_2;
input   [7:0]dataByte4_1;
input   [7:0]dataByte4_2;
input   rst;
input   [7:0]rxDataIn;
input   rxDataRdy;
input   sendCmdReq1;
input   sendCmdReq2;
input   txDataEmpty;
input   txDataFull;
output  [7:0]respByte;
output  [7:0]respByte1;
output  [7:0]respByte2;
output  [7:0]respByte3;
output  [7:0]respByte4;
output  respTout;
output  rxDataRdyClr;
output  sendCmdRdy;
output  [7:0]txDataOut;
output  txDataWen;

wire    [7:0]checkSumByte_1;
wire    [7:0]checkSumByte_2;
wire    clk;
wire    [7:0]cmdByte_1;
wire    [7:0]cmdByte_2;
wire    [7:0]dataByte1_1;
wire    [7:0]dataByte1_2;
wire    [7:0]dataByte2_1;
wire    [7:0]dataByte2_2;
wire    [7:0]dataByte3_1;
wire    [7:0]dataByte3_2;
wire    [7:0]dataByte4_1;
wire    [7:0]dataByte4_2;
reg     [7:0]respByte, next_respByte;
reg     respTout, next_respTout;
wire    rst;
wire    [7:0]rxDataIn;
wire    rxDataRdy;
reg     rxDataRdyClr, next_rxDataRdyClr;
reg     sendCmdRdy, next_sendCmdRdy;
wire    sendCmdReq1;
wire    sendCmdReq2;
wire    txDataEmpty;
wire    txDataFull;
reg     [7:0]txDataOut, next_txDataOut;
reg     txDataWen, next_txDataWen;
reg  [7:0]respByte1;
reg  [7:0]respByte2;
reg  [7:0]respByte3;
reg  [7:0]respByte4;

// diagram signals declarations
reg  [7:0]checkSumByte, next_checkSumByte;
reg  [7:0]cmdByte, next_cmdByte;
reg  [7:0]dataByte1, next_dataByte1;
reg  [7:0]dataByte2, next_dataByte2;
reg  [7:0]dataByte3, next_dataByte3;
reg  [7:0]dataByte4, next_dataByte4;
reg sendCmdReq, next_sendCmdReq;
reg  [9:0]timeOutCnt, next_timeOutCnt;

// BINARY ENCODED state machine: sndCmdSt
// State codes definitions:
typedef enum logic [4:0] 
{
	ST_S_CMD = 5'd0,
	WT_CMD,
	CMD_SEND_FF_ST,
	CMD_SEND_FF_FIN,
	CMD_CMD_BYTE_ST,
	CMD_CMD_BYTE_FIN,
	CMD_D_BYTE1_ST,
	CMD_D_BYTE1_FIN,
	CMD_D_BYTE2_ST,
	CMD_D_BYTE2_FIN,
	CMD_D_BYTE3_ST,
	CMD_D_BYTE3_FIN,
	CMD_D_BYTE4_ST,
	CMD_D_BYTE4_FIN,
	CMD_CS_ST,
	CMD_CS_FIN,
	CMD_REQ_RESP_ST,
	CMD_REQ_RESP_FIN,
	CMD_CHK_RESP,
	CMD_DEL
} sendCmd_e;

sendCmd_e CurrState_sndCmdSt, NextState_sndCmdSt;
reg [2:0] respCtr, next_respCtr;
reg [2:0] maxRespCnt, next_maxRespCnt;
reg [7:0] next_respByte1;
reg [7:0] next_respByte2;
reg [7:0] next_respByte3;
reg [7:0] next_respByte4;

// Diagram actions (continuous assignments allowed only: assign ...)
// diagram ACTION
always_ff @(posedge clk)
	sendCmdReq = sendCmdReq1 | sendCmdReq2;

always_ff @(posedge clk) begin
	cmdByte <= cmdByte_1 | cmdByte_2;
	dataByte1 <= dataByte1_1 | dataByte1_2;
	dataByte2 <= dataByte2_1 | dataByte2_2;
	dataByte3 <= dataByte3_1 | dataByte3_2;
	dataByte4 <= dataByte4_1 | dataByte4_2;
	checkSumByte <= checkSumByte_1 | checkSumByte_2;
end


// Machine: sndCmdSt

// NextState logic (combinatorial)
always_comb
begin
  NextState_sndCmdSt = CurrState_sndCmdSt;
  // Set default values for outputs and signals
  next_txDataWen = txDataWen;
  next_txDataOut = txDataOut;
  next_timeOutCnt = timeOutCnt;
  next_rxDataRdyClr = rxDataRdyClr;
  next_respByte = respByte;
  next_respByte1 = respByte1;
  next_respByte2 = respByte2;
  next_respByte3 = respByte3;
  next_respByte4 = respByte4;
  next_respTout = respTout;
  next_sendCmdRdy = sendCmdRdy;
  next_respCtr = respCtr;
  next_maxRespCnt = 3'd0;
  case (CurrState_sndCmdSt)  // synopsys parallel_case full_case
  ST_S_CMD:
    begin
      next_sendCmdRdy = 1'b0;
      next_txDataWen = 1'b0;
      next_txDataOut = 8'hff;	// was 00
      next_rxDataRdyClr = 1'b0;
      next_respByte = 8'h00;
      next_respTout = 1'b0;
      next_timeOutCnt = 10'h000;
      NextState_sndCmdSt = WT_CMD;
    end
  WT_CMD:
    begin
      next_txDataWen = 1'b0;
      next_sendCmdRdy = 1'b1;
      if (sendCmdReq == 1'b1) begin
        NextState_sndCmdSt = CMD_SEND_FF_ST;
        next_sendCmdRdy = 1'b0;
        next_respTout = 1'b0;
				next_respCtr = 3'd0;
      end
    end
  CMD_SEND_FF_ST:
    if (!txDataFull) begin
      NextState_sndCmdSt = CMD_SEND_FF_FIN;
      next_txDataOut = 8'hff;
      next_txDataWen = 1'b1;
    end
  CMD_SEND_FF_FIN:
  	begin
			next_txDataWen = 1'b0;
      NextState_sndCmdSt = CMD_CMD_BYTE_ST;
    end
  CMD_CMD_BYTE_ST:
		begin
			if (!txDataFull) begin
				NextState_sndCmdSt = CMD_CMD_BYTE_FIN;
				next_txDataOut = cmdByte;
				next_txDataWen = 1'b1;
				case(cmdByte)
				8'h48:	next_maxRespCnt = 3'd4;
				default: next_maxRespCnt = 3'd0;
				endcase
			end
		end
  CMD_CMD_BYTE_FIN:
  	begin
			next_txDataWen = 1'b0;
			NextState_sndCmdSt = CMD_D_BYTE1_ST;
  	end
  CMD_D_BYTE1_ST:
    begin
      if (!txDataFull) begin
        NextState_sndCmdSt = CMD_D_BYTE1_FIN;
        next_txDataOut = dataByte1;
        next_txDataWen = 1'b1;
      end
    end
  CMD_D_BYTE1_FIN:
  	begin
      next_txDataWen = 1'b0;
      NextState_sndCmdSt = CMD_D_BYTE2_ST;
  	end
  CMD_D_BYTE2_ST:
    begin
      if (!txDataFull) begin
        NextState_sndCmdSt = CMD_D_BYTE2_FIN;
        next_txDataOut = dataByte2;
        next_txDataWen = 1'b1;
      end
    end
  CMD_D_BYTE2_FIN:
  	begin
      next_txDataWen = 1'b0;
      NextState_sndCmdSt = CMD_D_BYTE3_ST;
  	end
  CMD_D_BYTE3_ST:
    begin
      if (txDataFull == 1'b0) begin
        NextState_sndCmdSt = CMD_D_BYTE3_FIN;
        next_txDataOut = dataByte3;
        next_txDataWen = 1'b1;
      end
    end
  CMD_D_BYTE3_FIN:
  	begin
      next_txDataWen = 1'b0;
      NextState_sndCmdSt = CMD_D_BYTE4_ST;
  	end
  CMD_D_BYTE4_ST:
    begin
      if (!txDataFull) begin
        NextState_sndCmdSt = CMD_D_BYTE4_FIN;
        next_txDataOut = dataByte4;
        next_txDataWen = 1'b1;
      end
    end
  CMD_D_BYTE4_FIN:
  	begin
      next_txDataWen = 1'b0;
      NextState_sndCmdSt = CMD_CS_ST;
  	end
  CMD_CS_ST:
    begin
      if (!txDataFull) begin
        NextState_sndCmdSt = CMD_CS_FIN;
        next_txDataOut = checkSumByte;
        next_txDataWen = 1'b1;
      end
    end
  CMD_CS_FIN:
    begin
      next_txDataWen = 1'b0;
      next_timeOutCnt = 10'h000;
      if (txDataEmpty == 1'b1) begin
        NextState_sndCmdSt = CMD_REQ_RESP_ST;
      end
    end
  CMD_REQ_RESP_ST:
		begin
			NextState_sndCmdSt = CMD_DEL;
			next_txDataOut = 8'hff;
			next_txDataWen = 1'b1;
			next_timeOutCnt = timeOutCnt + 1'b1;
			next_rxDataRdyClr = 1'b1;
		end
  CMD_DEL:
		begin
			NextState_sndCmdSt = CMD_REQ_RESP_FIN;
			next_txDataWen = 1'b0;
			next_rxDataRdyClr = 1'b0;
		end
  CMD_REQ_RESP_FIN:
		if (rxDataRdy == 1'b1) begin
			if (cmdByte==8'h48) begin
				case(respCtr)
				3'd0:	begin next_respByte = rxDataIn; NextState_sndCmdSt = CMD_CHK_RESP; end
				3'd1:	begin next_respByte1 = rxDataIn; NextState_sndCmdSt = CMD_CHK_RESP; end
				3'd2:	begin next_respByte2 = rxDataIn; NextState_sndCmdSt = CMD_CHK_RESP; end
				3'd3:	begin next_respByte3 = rxDataIn; NextState_sndCmdSt = CMD_CHK_RESP; end
				3'd4:	begin next_respByte4 = rxDataIn; NextState_sndCmdSt = CMD_CHK_RESP; end
				default:	NextState_sndCmdSt = CMD_CHK_RESP;
				endcase
			end
			else begin
				NextState_sndCmdSt = CMD_CHK_RESP;
				next_respByte = rxDataIn;
			end
		end
  CMD_CHK_RESP:
		begin
			// We don't set the timeout flag for a CMD8 because there might be
			// a low capacity card that doesn't recognize the command.
			if (cmdByte==8'h48) begin
				if (timeOutCnt == 10'h200)
					NextState_sndCmdSt = WT_CMD;
				else if (respCtr==maxRespCnt)
					NextState_sndCmdSt = WT_CMD;
				else if (respCtr==3'd0 && respByte == 8'h05)	// illegal command (non v2 card)
					NextState_sndCmdSt = WT_CMD;
				else if (respCtr==3'd0 && respByte[7])			// hasn't responded yet
					NextState_sndCmdSt = CMD_REQ_RESP_ST;
				else begin										// we got a response byte, go back for another one
					next_timeOutCnt = 10'h000;
					next_respCtr = respCtr + 3'd1;
					NextState_sndCmdSt = CMD_REQ_RESP_ST;
				end
			end
			else
			begin
				if (timeOutCnt == 10'h200) begin
					NextState_sndCmdSt = WT_CMD;
					if (cmdByte != 8'h77) next_respTout = 1'b1;
				end 
				else if (respByte[7] == 1'b0)
					NextState_sndCmdSt = WT_CMD;
				else
					NextState_sndCmdSt = CMD_REQ_RESP_ST;
			end
		end
  default:
  	NextState_sndCmdSt = ST_S_CMD;
  endcase
end

// Current State Logic (sequential)
always_ff @(posedge clk)
begin
  if (rst)
    CurrState_sndCmdSt <= ST_S_CMD;
  else
    CurrState_sndCmdSt <= NextState_sndCmdSt;
end

// Registered outputs logic
always_ff @(posedge clk)
if (rst) begin
  txDataWen <= 1'b0;
  txDataOut <= 8'hff;
  rxDataRdyClr <= 1'b0;
  respByte <= 8'h00;
  respByte1 <= 8'h00;
  respByte2 <= 8'h00;
  respByte3 <= 8'h00;
  respByte4 <= 8'h00;
  respTout <= 1'b0;
  sendCmdRdy <= 1'b0;
  timeOutCnt <= 10'h000;
	respCtr <= 3'd0;
	maxRespCnt <= 3'd0;
end
else begin
  txDataWen <= next_txDataWen;
  txDataOut <= next_txDataOut;
  rxDataRdyClr <= next_rxDataRdyClr;
  respByte <= next_respByte;
  respByte1 <= next_respByte1;
  respByte2 <= next_respByte2;
  respByte3 <= next_respByte3;
  respByte4 <= next_respByte4;
  respTout <= next_respTout;
  sendCmdRdy <= next_sendCmdRdy;
  timeOutCnt <= next_timeOutCnt;
	respCtr <= next_respCtr;
	maxRespCnt <= next_maxRespCnt;
end

endmodule
