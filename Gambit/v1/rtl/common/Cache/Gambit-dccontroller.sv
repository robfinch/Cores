// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DCController.v
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//
// ============================================================================
// 3668
`include "..\Gambit-config.sv"
`define HIGH	1'b1
`define LOW		1'b0

module DCController(rst_i, clk_i, dadr, rd, wr, wsel, wadr, wdat, bstate, state,
	invline, invlineAddr, icl_ctr, isROM, ROM_dat,
	dL2_rhit, dL2_rdat, dL2_whit, dL2_ld, dL2_wsel, dL2_wadr, dL2_wdat, dL2_nxt,
	dL1_hit, dL1_selpc, dL1_sel, dL1_adr, dL1_dat, dL1_wr, dL1_invline, dcnxt, dcwhich,
	dcl_o, cti_o, bte_o, bok_i, cyc_o, stb_o, ack_i, err_i, wrv_i, rdv_i, sel_o, adr_o, dat_i);
parameter ABW = 52;
parameter AMSB = ABW-1;
parameter L2_ReadLatency = 3'd3;
parameter L1_WriteLatency = 3'd3;
parameter ROM_ReadLatency = 3'd1;
input rst_i;
input clk_i;
input [AMSB:0] dadr;
input rd;
input wr;
input [7:0] wsel;
input [AMSB:0] wadr;
input [51:0] wdat;
input [4:0] bstate;
(* mark_debug="true" *)
output reg [3:0] state;
input invline;
input [71:0] invlineAddr;
output reg [39:0] icl_ctr;
output isROM;
input [415:0] ROM_dat;
input dL2_rhit;
input [467:0] dL2_rdat;
input dL2_whit;
output reg dL2_ld;
output reg [58:0] dL2_wsel;
output reg [AMSB:0] dL2_wadr;
output reg [467:0] dL2_wdat;
output reg dL2_nxt;

input dL1_hit;
output dL1_selpc;
output reg [AMSB:0] dL1_adr;
output reg [467:0] dL1_dat = 468'd0;	// NOP
output reg dL1_wr;
output reg [58:0] dL1_sel;
output reg dL1_invline;
output reg dcnxt;
output reg [1:0] dcwhich = 2'b00;

output reg dcl_o;
output reg [2:0] cti_o = 3'b000;
output reg [1:0] bte_o = 2'b00;
input bok_i;
output reg cyc_o = 1'b0;
output reg stb_o;
input ack_i;
input err_i;
input wrv_i;
input rdv_i;
output reg [7:0] sel_o;
output reg [AMSB:0] adr_o;
input [103:0] dat_i;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

reg [3:0] picstate;
`include "..\Gambit-busStates.sv"
reg invline_r = 1'b0;
reg [79:0] invlineAddr_r = 72'd0;

//assign L2_ld = (state==IC_Ack) && (ack_i|err_i|tlbmiss_i|exv_i);
assign dL1_selpc = (state==IDLE||state==IC5) && !invline_r;
assign isROM = dL1_adr[51:18]=={34{1'b1}};

wire clk = clk_i;
reg [2:0] dccnt;

//BUFH uclkb (.I(clk_i), .O(clk));

always @(posedge clk)
if (rst_i) begin
	icl_ctr <= 40'd0;
	dcl_o <= `LOW;
	cti_o <= 3'b000;
	bte_o <= 2'b00;
	cyc_o <= `LOW;
	stb_o <= `LOW;
	sel_o <= 16'h00;
	adr_o <= {dadr[AMSB:4],4'h0};
	state <= IDLE;
	dL1_adr <= 1'd0;
	dL2_ld <= FALSE;
`ifdef SIM
	dL1_dat <= 1'd0;
	dL2_wdat <= 1'd0;
`endif
end
else begin
dL1_wr <= FALSE;
dL1_invline <= FALSE;
dcnxt <= FALSE;
dL2_ld <= FALSE;
dL2_nxt <= FALSE;
if (invline) begin
	invline_r <= 1'b1;
	invlineAddr_r <= invlineAddr;
end

// Instruction cache state machine.
// On a miss first see if the instruction is in the L2 cache. No need to go to
// the BIU on an L1 miss.
// If not the machine will wait until the BIU loads the L2 cache.

// Capture the previous ic state, used to determine how long to wait in
// icstate #4.
picstate <= state;
case(state)
IDLE:
	begin
		dL2_ld <= FALSE;
		dL2_wsel <= wsel << wadr[4:0];
		dL2_wsel[71] <= 1'b1;
		dL2_wadr <= {wadr[AMSB:5],5'h0};
		dL2_wdat <= {512'd0,wdat} << (wadr[4:0] * 13);
		dccnt <= 3'd0;
		if (invline_r) begin
			dL1_adr <= {invlineAddr_r[AMSB:5],5'b0};
			dL1_invline <= TRUE;
			invline_r <= 1'b0;
		end
		// If the bus unit is busy doing an update involving L1_adr or L2_adr
		// we have to wait.
		else begin
			if (dL1_hit && wr) begin
				dL1_wr <= 1'b1;
				dL1_sel <= wsel << wadr[4:0];
				dL1_sel[71] <= 1'b1;
				dL1_adr <= {wadr[AMSB:5],5'h0};
				dL1_dat <= {512'd0,wdat} << (wadr[4:0] * 13);
				dL2_ld <= 1'b1;
			end
			else if (!dL1_hit && rd && !(dL2_whit && wr)) begin
				dL1_adr <= {dadr[AMSB:5],5'h0};
				dcwhich <= 2'b00;
				state <= IC2;
			end
			// Since everything in L1 is in L2 a hit on L1 must be a hit on L2
			// as well.
			if (dL2_whit && wr) begin
				dL2_ld <= 1'b1;
			end
		end
	end
IC2:
	begin
		dccnt <= dccnt + 3'd1;
		if (isROM) begin
			if (dccnt==ROM_ReadLatency) begin
				state <= IC_WaitROM;
				dL1_wr <= TRUE;
				dL1_sel <= {59{1'b1}};
				dL1_dat <= {256'd0,ROM_dat};
				dccnt <= 3'd0;
				state <= IC5;
			end
		end
		else begin
			if (dccnt==L2_ReadLatency) begin
				dccnt <= 3'd0;
		    state <= IC_WaitL2;
		  end
		end
	end

// If data was in the L2 cache already there's no need to wait on the
// BIU to retrieve data. It can be determined if the hit signal was
// already active when this state was entered in which case waiting
// will do no good.
// The IC machine will stall in this state until the BIU is ready for
// data transfers. 
IC_WaitL2: 
	if (dL2_rhit && picstate==IC2) begin
		dL1_wr <= TRUE;
		dL1_sel <= {59{1'b1}};
		dL1_dat <= dL2_rdat;
		dccnt <= 3'd0;
		state <= IC5;
	end
	else begin
		begin
			dccnt <= 3'd0;
			dcl_o <= `HIGH;
			cti_o <= 3'b001;
			bte_o <= 2'b00;
			cyc_o <= `HIGH;
			stb_o <= `HIGH;
			sel_o <= 8'hFF;
			adr_o <= {dL1_adr[AMSB:5],5'b0};
			dL2_wadr <= dL1_adr;
			dL2_wadr[4:0] <= 5'd0;
			dL2_ld <= TRUE;
			state <= IC_Ack;
		end
	end
// Wait for the L1 write latency to expire before continuing. Writes to the L1
// cache need to be visible before the processor can continue. Also pulse the
// random number generator associated with choosing a way.
IC5: 	
	begin
		dccnt <= dccnt + 3'd1;
		if (dccnt==L1_WriteLatency) begin
			dcnxt <= TRUE;
			dL2_nxt <= TRUE;	// Dont really need to advance if L2 hit.
			state <= IDLE;
		end
	end
IC_Ack:
  if (ack_i|err_i|wrv_i|rdv_i) begin
  	if (!bok_i) begin
  		stb_o <= `LOW;
			adr_o[AMSB:3] <= adr_o[AMSB:3] + 2'd1;
  		state <= IC_Nack2;
  	end
		if (wrv_i) begin
			dL1_dat[467:465] <= 2'd1;
			dL1_dat[464:0] <= 464'd0;
			dL2_wdat[467:465] <= 2'd1;
			dL2_wdat[464:0] <= 468'd0;
			nack();
	  end
		else if (rdv_i) begin
			dL1_dat[467:465] <= 2'd2;
			dL1_dat[464:0] <= 464'd0;
			dL2_wdat[467:465] <= 2'd1;
			dL2_wdat[464:0] <= 468'd0;
			nack();
		end
	  else if (err_i) begin
			dL1_dat[467:465] <= 2'd3;
			dL1_dat[464:0] <= 464'd0;
			dL2_wdat[467:465] <= 2'd1;
			dL2_wdat[464:0] <= 468'd0;
			nack();
	  end
	  else begin
	  	case(dccnt)
	  	3'd0:	dL1_dat[127:0] <= dat_i;
	  	3'd1:	dL1_dat[255:128] <= dat_i;
	  	3'd2:	dL1_dat[383:256] <= dat_i;
	  	3'd3:	dL1_dat[467:384] <= {8'h00,dat_i[69:0]};
	  	default:	dL1_dat <= dL1_dat;
	  	endcase
	  	case(dccnt)
	  	3'd0:	dL2_wdat[127:0] <= dat_i;
	  	3'd1:	dL2_wdat[255:128] <= dat_i;
	  	3'd2:	dL2_wdat[383:256] <= dat_i;
	  	3'd3:	dL2_wdat[467:384] <= {8'h00,dat_i[69:0]};
	  	default:	dL2_wdat <= dL2_wdat;
	  	endcase
	  end
    dccnt <= dccnt + 3'd1;
    if (dccnt==3'd2)
      cti_o <= 3'b111;
    if (dccnt==3'd3)
    	nack();
  end
// This state only used when burst mode is not allowed.
IC_Nack2:
	if (~ack_i) begin
		stb_o <= `HIGH;
		state <= IC_Ack;
	end
// The cycle after data loading is complete, pulse the L1 write to update the
// cache.
IC_Nack:
	begin
		dL2_ld <= TRUE;
		dL2_wsel <= {59{1'b1}};
    dccnt <= 3'd0;
		dL1_wr <= TRUE;
		dL1_sel <= {59{1'b1}};
		icl_ctr <= icl_ctr + 40'd1;
		state <= IC5;	// Wait for write latency to expire
	end
default:
	begin
   	state <= IDLE;
  end
endcase
end

task nack;
begin
	dcl_o <= `LOW;
	cti_o <= 3'b000;
	cyc_o <= `LOW;
	stb_o <= `LOW;
	state <= IC_Nack;
end
endtask

endmodule
