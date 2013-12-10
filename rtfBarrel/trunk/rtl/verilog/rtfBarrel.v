
module rtfBarrel(rst_i, clk_i, pc, insn, ihit);

reg [31:0] pc [0:7];
reg [2:0] if_ctx,dc_ctx,ex_ctx,mem_ctx,wb_ctx;
reg [31:0] if_ir,dc_ir,ex_ir,mem_ir,wb_ir;
reg [7:0] cf,nf,vf,zf;
wire [5:0] mem_op = mem_ir[5:0];
reg [31:0] regfile[0:255];	// regfile: 32 regs * 8 contexts
reg [4:0] Ra, Rb, wb_Rt;
reg [31:0] a,b,imm;
reg [32:0] res;
reg ack_id;		// delayed version of ack_i

always @(posedge clk_i)
	ack_id <= ack_i;

wire memIsMem = mem_op==`LB || mem_op==`LBU || mem_op==`LH || mem_op==`LHU || mem_op==`LW ||
				mem_op==`SB || mem_op==`SH || mem_op==`SW
				;
wire adv_pipe = memIsMem ? ack_id : 1'b1;

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
// If there is a cache miss we propagate a NOP instruction into the pipeline.
// Otherwise the register file read address is decoded. And the fetch context
// is incremented.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
always @(posedge clk_i)
if (adv_pipe) begin
	if (ihit) begin
		dc_ir <= insn;
		Ra <= insn[10: 5];
		Rb <= insn[15:11];
		if (if_ctx==3'd1)
			if_ctx <= 3'd7;
		else
			if_ctx <= if_ctx - 3'd1;
		dc_ctx <= if_ctx;
	end
	else begin
		dc_ir <= `NOP_INSN;
		Ra <= 5'd0;
		Rb <= 5'd0;
		dc_ctx <= 3'd0;
	end
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// DC stage
//
// Fetch operands from the register file.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
always @(posedge clk_i)
if (adv_pipe) begin
	ex_ir <= dc_ir;
	ex_ctx <= dc_ctx;
	a <= Ra==5'd0 ? 32'd0 : regfile[{dc_ctx,Ra}];
	b <= Rb==5'd0 ? 32'd0 : regfile[{dc_ctx,Rb}];
	imm <= {{16{dc_ir[31]}},dc_ir[31:16]};
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// EX stage
//
// Produce an execution result.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
always @(posedge clk_i)
if (adv_pipe) begin
	pc[ex_ctx] <= pc[ex_ctx] + 32'd4;
	mem_ir <= ex_ir;
	mem_ctx <= ex_ctx;
	mem_b <= b;
	case(ex_ir[5:0])
	`RR:
		case(ex_ir[31:26])
		`ADD:	res <= a + b;
		`SUB:	res <= a - b;
		`CMP:	res <= a - b;
		`AND:	res <= a & b;
		`OR:	res <= a | b;
		`XOR:	res <= a ^ b;
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

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// MEM stage
//
// Access memory if needed
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
always @(posedge clk_i)
if (adv_pipe) begin
	wb_ir <= mem_ir;
	wb_ctx <= mem_ctx;
	case(mem_ir[5:0])
	`LB,`LBU:	read_byte(res);
	`LH,`LHU:	read_half(res);
	`LW:		read_word(res);
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

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// WB stage
//
// Update the register file with results.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
always @(posedge clk_i)
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


// ----------------------------------------------------------------------------
// Supporting tasks.
// ----------------------------------------------------------------------------

task read_byte;
input [31:0] ad;
begin
	if (!cyc_o) begin
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
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 4'h0;
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
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		case(ad[1])
		1'd0:	sel_o <= 4'b0011;
		1'd1:	sel_o <= 4'b1100;
		endcase
		adr_o <= ad;
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 4'h0;
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
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 4'b1111;
		adr_o <= ad;
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 4'h0;
		mem_res <= dat_i;
	end
end
endtask

task write_byte;
input [31:0] ad;
input [31:0] dt;
begin
	if (!cyc_o) begin
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= 1'b0;
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
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		we_o <= 1'b0;
		sel_o <= 4'h0;
	end
end
endtask

task write_half;
input [31:0] ad;
input [31:0] dt;
begin
	if (!cyc_o) begin
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= 1'b0;
		case(ad[1])
		1'd0:	sel_o <= 4'b0011;
		1'd1:	sel_o <= 4'b1100;
		endcase
		adr_o <= {ad[31:1],1'b0};
		dat_o <= {2{dt[15:0]}};
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		we_o <= 1'b0;
		sel_o <= 4'h0;
	end
end
endtask

task write_word;
input [31:0] ad;
input [31:0] dt;
begin
	if (!cyc_o) begin
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= 1'b0;
		sel_o <= 4'b1111;
		adr_o <= {ad[31:2],2'b00};
		dat_o <= dt;
	end
	else if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		we_o <= 1'b0;
		sel_o <= 4'h0;
	end
end
endtask

endmodule

