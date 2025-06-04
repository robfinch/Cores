//////////////////////////////////////////////////////////////////////
////                                                              ////
//// spiMasterWishBoneBI.v                                        ////
////                                                              ////
//// This file is part of the spiMaster opencores effort.
//// <http://www.opencores.org/cores//>                           ////
////                                                              ////
//// Module Description:                                          ////
////  Control WB access to fifos and control and status registers 
////                                                              ////
//// To Do:                                                       ////
//// 
////                                                              ////
//// Author(s):                                                   ////
//// - Steve Fielding, sfielding@base2designs.com                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2008 Steve Fielding and OPENCORES.ORG          ////
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

 
module spiMasterWishBoneBI (
  clk, rst,
  address, dataIn, dataOut, writeEn, 
  strobe_i,
  ack_o,
  ctrlStsRegSel, 
  rxFifoSel, txFifoSel,
  dataFromCtrlStsReg,
  dataFromRxFifo,
  dataFromTxFifo,
	respByte1,
	respByte2,
	respByte3,
	respByte4
  );
input clk;
input rst;
input [7:0] address;
input [7:0] dataIn;
output [7:0] dataOut;
input strobe_i;
output ack_o;
input writeEn;
output ctrlStsRegSel;
output rxFifoSel;
output txFifoSel;
input [7:0] dataFromCtrlStsReg;
input [7:0] dataFromRxFifo;
input [7:0] dataFromTxFifo;
input [7:0] respByte1;
input [7:0] respByte2;
input [7:0] respByte3;
input [7:0] respByte4;

wire clk;
wire rst;
wire [7:0] address;
wire [7:0] dataIn;
reg [7:0] dataOut;
wire writeEn;
wire strobe_i;
reg ack_o;
reg ctrlStsRegSel;
reg rxFifoSel;
reg txFifoSel;
wire [7:0] dataFromCtrlStsReg;
wire [7:0] dataFromRxFifo;
wire [7:0] dataFromTxFifo;

//internal wires and regs
reg ack_delayed;
reg ack_immediate;

//address decode and data mux
always_comb
begin
  ctrlStsRegSel = 1'b0;
  rxFifoSel = 1'b0;
  txFifoSel = 1'b0;
  if (strobe_i)
	  case (address & `ADDRESS_DECODE_MASK)
    `CTRL_STS_REG_BASE : begin
	      ctrlStsRegSel = 1'b1;
	      dataOut = dataFromCtrlStsReg;
	    end
		`CMD_RESP_BASE: begin
				case(address[2:0])
				3'b000:	dataOut = respByte1;
				3'b001:	dataOut = respByte2;
				3'b010:	dataOut = respByte3;
				3'b011:	dataOut = respByte4;
				default:	dataOut = 8'h00;
				endcase
			end
	  `RX_FIFO_BASE : begin
		    rxFifoSel = 1'b1;
		    dataOut = dataFromRxFifo;
		  end
	  `TX_FIFO_BASE : begin
		    txFifoSel = 1'b1;
		    dataOut = dataFromTxFifo;
		  end
	  default: 
	    dataOut = 8'h00;
	  endcase
	else
		dataOut = 8'h00;
end

//delayed ack
always_ff @(posedge clk)
  ack_delayed <= strobe_i;

//immediate ack
always_comb
  ack_immediate = strobe_i;

//select between immediate and delayed ack
always_comb
  if (writeEn == 1'b0 &&
      (address == `RX_FIFO_BASE + `FIFO_DATA_REG ||
       address == `TX_FIFO_BASE + `FIFO_DATA_REG) )
    ack_o = ack_delayed & ack_immediate;
  else
    ack_o = ack_immediate;
end

endmodule
