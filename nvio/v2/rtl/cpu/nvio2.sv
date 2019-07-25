`include "nvio2-defines.sv"

module nvio2(hartid_i, rst_i, clk_i, nmi_i, irq_i, vpa_o, cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o);
input rst_i;
input clk_i;
input [31:0] hartid_i;
input nmi_i;
input irq_i;
output reg vpa_o;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [15:0] sel_o;
output reg [31:0] adr_o;
input [127:0] dat_i;
output reg [127:0] dat_o;
parameter RSTIP = 32'hFFFC0200;
parameter HIGH = 1'b1;
parameter LOW = 1'b0;

reg [7:0] state;
parameter IDLE = 8'd0;
parameter IFETCH = 8'd1;
parameter IFETCH2 = 8'd2;
parameter IFETCH3 = 8'd3;
parameter IFETCH4 = 8'd4;
parameter DECODE = 8'd5;
parameter REGFETCH = 8'd6;
parameter EXECUTE = 8'd7;
parameter WRITEBACK = 8'd8;
parameter MEMORY = 8'd9;
parameter MEMORY2 = 8'd10;
parameter MEMORY2_ACK = 8'd11;

reg nmi;
reg MachineMode;
reg [39:0] ir;
reg illegal_insn;
reg [31:0] ip;
reg [31:0] iip;				// ip of instruction being processed
reg [31:0] sel;
reg [6:0] opcode;
reg [5:0] funct;
reg [2:0] cond3;
reg [31:0] btgt;			// branch target
reg [6:0] bitno;
reg [11:0] csrno;
reg [1:0] csrop;
reg [6:0] Rs1, Rs2, Rs3, Rd;
reg wrrf;
reg [7:0] acnt;

(* ram_style="distributed" *)
reg [127:0] regfile [0:127];
wire [127:0] rfoa = regfile[Rs1];
wire [127:0] rfob = regfile[Rs2];
wire [127:0] rfoc = regfile[Rs3];
always @(posedge clk_i)
	if (wrrf)
		regfile[Rd] <= res;

reg [127:0] a, b, c, res, imm;

reg [63:0] mtick;
reg [127:0] mscratch;
reg [127:0] mstatus;
reg [31:0] mtvec;
reg [31:0] meip;
reg [31:0] mcause;
reg [127:0] cmdparm [0:7];

function fnStore;
input [6:0] opc;
case(opc)
`STB,`STW,`STT,`STO,`STH,`STHC,`MSX,
`STFS,`STFD,`STFQ:
	fnStore = TRUE;
default:
	fnStore = FALSE;
endcase
endfunction

function [15:0] fnSelect;
input [39:0] ins;
case(ins[6:0])
`LDB,`LDBU,`STB:	fnSelect = 16'h0001;
`LDW,`LDWU,`STW:	fnSelect = 16'h0003;
`LDT,`LDTU,`STT:	fnSelect = 16'h000F;
`LDO,`LDOU,`STO:	fnSelect = 16'h00FF;
`LDH,`LDHR,`STH,`STHC:	fnSelect = 16'hFFFF;
`LDFS,`STFS:			fnSelect = 16'h000F;
`LDFD,`STFD:			fnSelect = 16'h00FF;
`LDFQ,`STFQ:			fnSelcet = 16'hFFFF;
`MLX:
	case(ins[39:34])
	`LDBX,`LDBUX:	fnSelect = 16'h0001;
	`LDWX,`LDWUX:	fnSelect = 16'h0003;
	`LDTX,`LDTUX:	fnSelect = 16'h000F;
	`LDOX,`LDOUX:	fnSelect = 16'h00FF;
	`LDHX,`LDHRX:	fnSelect = 16'hFFFF;
	`LDFSX:				fnSelect = 16'h000F;
	`LDFDX:				fnSelect = 16'h00FF;
	`LDFQX:				fnSelect = 16'hFFFF;
	default:	fnSelect = 16'h0000;
	endcase
`MSX:
	case(ins[39:34])
	`STBX:	fnSelect = 16'h0001;
	`STWX:	fnSelect = 16'h0003;
	`STTX:	fnSelect = 16'h000F;
	`STOX:	fnSelect = 16'h00FF;
	`STHX:	fnSelect = 16'hFFFF;	
	`STFSX:	fnSelect = 16'h000F;
	`STFDX:	fnSelect = 16'h00FF;
	`STFQX:	fnSelect = 16'hFFFF;
	default:	fnSelect = 16'h0000;
	endcase
default:	fnSelect = 16'h0000;
endcase
endfunction

reg [2:0] Sc;
reg [31:0] sel;
reg [31:0] ea;

reg [255:0] wdat;
reg [127:0] dil;
wire [127:0] dati = dat_i >> {adr_o[3:0],3'b0};

wire mulss = opcode==`MULI || (opcode==`R3 && funct==`MUL);
wire [255:0] mulo;
mult128x128 umul1 (.clk(clk_i), .ce(1'b1), .ss(mulss), .su(1'b0), .a(a), .b(b), .p(mulo));

always @(posedge clk_i)
if (rst_i) begin
	mtick <= 64'd0;
	MachineMode <= 1'b1;
	wrrf <= 1'b0;
	ip <= RSTIP;
	mtvec <= 32'hFFFC0000;
	illegal_insn <= 1'b0;
	state <= IDLE;
end
else begin
mtick <= mtick + 2'd1;
wrrf <= 1'b0;
case(state)

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
IFETCH:
	begin
		nmi <= nmi_i;
		if (nmi_i & !nmi) begin
			illegal_insn <= 1'b0;
			MachineMode <= 1'b1;
			mcause <= 32'h8000000F;
			meip <= iip;
			ip <= mtvec + 9'h1FF;	// 65 * ol
			mstatus[11:0] <= {mstatus[8:0],3'b110};
		end
		else if (irq_i & mstatus[0]) begin
			illegal_insn <= 1'b0;
			MachineMode <= 1'b1;
			mcause <= 32'h80000003;
			meip <= iip;
			ip <= mtvec + {mstatus[2:1],4'd0,mstatus[2:1]};	// 65 * ol
			mstatus[11:0] <= {mstatus[8:0],3'b110};
		end
		else if (illegal_insn) begin
			illegal_insn <= 1'b0;
			MachineMode <= 1'b1;
			mcause <= 32'h2;
			meip <= iip;
			ip <= mtvec + {mstatus[2:1],4'd0,mstatus[2:1]};	// 65 * ol
			mstatus[11:0] <= {mstatus[8:0],3'b110};
		end
		else begin
			illegal_insn <= 1'b1;
			vpa_o <= HIGH;
			cyc_o <= HIGH;
			stb_o <= HIGH;
			sel_o <= 16'h1F << ip[3:0];
			sel <= 32'h1F << ip[3:0];
			adr_o <= ip;
			ip <= ip + 4'd5;
			iip <= ip;
			goto (IFETCH2);
		end
	end
IFETCH2:
	if (ack_i) begin
		stb_o <= LOW;
		ir <= dati;
		if (|sel[31:16]) begin
			goto(IFETCH3);
		end
		else begin
			vpa_o <= LOW;
			cyc_o <= LOW;
			sel_o <= 16'h0;
			goto(DECODE);
		end
	end
IFETCH3:
	begin
		stb_o <= HIGH;
		sel_o <= sel[31:16];
		adr_o <= {adr_o[31:4]+2'd1,4'h0};
		goto (IFETCH4);
	end
IFETCH4:
	if (ack_i) begin
		vpa_o <= LOW;
		cyc_o <= LOW;
		stb_o <= LOW;
		sel_o <= 16'h0;
		case(sel[31:16])
		16'h0001:	ir[39:32] <= dat_i[7:0];
		16'h0003:	ir[39:24] <= dat_i[15:0];
		16'h0007: ir[39:16] <= dat_i[23:0];
		16'h000F: ir[39:8] <= dat_i[31:0];
		default:	ir <= `FLT_IFETCH;
		endcase
		goto (DECODE);
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
DECODE:
	begin
		goto (REGFETCH);
		opcode <= ir[6:0];
		funct <= ir[39:34];
		case(ir[6:0])
		`STB,`STW,`STT,`STO,`STH,`STHC,`MSX,
		`STFS,`STFD,`STFQ:
			Rd <= 7'd0;
		`Bcc,`BBS,`BEQI,`BNEI,`BRG,`NOP,`BMISC1:
			Rd <= 7'd0;
		`CALL:
			Rd <= {MachineMode,6'd61};
		`BMISC2:
			case(ir[39:36])
			`SEI:	Rd <= {MachineMode,ir[12:7]};
			default:	Rd <= 7'd0;
			endcase
		`LILD,`LIAS1,`LIAS2,`LIAS3:
			Rd <= {MachineMode,ir[7] ? 6'd54 : 6'd53};
		default:
			Rd <= {MachineMode,ir[12:7]};
		endcase
		case(ir[6:0])
		`LILD,`LIAS1,`LIAS2,`LIAS3:
			Rs1 <= {MachineMode,ir[7] ? 6'd54 : 6'd53};
		default:
			Rs1 <= {MachineMode,ir[18:13]};
		endcase
		Rs2 <= {MachineMode,ir[24:19]};
		Rs3 <= {MachineMode,ir[30:25]};
		case(ir[6:0])
		`MLX:	imm <= {{122{ir[24]}},ir[24:29]};
		`MSX:	imm <= {{122[ir[5]}},ir[5:0]};
		`CHKI,
		`STB,`STW,`STT,`STO,`STC,`STCH,
		`STFS,`STFD,`STFQ:
			imm <= {{107{ir[39]}},ir[39:25],ir[5:0]};
		`LILD:	imm <= {{96{ir[39]}},ir[39],ir[18:8],ir[38:19]};
		`LIAS1:	imm <= {{64{ir[39]}},ir[39],ir[18:8],ir[38:19],32'h0};
		`LIAS2:	imm <= {{32{ir[39]}},ir[39],ir[18:8],ir[38:19],64'h0};
		`LIAS3:	imm <= {ir[39],ir[18:8],ir[38:19],96'h0};
		`BEQI,`BNEI:	imm <= {{119{ir[24]}},ir[24:19],ir[9:7]};
		`RET:		imm <= {109'd0,ir[39:25],4'h0};
		`CSR:		imm <= {ir[34:31],ir[18:13]};
		default:	imm <= {{107{ir[39]}},ir[39:19]};
		endcase
		Sc <= ir[33:31];
		cond3 <= ir[8:7];
		btgt <= {{17{ir[39]}},ir[39:25]};
		bitno <= {ir[24:19],ir[9]};
		csrno <= ir[30:19];
		csrop <= ir[39:38];
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
REGFETCH:
	begin
		goto (EXECUTE);
		case(opcode)
		`CSR:
			casez(csrop)
			3'b1??:		a <= imm;
			default:	a <= (Rs1[5:0]==6'd0) ? 128'd0 : rfoa;
			endcase
		default:
			a <= (Rs1[5:0]==6'd0) ? 128'd0 : rfoa;
		endcase
		case(opcode)
		`MULI,`MULUI:	b <= imm;
		default:
			b <= (Rs2[5:0]==6'd0) ? 128'd0 : rfob;
		endcase
		c <= (Rs3[5:0]==6'd0) ? 128'd0 : rfoc;
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
EXECUTE:
	begin
		goto (IFETCH);
		case(opcode)
		`LDB,`LDBU,`LDW,`LDWU,`LDT,`LDTU,`LDO,`LDOU,`LDH,`LDHR,
		`LDFS,`LDFD,`LDFQ:
			begin
				ea <= a + imm;
				illegal_insn <= 1'b0;
				goto (LOAD);
			end
		`MLX:
			begin
				ea <= a + (c << Sc) + imm;
				illegal_insn <= 1'b0;
				goto (LOAD);
			end
		`STB,`STW,`STT,`STO,`STH,`STHC,
		`STFS,`STFD,`STFQ:
			begin
				ea <= a + imm;
				illegal_insn <= 1'b0;
				goto (STORE);
			end
		`MSX:
			begin
				ea <= a + (c << Sc) + imm;
				illegal_insn <= 1'b0;
				goto (STORE);
			end
		`LILD:	begin res <= imm; wrrf <= 1'b1; illegal_insn <= 1'b0;end
		`LIAS1,`LIAS2,`LIAS3:
			begin res <= a + imm; wrrf <= 1'b1; illegal_insn <= 1'b0;end
		`MUL:		begin illegal_insn <= 1'b0; acnt <= 8'd20; goto (MULDIV1); end
		`MULU:	begin illegal_insn <= 1'b0; acnt <= 8'd20; goto (MULDIV1); end
		`DIV:		begin illegal_insn <= 1'b0; goto (DIV1); end
		`DIVU:	begin illegal_insn <= 1'b0; goto (DIVU1); end
		`ADD:		begin res <= a + imm; wrrf <= 1'b1; illegal_insn <= 1'b0; resp <= ap; end
		`LEA:		begin res <= a + imm; wrrf <= 1'b1; illegal_insn <= 1'b0; resp <= 1'b1; end
		`MOD:		begin illegal_insn <= 1'b0; goto (MOD); end
		`MODU:	begin illegal_insn <= 1'b0; goto (MODU); end
		`AND:		begin res <= a & imm; wrrf <= 1'b1; illegal_insn <= 1'b0; resp <= ap; end
		`OR:		begin res <= a | imm; wrrf <= 1'b1; illegal_insn <= 1'b0; resp <= ap; end
		`XOR:		begin res <= a ^ imm; wrrf <= 1'b1; illegal_insn <= 1'b0; resp <= ap; end
		`DIF:		begin res <= $signed(a) > $signed(imm) ? a - imm : imm - a; illegal_insn <= 1'b0; resp <= 1'b0; end
		`SLT:		begin res <= $signed(a) < $signed(imm); illegal_insn <= 1'b0; resp <= 1'b0; end
		`SLE:		begin res <= $signed(a) <= $signed(imm); illegal_insn <= 1'b0; resp <= 1'b0; end
		`SGT:		begin res <= $signed(a) > $signed(imm); illegal_insn <= 1'b0; resp <= 1'b0; end
		`SGE:		begin res <= $signed(a) >= $signed(imm); illegal_insn <= 1'b0; resp <= 1'b0; end
		`SLTU:	begin res <= a < imm; illegal_insn <= 1'b0; resp <= 1'b0; end
		`SLEU:	begin res <= a <= imm; illegal_insn <= 1'b0; resp <= 1'b0; end
		`SGTU:	begin res <= a > imm; illegal_insn <= 1'b0; resp <= 1'b0; end
		`SGEU:	begin res <= a >= imm; illegal_insn <= 1'b0; resp <= 1'b0; end
		`SEQ:		begin res <= a == imm; illegal_insn <= 1'b0; resp <= 1'b0; end
		`SNE:		begin res <= a != imm; illegal_insn <= 1'b0; resp <= 1'b0; end
		`CMP:		begin res <= $signed(a) < $signed(imm) ? -128'd1 : a==imm ? 128'd0 : 128'd1;
		`CMPU:	begin res <= a < imm ? -128'd1 : a==imm ? 128'd0 : 128'd1;

		`CSR:
			begin
				casez(csrno)
				12'h001:  begin res <= hartid_i; illegal_insn <= 1'b0; wrrf <= 1'b1; end
				12'h002:	begin res <= mtick; illegal_insn <= 1'b0; wrrf <= 1'b1; end
				12'h006:	begin res <= mcause; illegal_insn <= 1'b0; wrrf <= 1'b1; end
				12'h009:	begin res <= mscratch; illegal_insn <= 1'b0; wrrf <= 1'b1; end
				12'b0000_0011_1???:	begin res <= cmdparm[csrno[2:0]]; illegal_insn <= 1'b0; wrrf <= 1'b1; end
				12'h044:	begin res <= mstatus; illegal_insn <= 1'b0; wrrf <= 1'b1; end
				endcase
				case(csrop[1:0])
				2'd0:	;
				2'd1:
					casez(csrno)
					12'h006:	mcause <= a;
					12'h009:	mscratch <= a;
					12'b0000_0011_1???:	cmdparm[csrno[2:0]] <= a;
					12'h044:	mstatus <= a;
					endcase
				2'd2:	
					casez(csrno)
					12'h044:	mstatus <= mstatus | a;
					default:	;
					endcase
				2'd3:
					casez(csrno)
					12'h044:	mstatus <= mstatus & ~a;
					default:	;
					endcase
				endcase
			end

		`Bcc:
			begin
				case(cond3)
				`BEQ:	begin if (a==b) begin ip <= iip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
				`BNE:	begin if (a!=b) begin ip <= iip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
				`BLT:	begin if ($signed(a) < $signed(b)) begin ip <= iip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
				`BGE:	begin if ($signed(a) >= $signed(b)) begin ip <= iip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
				`BLTU:	begin if (a < b) begin ip <= iip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
				`BGEU:	begin if (a >= b) begin ip <= iip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
				endcase
			end
		`BBc:
			case(cond2)
			2'd0:	begin if ( a[bitno]) begin ip <= iip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
			2'd1:	begin if (!a[bitno]) begin ip <= iip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
			default:	;
			endcase
		`BEQI:	begin if (a==imm) begin ip <= iip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
		`BNEI:	begin if (a!=imm) begin ip <= iip[11:0] <= btgt[11:0]; ip[31:12] <= iip[31:12]+btgt[31:12]; end illegal_insn <= 1'b0; end
		`JAL:		begin ip <= a + imm; res <= ip; illegal_insn <= 1'b0; end
		`JMP:		begin ip <= ir[38:7]; illegal_insn <= 1'b0; end
		`CALL:	begin ip <= ir[38:7]; illegal_insn <= 1'b0; res <= ip; end
		`RET:		begin res <= a + imm; wrrf <= 1'b1; illegal_insn <= 1'b0; resp <= 1'b1; end
		endcase
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
MULDIV1:
	begin
		acnt <= acnt - 2'd1;
		if (acnt==8'd0) begin
			case(opcode)
			`R3:
				case(funct)
				`MUL,`MULU:		res <= mulo[127:0];
				`MULH,`MULUH:	res <= mulo[255:128];
				default:			res <= 128'd0;
				endcase
			default:	res <= mulo[127:0];
			endcase
		end
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
LOAD:
	begin
		cyc_o <= HIGH;
		stb_o <= HIGH;
		sel_o <= fnSelect(ir) << ea[3:0];
		sel <= fnSelect(ir) << ea[3:0];
		adr_o <= ea;
		goto (LOAD1);
	end
LOAD1:
	if (ack_i) begin
		stb_o <= LOW;
		dil[127:0] <= dati;
		if (|sel[31:16]) begin
			goto (LOAD2);
		end
		else begin
			cyc_o <= LOW;
			sel_o <= 16'h0;
			goto (LOAD4);
		end
	end
// Run a second bus cycle for data that crosses a 128-bit boundary.
LOAD2:
	if (~ack_i) begin
		stb_o <= HIGH;
		sel_o <= sel[31:16];
		adr_o <= {adr_o[31:4]+2'd1,4'h0};
		goto (LOAD3);
	end
LOAD3:
	if (ack_i) begin
		cyc_o <= LOW;
		stb_o <= LOW:
		sel_o <= 16'h0;
		dil[255:128] <= dat_i;
		goto (LOAD4);
	end
LOAD4:
	begin
		dil <= dil >> {ea[3:0],3'b0};
		goto (LOAD5);
	end
LOAD5:
	begin
		goto (IFETCH);
		case(opcode)
		`LDB:		begin res <= {{120{dil[7]}},dil[7:0]}; wrrf <= 1'b1; end
		`LDBU:	begin res <= {120'd0,dil[7:0]}; wrrf <= 1'b1; end
		`LDW:		begin res <= {{112{dil[15]}},dil[15:0]}; wrrf <= 1'b1; end
		`LDWU:	begin res <= {112'd0,dil[15:0]}; wrrf <= 1'b1; end
		`LDT:		begin res <= {{96{dil[31]}},dil[31:0]}; wrrf <= 1'b1; end
		`LDTU:	begin res <= {96'd0,dil[31:0]}; wrrf <= 1'b1; end
		`LDO:		begin res <= {{64{dil[63]}},dil[63:0]}; wrrf <= 1'b1; end
		`LDOU:	begin res <= {64'd0,dil[63:0]}; wrrf <= 1'b1; end
		`LDH:		begin res <= dil[127:0]; wrrf <= 1'b1; end
		`LDHR:	begin res <= dil[127:0]; wrrf <= 1'b1; end
		`LDFS:	begin fa <= dil[31:0]; fpfunct <= `FCVTSQ; fpopcode <= `FLT1; state <= LOAD6; end
		`LDFD:	begin fa <= dil[63:0]; fpfunct <= `FCVTDQ; fpopcode <= `FLT1; state <= LOAD6; end
		`LDFQ:	begin res <= dil[127:0]; wrrf <= 1'b1; end
		`MLX:
			case(ir[39:35])
			`LDBX:	begin res <= {{120{dil[7]}},dil[7:0]}; wrrf <= 1'b1; end
			`LDBUX:	begin res <= {120'd0,dil[7:0]}; wrrf <= 1'b1; end
			`LDWX:	begin res <= {{112{dil[15]}},dil[15:0]}; wrrf <= 1'b1; end
			`LDWUX:	begin res <= {112'd0,dil[15:0]}; wrrf <= 1'b1; end
			`LDTX:	begin res <= {{96{dil[31]}},dil[31:0]}; wrrf <= 1'b1; end
			`LDTUX:	begin res <= {96'd0,dil[31:0]}; wrrf <= 1'b1; end
			`LDOX:	begin res <= {{64{dil[63]}},dil[63:0]}; wrrf <= 1'b1; end
			`LDOUX:	begin res <= {64'd0,dil[63:0]}; wrrf <= 1'b1; end
			`LDHX:	begin res <= dil[127:0]; wrrf <= 1'b1; end
			`LDHRX:	begin res <= dil[127:0]; wrrf <= 1'b1; end
			`LDFSX:	begin fa <= dil[31:0]; fpfunct <= `FCVTSQ; fpopcode <= `FLT1; state <= LOAD6; end
			`LDFDX:	begin fa <= dil[63:0]; fpfunct <= `FCVTDQ; fpopcode <= `FLT1; state <= LOAD6; end
			`LDFQX:	begin res <= dil[127:0]; wrrf <= 1'b1; end
			endcase
		default:	;
		endcase
	end
LOAD6:
	if (fpdone) begin
		wrrf <= 1'b1;
		res <= fpres;
		goto (IFETCH);
	end

STORE:
	begin
		sel <= fnSelect(ir) << ea[3:0];
		wdat <= b << {ea[3:0],3'b0};
		case(opcode)
		`STFS:
			begin
				fa <= b;
				fpfunct <= `FCVTQS;
				fpopcode <= `FLT1; 
				goto (STORE1);
			end
		`STFD:
			begin
				fa <= b;
				fpfunct <= `FCVTQD;
				fpopcode <= `FLT1; 
				goto (STORE1);
			end
		`MSX:
			case(ir[39:35])
			`STFSX:
				begin
					fa <= b;
					fpfunct <= `FCVTQS;
					fpopcode <= `FLT1; 
					goto (STORE1);
				end
			`STFDX:
				begin
					fa <= b;
					fpfunct <= `FCVTQD;
					fpopcode <= `FLT1; 
					goto (STORE1);
				end
			endcase
		default:	goto (STORE3);
		endcase
	end
STORE1:
	if (fpdone) begin
		b <= fpres;
		goto (STORE2);
	end
STORE2:
	begin
		wdat <= b << {ea[3:0],3'b0};
		goto (STORE3);
	end
STORE3:
	begin
		cyc_o <= HIGH;
		stb_o <= HIGH;
		we_o <= HIGH;
		sel_o <= sel[15:0];
		adr_o <= ea;
		dat_o <= wdat[127:0];
		goto (STORE4);
	end
STORE4:
	if (ack_i) begin
		stb_o <= LOW;
		if (|sel[31:16]) begin
			goto (STORE5);
		end
		else begin
			cyc_o <= LOW;
			sel_o <= 16'h0;
			we_o <= LOW;
			goto (IFETCH);
		end
	end
// Run a second bus cycle for data that crosses a 128-bit boundary.
STORE5:
	if (~ack_i) begin
		stb_o <= HIGH;
		sel_o <= sel[31:16];
		adr_o <= {adr_o[31:4]+2'd1,4'h0};
		dat_o <= wdat[255:128];
		goto (STORE6);
	end
STORE6:
	if (ack_i) begin
		cyc_o <= LOW;
		stb_o <= LOW:
		we_o <= LOW;
		sel_o <= 16'h0;
		goto (IFETCH);
	end

default:	goto(IDLE);
endcase
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Support tasks
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

task goto;
input [7:0] nst;
begin
state <= nst;
end
endtask

endmodule
