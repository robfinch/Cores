// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rtf64-fetchbuf.sv
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
//
`include "../inc/rtf64-config.sv"
`include "../inc/rtf64-defines.sv"
`include "../inc/rtf64-types.sv"

// FETCH
//
module rtf64_fetchbuf(rst, clk, fcu_clk,
	freezePC,
    insn0, insn1, len1, len2, phit,
    branchmiss, misspc, predict_taken0, predict_taken1,
    queued1, queued2, queuedNop,
    pc0, pc1, fetchbuf,
    fetchbufA,
    fetchbufB,
    fetchbufC,
    fetchbufD,
    fetchbuf0,
    fetchbuf1,
    brkVec,
    btgtA, btgtB, btgtC, btgtD,
    take_branch0, take_branch1,
    stompedRets,
    panic
);
parameter AMSB = `AMSB;
parameter RSTPC = 64'hFFFFFFFFFFFC0100;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
input rst;
input clk;
input fcu_clk;
input freezePC;
input tInstruction insn0;
input tInstruction insn1;
input [3:0] len1;
input [3:0] len2;
input phit;
input branchmiss;
input tAddress misspc;
input predict_taken0;
input predict_taken1;
input queued1;
input queued2;
input queuedNop;
output tAddress pc0;
output tAddress pc1;
output reg fetchbuf;
output tFetchBuffer fetchbufA;
output tFetchBuffer fetchbufB;
output tFetchBuffer fetchbufC;
output tFetchBuffer fetchbufD;
output tFetchBuffer fetchbuf0;
output tFetchBuffer fetchbuf1;
input tAddress brkVec;
input tAddress btgtA;
input tAddress btgtB;
input tAddress btgtC;
input tAddress btgtD;
output take_branch0;
output take_branch1;
input [3:0] stompedRets;
output reg [3:0] panic;

integer n;
tAddress nextPC;
reg didFetch;

function IsBranch;
input tInstruction isn;
case(isn.opcode)
`BEQ,`BNE,`BMI,`BPL,`BVS,`BVC,`BCS,`BCC,`BT,
`BLE,`BGT,`BLEU,`BGTU,`BOD,`BPS,`BEQZ,`BNEZ,`BBC:
  IsBranch = TRUE;
default: IsBranch = FALSE;
endcase
endfunction

function IsJSR;
input tInstruction isn;
IsJSR = isn.opcode==`JSR;
endfunction

function IsJMP;
input tInstruction isn;
IsJMP = isn.opcode==`JMP;
endfunction

function IsRTS;
input tInstruction isn;
IsRTS = isn.opcode==`RTS;
endfunction

function IsBRK;
input tInstruction isn;
IsBRK = isn.opcode==`BRK;
endfunction

function IsRTI;
input tInstruction isn;
IsRTI = isn.opcode==`RTI;
endfunction


reg stompedRet;
reg ret0Counted, ret1Counted;
wire [AMSB:0] retpc0, retpc1;

reg did_branchbackAB;
reg did_branchbackCD;

tAddress branch_pcA;
tAddress branch_pcB;
tAddress branch_pcC;
tAddress branch_pcD;

branchMux ubmux1(fetchbufA, retpc0, brkVec, btgtA, branch_pcA);
branchMux ubmux2(fetchbufB, retpc1, brkVec, btgtB, branch_pcB);
branchMux ubmux3(fetchbufC, retpc0, brkVec, btgtC, branch_pcC);
branchMux ubmux4(fetchbufD, retpc1, brkVec, btgtD, branch_pcD);

wire take_branchA = ({fetchbufA.v, IsBranch(fetchbufA.ins), fetchbufA.predict_taken}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRTS(fetchbufA.ins)||IsJSR(fetchbufA.ins)||
                        IsRTI(fetchbufA.ins)|| IsBRK(fetchbufA.ins)) &&
                        fetchbufA.v);

wire take_branchB = ({fetchbufB.v, IsBranch(fetchbufB.ins), fetchbufB.predict_taken}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRTS(fetchbufB.ins)||IsJSR(fetchbufB.ins)||
                        IsRTI(fetchbufB.ins)|| IsBRK(fetchbufB.ins)) &&
                        fetchbufB.v);

wire take_branchC = ({fetchbufC.v, IsBranch(fetchbufC.ins), fetchbufC.predict_taken}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRTS(fetchbufC.ins)||IsJSR(fetchbufC.ins)||
                        IsRTI(fetchbufC.ins)|| IsBRK(fetchbufC.ins)) &&
                        fetchbufC.v);

wire take_branchD = ({fetchbufD.v, IsBranch(fetchbufD.ins), fetchbufD.predict_taken}  == {`VAL, `TRUE, `TRUE}) ||
                        ((IsRTS(fetchbufD.ins)||IsJSR(fetchbufD.ins)||
                        IsRTI(fetchbufD.ins)|| IsBRK(fetchbufD.ins)) &&
                        fetchbufD.v);

assign take_branch0 = fetchbuf==1'b0 ? take_branchA : take_branchC;
assign take_branch1 = fetchbuf==1'b0 ? take_branchB : take_branchD;
wire take_branch = take_branch0 || take_branch1;

`ifdef FCU_ENH1
FT2021_RSB #(AMSB) ursb1
(
	.rst(rst),
	.clk(fcu_clk),
	.queued1(queued1),
	.queued2(queued2),
	.fetchbuf0(fetchbuf0),
	.fetchbuf1(fetchbuf1),
	.stompedRets(stompedRets),
	.stompedRet(stompedRet),
	.pc(retpc0)
);

FT2021_RSB #(AMSB) ursb2
(
	.rst(rst),
	.clk(fcu_clk),
	.queued1(queued1),
	.queued2(1'b0),
	.fetchbuf0(fetchbuf1),
	.fetchbuf1(1'b0),
	.stompedRets(stompedRets[3:1]),
	.stompedRet(stompedRet),
	.pc(retpc1)
);
`else
assign retpc0 = RSTPC;
assign retpc1 = RSTPC;
`endif

assign pc1 = pc0 + len1;

always @(posedge clk)
if (rst) begin
  nextPC = RSTPC;
	pc0 = RSTPC;
	fetchbufA.v = 0;
	fetchbufB.v = 0;
	fetchbufC.v = 0;
	fetchbufD.v = 0;
	fetchbufA.ins = `NOP_INSN;
	fetchbufB.ins = `NOP_INSN;
	fetchbufC.ins = `NOP_INSN;
	fetchbufD.ins = `NOP_INSN;
	fetchbuf = 0;
	panic = 4'h0;//`PANIC_NONE;
	didFetch = 1'b0;
end
else begin
	
	did_branchbackAB <= take_branchA|take_branchB;
	did_branchbackCD <= take_branchC|take_branchD;
	didFetch = 1'b0;

	stompedRet = FALSE;

//  if (phit & ~freezePC & (queued1|queued2))
//    pc0 = nextPC;

	begin
    //
    // get data iff the fetch buffers are empty
    //
    if (fetchbufA.v == `INV && fetchbufB.v == `INV && fetchbufC.v==`INV && fetchbufD.v==`INV) begin
			FetchAB();
			fetchbuf = 1'b0;
    end

  	if (branchmiss) begin
  		pc0 = misspc;
  		fetchbufA.v = `INV;
  		fetchbufB.v = `INV;
  		fetchbufC.v = `INV;
  		fetchbufD.v = `INV;
  		fetchbuf = 1'b0;
  		$display("********************");
  		$display("********************");
  		$display("********************");
  		$display("Branch miss");
  		$display("misspc=%h", misspc);
  		$display("********************");
  		$display("********************");
  		$display("********************");
  	end
  	else if (take_branch) begin

      // update the fetchbuf valid bits as well as fetchbuf itself
      // ... this must be based on which things are backwards branches, how many things
      // will get enqueued (0, 1, or 2), and how old the instructions are
      if (fetchbuf == 1'b0) case ({fetchbufA.v, fetchbufB.v, fetchbufC.v, fetchbufD.v})

  		4'b0000: ;	// do nothing
  		4'b0001: ;
  		4'b0010: ;
  		4'b0011: ;
  		4'b0100 :
  	    begin
  		    fetchbufB.v = !(queued1|queuedNop);	// if it can be queued, it will
  		    fetchbuf = fetchbuf + (queued1|queuedNop);
  		    FetchCD();
  	    	pc0 = branch_pcB;
 					nextPC = branch_pcB;
  			end
  		4'b0101:
  			begin
  				pc0 = branch_pcB;
 					nextPC = branch_pcB;
  				fetchbufD.v = `INV;
  				fetchbufB.v = !(queued1|queuedNop);
  			end
  		4'b0110:
  			begin
  				pc0 = branch_pcB;
 					nextPC = branch_pcB;
  				fetchbufC.v = `INV;
  				fetchbufB.v = !(queued1|queuedNop);
  			end
  		4'b0111:
  			begin
  				pc0 = branch_pcB;
 					nextPC = branch_pcB;
  				fetchbufC.v = `INV;
  				fetchbufD.v = `INV;
  			  fetchbufB.v = !(queued1|queuedNop);	// if it can be queued, it will
  				fetchbuf = fetchbuf + (queued1|queuedNop);
  			end
  		4'b1000 :
  			begin
  		    fetchbufA.v = !(queued1|queuedNop);	// if it can be queued, it will
  		    fetchbuf = fetchbuf + (queued1|queuedNop);
  		    FetchCD();
  		    pc0 = branch_pcA;
 					nextPC = branch_pcA;
  			end
  		4'b1001:
  			begin
  				pc0 = branch_pcA;
 					nextPC = branch_pcA;
  				fetchbufD.v = `INV;
  		    fetchbufA.v = !(queued1|queuedNop);	// if it can be queued, it will
  		    fetchbuf = fetchbuf + (queued1|queuedNop);
  			end
  		4'b1010:
  			begin
  				pc0 = branch_pcA;
 					nextPC = branch_pcA;
  				fetchbufC.v = `INV;
  		    fetchbufA.v = !(queued1|queuedNop);	// if it can be queued, it will
  		    fetchbuf = fetchbuf + (queued1|queuedNop);
  			end
  		4'b1011:
  			begin
  				pc0 = branch_pcA;
 					nextPC = branch_pcA;
  				fetchbufC.v = `INV;
  				fetchbufD.v = `INV;
  				fetchbufA.v =!(queued1|queuedNop);	// if it can be queued, it will
  				fetchbuf = fetchbuf + (queued1|queuedNop);
  			end
  		4'b1100:
  			begin
  				if (take_branchA) begin
  					pc0 = branch_pcA;
  					nextPC = branch_pcA;
  					fetchbufA.v = !(queued1|queuedNop);	// if it can be queued, it will
  					fetchbufB.v = `INV;
  					if ((queued1|queuedNop))   fetchbuf = 1'b1;
  				end
  				else if (take_branchB) begin
  				  if (did_branchbackAB) begin
  				    FetchCD();
    					fetchbufA.v = !(queued1|queuedNop);	// if it can be queued, it will
    					fetchbufB.v = !(queued2|queuedNop);	// if it can be queued, it will
    					if ((queued2|queuedNop))   fetchbuf = 1'b1;
  				  end
  				  else begin
    					pc0 = branch_pcB;
    					nextPC = branch_pcB;
    					fetchbufA.v = !(queued1|queuedNop);	// if it can be queued, it will
    					fetchbufB.v = !(queued2|queuedNop);	// if it can be queued, it will
    					if ((queued2|queuedNop))   fetchbuf = 1'b0;
  					end
  		    end
  		    // else hardware error
  		  end
  		4'b1101:
  			begin
  				fetchbufD.v = `INV;
  				if (take_branchA) begin
  					pc0 = branch_pcA;
  					nextPC = branch_pcA;
  					fetchbufA.v = !(queued1|queuedNop);	// if it can be queued, it will
  					fetchbufB.v = `INV;
  					if ((queued1|queuedNop))   fetchbuf = 1'b1;
  				end
  				else if (take_branchB) begin
  					pc0 = branch_pcB;
  					nextPC = branch_pcB;
  					fetchbufA.v = !(queued1|queuedNop);	// if it can be queued, it will
  					fetchbufB.v = !(queued2|queuedNop);	// if it can be queued, it will
  					if ((queued2|queuedNop))   fetchbuf = 1'b1;
  		    end
  		    // else hardware error
  		  end
  		4'b1110:
  			begin
  				fetchbufC.v = `INV;
  				if (take_branchA) begin
  					pc0 = branch_pcA;
  					nextPC = branch_pcA;
  					fetchbufA.v = !(queued1|queuedNop);	// if it can be queued, it will
  					fetchbufB.v = `INV;
  					if ((queued1|queuedNop))   fetchbuf = 1'b1;
  				end
  				else if (take_branchB) begin
  					pc0 = branch_pcB;
  					nextPC = branch_pcB;
  					fetchbufA.v = !(queued1|queuedNop);	// if it can be queued, it will
  					fetchbufB.v = !(queued2|queuedNop);	// if it can be queued, it will
  					if ((queued2|queuedNop))   fetchbuf = 1'b1;
  		    end
  		    // else hardware error
  		  end
  		4'b1111:
  			begin
  				begin
  					if (take_branchA) begin
  						pc0 = branch_pcA;
    					nextPC = branch_pcA;
  						fetchbufB.v = `INV;
  						fetchbufC.v = `INV;
  						fetchbufD.v = `INV;
  						fetchbufA.v = !(queued1|queuedNop);	// if it can be queued, it will
  						fetchbuf = fetchbuf + (queued1|queuedNop);
  					end
  					else if (take_branchB) begin
  						pc0 = branch_pcB;
    					nextPC = branch_pcB;
  						fetchbufC.v = `INV;
  						fetchbufD.v = `INV;
  						fetchbufA.v = !(queued1|queuedNop);	// if it can be queued, it will
  						fetchbufB.v = !(queued2|queuedNop);	// if it can be queued, it will
  						fetchbuf = fetchbuf + (queued2|queuedNop);
  					end
  				end
  			end
      default:    ;
  	  endcase
  	  else case ({fetchbufC.v, fetchbufD.v, fetchbufA.v, fetchbufB.v})

  		4'b0000: ;	// do nothing
  		4'b0001: ;
  		4'b0010: ;
  		4'b0011: ;
  		4'b0100 :
  	    begin
  		    fetchbufD.v = !(queued1|queuedNop);	// if it can be queued, it will
  		    fetchbuf = fetchbuf + (queued1|queuedNop);
  		    FetchAB();
  	    	pc0 = branch_pcD;
 					nextPC = branch_pcD;
  			end
  		4'b0101:
  			begin
  				pc0 = branch_pcD;
 					nextPC = branch_pcD;
  				fetchbufB.v = `INV;
  				fetchbufD.v = !(queued1|queuedNop);
  			end
  		4'b0110:
  			begin
  				pc0 = branch_pcD;
 					nextPC = branch_pcD;
  				fetchbufA.v = `INV;
  				fetchbufD.v = !(queued1|queuedNop);
  			end
  		4'b0111:
  			begin
  				pc0 = branch_pcD;
 					nextPC = branch_pcD;
  				fetchbufA.v = `INV;
  				fetchbufB.v = `INV;
  			  fetchbufD.v = !(queued1|queuedNop);	// if it can be queued, it will
  				fetchbuf = fetchbuf + (queued1|queuedNop);
  			end
  		4'b1000 :
  			begin
  		    fetchbufC.v = !(queued1|queuedNop);	// if it can be queued, it will
  		    fetchbuf = fetchbuf + (queued1|queuedNop);
  		    FetchAB();
  		    pc0 = branch_pcC;
 					nextPC = branch_pcC;
  			end
  		4'b1001:
  			begin
  				pc0 = branch_pcC;
 					nextPC = branch_pcC;
  				fetchbufB.v = `INV;
  		    fetchbufC.v = !(queued1|queuedNop);	// if it can be queued, it will
  		    fetchbuf = fetchbuf + (queued1|queuedNop);
  			end
  		4'b1010:
  			begin
  				pc0 = branch_pcC;
 					nextPC = branch_pcC;
  				fetchbufA.v = `INV;
  		    fetchbufC.v = !(queued1|queuedNop);	// if it can be queued, it will
  		    fetchbuf = fetchbuf + (queued1|queuedNop);
  			end
  		4'b1011:
  			begin
  				pc0 = branch_pcC;
 					nextPC = branch_pcC;
  				fetchbufA.v = `INV;
  				fetchbufB.v = `INV;
  				fetchbufC.v =!(queued1|queuedNop);	// if it can be queued, it will
  				fetchbuf = fetchbuf + (queued1|queuedNop);
  			end
  		4'b1100:
  			begin
  				if (take_branchC) begin
  					pc0 = branch_pcC;
  					nextPC = branch_pcC;
  					fetchbufC.v = !(queued1|queuedNop);	// if it can be queued, it will
  					fetchbufD.v = `INV;
  					if ((queued1|queuedNop))   fetchbuf = 1'b1;
  				end
  				else if (take_branchD) begin
  				  if (did_branchbackCD) begin
    					fetchbufC.v = !(queued1|queuedNop);	// if it can be queued, it will
    					fetchbufD.v = !(queued2|queuedNop);	// if it can be queued, it will
    					if ((queued2|queuedNop))   fetchbuf = 1'b0;
    					FetchAB();
  				  end
  				  else begin
    					pc0 = branch_pcD;
    					nextPC = branch_pcD;
    					fetchbufC.v = !(queued1|queuedNop);	// if it can be queued, it will
    					fetchbufD.v = !(queued2|queuedNop);	// if it can be queued, it will
    					if ((queued2|queuedNop))   fetchbuf = 1'b1;
  				  end
  		    end
  		    // else hardware error
  		  end
  		4'b1101:
  			begin
  				fetchbufB.v = `INV;
  				if (take_branchC) begin
  					pc0 = branch_pcC;
  					nextPC = branch_pcC;
  					fetchbufC.v = !(queued1|queuedNop);	// if it can be queued, it will
  					fetchbufD.v = `INV;
  					if ((queued1|queuedNop))   fetchbuf = 1'b1;
  				end
  				else if (take_branchD) begin
  					pc0 = branch_pcD;
  					nextPC = branch_pcD;
  					fetchbufC.v = !(queued1|queuedNop);	// if it can be queued, it will
  					fetchbufD.v = !(queued2|queuedNop);	// if it can be queued, it will
  					if ((queued2|queuedNop))   fetchbuf = 1'b1;
  		    end
  		    // else hardware error
  		  end
  		4'b1110:
  			begin
  				fetchbufA.v = `INV;
  				if (take_branchC) begin
  					pc0 = branch_pcC;
  					nextPC = branch_pcC;
  					fetchbufC.v = !(queued1|queuedNop);	// if it can be queued, it will
  					fetchbufD.v = `INV;
  					if ((queued1|queuedNop))   fetchbuf = 1'b1;
  				end
  				else if (take_branchD) begin
  					pc0 = branch_pcD;
  					nextPC = branch_pcD;
  					fetchbufC.v = !(queued1|queuedNop);	// if it can be queued, it will
  					fetchbufD.v = !(queued2|queuedNop);	// if it can be queued, it will
  					if ((queued2|queuedNop))   fetchbuf = 1'b1;
  		    end
  		    // else hardware error
  		  end
  		4'b1111:
  			begin
  				begin
  					if (take_branchC) begin
  						pc0 = branch_pcC;
    					nextPC = branch_pcC;
  						fetchbufD.v = `INV;
  						fetchbufA.v = `INV;
  						fetchbufB.v = `INV;
  						fetchbufC.v = !(queued1|queuedNop);	// if it can be queued, it will
  						fetchbuf = fetchbuf + (queued1|queuedNop);
  					end
  					else if (take_branchD) begin
  						pc0 = branch_pcD;
  					  nextPC = branch_pcD;
  						fetchbufA.v = `INV;
  						fetchbufB.v = `INV;
  						fetchbufC.v = !(queued1|queuedNop);	// if it can be queued, it will
  						fetchbufD.v = !(queued2|queuedNop);	// if it can be queued, it will
  						fetchbuf = fetchbuf + (queued2|queuedNop);
  					end
  				end
  			end
      default:    ;
  	  endcase
  	end // if branchback

  	else begin	// there is no branchback in the system
      //
      // get data iff the fetch buffers are empty
      //
      if (fetchbufA.v == `INV && fetchbufB.v == `INV) begin
        FetchAB();
        // fetchbuf steering logic correction
        if (fetchbufC.v==`INV && fetchbufD.v==`INV)
          fetchbuf = 1'b0;
      end
      else if (fetchbufC.v == `INV && fetchbufD.v == `INV) begin
  	    FetchCD();
  	  end
  	    //
  	    // update fetchbufX_v and fetchbuf ... relatively simple, as
  	    // there are no backwards branches in the mix
      if (fetchbuf == 1'b0) case ({fetchbufA.v, fetchbufB.v, (queued1|queuedNop), (queued2|queuedNop)})
  		4'b00_00 : ;	// do nothing
  		4'b00_01:	;
  		4'b00_10:	;
  		4'b00_11:	;
  		4'b01_00: ;	// do nothing
  		4'b01_01:	;
  		4'b01_10,
  		4'b01_11:
  			begin	// enqueue fbB and flip fetchbuf
  				fetchbufB.v = `INV;
  			  fetchbuf = ~fetchbuf;
  		  end
  		4'b10_00: ;	// do nothing
  		4'b10_01: ;
  		4'b10_10,
  		4'b10_11:
  			begin	// enqueue fbA and flip fetchbuf
  				fetchbufA.v = `INV;
  			  fetchbuf = ~fetchbuf;
  		  end
  		4'b11_00: ;	// do nothing
  		4'b11_01: ;
  		4'b11_10:
  			begin	// enqueue fbA but leave fetchbuf
  				fetchbufA.v = `INV;
  		  end
  		4'b11_11:
  			begin	// enqueue both and flip fetchbuf
  				fetchbufA.v = `INV;
  				fetchbufB.v = `INV;
  			  fetchbuf = ~fetchbuf;
  		  end
  		default:  panic = 4'h1;//`PANIC_INVALIDIQSTATE;
      endcase
      else case ({fetchbufC.v, fetchbufD.v, (queued1|queuedNop), (queued2|queuedNop)})
  		4'b00_00 : ;	// do nothing
  		4'b00_01: ;
  		4'b00_10 : ;	// do nothing
  		4'b00_11 : ;	// do nothing
  		4'b01_00 : ;	// do nothing
  		4'b01_01 : ;
  		4'b01_10,
  		4'b01_11 :
  			begin	// enqueue fbD and flip fetchbuf
  				fetchbufD.v = `INV;
  			  fetchbuf = ~fetchbuf;
  		  end
  		4'b10_00 : ;	// do nothing
  		4'b10_01: ;
  		4'b10_10,
  		4'b10_11:
  			begin	// enqueue fbC and flip fetchbuf
  				fetchbufC.v = `INV;
  			  fetchbuf = ~fetchbuf;
  		  end
  		4'b11_00 : ;	// do nothing
  		4'b11_01: ;
  		4'b11_10:
  			begin	// enqueue fbC but leave fetchbuf
  				fetchbufC.v = `INV;
  		  end
  		4'b11_11:
  			begin	// enqueue both and flip fetchbuf
  				fetchbufC.v = `INV;
  				fetchbufD.v = `INV;
  			  fetchbuf = ~fetchbuf;
  		  end
  		default:  panic = 4'h1;//`PANIC_INVALIDIQSTATE;
  	  endcase
  	end
	end
end

assign fetchbuf0 = (fetchbuf == 1'b0) ? fetchbufA : fetchbufC;
assign fetchbuf1 = (fetchbuf == 1'b0) ? fetchbufB : fetchbufD;

task FetchA;
begin
  if (phit & ~freezePC & ~didFetch) begin
  	fetchbufA.ins = insn0;
  	fetchbufA.v = `VAL;
  	fetchbufA.adr = pc0;
  	fetchbufA.predict_taken = predict_taken0;
  end
end
endtask

task FetchB;
begin
	if (phit && ~freezePC && ~didFetch) begin
  	fetchbufB.ins = insn1;
    if (IsBranch(insn0) & predict_taken0)
      fetchbufB.v = `INV;
    else
  	  fetchbufB.v = `WAYS > 1;
  	fetchbufB.adr = pc0 + len1;
  	fetchbufB.predict_taken = predict_taken1;
		if (`WAYS > 1)
			pc0 = pc0 + len1 + len2;
		else
			pc0 = pc0 + len1;
		didFetch = 1'b1;
	end
end
endtask


task FetchAB;
begin
	FetchA();
	FetchB();
end
endtask

task FetchC;
begin
	if (phit && ~freezePC && ~didFetch) begin
  	fetchbufC.ins = insn0;
  	fetchbufC.v = `VAL;
  	fetchbufC.adr = pc0;
  	fetchbufC.predict_taken = predict_taken0;
  end
end
endtask

task FetchD;
begin
	if (phit && ~freezePC && ~didFetch) begin
  	fetchbufD.ins = insn1;
    if (IsBranch(insn0) & predict_taken0)
      fetchbufD.v = `INV;
    else
  	  fetchbufD.v = `WAYS > 1;
  	fetchbufD.adr = pc0 + len1;
  	fetchbufD.predict_taken = predict_taken1;
		if (`WAYS > 1)
			pc0 = pc0 + len1 + len2;
		else
			pc0 = pc0 + len1;
		didFetch = 1'b1;
	end
end
endtask

task FetchCD;
begin
	FetchC();
	FetchD();
end
endtask

endmodule

module branchMux(fetchbuf, retpc, brkVec, btgt, branch_pc);
parameter AMSB = `AMSB;
input tFetchBuffer fetchbuf;
input tAddress retpc;
input tAddress brkVec;
input tAddress btgt;
output tAddress branch_pc;

always @*
case(fetchbuf.ins.gen.opcode)
`RTS:	  branch_pc = retpc;
`JMP:	  
  if (fetchbuf.ins.jmp.m)
    branch_pc = fetchbuf.adr + {{34{fetchbuf.ins.jmp.addr[31]}},fetchbuf.ins.jmp.addr[31:2]};
  else
    branch_pc = {fetchbuf.adr[63:32],fetchbuf.ins.jmp.addr[31:2],2'b00};
`BRK:	  branch_pc = brkVec;
default:
	begin
		branch_pc = fetchbuf.adr + {{41{fetchbuf.ins.br.disp[11]}},fetchbuf.ins.br.disp} + 2'd2;
	end

endcase

endmodule
