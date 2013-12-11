// ============================================================================
//        __
//   \\__/ o\    (C) 2013  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
//
//     31        20     15     10     5       0
//	   +--------+------+------+------+--------+
//	RR | func   |  Rt  |  Rb  |  Ra  | opcode |	
//	   +--------+------+------+------+--------+
//	RI |   immediate   |  Rt  |  Ra  | opcode |
//	   +---------------+------+------+--------+
//	 J |          address            | opcode |
//	   +-----------------------+-----+--------+
//	 B |       displacement    | cnd | opcode |
//	   +-----------------------+-----+--------+
//
// ============================================================================
//
`define RR		6'd2
`define ADD			6'd4
`define SUB			6'd5
`define CMP			6'd6
`define AND			6'd8
`define OR			6'd9
`define XOR			6'd10
`define SHL			6'd16
`define SHR			6'd17
`define ASR			6'd18
`define ROL			6'd19
`define ROR			6'd20
`define SHLI		6'd21
`define SHRI		6'd22
`define ASRI		6'd23
`define ROLI		6'd24
`define RORI		6'd25
`define ADDI	6'd4
`define SUBI	6'd5
`define CMPI	6'd6
`define ANDI	6'd8
`define ORI		6'd9
`define XORI	6'd10
`define Bcc		6'd16
`define BRA			4'd0
`define BEQ			4'd2
`define BNE			4'd3
`define BLT			4'd4
`define BLE			4'd5
`define BGT			4'd6
`define BGE			4'd7
`define BLTU		4'd8
`define BLEU		4'd9
`define BGTU		4'd10
`define BGEU		4'd11
`define BMI			4'd12
`define BPL			4'd13
`define BVS			4'd14
`define BVC			4'd15
`define LB		6'd32
`define LBU		6'd33
`define LH		6'd34
`define LHU		6'd35
`define LW		6'd36
`define LICL	6'd39
`define SB		6'd40
`define SH		6'd41
`define SW		6'd42
`define NOP		6'd63

`define NOP_INSN	{26'd0,`NOP};

module rtfBarrel(rst_i, clk_i, bte_o, cti_o, cyc_o, stb_o, sel_o, we_o, adr_o, dat_i, dat_o);
parameter ICACHE = 2'd1;
parameter RUN = 2'd2;
input rst_i;
input clk_i;
output reg [1:0] bte_o;
output reg [2:0] cti_o;
output reg cyc_o;
output reg stb_o;
output reg [3:0] sel_o;
output reg we_o;
output reg [31:0] adr_o;
input [31:0] dat_i;
output reg [31:0] dat_o;

reg [1:0] state;
reg [31:0] pc [0:7];
reg [2:0] if_ctx,dc_ctx,ex_ctx,mem_ctx,wb_ctx;
reg [31:0] if_ir,dc_ir,ex_ir,mem_ir,wb_ir;
reg [7:0] cf,nf,vf,zf;		// flags register
wire [5:0] ex_op = ex_ir[5:0];
wire [5:0] mem_op = mem_ir[5:0];
reg [31:0] regfile[0:255];	// regfile: 32 regs * 8 contexts
reg [4:0] Ra, Rb, wb_Rt;
reg [31:0] a,b,imm,mem_b,mem_a,mem_imm;
reg [32:0] res,mem_res;
reg [31:0] imiss_adr [0:7];

wire [5:0] dc_op = dc_ir[5:0];
wire [5:0] dc_func = dc_ir[31:26];
wire dc_isShifti = dc_op==`RR && (dc_func==`SHLI || dc_func==`SHRI || dc_func==`ASRI || dc_func==`ROLI || dc_func==`RORI);

wire memIsMem = mem_op==`LB || mem_op==`LBU || mem_op==`LH || mem_op==`LHU || mem_op==`LW || mem_op==`LICL ||
				mem_op==`SB || mem_op==`SH || mem_op==`SW
				;
wire adv_pipe = memIsMem ? ack_i && ( cti_o==3'b000 || cti_o==3'b111) : 1'b1;

wire signed [31:0] as = a;
wire signed [31:0] bs = b;
wire [64:0] shlo = {32'd0,a} << b[4:0];
wire [64:0] shro = {a,32'b0} >> b[4:0];
wire signed [31:0] asro = as >> bs[4:0];

reg rst1 = 1'b0;
always @(posedge clk_i)
	rst1 = rst_i;
wire rst_edge = rst_i & ~rst1;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Instruction Cache
// 4-way set associative.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

wire [31:0] insn0,insn1,insn2,insn3;

icache_ram u1
(
	.wclk(clk_i),
	.we(state==ICACHE && ack_i),
	.adr(adr_o),
	.dat(dat_i),
	.rclk(~clk_i),
	.pc(pc[if_ctx]),
	.insn0(insn0),
	.insn1(insn1),
	.insn2(insn2),
	.insn3(insn3)
);

wire ihit0,ihit1,ihit2,ihit3;
wire ihit = ihit0|ihit1|ihit2|ihit3;

itag_ram u2
(
	.wclk(clk_i),
	.we(state==ICACHE && ack_i && adr_o[3:2]==2'b11),
	.adr(adr_o),
	.rclk(~clk_i),
	.pc(pc[if_ctx]),
	.ihit0(ihit0),
	.ihit1(ihit1),
	.ihit2(ihit2),
	.ihit3(ihit3)
);

wire [31:0] insn = ihit0 ? insn0 : ihit1 ? insn1 : ihit2 ? insn2 : ihit3 ? insn3 : `LICL;

//  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
// Evaluate branch condition
// Takes place during the EX stage
//  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
//
wire ezf = zf[ex_ctx];	// convenience translations
wire ecf = cf[ex_ctx];
wire enf = nf[ex_ctx];
wire evf = vf[ex_ctx];

reg takb;
always @(ex_ir or ezf or ecf or evf or enf)
begin
	case(ex_ir[9:6])
	`BRA:	takb <= 1'b1;
	`BEQ:	takb <=  ezf;
	`BNE:	takb <= !ezf;
	`BGTU:	takb <= !ecf & !ezf;
	`BLEU:	takb <=  ecf | ezf;
	`BLTU:	takb <=  ecf;
	`BGEU:	takb <= !ecf;
	`BMI:	takb <=  enf;
	`BPL:	takb <= !enf;
	`BVS:	takb <=  evf;
	`BVC:	takb <= !evf;
	`BGT:	takb <= (enf & evf & !ezf) | (!enf & !evf & !ezf);
	`BGE:	takb <= (enf & evf) | (!enf & !evf);
	`BLE:	takb <= ezf | (enf & !evf) | (!enf & evf);
	`BLT:	takb <= (enf & !evf) | (!enf & evf);
	default:	takb <= 1'b0;
	endcase
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// IF stage
//
// If there is a cache miss we propagate a LICL instruction into the pipeline.
// Otherwise the register file read address is decoded. And the fetch context
// is incremented.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
always @(posedge clk_i)
if (rst_i) begin
	dc_ir <= `NOP_INSN;
	Ra <= 5'd0;
	Rb <= 5'd0;
	if_ctx <= 3'd0;
	dc_ctx <= 3'd0;
end
else begin
if (adv_pipe) begin
	dc_ir <= insn;
	Ra <= insn[10: 5];
	Rb <= insn[15:11];
	if_ctx <= if_ctx + 3'd1;
	dc_ctx <= if_ctx;
	if (!ihit)
		imiss_adr[if_ctx] <= pc[if_ctx];
end
end


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// DC/RF stage
//
// Fetch operands from the register file.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
always @(posedge clk_i)
if (rst_i) begin
	if (rst_edge)
		ex_ctx <= 3'd0;
	else
		ex_ctx <= ex_ctx + 3'd1;
	ex_ir <= `NOP_INSN;
	a <= 32'd0;
	b <= 32'd0;
	imm <= 32'd0;
end
else begin
if (adv_pipe) begin
	ex_ir <= dc_ir;
	ex_ctx <= dc_ctx;
	a <= Ra==5'd0 ? 32'd0 : regfile[{dc_ctx,Ra}];
	if (dc_isShifti)
		b <= Rb;
	else
		b <= Rb==5'd0 ? 32'd0 : regfile[{dc_ctx,Rb}];
	imm <= {{16{dc_ir[31]}},dc_ir[31:16]};
end
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// EX stage
//
// Produce an execution result. The PC is also updated at this point so there
// is only a single stage the PC update occurs in.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
initial begin
	mem_ctx <= 3'd0;
end

always @(posedge clk_i)
if (rst_i) begin
	mem_ir <= `NOP_INSN;
	mem_a <= 32'd0;
	mem_b <= 32'd0;
	mem_imm <= 32'd0;
	pc[ex_ctx] <= 32'hFFFFFFF0;
	res <= 33'd0;
	if (rst_edge)
		mem_ctx <= 3'd0;
	else
		mem_ctx <= mem_ctx + 3'd1;
end
else begin
if (adv_pipe) begin
	if (ex_op!=`LICL)
		pc[ex_ctx] <= pc[ex_ctx] + 32'd4;
	mem_ir <= ex_ir;
	mem_ctx <= ex_ctx;
	mem_a <= a;
	mem_b <= b;
	mem_imm <= imm;
	case(ex_op)
	`RR:
		case(ex_ir[31:26])
		`ADD:	res <= a + b;
		`SUB:	res <= a - b;
		`CMP:	res <= a - b;
		`AND:	res <= a & b;
		`OR:	res <= a | b;
		`XOR:	res <= a ^ b;
		`SHL,`SHLI:	res <= shlo[32: 0];
		`SHR,`SHRI:	res <= shro[64:32];
		`ASR,`ASRI:	res <= asro[31: 0];
		`ROL,`ROLI:	res <= shlo[31:0]|shlo[63:32];
		`ROR,`RORI:	res <= shro[31:0]|shro[63:32];
		default:	res <= 32'd0;
		endcase
	`ADDI:	res <= a + imm;
	`SUBI:	res <= a - imm;
	`CMPI:	res <= a - imm;
	`ANDI:	res <= a & imm;
	`ORI:	res <= a | imm;
	`XORI:	res <= a ^ imm;
	`JMP:	pc[ex_ctx] <= ir[31:6];
	`CALL:	begin res <= pc[ex_ctx]; pc[ex_ctx] <= ir[31:6]; end
	`Bcc:
		case(ex_ir[9:6])
		`BRA,`BEQ,`BNE,`BLT,`BLE,`BGT,`BGE,`BLTU,`BLEU,`BGTU,`BGEU,`BMI,`BPL,`BVS,`BVC:
			if (takb)
				pc[ex_ctx] <= pc[ex_ctx] + {{16{ex_ir[31]}},ex_ir[31:16]};
		endcase
	`LB,`LBU,`LH,`LHU,`LW,`SB,`SH,`SW:
		res <= a + imm;
	default:	res <= 32'd0;
	endcase
end
end


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// MEM stage
//
// Access memory if needed. Compute overflow. We compute overflow here
// rather than in the next stage in order to avoid passing operands further
// down the pipeline.
// Figure out which register is the target register.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
always @(posedge clk_i)
if (rst_i) begin
	state <= RUN;
	wb_ir <= `NOP_INSN;
	wb_Rt <= 5'd0;
	if (rst_edge)
		wb_ctx <= 3'd0;
	else
		wb_ctx <= wb_ctx + 3'd1;
	vf[mem_ctx] <= 1'b0;
	mem_res <= 33'd0;
	nack();
end
else begin
if (adv_pipe) begin
	wb_ir <= mem_ir;
	wb_ctx <= mem_ctx;
	case(mem_ir[5:0])
	`RR:
		case (mem_ir[31:26])
		`ADD:		vf[mem_ctx] <= (res[31] ^ mem_b[31]) & (1'b1 ^ mem_a[31] ^ mem_b[31]);
		`SUB,`CMP:	vf[mem_ctx] <= (1'b1 ^ res[31] ^ mem_b[31]) & (mem_a[31] ^ mem_b[31]);
		endcase
	`ADDI:			vf[mem_ctx] <= (res[31] ^ mem_imm[31]) & (1'b1 ^ mem_a[31] ^ mem_imm[31]);
	`SUBI,`CMPI:	vf[mem_ctx] <= (1'b1 ^ res[31] ^ mem_imm[31]) & (mem_a[31] ^ mem_imm[31]);
	`LB,`LBU:	read_byte(res);
	`LH,`LHU:	read_half(res);
	`LW:		read_word(res);
	`LICL:		read_iline(imiss_adr[mem_ctx]);
	`SB:		write_byte(res,mem_b);
	`SH:		write_half(res,mem_b);
	`SW:		write_half(res,mem_b);
	default:	mem_res <= res;
	endcase
	// Set target register
	case(mem_ir[5:0])
	`RR:
		wb_Rt <= mem_ir[20:16];
	`ADDI,`SUBI:
		wb_Rt <= mem_ir[15:11];
	`ANDI,`XORI,`ORI:
		wb_Rt <= mem_ir[15:11];
	`CALL:
		wb_Rt <= 5'd31;
	`LB,`LBU,`LH,`LHU,`LW:
		wb_Rt <= mem_ir[15:11];
	default:
		wb_Rt <= 5'h00;
	endcase
end
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// WB stage
//
// Update the register file with results.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
always @(posedge clk_i)
if (rst_i) begin
	zf[wb_ctx] <= 1'b0;
	cf[wb_ctx] <= 1'b0;
	nf[wb_ctx] <= 1'b0;
	regfile[{wb_ctx,wb_Rt}] <= 32'd0;
end
else begin
if (adv_pipe) begin
	case(wb_ir[5:0])
	`RR:
		case(wb_ir[31:26])
		`ADD,`SUB,`CMP:
			begin
				cf[wb_ctx] <= mem_res[32];
				zf[wb_ctx] <= mem_res[31:0]==32'd0;
				nf[wb_ctx] <= mem_res[31];
			end
		`SHL,`SHR,`ASR,`ROL,`ROR,`SHLI,`SHRI,`ASRI,`RORI,`ROLI:
			begin
				cf[wb_ctx] <= mem_res[32];
				zf[wb_ctx] <= mem_res[31:0]==32'd0;
				nf[wb_ctx] <= mem_res[31];
			end
		`AND,`OR,`XOR:
			begin
				zf[wb_ctx] <= mem_res[31:0]==32'd0;
				nf[wb_ctx] <= mem_res[31];
			end
		endcase
	`ADDI,`SUBI,`CMPI:
		begin
			cf[wb_ctx] <= mem_res[32];
			zf[wb_ctx] <= mem_res[31:0]==32'd0;
			nf[wb_ctx] <= mem_res[31];
		end
	`ANDI,`ORI,`XORI:
		begin
			zf[wb_ctx] <= mem_res[31:0]==32'd0;
			nf[wb_ctx] <= mem_res[31];
		end
	`LB,`LBU,`LH,`LHU,`LW:
		begin
			zf[wb_ctx] <= mem_res[31:0]==32'd0;
			nf[wb_ctx] <= mem_res[31];
		end
	endcase
	regfile[{wb_ctx,wb_Rt}] <= mem_res;
end
end

// ----------------------------------------------------------------------------
// Supporting tasks.
// ----------------------------------------------------------------------------

task nack;
begin
	bte_o <= 2'b00;
	cti_o <= 3'b000;
	cyc_o <= 1'b0;
	stb_o <= 1'b0;
	we_o <= 1'b0;
	sel_o <= 4'h0;
	adr_o <= 32'd0;
	dat_o <= 32'd0;
end
endtask

task read_byte;
input [31:0] ad;
begin
	if (!cyc_o) begin
		bte_o <= 2'b00;
		cti_o <= 3'b000;
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		case(ad[1:0])
		2'd0:	sel_o <= 4'b0001;
		2'd1:	sel_o <= 4'b0010;
		2'd2:	sel_o <= 4'b0100;
		2'd3:	sel_o <= 4'b1000;
		endcase
		adr_o <= ad;
	end
	else if (ack_i) begin
		nack();
		if (mem_op==`LB)
			case(sel_o)
			4'b0001:	mem_res <= {{24{dat_i[7]}},dat_i[7:0]};
			4'b0010:	mem_res <= {{24{dat_i[15]}},dat_i[15:8]};
			4'b0100:	mem_res <= {{24{dat_i[23]}},dat_i[23:16]};
			4'b1000:	mem_res <= {{24{dat_i[31]}},dat_i[31:24]};
			endcase
		else
			case(sel_o)
			4'b0001:	mem_res <= dat_i[7:0];
			4'b0010:	mem_res <= dat_i[15:8];
			4'b0100:	mem_res <= dat_i[23:16];
			4'b1000:	mem_res <= dat_i[31:24];
			endcase
	end
end
endtask

task read_half;
input [31:0] ad;
begin
	if (!cyc_o) begin
		bte_o <= 2'b00;
		cti_o <= 3'b000;
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		case(ad[1])
		1'd0:	sel_o <= 4'b0011;
		1'd1:	sel_o <= 4'b1100;
		endcase
		adr_o <= ad;
	end
	else if (ack_i) begin
		nack();
		if (mem_op==`LH)
			case(sel_o)
			4'b0011:	mem_res <= {{16{dat_i[15]}},dat_i[15:0]};
			4'b1100:	mem_res <= {{16{dat_i[31]}},dat_i[31:16]};
			endcase
		else
			case(sel_o)
			4'b0011:	mem_res <= dat_i[15:0];
			4'b1100:	mem_res <= dat_i[31:16];
			endcase
	end
end
endtask

task read_word;
input [31:0] ad;
begin
	if (!cyc_o) begin
		bte_o <= 2'b00;
		cti_o <= 3'b000;
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 4'b1111;
		adr_o <= ad;
	end
	else if (ack_i) begin
		nack();
		mem_res <= dat_i;
	end
end
endtask

task read_iline;
input [31:0] ad;
begin
	if (!cyc_o) begin
		bte_o <= 2'b00;
		cti_o <= 3'b001;
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 4'b1111;
		adr_o <= {ad[31:4],4'b0000};
		state <= ICACHE;
	end
	else if (ack_i && adr_o[3:2]==2'b10) begin
		cti_o <= 3'b111;
		adr_o[3:2] <= adr_o[3:2] + 2'd1;
	end
	else if (ack_i && adr_o[3:2]==2'b11) begin
		state <= RUN;
		nack();
	end
	else if (ack_i)
		adr_o[3:2] <= adr_o[3:2] + 2'd1;
end
endtask

task write_byte;
input [31:0] ad;
input [31:0] dt;
begin
	if (!cyc_o) begin
		bte_o <= 2'b00;
		cti_o <= 3'b000;
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= 1'b1;
		case(ad[1:0])
		2'd0:	sel_o <= 4'b0001;
		2'd1:	sel_o <= 4'b0010;
		2'd2:	sel_o <= 4'b0100;
		2'd3:	sel_o <= 4'b1000;
		endcase
		adr_o <= ad;
		dat_o <= {4{dt[7:0]}};
	end
	else if (ack_i) begin
		nack();
	end
end
endtask

task write_half;
input [31:0] ad;
input [31:0] dt;
begin
	if (!cyc_o) begin
		bte_o <= 2'b00;
		cti_o <= 3'b000;
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= 1'b1;
		case(ad[1])
		1'd0:	sel_o <= 4'b0011;
		1'd1:	sel_o <= 4'b1100;
		endcase
		adr_o <= {ad[31:1],1'b0};
		dat_o <= {2{dt[15:0]}};
	end
	else if (ack_i) begin
		nack();
	end
end
endtask

task write_word;
input [31:0] ad;
input [31:0] dt;
begin
	if (!cyc_o) begin
		bte_o <= 2'b00;
		cti_o <= 3'b000;
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= 1'b1;
		sel_o <= 4'b1111;
		adr_o <= {ad[31:2],2'b00};
		dat_o <= dt;
	end
	else if (ack_i) begin
		nack();
	end
end
endtask

endmodule

module icache_ram(wclk, we, adr, dat, rclk, pc, insn0, insn1, insn2, insn3);
input wclk;
input we;
input [31:0] adr;
input [31:0] dat;
input rclk;
input [31:0] pc;
output [31:0] insn0;
output [31:0] insn1;
output [31:0] insn2;
output [31:0] insn3;

reg [31:0] mem0 [0:1023];
reg [31:0] mem1 [0:1023];
reg [31:0] mem2 [0:1023];
reg [31:0] mem3 [0:1023];
reg [12:2] rpc;
integer n;

initial begin
	for (n = 0; n < 1024; n = n + 1)
	begin
		mem0[n] <= `NOP_INSN;
		mem1[n] <= `NOP_INSN;
		mem2[n] <= `NOP_INSN;
		mem3[n] <= `NOP_INSN;
	end
end

always @(posedge wclk)
	if (we) mem[adr[12:2]] <= dat;
always @(posedge rclk)
	rpc <= pc[12:2];
assign insn0 = mem0[rpc];
assign insn1 = mem1[rpc];
assign insn2 = mem2[rpc];
assign insn3 = mem3[rpc];

endmodule

module itag_ram(wclk, we, adr, rclk, pc, ihit0, ihit1, ihit2, ihit3);
input wclk;
input we;
input [31:0] adr;
input rclk;
input [31:0] pc;
output ihit0;
output ihit1;
output ihit2;
output ihit3;

reg [1:0] wcnt;				// way counter
reg [32:13] mem0 [0:255];
reg [32:13] mem1 [0:255];
reg [32:13] mem2 [0:255];
reg [32:13] mem3 [0:255];
reg [31:2] rpc;
integer n;

initial begin
	for (n = 0; n < 256; n = n + 1)
	begin
		mem0[n] <= 20'd0;
		mem1[n] <= 20'd0;
		mem2[n] <= 20'd0;
		mem3[n] <= 20'd0;
	end
end

always @(posedge wclk)
	if (we & wcnt==2'b00)
		mem0[adr[12:2]] <= {1'b1,adr[31:13]};
always @(posedge wclk)
	if (we & wcnt==2'b01)
		mem1[adr[12:2]] <= {1'b1,adr[31:13]};
always @(posedge wclk)
	if (we & wcnt==2'b10)
		mem2[adr[12:2]] <= {1'b1,adr[31:13]};
always @(posedge wclk)
	if (we & wcnt==2'b11)
		mem3[adr[12:2]] <= {1'b1,adr[31:13]};
always @(posedge rclk)
	rpc <= pc[12:2];

wire [32:13] tag0 = mem0[rpc];
wire [32:13] tag1 = mem1[rpc];
wire [32:13] tag2 = mem2[rpc];
wire [32:13] tag3 = mem3[rpc];

assign ihit0 = tag0=={1'b1,rpc[31:13]};
assign ihit1 = tag1=={1'b1,rpc[31:13]};
assign ihit2 = tag2=={1'b1,rpc[31:13]};
assign ihit3 = tag3=={1'b1,rpc[31:13]};

endmodule

