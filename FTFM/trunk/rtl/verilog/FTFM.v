// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  Finitron Forth Machine
//  FTFM.v
//
// - stack machine
// - five bit instructions
// - executes up to five instructions per clock cycle
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
// Approx. 28019 LUTs. 44,850 LC's).
// ============================================================================
//

// nop
// fetch
// store
// >r	pdpr	move top to return stack
// r>	prpd	move return stack to top
// r@	mvrd	copy return stack to top
// 2/	asr
// dup		duplicate top
// over		duplicate next
// drop		discard top
// +	add		
// &	and
// |	or
// ^	xor
// *	mul
// ; 	ret
// jz	jz
// j	jmp
// p	call

`define TRUE	1'b1
`define FALSE	1'b0
`define HIGH	1'b1
`define LOW		1'b0

`define NOP		5'd0
`define FETCH	5'd1
`define STORE	5'd2
`define PDPR	5'd3
`define PRPD	5'd4
`define MVRD	5'd5
`define ASR		5'd6
`define DUP		5'd7
`define OVER	5'd8
`define DROP	5'd9
`define ADD		5'd10
`define AND		5'd11
`define OR		5'd12
`define XOR		5'd13
`define RET		5'd14
`define JZ		5'd15
`define JMP		5'd16
`define CALL	5'd17
`define SUB		5'd18
`define INV		5'd19
`define LIT		5'd20
`define LIT15	5'd21
`define LIT5	5'd22
`define EQ		5'd23
`define LT		5'd24
`define SHL		5'd25
`define SHR		5'd26
`define MUL		5'd27

// SWAP:
//		OVER
//		>R
//		>R
//		DROP
//		R>
//		R>

module FTFM(rst_i, clk_i, cyc_o, stb_o, ack_i, we_o, adr_o, dat_o, dat_i);
input rst_i;
input clk_i;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [24:0] adr_o;
output reg [26:0] dat_o;
input [26:0] dat_i;

reg [3:0] state;
parameter RUN = 4'd0;
parameter MEMLD = 4'd1;
parameter MEMST = 4'd2;
parameter MEMACK = 4'd3;
parameter MEMNACK = 4'd4;

function IsLS;
input [4:0] op;
IsLS = op==`FETCH || op==`STORE;
endfunction

reg domem;
reg [4:0] slot_v, pslot_v;
reg [4:0] slot_done;
reg [31:0] din0, din1, din2, din3, din4;
reg [31:0] rstack [0:63];
reg [5:0] rsp, rsp0, rsp1, rsp2, rsp3, rsp4;
reg [31:0] dstack [0:63];
reg [5:0] dsp, dsp0, dsp1, dsp2, dsp3, dsp4;

reg [31:0] dmem [0:16383];
reg [63:0] rommem [0:16383];

initial begin
`include "c:\cores5\ftfm\trunk\software\boot\boot.ve0"
end

reg [14:0] pc, npc;


reg [31:0] res0, res1, res2, res3, res4;
reg [2:0] skip0, skip1, skip2, skip3, skip4;
wire [31:0] tos = dstack[dsp];
wire [31:0] nos = dstack[dsp-1];
reg [31:0] dmem_o, dmem0_o, dmem1_o;
reg [26:0] imem_o;

reg [4:0] store_v;
reg [31:0] store_addr;
reg [31:0] store_data;

always @(posedge clk_i)
	if (ir[4:0]==`STORE && tos[31:24]==8'h00 && state==MEMACK)
		dmem[adr_o[15:2]] <= dat_o;

always @(negedge clk_i)
	dmem_o <= dmem[tos];
always @(negedge clk_i)
	dmem0_o <= dmem[dsp0];
always @(negedge clk_i)
	dmem1_o <= dmem[dsp1];
always @(negedge clk_i)
	imem_o <= rommem[pc][26:0];
wire [26:0] ir = imem_o[26:0];

reg [2:0] which;

always @(posedge clk_i)
if (rst_i) begin
	dsp <= 6'd63;
	rsp <= 6'd63;
	pc <= 15'd0;
	pslot_v <= 5'h1F;
	slot_v <= 5'h1F;
	domem <= `TRUE;
	which <= 3'd7;
	state <= RUN;
end
else begin
case(state)
RUN:
	begin
		domem <= `TRUE;
		//
		skip0 = 3'd0;
		skip1 = 3'd0;
		skip2 = 3'd0;
		skip3 = 3'd0;
		skip4 = 3'd0;
		rsp0 = rsp;
		dsp0 = dsp;
		res0 = tos;

		slot_done = 5'h1F;
		if (IsLS(ir[4:0]) && slot_v[0])
			slot_done = 5'h01;
		else if (IsLS(ir[9:5]) && slot_v[1])
			slot_done = 5'h03;
		else if (IsLS(ir[14:10]) && slot_v[2]) 
			slot_done = 5'h07;
		else if (IsLS(ir[19:15]) && slot_v[3]) 
			slot_done = 5'h0F;
		if (slot_done==5'h1F) begin
			npc = pc + 15'd1;
			slot_v <= 5'h1F;
		end

		if (ir[26]==1'b1) begin
			res0 = {{1{ir[25]}},ir[25:0]};
			skip2 = 1'b1;
		end
		else
			datapath (
				.which(3'd0),
				.op(ir[4:0]),
				.dsp_i(dsp),
				.dsp_o(dsp0),
				.rsp_i(rsp),
				.rsp_o(rsp0),
				.dmem_i(dmem_o),
				.din(din0),
				.res_i(tos),
				.res_o(res0),
				.skip(skip0),
				.lit15(ir[19:5]),
				.lit5(ir[9:5])
			);
		dstack[dsp0] = res0;
		rsp1 = rsp0;
		dsp1 = dsp0;
		if (skip0 > 3'd0)
			res1 = res0;
		else
			datapath (
				.which(3'd1),
				.op(ir[9:5]),
				.dsp_i(dsp0),
				.dsp_o(dsp1),
				.rsp_i(rsp0),
				.rsp_o(rsp1),
				.dmem_i(dmem0_o),
				.din(din1),
				.res_i(res0),
				.res_o(res1),
				.skip(skip1),
				.lit15(ir[24:10]),
				.lit5(ir[14:10])
			);
		rsp2 = rsp1;
		dsp2 = dsp1;
		dstack[dsp1] = res1;
		if (skip0 > 3'd1 || skip1 > 3'd0)
			res2 = res1;
		else
			datapath (
				.which(3'd2),
				.op(ir[14:10]),
				.dsp_i(dsp1),
				.dsp_o(dsp2),
				.rsp_i(rsp1),
				.rsp_o(rsp2),
				.dmem_i(dmem1_o),
				.din(din2),
				.res_i(res1),
				.res_o(res2),
				.skip(skip2),
				.lit15(ir[24:15]),
				.lit5(ir[19:15])
			);
		rsp3 = rsp2;
		dsp3 = dsp2;
		dstack[dsp2] = res2;
		if (skip0 > 3'd2 || skip1 > 3'd1 || skip2 > 3'd0)
			res3 = res2;
		else
			datapath (
				.which(3'd3),
				.op(ir[19:15]),
				.dsp_i(dsp2),
				.dsp_o(dsp3),
				.rsp_i(rsp2),
				.rsp_o(rsp3),
				.dmem_i(32'h0),
				.din(din3),
				.res_i(res2),
				.res_o(res3),
				.skip(skip3),
				.lit15(ir[24:20]),
				.lit5(ir[24:20])
			);
		dstack[dsp3] = res3;
		rsp4 = rsp3;
		dsp4 = dsp3;
		if (skip0 > 3'd3 || skip1 > 3'd2 || skip2 > 3'd1 || skip3 > 3'd0)
			res4 = res3;
		else
			datapath (
				.which(3'd4),
				.op(ir[24:20]),
				.dsp_i(dsp3),
				.dsp_o(dsp4),
				.rsp_i(rsp3),
				.rsp_o(rsp4),
				.dmem_i(32'h0),
				.din(din4),
				.res_i(res3),
				.res_o(res4),
				.skip(skip4),
				.lit15(15'd0),
				.lit5(5'd0)
			);
		dstack[dsp4] = res4;
		dsp <= dsp4;
		rsp <= rsp4;
		pc <= npc;
		slot_v <= 5'h1F;
		if (IsLS(ir[4:0]) && slot_v[0])
			slot_v <= 5'h1E;
		else if (IsLS(ir[9:5]) && slot_v[1])
			slot_v <= 5'h1C;
		else if (IsLS(ir[14:10]) && slot_v[2]) 
			slot_v <= 5'h18;
		else if (IsLS(ir[19:15]) && slot_v[3]) 
			slot_v <= 5'h10;
	end
MEMLD:
	begin
		cyc_o <= `HIGH;
		stb_o <= `HIGH;
		case(which)
		3'd0:	adr_o <= dstack[dsp];
		3'd1:	adr_o <= dstack[dsp0];
		3'd2:	adr_o <= dstack[dsp1];
		3'd3:	adr_o <= dstack[dsp2];
		3'd4:	adr_o <= dstack[dsp3];
		endcase
		state <= MEMACK;
	end
MEMST:
	begin
		cyc_o <= `HIGH;
		stb_o <= `HIGH;
		we_o <= `HIGH;
		adr_o <= store_addr[which];
		dat_o <= store_data[which];
		state <= MEMACK;
	end
MEMACK:
	if (ack_i) begin
		cyc_o <= `LOW;
		stb_o <= `LOW;
		we_o <= `LOW;
		case(which)
		3'd0: din0 <= dat_i;
		3'd1: din1 <= dat_i;
		3'd2: din2 <= dat_i;
		3'd3: din3 <= dat_i;
		3'd4: din4 <= dat_i;
		endcase
		state <= MEMNACK;
	end
MEMNACK:
	if (~ack_i) begin
		case(which)
		3'd7:
			if (ir[4:0]==`STORE) begin
				which <= 3'd0;
				state <= MEMST;
			end
			else if (ir[4:0]==`FETCH) begin
				which <= 3'd0;
				state <= MEMLD;
			end
			else if (ir[9:5]==`STORE) begin
				which <= 3'd1;
				state <= MEMST;
			end
			else if (ir[9:5]==`FETCH) begin
				which <= 3'd1;
				state <= MEMLD;
			end
			else if (ir[14:10]==`STORE) begin
				which <= 3'd2;
				state <= MEMST;
			end
			else if (ir[14:10]==`FETCH) begin
				which <= 3'd2;
				state <= MEMLD;
			end
			else if (ir[19:15]==`STORE) begin
				which <= 3'd3;
				state <= MEMST;
			end
			else if (ir[19:15]==`FETCH) begin
				which <= 3'd3;
				state <= MEMLD;
			end
			else if (ir[24:20]==`STORE) begin
				which <= 3'd4;
				state <= MEMST;
			end
			else if (ir[24:20]==`FETCH) begin
				which <= 3'd4;
				state <= MEMLD;
			end
			else begin
				which <= 3'd7;
				state <= RUN;
			end
		3'd0:
			if (ir[9:5]==`STORE) begin
				which <= 3'd1;
				state <= MEMST;
			end
			else if (ir[9:5]==`FETCH) begin
				which <= 3'd1;
				state <= MEMLD;
			end
			else if (ir[14:10]==`STORE) begin
				which <= 3'd2;
				state <= MEMST;
			end
			else if (ir[14:10]==`FETCH) begin
				which <= 3'd2;
				state <= MEMLD;
			end
			else if (ir[19:15]==`STORE) begin
				which <= 3'd3;
				state <= MEMST;
			end
			else if (ir[19:15]==`FETCH) begin
				which <= 3'd3;
				state <= MEMLD;
			end
			else if (ir[24:20]==`STORE) begin
				which <= 3'd4;
				state <= MEMST;
			end
			else if (ir[24:20]==`FETCH) begin
				which <= 3'd4;
				state <= MEMLD;
			end
			else begin
				which <= 3'd7;
				state <= RUN;
			end
		3'd1:
			if (ir[14:10]==`STORE) begin
				which <= 3'd2;
				state <= MEMST;
			end
			else if (ir[14:10]==`FETCH) begin
				which <= 3'd2;
				state <= MEMLD;
			end
			else if (ir[19:15]==`STORE) begin
				which <= 3'd3;
				state <= MEMST;
			end
			else if (ir[19:15]==`FETCH) begin
				which <= 3'd3;
				state <= MEMLD;
			end
			else if (ir[24:20]==`STORE) begin
				which <= 3'd4;
				state <= MEMST;
			end
			else if (ir[24:20]==`FETCH) begin
				which <= 3'd4;
				state <= MEMLD;
			end
			else begin
				which <= 3'd7;
				state <= RUN;
			end
		3'd2:
			if (ir[19:15]==`STORE) begin
				which <= 3'd3;
				state <= MEMST;
			end
			else if (ir[19:15]==`FETCH) begin
				which <= 3'd3;
				state <= MEMLD;
			end
			else if (ir[24:20]==`STORE) begin
				which <= 3'd4;
				state <= MEMST;
			end
			else if (ir[24:20]==`FETCH) begin
				which <= 3'd4;
				state <= MEMLD;
			end
			else begin
				which <= 3'd7;
				state <= RUN;
			end
		3'd3:
			if (ir[24:20]==`STORE) begin
				which <= 3'd4;
				state <= MEMST;
			end
			else if (ir[24:20]==`FETCH) begin
				which <= 3'd4;
				state <= MEMLD;
			end
			else begin
				which <= 3'd7;
				state <= RUN;
			end
		3'd4:
			begin
				which <= 3'd7;
				state <= RUN;
			end
		default:
			begin
				which <= 3'd7;
				state <= RUN;
			end
		endcase
		state <= RUN;
	end
endcase
end

task datapath;
input [2:0] which;
input [4:0] op;
input [5:0] dsp_i;
output [5:0] dsp_o;
input [5:0] rsp_i;
output [5:0] rsp_o;
input [31:0] dmem_i;
input [31:0] din;
input [31:0] res_i;
output [31:0] res_o;
output [2:0] skip;
input [14:0] lit15;
input [4:0] lit5;
begin
	dsp_o = dsp_i;
	rsp_o = rsp_i;
	res_o = res_i;
	skip = 3'd0;
	if (slot_v[which])
	case (op)
	`NOP:	res_o = res_i;
	`PDPR:  
			begin
				rstack[rsp_i-6'd1] <= dstack[dsp_i];
				dsp_o = dsp_i + 6'd1;
				rsp_o = rsp_i - 6'd1;
			end
	`PRPD:	begin
				dstack[dsp_i-6'd1] <= rstack[rsp_i];
				rsp_o = rsp_i + 6'd1;
				dsp_o = dsp_i - 6'd1;
			end
	`MVRD:	begin res_o = rstack[rsp_i]; dsp_o = dsp_i - 6'd1; end
	`DUP:	begin res_o = res_i; dsp_o = dsp_i - 6'd1; end
	`DROP:	begin res_o = dstack[dsp_i + 6'd1]; dsp_o = dsp_i + 6'd1; end
	`OVER:	begin res_o = dstack[dsp_i + 6'd1]; dsp_o = dsp_i - 6'd1; end
	`INV:	begin res_o = ~res_i; end
	`ADD:	begin res_o = res_i + dstack[dsp_i-1]; dsp_o = dsp_i + 6'd1; end
	`SUB:	begin res_o = res_i - dstack[dsp_i-1]; dsp_o = dsp_i + 6'd1; end
	`AND:	begin res_o = res_i & dstack[dsp_i-1]; dsp_o = dsp_i + 6'd1; end
	`OR:	begin res_o = res_i | dstack[dsp_i-1]; dsp_o = dsp_i + 6'd1; end
	`XOR:	begin res_o = res_i ^ dstack[dsp_i-1]; dsp_o = dsp_i + 6'd1; end
	`MUL:	begin res_o = $signed(res_i) * $signed(dstack[dsp_i-1]); dsp_o = dsp_i + 6'd1; end
	`EQ:	begin res_o = (res_i ^ dstack[dsp_i-1])==0; dsp_o = dsp_i + 6'd1; end
	`LT:	begin res_o = ($signed(res_i) < $signed(dstack[dsp_i-1])); dsp_o = dsp_i + 6'd1; end
	`ASR:	begin res_o = $signed(dstack[dsp_i-1]) >> res_i; end
	`SHR:	begin res_o = dstack[dsp_i-1] >> res_i; end
	`SHL:	begin res_o = dstack[dsp_i-1] << res_i; end
	`JMP:	begin npc = res_i[14:0]; end
	`JZ:	begin if (res_i==32'd0) npc = lit15; skip = 3'd3; end
	`CALL:	begin rstack[rsp-6'd1] = pc; npc = res_i[14:0]; end
	`RET:	begin npc = rstack[rsp_i]; rsp_o = rsp_i + 6'd1; end
	`LIT15:	begin res_o = {{17{ir[24]}},ir[24:10]}; skip1 = 1'b1; end
	`LIT5:	begin res_o = {{22{ir[14]}},ir[14:10]}; skip4 = `TRUE; end
	`FETCH:	begin
				res_o = dmem_i;
				if (res_i[31:24]>8'h00) begin
					res_o = din;
					if (domem) begin
						domem <= `FALSE;
						state <= MEMNACK;
					end
				end
			end
	`STORE:	begin
				store_v[which] <= 1'b1;
				store_addr[which] <= dstack[dsp];
				store_data[which] <= dstack[dsp_i-6'd1];
				dsp_o = dsp_i + 6'd2;
				state <= MEMNACK;
			end
	`LIT15:	begin res0 = {{17{lit15[14]}},lit15[14:0]}; skip = 3'd3; end
	`LIT5:	begin res0 = {{27{lit5[4]}},lit5[4:0]}; skip = 3'd1; end
	endcase
end
endtask

endmodule
