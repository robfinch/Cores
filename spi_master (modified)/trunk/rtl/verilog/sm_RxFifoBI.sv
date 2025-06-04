//////////////////////////////////////////////////////////////////////
////                                                              ////
//// sm_RxfifoBI.v                                                ////
////                                                              ////
//// This file is part of the spiMaster opencores effort.
//// <http://www.opencores.org/cores//>                           ////
////                                                              ////
//// Module Description:                                          ////
//// 
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

module sm_RxfifoBI (
  address, 
  writeEn, 
  strobe_i,
  busClk, 
  spiSysClk, 
  rstSyncToBusClk, 
  fifoSelect,
  fifoDataIn,
  busDataIn, 
  busDataOut,
  fifoREn,
  forceEmptySyncToSpiClk,
  forceEmptySyncToBusClk,
  numElementsInFifo
  );
input [2:0] address;
input writeEn;
input strobe_i;
input busClk;
input spiSysClk;
input rstSyncToBusClk;
input [7:0] fifoDataIn;
input [7:0] busDataIn; 
output [7:0] busDataOut;
output fifoREn;
output forceEmptySyncToSpiClk;
output forceEmptySyncToBusClk;
input [15:0] numElementsInFifo;
input fifoSelect;


wire [2:0] address;
wire writeEn;
wire strobe_i;
wire busClk;
wire spiSysClk;
wire rstSyncToBusClk;
wire [7:0] fifoDataIn;
wire [7:0] busDataIn; 
reg [7:0] busDataOut;
reg fifoREn;
wire forceEmptySyncToSpiClk;
wire forceEmptySyncToBusClk;
wire [15:0] numElementsInFifo;
wire fifoSelect;

reg forceEmptyReg;
reg forceEmpty;
reg forceEmptyToggle;
reg [2:0] forceEmptyToggleSyncToSpiClk;

//sync write
always_ff @(posedge busClk)
begin
  if (writeEn == 1'b1 && fifoSelect == 1'b1 && 
    address == `FIFO_CONTROL_REG && strobe_i == 1'b1 && busDataIn[0] == 1'b1)
    forceEmpty <= 1'b1;
  else
    forceEmpty <= 1'b0;
end

//detect rising edge of 'forceEmpty', and generate toggle signal
always_ff @(posedge busClk) begin
  if (rstSyncToBusClk == 1'b1) begin
    forceEmptyReg <= 1'b0;
    forceEmptyToggle <= 1'b0;
  end
  else begin
    if (forceEmpty == 1'b1)
      forceEmptyReg <= 1'b1;
    else
      forceEmptyReg <= 1'b0;
    if (forceEmpty == 1'b1 && forceEmptyReg == 1'b0)
      forceEmptyToggle <= ~forceEmptyToggle;
  end
end
assign forceEmptySyncToBusClk = (forceEmpty == 1'b1 && forceEmptyReg == 1'b0) ? 1'b1 : 1'b0;


// double sync across clock domains to generate 'forceEmptySyncToSpiClk'
always_ff @(posedge spiSysClk)
  forceEmptyToggleSyncToSpiClk <= {forceEmptyToggleSyncToSpiClk[1:0], forceEmptyToggle};
assign forceEmptySyncToSpiClk = forceEmptyToggleSyncToSpiClk[2] ^ forceEmptyToggleSyncToSpiClk[1];

// async read mux
always_comb
begin
  case (address)
  `FIFO_DATA_REG : busDataOut = fifoDataIn;
  `FIFO_DATA_COUNT_MSB : busDataOut = numElementsInFifo[15:8];
  `FIFO_DATA_COUNT_LSB : busDataOut = numElementsInFifo[7:0];
  default: busDataOut = 8'h00; 
  endcase
end

//generate fifo read strobe
always_comb begin
  if (address == `FIFO_DATA_REG && writeEn == 1'b0 && 
	  strobe_i == 1'b1 &&   fifoSelect == 1'b1)
    fifoREn = 1'b1;
  else
    fifoREn = 1'b0;
end


endmodule
