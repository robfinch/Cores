// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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
module rtfItanium2(rst_i, clk_i, );
parameter QENTRIES = 5;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

parameter BUnit = 3'd1;
parameter IUnit = 3'd2;
parameter FUnit = 3'd3;
parameter MUnit = 3'd4;

(* ram_style="block" *)
reg [127:0] imem [0:12287];
initial begin
`include "d:/cores6/rtfItanium/v1/software/boot/boot.ve0"
end

reg [63:0] ip, rip;
reg [1:0] slot;

wire [127:0] ir = ibundle;
wire [4:0] template = ir[124:120];
reg [42:0] ir43;
wire [7:0] Rt = ir41[12:6];
reg [4:0] state;
reg [127:0] ir;
reg [7:0] cnt;
reg r1IsFp,r2IsFp,r3IsFp;

reg  [`QBITS] tail0;
reg  [`QBITS] tail1;
reg  [`QBITS] tail2;
reg  [`QBITS] heads[0:QENTRIES-1];

reg commit_v;
reg [5:0] commit_tgt;
reg [79:0] commit_bus;

wire [79:0] L1_adr, L2_adr;
wire [257:0] L1_dat, L2_dat;
wire L1_wr, L2_wr;
wire L2_ld;
wire L1_ihit, L2_ihit;
wire L1_nxt, L2_nxt;					// advances cache way lfsr
wire [2:0] L2_cnt;

wire d0L1_wr, d0L2_ld;
wire d1L1_wr, d1L2_ld;
wire [79:0] d0L1_adr, d0L2_adr;
wire [79:0] d1L1_adr, d1L2_adr;
wire d0L1_dhit, d0L2_dhit;
wire d0L1_nxt, d0L2_nxt;					// advances cache way lfsr
wire d1L1_dhit, d1L2_dhit;
wire d1L1_nxt, d1L2_nxt;					// advances cache way lfsr
wire [40:0] d0L1_sel, d0L2_sel;
wire [40:0] d1L1_sel, d1L2_sel;
wire [330:0] d0L1_dat, d0L2_dat;
wire [330:0] d1L1_dat, d1L2_dat;

function [2:0] Unit0;
input [4:0] tmp;
case(tmp)
5'h00:	Unit0 = IUnit;
5'h01:	Unit0 = IUnit;
5'h02:	Unit0 = IUnit;
5'h03:	Unit0 = IUnit;
5'h08:	Unit0 = IUnit;
5'h09:	Unit0 = IUnit;
5'h0A:	Unit0 = IUnit;
5'h0B:	Unit0 = IUnit;
5'h0C:	Unit0 = IUnit;
5'h0D:	Unit0 = IUnit;
5'h0E:	Unit0 = FUnit;
5'h0F:	Unit0 = FUnit;
5'h10:	Unit0 = BUnit;
5'h11:	Unit0 = BUnit;
5'h12:	Unit0 = BUnit;
5'h13:	Unit0 = BUnit;
5'h16:	Unit0 = BUnit;
5'h17:	Unit0 = BUnit;
5'h18:	Unit0 = BUnit;
5'h19:	Unit0 = BUnit;
5'h1C:	Unit0 = BUnit;
5'h1D:	Unit0 = BUnit;
default:	Unit0 = NUnit;
endcase
endfunction

function [2:0] Unit1;
input [4:0] tmp;
case(tmp)
5'h00:	Unit1 = IUnit;
5'h01:	Unit1 = IUnit;
5'h02:	Unit1 = IUnit;
5'h03:	Unit1 = IUnit;
5'h08:	Unit1 = MUnit;	
5'h09:	Unit1 = MUnit;	
5'h0A:	Unit1 = MUnit;	
5'h0B:	Unit1 = MUnit;
5'h0C:	Unit1 = FUnit;
5'h0D:	Unit1 = FUnit;
5'h0E:	Unit1 = MUnit;	
5'h0F:	Unit1 = MUnit;
5'h10:	Unit1 = IUnit;
5'h11:	Unit1 = IUnit;
5'h12:	Unit1 = BUnit;
5'h13:	Unit1 = BUnit;
5'h15:	Unit1 = BUnit;
5'h16:	Unit1 = BUnit;
5'h18:	Unit1 = MUnit;	
5'h19:	Unit1 = MUnit;
5'h1C:	Unit1 = FUnit;
5'h1D:	Unit1 = FUnit;
default:	Unit1 = NUnit;
endcase
endfunction

function [2:0] Unit2;
input [4:0] tmp;
case(tmp)
5'h00:	Unit2 = MUnit;	
5'h01:	Unit2 = MUnit;	
5'h02:	Unit2 = MUnit;	
5'h03:	Unit2 = MUnit;	
5'h04:	Unit2 = MUnit;	
5'h05:	Unit2 = MUnit;	
5'h08:	Unit2 = MUnit;	
5'h09:	Unit2 = MUnit;	
5'h0A:	Unit2 = MUnit;	
5'h0B:	Unit2 = MUnit;	
5'h0C:	Unit2 = MUnit;	
5'h0D:	Unit2 = MUnit;	
5'h0E:	Unit2 = MUnit;	
5'h0F:	Unit2 = MUnit;	
5'h10:	Unit2 = MUnit;	
5'h11:	Unit2 = MUnit;	
5'h12:	Unit2 = MUnit;	
5'h13:	Unit2 = MUnit;	
5'h16:	Unit2 = BUnit;
5'h17:	Unit2 = BUnit;	
5'h18:	Unit2 = MUnit;	
5'h19:	Unit2 = MUnit;	
5'h1C:	Unit2 = MUnit;	
5'h1D:	Unit2 = MUnit;	
default:	Unit2 = NUnit;
endcase
endfunction

function IsMUnit;
input [4:0] tmp;
input [1:0] slt;
case(tmp)
5'h0A,5'h0B:
	IsMUnit = slt==2'd0 || slt==2'd1;
5'h0C,5'h0D:
	IsMUnit = slt==2'd0;
5'h0E,5'h0F:
	IsMUnit = slt==2'd0 || slt==2'd1;
5'h10,5'h11,5'h12,5'h13:
	IsMUnit = slt==2'd0;
5'h18,5'h19:
	IsMUnit = slt==2'd0 || slt==2'd1;
5'h1C,5'h1D:
	IsMUnit = slt==2'd0;
default:
	IsMUnit = FALSE;
endcase
endfunction

function IsFUnit;
input [4:0] tmp;
input [1:0] slt;
case(tmp)
5'h0C,5'h0D:
	IsFUnit = slt==2'd1;
5'h0E,5'h0F:
	IsFUnit = slt==2'd2;
5'h1C,5'h1D:
	IsFUnit = slt==2'd1;
default:	IsFUnit = FALSE;
endcase
endfunction

function IsIUnit;
input [4:0] tmp;
input [1:0] slt;
case(tmp)
5'h0A,5'h0B,5'h0C,5'h0D:
	IsIUnit = slt==2'd2;
5'h10,5'h11:
	IsIUnit = slt==2'd1;
default:	IsIUnit = FALSE;
endcase
endfunction

function IsBUnit;
input [4:0] tmp;
input [1:0] slt;
case(tmp)
5'h10,5'h11:
	IsBUnit = slt==2'd2;
5'h12,5'h13:
	IsBUnit = slt==2'd1 || slt==2'd2;
5'h16,5'h17:
	IsBUnit = TRUE;
5'h18,5'h19:
	IsBUnit = slt==2'd2;
5'h1C,5'h1D:
	IsBUnit = slt==2'd2;
default:	IsBUnit = FALSE;
endcase
endfunction

function IsFpLoad;
input [40:0] ins;
if (ins[40:37]==4'h6) begin
	case({ins[36],ins[27]})
	2'b00:
		case(ins[35:30])
		6'h00,6'h01,6'h02,6'h03,
		6'h04,6'h05,6'h06,6'h07,
		6'h08,6'h09,6'h0A,6'h0B,
		6'h0C,6'h0D,6'h0E,6'h0F:
			IsFpLoad = TRUE;
		6'h1B:
			IsFpLoad = TRUE;
		6'h20,6'h21,6'h22,6'h23,
		6'h24,6'h25,6'h26,6'h27:
			IsFpLoad = TRUE;
		default:	IsFpLoad = FALSE;
		endcase
	2'b01:
		case(ins[35:30])
		6'h01,6'h02,6'h03,
		6'h05,6'h06,6'h07,
		6'h09,6'h0A,6'h0B,
		6'h0D,6'h0E,6'h0F:
			IsFpLoad = TRUE;
		6'h1C,6'h1D,6'h1E,6'h1F:
			IsFpLoad = TRUE;
		6'h21,6'h22,6'h23,
		6'h25,6'h26,6'h27:
			IsFpLoad = TRUE;
		default:	IsFpLoad = FALSE;
		endcase
	2'b10:
		case(ins[35:30])
		6'h00,6'h01,6'h02,6'h03,
		6'h04,6'h05,6'h06,6'h07,
		6'h08,6'h09,6'h0A,6'h0B,
		6'h0C,6'h0D,6'h0E,6'h0F:
			IsFpLoad = TRUE;
		6'h1B:
			IsFpLoad = TRUE;
		6'h20,6'h21,6'h22,6'h23,
		6'h24,6'h25,6'h26,6'h27:
			IsFpLoad = TRUE;
		6'h2C,6'h2D,6'h2E,6'h2F:
			IsFpLoad = TRUE;
		default:	IsFpLoad = FALSE;
		endcase
	2'b11:
		case(ins[35:30])
		6'h01,6'h02,6'h03,
		6'h05,6'h06,6'h07,
		6'h09,6'h0A,6'h0B,
		6'h0D,6'h0E,6'h0F:
			IsFpLoad = TRUE;
		6'h21,6'h22,6'h23,
		6'h25,6'h26,6'h27:
			IsFpLoad = TRUE;
		default:	IsFpLoad = FALSE;
		endcase
	end
end
endfunction

function [6:0] InstType;
input [4:0] tmp;
input [40:0] ins;
if (IsMUnit(tmp)) begin
	case(ins[40:37])
	4'h0:	InstType = ITMemmgnt;
	4'h1: InstType = ITMemmgnt;
	4'h4:	InstType = ITIntLdReg;
	4'h5:	InstType = ITIntLdStImm;
	4'h6:	InstType = ITFpLdStReg;
	4'h7:	InstType = ITFPLdStImm;
	4'h8:	InstType = ITALU;
	4'h9: InstType = ITAdd;
	4'hC:	InstType = ITCmp;
	4'hD:	InstType = ITCmp;
	4'hE:	InstType = ITCmp;
	default:	InstType = ITUnimp;
	endcase
end
else if (IsIUnit(tmp)) begin
	case(ins[40:37])
	4'h0:	InstType = ITMisc;
	4'h4:	InstType = ITDeposit;
	4'h5:	InstType = ITShift;
	4'h6:	InstType = ITMovl;
	4'h7:	InstType = ITMpy;
	4'h8:	InstType = ITALU;
	4'h9: InstType = ITAdd;
	4'hC:	InstType = ITCmp;
	4'hD:	InstType = ITCmp;
	4'hE:	InstType = ITCmp;
	default:	InstType = ITUnimp;
	endcase
end
else if (IsFUnit(tmp)) begin
	case(ins[40:37])
	4'h0:	InstType = ITFPMisc;
	4'h1:	InstType = ITFPMisc;
	4'h4:	InstType = ITFPCmp;
	4'h5:	InstType = ITFPClass;
	4'h8:	InstType = ITFPfma;
	4'h9:	InstType = ITFPfma;
	4'hA:	InstType = ITFPfms;
	4'hB:	InstType = ITFPfms;
	4'hC:	InstType = ITFPfnma;
	4'hD:	InstType = ITFPfnma;
	4'hE:	InstType = ITFPSelect;
	default:	InstType = ITUnimp;
	endcase
end
else if (IsBUnit(tmp)) begin
	case(ins[40:37])
	4'h0:	InstType = ITIndBranch;
	4'h1:	InstType = ITIndCall;
	4'h2:	InstType = ITNop;
	4'h4:	InstType = ITRelBranch;
	4'h5:	InstType = ITRelCall;
	default:	InstType = ITUnimp;
	endcase
end
endfunction

Regfile urf1
(
	.clk(clk_i),
	.wr(commit_v),
	.wa(commit_tgt),
	.i(commit_bus),
	.ra0(),
	.ra1()
	.ra2(),
	.ra3(),
	.ra4(),
	.ra5(),
	.ra6(),
	.ra7(),
	.ra8(),
	.o0(),
	.o1(),
	.o2(),
	.o3(),
	.o4(),
	.o5(),
	.o6(),
	.o7(),
	.o8()
);


ICController uicc1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.pc(ip),
	.hit(L1_ihit),
	.bstate(bus_state),
	.state(icstate),
	.invline(1'b0),
	.invlineAddr(80'h0),
	.icl_ctr(),
	.ihitL2(L2_ihit),
	.L2_ld(L2_ld),
	.L2_cnt(L2_cnt),
	.L2_adr(L2_adr),
	.L2_dat(L2_dat),
	.L2_nxt(L2_nxt),
	.L1_selpc(L1_selpc),
	.L1_adr(L1_adr),
	.L1_dat(L1_dat),
	.L1_wr(L1_wr),
	.L1_invline(),
	.icnxt(L1_nxt),
	.icwhich(),
	.icl_o(),
	.cti_o(),
	.bte_o(),
	.bok_i(),
	.cyc_o(),
	.stb_o(),
	.ack_i(),
	.err_i(),
	.tlbmiss_i(),
	.exv_i(),
	.sel_o(),
	.adr_o(),
	.dat_i(dat_i)
);

L1_icache uic1
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(L1_nxt),
	.wr(L1_wr),
	.wadr(L1_adr),
	.adr(L1_selpc ? ip : L1_adr),
	.i(L1_dat),
	.o(ibundle),
	.fault(),
	.hit(L1_ihit),
	.invall(1'b0),
	.invline(1'b0)
);

L2_icache uic2
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(L2_nxt),
	.wr(L2_wr),
	.adr(L2_ld ? L2_adr : L1_adr),
	.cnt(L2_cnt),
	.exv_i(1'b0),
	.i(dat_i),
	.err_i(1'b0),
	.o(L2_dat),
	.hit(L2_ihit),
	.invall(1'b0),
	.invline(1'b0)
);

DCController udcc1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.dadr(),
	.rd(),
	.wr(),
	.wsel(),
	.wdat(),
	.bstate(),
	.state(),
	.invline(1'b0),
	.invlineAddr(80'h0),
	.icl_ctr(),
	.dL2_hit(d0L2_hit),
	.dL2_ld(d0L2_ld),
	.dL2_sel(d0L2_sel),
	.dL2_adr(d0L2_adr),
	.dL2_dat(d0L2_dat),
	.dL2_nxt(d0L2_nxt),
	.dL1_hit(d0L1_hit),
	.dL1_selpc(d0L1_selpc),
	.dL1_sel(d0L1_sel),
	.dL1_adr(d0L1_adr),
	.dL1_dat(d0L1_dat),
	.dL1_wr(d0L1_wr),
	.dL1_invline(1'b0),
	.dcnxt(),
	.dcwhich(),
	.dcl_o(),
	.cti_o(),
	.bte_o(),
	.bok_i(),
	.cyc_o(),
	.stb_o(),
	.ack_i(),
	.err_i(),
	.wrv_i(),
	.rdv_i(),
	.sel_o(),
	.adr_o(),
	.dat_i(dat_i)
);

L1_dcache udc1
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(d0L1_nxt),
	.wr(d0L1_wr),
	.wadr(d0L1_adr),
	.adr(d0L1_selpc ? vadr : d0L1_adr),
	.i(d0L1_dat),
	.o(d0cdat0),
	.fault(),
	.hit(d0L1_dhit),
	.invall(1'b0),
	.invline(1'b0)
);

L2_dcache udc2
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(d0L2_nxt),
	.wr(d0L2_wr),
	.adr(d0L2_ld ? d0L2_adr : d0L1_adr),
	.sel(d0L2_sel),
	.rdv_i(1'b0),
	.wrv_i(1'b0),
	.i(d0L1_dat),
	.err_i(1'b0),
	.o(d0L2_dat),
	.hit(d0L2_dhit),
	.invall(1'b0),
	.invline(1'b0)
);


DCController udcc2
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.dadr(),
	.rd(),
	.wr(),
	.wsel(),
	.wdat(),
	.bstate(),
	.state(),
	.invline(1'b0),
	.invlineAddr(80'h0),
	.icl_ctr(),
	.dL2_hit(d1L2_hit),
	.dL2_ld(d1L2_ld),
	.dL2_sel(d1L2_sel),
	.dL2_adr(d1L2_adr),
	.dL2_dat(d1L2_dat),
	.dL2_nxt(d1L2_nxt),
	.dL1_hit(d1L1_hit),
	.dL1_selpc(d1L1_selpc),
	.dL1_sel(d1L1_sel),
	.dL1_adr(d1L1_adr),
	.dL1_dat(d1L1_dat),
	.dL1_wr(d1L1_wr),
	.dL1_invline(1'b0),
	.dcnxt(),
	.dcwhich(),
	.dcl_o(),
	.cti_o(),
	.bte_o(),
	.bok_i(),
	.cyc_o(),
	.stb_o(),
	.ack_i(),
	.err_i(),
	.wrv_i(),
	.rdv_i(),
	.sel_o(),
	.adr_o(),
	.dat_i(dat_i)
);

L1_dcache udc1
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(d1L1_nxt),
	.wr(d1L1_wr),
	.wadr(d1L1_adr),
	.adr(d1L1_selpc ? vadr : d1L1_adr),
	.i(d1L1_dat),
	.o(d1cdat0),
	.fault(),
	.hit(d1L1_dhit),
	.invall(1'b0),
	.invline(1'b0)
);

L2_dcache udc2
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(d1L2_nxt),
	.wr(d1L2_ld),
	.adr(d1L2_ld ? d1L2_adr : d1L1_adr),
	.sel(d1L2_sel),
	.rdv_i(1'b0),
	.wrv_i(1'b0),
	.i(d1L1_dat),
	.err_i(1'b0),
	.o(d1L2_dat),
	.hit(d1L2_dhit),
	.invall(1'b0),
	.invline(1'b0)
);

// Determine the head increment amount, this must match code later on.
reg [2:0] hi_amt;
always @*
begin
	hi_amt <= 4'd0;
  casez ({ iq_v[heads[0]],
		iq_state[heads[0]]==IQS_CMT,
		iq_v[heads[1]],
		iq_state[heads[1]]==IQS_CMT,
		iq_v[heads[2]],
		iq_state[heads[2]]==IQS_CMT})

	// retire 3
	6'b0?_0?_0?:
		if (heads[0] != tail0 && heads[1] != tail0 && heads[2] != tail0)
			hi_amt <= 3'd3;
		else if (heads[0] != tail0 && heads[1] != tail0)
			hi_amt <= 3'd2;
		else if (heads[0] != tail0)
			hi_amt <= 3'd1;
	6'b0?_0?_10:
		if (heads[0] != tail0 && heads[1] != tail0)
			hi_amt <= 3'd2;
		else if (heads[0] != tail0)
			hi_amt <= 3'd1;
		else
			hi_amt <= 3'd0;
	6'b0?_0?_11:
		if (`NUM_CMT > 2 || cmt_head2)
			hi_amt <= 3'd3;
		else
			hi_amt <= 3'd2;

	// retire 1 (wait for regfile for heads[1])
	6'b0?_10_??:
		hi_amt <= 3'd1;

	// retire 2
	6'b0?_11_0?,
	6'b0?_11_10:
    if (`NUM_CMT > 1 || cmt_head1)
			hi_amt <= 3'd2;	
    else
			hi_amt <= 3'd1;
  6'b0?_11_11:
    if (`NUM_CMT > 2 || (`NUM_CMT > 1 && cmt_head2))
			hi_amt <= 3'd3;
  	else if (`NUM_CMT > 1 || cmt_head1)
			hi_amt <= 3'd2;
  	else
			hi_amt <= 3'd1;
  6'b10_??_??:	;
  6'b11_0?_0?:
  	if (heads[1] != tail0 && heads[2] != tail0)
			hi_amt <= 3'd3;
  	else if (heads[1] != tail0)
			hi_amt <= 3'd2;
  	else
			hi_amt <= 3'd1;
  6'b11_0?_10:
  	if (heads[1] != tail0)
			hi_amt <= 3'd2;
  	else
			hi_amt <= 3'd1;
  6'b11_0?_11:
  	if (heads[1] != tail0) begin
  		if (`NUM_CMT > 2 || cmt_head2)
				hi_amt <= 3'd3;
  		else
				hi_amt <= 3'd2;
  	end
  	else
			hi_amt <= 3'd1;
  6'b11_10_??:
			hi_amt <= 3'd1;
  6'b11_11_0?:
  	if (`NUM_CMT > 1 && heads[2] != tail0)
			hi_amt <= 3'd3;
  	else if (cmt_head1 && heads[2] != tail0)
			hi_amt <= 3'd3;
		else if (`NUM_CMT > 1 || cmt_head1)
			hi_amt <= 3'd2;
  	else
			hi_amt <= 3'd1;
  6'b11_11_10:
		if (`NUM_CMT > 1 || cmt_head1)
			hi_amt <= 3'd2;
  	else
			hi_amt <= 3'd1;
	6'b11_11_11:
		if (`NUM_CMT > 2 || (`NUM_CMT > 1 && cmt_head2))
			hi_amt <= 3'd3;
		else if (`NUM_CMT > 1 || cmt_head1)
			hi_amt <= 3'd2;
		else
			hi_amt <= 3'd1;
	default:
		begin
			hi_amt <= 3'd0;
			$display("hi_amt: Uncoded case %h",{ iq_v[heads[0]],
				iq_state[heads[0]],
				iq_v[heads[1]],
				iq_state[heads[1]],
				iq_v[heads[2]],
				iq_state[heads[2]]});
		end
  endcase
end

// Amount subtracted from sequence numbers
reg [`SNBITS] tosub;
always @*
case(hi_amt)
3'd3: tosub <= (iq_v[heads[2]] ? iq_sn[heads[2]]
							 : iq_v[heads[1]] ? iq_sn[heads[1]]
							 : iq_v[heads[0]] ? iq_sn[heads[0]]
							 : 4'b0);
3'd2: tosub <= (iq_v[heads[1]] ? iq_sn[heads[1]]
							 : iq_v[heads[0]] ? iq_sn[heads[0]]
							 : 4'b0);
3'd1: tosub <= (iq_v[heads[0]] ? iq_sn[heads[0]]
							 : 4'b0);							 
default:	tosub <= 4'd0;
endcase

reg [`SNBITS] maxsn [0:`WAYS-1];
always @*
begin
	maxsn = 8'd0;
	for (n = 0; n < QENTRIES; n = n + 1)
		if (iqentry_sn[n] > maxsn && iq_v[n])
			maxsn = iq_sn[n];
	maxsn = maxsn - tosub;
end


always @(posedge clk_i)
if (rst_i) begin
	cnt <= 8'd0;
	ircnt <= 2'd0;
	ip <= RST_ADDR;
end
else begin
case (state)
RESET:
	begin
		rip <= ip[63:4];
		cnt <= cnt + 2'd1;
		if (cnt[2])
			state <= IFETCH;
	end
IFETCH:
	begin
		selFpReg <= 1'b0;
		fpLdSt <= 1'b0;
		slot <= slot + 2'd1;
		case(slot)
		2'd0:	begin ir41 <= ir[40:0]; state <= DCRF; end
		2'd1:	begin ir41 <= ir[81:41]; state <= DCRF; end
		2'd2:	begin ir41 <= ir[122:82]; state <= DCRF; end
		2'd3:
			begin
				rip <= ip[63:4] + 2'd1;
				ip <= ip + 8'd16;
			end
		endcase
	end
DCRF:
	begin
		if ((template==5'h0C || template==5'h0D) && slot==2'd1)
			selFp <= 1'b1;
		else if ((template==5'h0E || template==5'h0F) && slot==2'd2)
			selFp <= 1'b1;
		else if ((template==5'h1C || template==5'h1D) && slot==2'd1)
			selFp <= 1'b1;
		if ((template==))
	end
endcase
end

	case({slot0v,slot1v,slot2v}&{3{L1_ihit}})
	3'b000:	;
	3'b001:
		if (canq1) begin
			queue_slot2(tail0,maxsn+2'd1);
			slot0v <= VAL;
			slot1v <= VAL;
			slot2v <= VAL;
			ip <= ip + 80'd16;
		end
	3'b010:
		if (canq1) begin
			queue_slot1(tail0,maxsn+2'd1);
			slot0v <= VAL;
			slot1v <= VAL;
			slot2v <= VAL;
			ip <= ip + 80'd16;
		end
	3'b011:
		if (canq2) begin
			queue_slot1(tail0,maxsn+2'd1);
			queue_slot2(tail1,maxsn+2'd2);
			slot1v <= INV;
			slot2v <= INV;
			ip <= ip + 80'd16;
		end
		else if (canq1) begin
			queue_slot1(tail0,maxsn+2'd1);
			slot1v <= INV;
		end
	3'b100:
		if (canq1) begin
			queue_slot0(tail0,maxsn+2'd1);
			slot0v <= VAL;
			slot1v <= VAL;
			slot2v <= VAL;
			ip <= ip + 80'd16;
		end
	3'b101:
		if (canq2) begin
			queue_slot0(tail0,maxsn+2'd1);
			queue_slot2(tail1,maxsn+2'd2);
			slot0v <= VAL;
			slot1v <= VAL;
			slot2v <= VAL;
			ip <= ip + 80'd16;
		end
		else if (canq1) begin
			queue_slot0(tail0,maxsn+2'd1);
			slot0v <= INV;
		end
	3'b110:
		if (canq2) begin
			queue_slot0(tail0,maxsn+2'd1);
			queue_slot1(tail1,maxsn+2'd2);
			slot0v <= VAL;
			slot1v <= VAL;
			slot2v <= VAL;
			ip <= ip + 80'd16;
		end
		else if (canq1) begin
			queue_slot0(tail0,maxsn+2'd1);
			slot0v <= INV;
		end
	3'b111:
		if (canq3) begin
			queue_slot0(tail0,maxsn+2'd1);
			queue_slot1(tail1,maxsn+2'd2);
			queue_slot2(tail2,maxsn+2'd3);
			slot0v <= VAL;
			slot1v <= VAL;
			slot2v <= VAL;
			ip <= ip + 80'd16;
		end
		else if (canq2) begin
			queue_slot0(tail0,maxsn+2'd1);
			queue_slot1(tail1,maxsn+2'd2);
			slot0v <= INV;
			slot1v <= INV;
		end
		else if (canq1) begin
			queue_slot0(tail0,maxsn+2'd1);
			slot0v <= INV;
		end
	endcase

	if (wb_update_iq) begin
		for (n = 0; n < QENTRIES; n = n + 1) begin
			if (wbo_id[n]) begin
	      iqentry_exc[n] <= wb_fault;
	     	iqentry_state[n] <= IQS_CMT;
				iqentry_aq[n] <= `INV;
			end
		end
	end


task setinsn;
input [`QBITS] nn;
input [143:0] bus;
begin
	iq_argI[nn]  <= bus[`IB_CONST];
	iq_imm  [nn]  <= bus[`IB_IMM];
	iq_cmp	 [nn]  <= bus[`IB_CMP];
	iq_tlb  [nn]  <= bus[`IB_TLB];
	iq_sz   [nn]  <= bus[`IB_SZ];
	iq_jal	 [nn]  <= bus[`IB_JAL];
	iq_ret  [nn]  <= bus[`IB_RET];
	iq_irq  [nn]  <= bus[`IB_IRQ];
	iq_brk	 [nn]  <= bus[`IB_BRK];
	iq_rti  [nn]  <= bus[`IB_RTI];
	iq_bt   [nn]  <= bus[`IB_BT];
	iq_alu  [nn]  <= bus[`IB_ALU];
	iq_alu0 [nn]  <= bus[`IB_ALU0];
	iq_fpu  [nn]  <= bus[`IB_FPU];
	iq_fc   [nn]  <= bus[`IB_FC];
	iq_canex[nn]  <= bus[`IB_CANEX];
	iq_loadv[nn]  <= bus[`IB_LOADV];
	iq_load [nn]  <= bus[`IB_LOAD];
	iq_loadseg[nn]<= bus[`IB_LOADSEG];
	iq_preload[nn]<= bus[`IB_PRELOAD];
	iq_store[nn]  <= bus[`IB_STORE];
	iq_push [nn]  <= bus[`IB_PUSH];
	iq_oddball[nn] <= bus[`IB_ODDBALL];
	iq_memsz[nn]  <= bus[`IB_MEMSZ];
	iq_mem  [nn]  <= bus[`IB_MEM];
	iq_memndx[nn] <= bus[`IB_MEMNDX];
	iq_rmw  [nn]  <= bus[`IB_RMW];
	iq_memdb[nn]  <= bus[`IB_MEMDB];
	iq_memsb[nn]  <= bus[`IB_MEMSB];
	iq_shft [nn]  <= bus[`IB_SHFT];	// 48 bit shift instructions
	iq_sei	 [nn]	 <= bus[`IB_SEI];
	iq_aq   [nn]  <= bus[`IB_AQ];
	iq_rl   [nn]  <= bus[`IB_RL];
	iq_jmp  [nn]  <= bus[`IB_JMP];
	iq_br   [nn]  <= bus[`IB_BR];
	iq_sync [nn]  <= bus[`IB_SYNC];
	iq_fsync[nn]  <= bus[`IB_FSYNC];
	iq_rfw  [nn]  <= bus[`IB_RFW];
	iq_we   [nn]  <= bus[`IB_WE];
end
endtask
	
task queue_slot0;
input [`QBITS] ndx;
input [`SNBITS] seqnum;
begin
	iq_v[ndx] <= VAL;
	iq_sn[ndx] <= seqnum;
	iq_state[ndx] <= IQS_QUEUED;
	iq_ip[ndx] <= ip;
	iq_unit[ndx] <= Unit0(ibundle[124:120]);
	iq_instr[ndx] <= ibundle[39:0];
	iq_argA[ndx] <= rfoa0;
	iq_argB[ndx] <= rfob0;
	iq_argC[ndx] <= rfoc0;
	iq_argAv[ndx] <= regIsValid[Ra0] || Source1Valid({Unit0(ibundle[124:120]),ibundle[39:0]});
	iq_argBv[ndx] <= regIsValid[Rb0] || Source2Valid({Unit0(ibundle[124:120]),ibundle[39:0]});
	iq_argCv[ndx] <= regIsValid[Rc0] || Source2Valid({Unit0(ibundle[124:120]),ibundle[39:0]});
	iq_argAs[ndx] <= rf_source[Ra0];
	iq_argBs[ndx] <= rf_source[Rb0];
	iq_argCs[ndx] <= rf_source[Rc0];
	iq_pt[ndx] <= predict_taken0;
	iq_tgt[ndx] <= Rt0;
	iq_res[ndx] <= 80'd0;
	iq_exc[ndx] <= `FLT_NONE;
	set_insn(ndx,id0_bus);
end
endtask

task queue_slot1;
input [`QBITS] ndx;
input [`SNBITS] seqnum;
begin
	iq_v[ndx] <= VAL;
	iq_sn[ndx] <= seqnum;
	iq_state[ndx] <= IQS_QUEUED;
	iq_ip[ndx] <= ip;
	iq_unit[ndx] <= Unit1(ibundle[124:120]);
	iq_instr[ndx] <= ibundle[79:40];
	iq_argA[ndx] <= rfoa1;
	iq_argB[ndx] <= rfob1;
	iq_argC[ndx] <= rfoc1;
	iq_argAv[ndx] <= regIsValid[Ra1] || Source1Valid({Unit1(ibundle[124:120]),ibundle[79:40]});
	iq_argBv[ndx] <= regIsValid[Rb1] || Source2Valid({Unit1(ibundle[124:120]),ibundle[79:40]});
	iq_argCv[ndx] <= regIsValid[Rc1] || Source2Valid({Unit1(ibundle[124:120]),ibundle[79:40]});
	iq_argAs[ndx] <= rf_source[Ra1];
	iq_argBs[ndx] <= rf_source[Rb1];
	iq_argCs[ndx] <= rf_source[Rc1];
	iq_pt[ndx] <= predict_taken1;
	iq_tgt[ndx] <= Rt1;
	iq_res[ndx] <= 80'd0;
	iq_exc[ndx] <= `FLT_NONE;
	set_insn(ndx,id1_bus);
end
endtask

task queue_slot2;
input [`QBITS] ndx;
input [`SNBITS] seqnum;
begin
	iq_v[ndx] <= VAL;
	iq_sn[ndx] <= seqnum;
	iq_state[ndx] <= IQS_QUEUED;
	iq_ip[ndx] <= ip;
	iq_unit[ndx] <= Unit2(ibundle[124:120]);
	iq_instr[ndx] <= ibundle[119:80];
	iq_argA[ndx] <= rfoa2;
	iq_argB[ndx] <= rfob2;
	iq_argC[ndx] <= rfoc2;
	iq_argAv[ndx] <= regIsValid[Ra2] || Source1Valid({Unit2(ibundle[124:120]),ibundle[119:80]});
	iq_argBv[ndx] <= regIsValid[Rb2] || Source2Valid({Unit2(ibundle[124:120]),ibundle[119:80]});
	iq_argCv[ndx] <= regIsValid[Rc2] || Source2Valid({Unit2(ibundle[124:120]),ibundle[119:80]});
	iq_argAs[ndx] <= rf_source[Ra2];
	iq_argBs[ndx] <= rf_source[Rb2];
	iq_argCs[ndx] <= rf_source[Rc2];
	iq_pt[ndx] <= predict_taken2;
	iq_tgt[ndx] <= Rt2;
	iq_res[ndx] <= 80'd0;
	iq_exc[ndx] <= `FLT_NONE;
	set_insn(ndx,id2_bus);
end
endtask

endmodule

