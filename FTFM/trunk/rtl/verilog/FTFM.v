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
parameter MEMNACK = 4'd3;

reg [26:0] din;
reg [17:0] rstack [0:63];
reg [5:0] rsp, rsp0, rsp1, rsp2, rsp3, rsp4;
reg [26:0] dstack [0:63];
reg [5:0] dsp, dsp0, dsp1, dsp2, dsp3, dsp4;

reg [26:0] dmem [0:16383];
reg [63:0] rommem [0:16383];

initial begin
`include "c:\cores5\ftfm\trunk\software\boot\boot.ve0"
end

reg [14:0] pc, npc;


reg [26:0] res0, res1, res2, res3, res4;
reg loadf;
reg skip0, skip1, skip2, skip3, skip4, skip5, skip6;
wire [26:0] tos = dstack[dsp];
wire [26:0] nos = dstack[dsp-1];
reg [26:0] dmem_o;
reg [26:0] imem_o;

always @(posedge clk_i)
	if (ir[4:0]==`STORE && tos[26:25]==2'b00 && state==RUN)
		dmem[tos] <= nos;

always @(negedge clk_i)
	dmem_o <= dmem[tos];
always @(negedge clk_i)
	imem_o <= rommem[pc][26:0];
wire [26:0] ir = imem_o[26:0];

always @(posedge clk_i)
if (rst_i) begin
	dsp <= 6'd63;
	rsp <= 6'd63;
	pc <= 15'd0;
	loadf <= `FALSE;
	state <= RUN;
end
else begin
loadf <= `FALSE;
case(state)
RUN:
	begin
		if (!loadf)
		npc = pc + 15'd1;
		else
		npc = pc;
		//
		skip0 = 1'b0;
		skip1 = 1'b0;
		skip2 = 1'b0;
		skip3 = 1'b0;
		skip4 = 1'b0;
		skip5 = 1'b0;
		skip6 = 1'b0;
		rsp0 = rsp;
		dsp0 = dsp;
		res0 = tos;
		if (ir[26]==1'b1) begin
			res0 = {{1{ir[25]}},ir[25:0]};
			skip2 = 1'b1;
		end
		else if (!loadf)
		case (ir[4:0])
		`NOP:	res0 = tos;
		`PDPR:  
				begin	// pop d, push r
					rstack[rsp-6'd1] <= tos;
					dsp0 = dsp + 6'd1;
					rsp0 = rsp - 6'd1;
				end
		`PRPD:	begin	// pop r, push d
					res0 = rstack[rsp];
					rsp0 = rsp + 6'd1;
					dsp0 = dsp - 6'd1;
				end
		`MVRD:	begin res0 = rstack[rsp]; dsp0 = dsp - 6'd1; end
		`DUP:	begin res0 = tos; dsp0 = dsp - 6'd1; end
		`DROP:	begin res0 = dstack[dsp + 6'd1]; dsp0 = dsp + 6'd1; end
		`OVER:	begin res0 = nos; dsp0 = dsp - 6'd1; end
		`INV:	begin res0 = ~tos; end
		`ADD:	begin res0 = tos + dstack[dsp-1]; dsp0 = dsp + 6'd1; end
		`SUB:	begin res0 = tos - dstack[dsp-1]; dsp0 = dsp + 6'd1; end
		`AND:	begin res0 = tos & dstack[dsp-1]; dsp0 = dsp + 6'd1; end
		`OR:	begin res0 = tos | dstack[dsp-1]; dsp0 = dsp + 6'd1; end
		`XOR:	begin res0 = tos ^ dstack[dsp-1]; dsp0 = dsp + 6'd1; end
		`MUL:	begin res0 = $signed(tos) * $signed(dstack[dsp-1]); dsp0 = dsp + 6'd1; end
		`EQ:	begin res0 = (tos ^ dstack[dsp-1])==0; dsp0 = dsp + 6'd1; end
		`LT:	begin res0 = ($signed(tos) < $signed(dstack[dsp-1])); dsp0 = dsp + 6'd1; end
		`ASR:	begin res0 = $signed(nos) >> tos; end
		`SHR:	begin res0 = nos >> tos; end
		`SHL:	begin res0 = nos << tos; end
		`JMP:	begin npc = ir[19:5]; skip0 = 1'b1; end
		`JZ:	begin if (tos==27'd0) npc = ir[19:5]; skip0 = 1'b1; end
		`CALL:	begin rstack[rsp-6'd1] = pc; npc = ir[19:5]; skip0 = 1'b1; end
		`RET:	begin npc = rstack[rsp]; rsp0 = rsp + 6'd1; end
		`FETCH:	begin
					res0 = dmem_o;
					if (tos[26:25]==2'b11) begin
						cyc_o <= `HIGH;
						stb_o <= `HIGH;
						adr_o <= tos[24:0];
						state <= MEMLD;
					end
				end
		`STORE:	begin
					if (tos[26:25]==2'b11) begin
						cyc_o <= `HIGH;
						stb_o <= `HIGH;
						we_o <= `HIGH;
						adr_o <= tos[24:0];
						dat_o <= nos;
						state <= MEMST;
					end
				end
		`LIT15:	begin res0 = {{17{ir[19]}},ir[19:5]}; skip0 = 1'b1; end
		`LIT5:	begin res0 = {{22{ir[9]}},ir[9:5]}; skip3 = `TRUE; end
		endcase
		dstack[dsp0] = res0;
		rsp1 = rsp0;
		dsp1 = dsp0;
		if (skip0|skip2|skip3|loadf)
			res1 = res0;
		else
		case (ir[9:5])
		`NOP:	res1 = res0;
		`PDPR:  
				begin
					rstack[rsp0-6'd1] <= dstack[dsp0];
					dsp1 = dsp0 + 6'd1;
					rsp1 = rsp0 - 6'd1;
				end
		`PRPD:	begin
					dstack[dsp0-6'd1] <= rstack[rsp0];
					rsp1 = rsp0 + 6'd1;
					dsp1 = dsp0 - 6'd1;
				end
		`MVRD:	begin res1 = rstack[rsp0]; dsp1 = dsp0 - 6'd1; end
		`DUP:	begin res1 = res0; dsp1 = dsp0 - 6'd1; end
		`DROP:	begin res1 = dstack[dsp0 + 6'd1]; dsp1 = dsp0 + 6'd1; end
		`OVER:	begin res1 = dstack[dsp0 + 6'd1]; dsp1 = dsp0 - 6'd1; end
		`INV:	begin res1 = ~res0; end
		`ADD:	begin res1 = res0 + dstack[dsp0-1]; dsp1 = dsp0 + 6'd1; end
		`SUB:	begin res1 = res0 - dstack[dsp0-1]; dsp1 = dsp0 + 6'd1; end
		`AND:	begin res1 = res0 & dstack[dsp0-1]; dsp1 = dsp0 + 6'd1; end
		`OR:	begin res1 = res0 | dstack[dsp0-1]; dsp1 = dsp0 + 6'd1; end
		`XOR:	begin res1 = res0 ^ dstack[dsp0-1]; dsp1 = dsp0 + 6'd1; end
		`MUL:	begin res1 = $signed(res0) * $signed(dstack[dsp0-1]); dsp1 = dsp0 + 6'd1; end
		`EQ:	begin res1 = (res0 ^ dstack[dsp0-1])==0; dsp1 = dsp0 + 6'd1; end
		`LT:	begin res1 = ($signed(res0) < $signed(dstack[dsp0-1])); dsp1 = dsp0 + 6'd1; end
		`ASR:	begin res1 = $signed(dstack[dsp0-1]) >> res0; end
		`SHR:	begin res1 = dstack[dsp0-1] >> res0; end
		`SHL:	begin res1 = dstack[dsp0-1] << res0; end
		`JMP:	begin npc = ir[24:10]; skip1 = 1'b1; end
		`JZ:	begin if (res0==27'd0) npc = ir[24:10]; skip1 = 1'b1; end
		`CALL:	begin rstack[rsp-6'd1] = pc; npc = ir[24:10]; skip1 = 1'b1; end
		`RET:	begin npc = rstack[rsp0]; rsp1 = rsp0 + 6'd1; end
		`LIT15:	begin res1 = {{17{ir[24]}},ir[24:10]}; skip1 = 1'b1; end
		`LIT5:	begin res1 = {{22{ir[14]}},ir[14:10]}; skip4 = `TRUE; end
		endcase
		rsp2 = rsp1;
		dsp2 = dsp1;
		dstack[dsp1] = res1;
		if (skip0|skip1|skip2|skip4|loadf)
			res2 = res1;
		else
		case(ir[14:10])
		`NOP:	res2 = res1;
		`PDPR:  
				begin
					rstack[rsp1-6'd1] <= dstack[dsp1];
					dsp2 = dsp1 + 6'd1;
					rsp2 = rsp1 - 6'd1;
				end
		`PRPD:	begin
					dstack[dsp1-6'd1] <= rstack[rsp1];
					rsp2 = rsp1 + 6'd1;
					dsp2 = dsp1 - 6'd1;
				end
		`DUP:	begin res2 = res1; dsp2 = dsp1 - 6'd1; end
		`DROP:	begin res2 = dstack[dsp1 + 6'd1]; dsp2 = dsp1 + 6'd1; end
		`OVER:	begin res2 = dstack[dsp1 + 6'd1]; dsp2 = dsp1 - 6'd1; end
		`INV:	begin res2 = ~res1; end
		`MVRD:	begin res2 = rstack[rsp1]; dsp2 = dsp1 - 6'd1; end
		`ADD:	begin res2 = res1 + dstack[dsp1-1]; dsp2 = dsp1 + 6'd1; end
		`SUB:	begin res2 = res1 - dstack[dsp1-1]; dsp2 = dsp1 + 6'd1; end
		`AND:	begin res2 = res1 & dstack[dsp1-1]; dsp2 = dsp1 + 6'd1; end
		`OR:	begin res2 = res1 | dstack[dsp1-1]; dsp2 = dsp1 + 6'd1; end
		`XOR:	begin res2 = res1 ^ dstack[dsp1-1]; dsp2 = dsp1 + 6'd1; end
		`MUL:	begin res2 = $signed(res1) * $signed(dstack[dsp1-1]); dsp2 = dsp1 + 6'd1; end
		`EQ:	begin res2 = (res1 ^ dstack[dsp1-1])==0; dsp2 = dsp1 + 6'd1; end
		`LT:	begin res2 = ($signed(res1) < $signed(dstack[dsp1-1])); dsp2 = dsp1 + 6'd1; end
		`ASR:	begin res2 = $signed(dstack[dsp1-1]) >> res1; end
		`SHR:	begin res2 = dstack[dsp1-1] >> res1; end
		`SHL:	begin res2 = dstack[dsp1-1] << res1; end
		`RET:	begin npc = rstack[rsp1]; rsp2 = rsp1 + 6'd1; end
		`LIT5:	begin res2 = {{22{ir[19]}},ir[19:14]}; skip5 = `TRUE; end
		endcase
		rsp3 = rsp2;
		dsp3 = dsp2;
		dstack[dsp2] = res2;
		if (skip0|skip1|skip2|skip5|loadf)
			res3 = res2;
		else
		case(ir[19:15])
		`NOP:	res3 = res2;
		`PDPR:  
				begin
					rstack[rsp2-6'd1] <= dstack[dsp2];
					dsp3 = dsp2 + 6'd1;
					rsp3 = rsp2 - 6'd1;
				end
		`PRPD:	begin
					dstack[dsp2-6'd1] <= rstack[rsp2];
					rsp3 = rsp2 + 6'd1;
					dsp3 = dsp2 - 6'd1;
				end
		`MVRD:	begin res3 = rstack[rsp2]; dsp3 = dsp2 - 6'd1; end
		`MVRD:	begin res3 = rstack[rsp2]; dsp3 = dsp2 - 6'd1; end
		`DUP:	begin res3 = res2; dsp3 = dsp2 - 6'd1; end
		`DROP:	begin res3 = dstack[dsp2 + 6'd1]; dsp3 = dsp2 + 6'd1; end
		`OVER:	begin res3 = dstack[dsp2 + 6'd1]; dsp3 = dsp2 - 6'd1; end
		`INV:	begin res3 = ~res2; end
		`ADD:	begin res3 = res2 + dstack[dsp2-1]; dsp3 = dsp2 + 6'd1; end
		`SUB:	begin res3 = res2 - dstack[dsp2-1]; dsp3 = dsp2 + 6'd1; end
		`AND:	begin res3 = res2 & dstack[dsp2-1]; dsp3 = dsp2 + 6'd1; end
		`OR:	begin res3 = res2 | dstack[dsp2-1]; dsp3 = dsp2 + 6'd1; end
		`XOR:	begin res3 = res2 ^ dstack[dsp2-1]; dsp3 = dsp2 + 6'd1; end
		`MUL:	begin res3 = $signed(res2) * $signed(dstack[dsp2-1]); dsp3 = dsp2 + 6'd1; end
		`EQ:	begin res3 = (res2 ^ dstack[dsp2-1])==0; dsp3 = dsp2 + 6'd1; end
		`LT:	begin res3 = ($signed(res2) < $signed(dstack[dsp2-1])); dsp3 = dsp2 + 6'd1; end
		`ASR:	begin res3 = $signed(res2) >> 1; end
		`ASR:	begin res3 = $signed(dstack[dsp2-1]) >> res2; end
		`SHR:	begin res3 = dstack[dsp2-1] >> res2; end
		`SHL:	begin res3 = dstack[dsp2-1] << res2; end
		`RET:	begin npc = rstack[rsp2]; rsp3 = rsp2 + 6'd1; end
		`LIT5:	begin res3 = {{22{ir[19]}},ir[19:14]}; skip6 = `TRUE; end
		endcase
		dstack[dsp3] = res3;
		rsp4 = rsp3;
		dsp4 = dsp3;
		if (skip1|skip2|skip6|loadf)
			res4 = res3;
		else
		case(ir[24:20])
		`NOP:	res4 = res3;
		`PDPR:  
				begin
					rstack[rsp3-6'd1] <= dstack[dsp3];
					dsp4 = dsp3 + 6'd1;
					rsp4 = rsp3 - 6'd1;
				end
		`PRPD:	begin
					dstack[dsp3-6'd1] <= rstack[rsp3];
					rsp4 = rsp3 + 6'd1;
					dsp4 = dsp3 - 6'd1;
				end
		`MVRD:	begin res4 = rstack[rsp3]; dsp4 = dsp3 - 6'd1; end
		`DUP:	begin res4 = res3; dsp4 = dsp3 - 6'd1; end
		`DROP:	begin res4 = dstack[dsp3 + 6'd1]; dsp4 = dsp3 + 6'd1; end
		`OVER:	begin res4 = dstack[dsp3 + 6'd1]; dsp4 = dsp3 - 6'd1; end
		`INV:	begin res4 = ~res3; end
		`ADD:	begin res4 = res3 + dstack[dsp3-1]; dsp4 = dsp3 + 6'd1; end
		`SUB:	begin res4 = res3 - dstack[dsp3-1]; dsp4 = dsp3 + 6'd1; end
		`AND:	begin res4 = res3 & dstack[dsp3-1]; dsp4 = dsp3 + 6'd1; end
		`OR:	begin res4 = res3 | dstack[dsp3-1]; dsp4 = dsp3 + 6'd1; end
		`XOR:	begin res4 = res3 ^ dstack[dsp3-1]; dsp4 = dsp3 + 6'd1; end
		`MUL:	begin res4 = $signed(res3) * $signed(dstack[dsp3-1]); dsp4 = dsp3 + 6'd1; end
		`EQ:	begin res4 = (res3 ^ dstack[dsp3-1])==0; dsp4 = dsp3 + 6'd1; end
		`LT:	begin res4 = ($signed(res3) < $signed(dstack[dsp3-1])); dsp4 = dsp3 + 6'd1; end
		`ASR:	begin res4 = $signed(dstack[dsp3-1]) >> res3; end
		`SHR:	begin res4 = dstack[dsp3-1] >> res3; end
		`SHL:	begin res4 = dstack[dsp3-1] << res3; end
		`RET:	begin npc = rstack[rsp3]; rsp4 = rsp3 + 6'd1; end
		endcase
		dstack[dsp4] = loadf ? din : res4;
		dsp <= dsp4;
		rsp <= rsp4;
		pc <= npc;
	end
MEMLD:
	if (ack_i) begin
		cyc_o <= `LOW;
		stb_o <= `LOW;
		din <= dat_i;	
		loadf <= `TRUE;
		state <= MEMNACK;
	end
MEMST:
	if (ack_i) begin
		cyc_o <= `LOW;
		stb_o <= `LOW;
		we_o <= `LOW;
		state <= MEMNACK;
	end
MEMNACK:
	if (~ack_i) begin
		loadf <= loadf;
		state <= RUN;
	end
endcase
end


endmodule
