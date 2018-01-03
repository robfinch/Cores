// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// FT64seq.v
// - FT64 processing core - sequential version
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
`define BRK		6'h00
`define R2		6'h02
`define R1			6'h01
`define ABS				5'h04
`define NOT             5'h05
`define SUB			6'h05
`define Scc		    6'h06
`define Sccu	    6'h07
`define SHIFTW		6'h0F
`define SHIFTB		6'h1F
`define LEAX		6'h18
`define PUSH		6'h19
`define POP			6'h1A
`define UNLINK		6'h1B
`define SYNC		6'h22
`define XCHG		6'h2E
`define SHIFTC		6'h2F
`define SEI			6'h30
`define RTI			6'h32
`define DIVMODU		6'h3C
`define DIVMODSU	6'h3D
`define DIVMOD		6'h3E
`define SHIFTH		6'h3F
`define BccR	6'h03
`define ADD		6'h04
`define CMP		6'h06
`define CMPU	6'h07
`define AND		6'h08
`define OR		6'h09
`define XOR		6'h0A
`define TGT		6'h0C
`define REX		6'h0D
`define CSR		6'h0E
`define LH		6'h10
`define LHU		6'h11
`define LW		6'h12
`define LB		6'h13
`define SH		6'h14
`define SB		6'h15
`define SW		6'h16
`define JAL		6'h18
`define CALL	6'h19
`define QOPI	6'h1A
`define QOR			3'd0
`define QADD		3'd1
`define QAND		3'd2
`define QXOR		3'd3
`define SccI	6'h1B
`define NOP		6'h1C
`define LC		6'h20
`define LCU		6'h21
`define BITFLD	6'h22
`define LBU		6'h23
`define SC		6'h24
`define BBc0	6'h26
`define BBc1	6'h27
`define JMP		6'h28
`define RET		6'h29
`define LINK	6'h2A
`define CALLR	6'h2B
`define MODUI	6'h2C
`define MODSUI	6'h2D
`define MODI	6'h2E
`define Bcc0	6'h30
`define Bcc1	6'h31
`define BEQ0	6'h32
`define BEQ1	6'h33
`define MULU	6'h38
`define MULSU	6'h39
`define MUL		6'h3A
`define DIVUI	6'h3C
`define DIVSUI	6'h3D
`define DIVI	6'h3E

`define SHL		4'h0
`define SHR		4'h1
`define ASL		4'h2
`define ASR		4'h3
`define ROL		4'h4
`define ROR		4'h5
`define SHLI	4'h8
`define SHRI	4'h9
`define ASLI	4'hA
`define ASRI	4'hB
`define ROLI	4'hC
`define RORI	4'hD

`define BEQ		4'h0
`define BNE		4'h1
`define BLT		4'h2
`define BGE		4'h3
`define BLTU	4'h4
`define BGEU	4'h5
`define FBEQ	4'h8
`define FBNE	4'h9
`define FBLT	4'hA
`define FBGE	4'hB

`define HARTID	11'h001
`define TICK	11'h002
`define CAUSE	11'h006
`define SCRATCH	11'h009
`define SEMA	11'h00C
`define TVEC	11'b000_0011_0???
`define TIME	11'h7E0
`define INSTRET	11'h7E1

module FT64seq(hartid_i, rst_i, clk_i, tm_clk_i, irq_i, cause_i,
	cyc_o, stb_o, ack_i, sel_o, we_o, adr_o, dat_i, dat_o,
	state);
input [63:0] hartid_i;
input rst_i;
input clk_i;
input tm_clk_i;				// 100 MHz
input [2:0] irq_i;
input [8:0] cause_i;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg [15:0] sel_o;
output reg we_o;
output reg [31:0] adr_o;
input [127:0] dat_i;
output reg [127:0] dat_o;
output reg [7:0] state;

// Wall clock timing parameter. Number of tm_clk_i cycles for 1s interval
parameter WCTIME1S = 32'd100000000;

parameter RST_ADDR = 32'hFFFC0100;
parameter RESET = 8'd0;
parameter IFETCH = 8'd1;
parameter IFETCH_ACK = 8'd2;
parameter IFETCH_NACK = 8'd3;
parameter REGFETCH = 8'd4;
parameter DECODE = 8'd5;
parameter EXECUTE = 8'd6;
parameter MEMORY = 8'd7;
parameter MEMORY_NACK = 8'd8;
parameter MULDIV2 = 8'd9;

parameter word = 2'd3;
parameter half = 2'd2;
parameter char = 2'd1;
parameter byt_ = 2'd0;

integer n, m;
reg [63:0] sema;
reg [43:0] brkstack [0:4];
reg [31:0] tvec [0:7];
reg [2:0] ol;
reg [2:0] im;
reg [7:0] pl;
reg [31:0] pc,opc;
reg [31:0] ir;
wire [5:0] opcode = ir[5:0];
wire [5:0] funct = ir[31:26];
wire [4:0] func5 = ir[25:21];
wire [3:0] func4 = ir[25:22];
reg [1:0] opsize;
reg [31:0] ibuf_adr [0:7];
reg [31:0] ibuf [0:7];
reg [2:0] ibuf_cnt;
reg rfwr;
reg [4:0] Ra, Rb, Rc, Rt;
reg [63:0] regfile [0:31];
wire [63:0] rfoa = regfile[Ra];
wire [63:0] rfob = regfile[Rb];
wire [63:0] rfoc = regfile[Rc];
reg [63:0] a,b,c,res;
reg [31:0] rasstack [0:511];
reg [8:0] rassp;

// CSR's
reg [8:0] cause;
reg [63:0] scratch;
reg [63:0] tick;
reg [63:0] wctime, times;
reg [63:0] instret;

wire [127:0] produ;// = a * b;
wire [127:0] prods;// = $signed(a) * $signed(b);
wire [127:0] prodsu;// = $signed(a) * b;
wire [2:0] npl = ir[23:16] | a;
wire [63:0] sum = a + b;
wire [63:0] dif = a - b;
wire [31:0] eandx = a + (b << ir[22:21]);
wire [63:0] am8 = a - 32'd8;	// for link
wire [31:0] xIncea = ir[25] ? a + {{59{ir[25]}},ir[25:21]} : a;	// for POP / PUSH

function [23:0] regname;
input [4:0] regno;
case(regno)
5'd0:	regname = "r0";
5'd1:	regname = "r1";
5'd2:	regname = "r2";
5'd3:	regname = "r3";
5'd4:	regname = "r4";
5'd5:	regname = "r5";
5'd6:	regname = "r6";
5'd7:	regname = "r7";
5'd8:	regname = "r8";
5'd9:	regname = "r9";
5'd10:	regname = "r10";
5'd11:	regname = "r11";
5'd12:	regname = "r12";
5'd13:	regname = "r13";
5'd14:	regname = "r14";
5'd15:	regname = "r15";
5'd16:	regname = "r16";
5'd17:	regname = "r17";
5'd18:	regname = "r18";
5'd19:	regname = "r19";
5'd20:	regname = "r20";
5'd21:	regname = "r21";
5'd22:	regname = "r22";
5'd23:	regname = "r23";
5'd24:	regname = "r24";
5'd25:	regname = "r25";
5'd26:	regname = "r26";
5'd27:	regname = "r27";
5'd28:	regname = "r28";
5'd29:	regname = "r29";
5'd30:	regname = "bp";
5'd31:	regname = "sp";
endcase
endfunction

always @*
begin
m <= 4'hF;
for (n = 0; n < 8; n = n + 1)
	if (pc==ibuf_adr[n])
		m <= n;
end

reg [127:0] din;	// input data latch
reg [3:0] dshift;
wire [7:0] byte_in = din >> {dshift[3:0],3'b0};
wire [15:0] char_in = din >> {dshift[3:1],4'h0};
wire [31:0] half_in = din >> {dshift[3:2],5'h0};
wire [63:0] word_in = din >> {dshift[3],6'h0};

wire [127:0] shlo = {64'd0,a} << b[5:0];
wire [127:0] shro = {a,64'd0} >> b[5:0];
wire [31:0]  asro32 = a[31] ? ~(32'hFFFFFFFFFFFFFFFF >> b[5:0]) | shro[95:64] : shro[95:64];

wire [63:0] bfo;
wire [63:0] shiftwo;
wire [31:0] shiftho;

FT64_shift uws1
(
	.instr(ir),
	.a(a),
	.b(b),
	.res(shiftwo),
	.ov()
);

FT64_shifth uhws1
(
	.instr(ir),
	.a(a[31:0]),
	.b(b[31:0]),
	.res(shiftho),
	.ov()
);

FT64_bitfield ubf1
(
	.inst(ir),
	.a(a),
	.b(b),
	.o(bfo),
	.masko()
);

reg div_ld, mul_ld;
reg [4:0] mul_cnt;
wire div_done;
wire [63:0] div_qo, div_ro;
wire div_sgn = opcode==`DIVI || opcode==`MODI || (opcode==`R2 && (funct==`DIVMOD));
wire div_sgnus = opcode==`DIVSUI || opcode==`MODSUI || (opcode==`R2 && (funct==`DIVMODSU));

FT64_divider udiv1
(
	.rst(rst_i),
	.clk(clk_i),
	.ld(div_ld),
	.abort(),
	.sgn(div_sgn),
	.sgnus(div_sgnus),
	.a(a),
	.b(b),
	.qo(div_qo),
	.ro(div_ro),
	.dvByZr(),
	.done(div_done),
	.idle()
);

FT64_mul umul1
(
	.CLK(clk_i),
	.A(a),
	.B(b),
	.P(prods)
);

FT64_mulu umul2
(
	.CLK(clk_i),
	.A(a),
	.B(b),
	.P(produ)
);

FT64_mulsu umul3
(
	.CLK(clk_i),
	.A(a),
	.B(b),
	.P(prodsu)
);

wire takb;

FT64_EvalBranch ube1
(
	.instr(ir),
	.a(a),
	.b(b),
	.takb(takb)
);

always @(posedge clk_i)
if (rst_i)
	mul_cnt <= 5'd19;
else begin
	if (mul_ld)
		mul_cnt <= 5'd1;
	else if (mul_cnt < 5'd19)
		mul_cnt <= mul_cnt + 5'd1;
end
wire mul_done = mul_cnt==5'd19;

always @(posedge clk_i)
	if (ack_i)
		din <= dat_i;
always @(posedge clk_i)
	if (ack_i)
		dshift <= adr_o[3:0];

always @(posedge clk_i)
	if (rst_i)
		tick <= 63'd0;
	else
		tick <= tick + 64'd1;

always @(posedge clk_i)
if (rst_i)
	state <= RESET;
else begin

// Cause these signals to pulse for just one clock cycle. They are set
// active below.
div_ld <= `FALSE;
mul_ld <= `FALSE;
rfwr <= `FALSE;

case(state)

// RESET:
// Reset only the signals critical to the proper operation of the core.
// This includes setting the PC address and deactivating the bus
// controls.
RESET:
	begin
	im <= 3'd7;
	ol <= 3'd0;
	pl <= 8'h00;
	pc <= RST_ADDR;
	cyc_o <= `LOW;
	stb_o <= `LOW;
	we_o <= `LOW;
	sel_o <= 16'h0000;
	adr_o <= 32'hFFFFFFFF;
	instret <= 64'd0;
	goto(IFETCH);
	end

// IFETCH:
// Fetch instructions from memory located by the program counter. A fully
// associative buffer (cache) of the most recently used eight instructions
// is maintained. A memory access won't be required if the instruction can
// be found in the buffer.
// Also update the register file for the previous instruction. Rather than
// have another state in the state machine to perform the register update
// it is done here to improve performance.
IFETCH:
	begin
		$display("%d", $time);
		opc <= pc;
		instret <= instret + 64'd1;
		if (irq_i > im) begin
			ir <= {13'd0,irq_i,1'b0,cause_i,`BRK};
			goto(DECODE);
		end
		else if (m[3]) begin
			cyc_o <= `HIGH;
			stb_o <= `HIGH;
			sel_o <= 16'hF << {pc[3:2],2'b0};
			adr_o <= pc;
			goto(IFETCH_ACK);
		end
		else begin
			ir <= ibuf[m];
			pc <= pc + 32'd4;
			$display("ir: %h (from ibuf)", ibuf[m]);
			goto(DECODE);
		end
	end
IFETCH_ACK:
	if (ack_i) begin
		cyc_o <= `LOW;
		stb_o <= `LOW;
		sel_o <= 16'h0000;
		//adr_o <= 32'hFFFFFFFF;
		goto(IFETCH_NACK);
	end
IFETCH_NACK:
	if (~ack_i) begin
		ir <= half_in;
		ibuf[ibuf_cnt] <= half_in;
		ibuf_adr[ibuf_cnt] <= pc;
		ibuf_cnt <= ibuf_cnt + 3'd1;
		pc <= pc + 32'd4;
		$display("ir: %h", half_in);
		goto(DECODE);
	end

// DECODE:
// Setup for register file access. Ra, Rb, Rc are almost always decoded from
// the same spot in the instruction register to keep the decoding simple and
// access to the register file fast. For the call instruction Ra is forced to
// r31 since it doesn't come from the ir. Rt tends to float around depending on
// the instruction.
// Several instructions which do not have register operands (JMP,NOP,RTI, and
// BRK) are executed directly in the decode stage to improve performance.
DECODE:
	begin
		goto(REGFETCH);
		Ra <= ir[10:6];
		Rb <= ir[15:11];
		Rc <= ir[20:16];
		Rt <= 5'd0;
		opsize <= word;
		case(opcode)
		`BRK:
			begin
				for (n = 0; n < 4; n = n + 1)
					brkstack[n+1] <= brkstack[n];
				brkstack[0] <= {pc[31:2],pl,ol,im};
				if (ir[15]==1'b0)
					im <= ir[18:16];
				ol <= 3'd0;
				pl <= 8'h00;
				pc <= tvec[0];
				goto(IFETCH);
			end
		`R2:
			begin
				Rt <= ir[20:16];
				case(funct)
				`RTI:
					begin
						pc <= {brkstack[0][43:14],2'b00};
						pl <= brkstack[0][13:6];
						ol <= brkstack[0][5:3];
						im <= brkstack[0][2:0];
						for (n = 0; n < 4; n = n + 1)
							brkstack[n] <= brkstack[n+1];
						sema[0] <= 1'b0;
						sema[{ir[21],ir[15:11]}] <= 1'b0;
						goto(IFETCH);
					end
				`R1:
					case(func5)
					`ABS,`NOT:	Rt <= ir[15:11];
					endcase
				`ADD,`SUB:
				    opsize <= ir[22:21];
				// The SYNC instruction is treated as a NOP since this machine
				// is strictly in order.
				`SYNC:	goto(IFETCH);
				`SB,`SC,`SH,`SW:	Rt <= 5'd0;
				`PUSH:
					Rt <= ir[20:16];
				`POP:
				    Rt <= ir[15:11];
				endcase
			end
		`TGT:	goto(IFETCH);
		`NOP:	goto(IFETCH);
		`JMP:
			begin
			pc <= {pc[31:28],ir[31:6],2'b00};
			goto(IFETCH);
			end
		`CALL:
			begin
			Ra <= 5'd31;
			Rt <= 5'd31;
			end
		`CALLR:
			Rt <= ir[10:6];
		`JAL,`RET:
			Rt <= ir[15:11];
		`LINK:
            Rt <= ir[15:11];
		`CSR:
			Rt <= ir[15:11];
		`QOPI:
			begin
			Ra <= ir[15:11];
			Rt <= ir[15:11];
			end
		`BITFLD:
			Rt <= ir[20:16];
		`MULU:	Rt <= ir[15:11];
		`ADD,`CMP,`CMPU,`AND,`OR,`XOR,
		`MUL,`MULSU,
		`DIVI,`DIVUI,`DIVSUI,`MODI,`MODUI,`MODSUI,
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW:
			Rt <= ir[15:11];
		`SB,`SC,`SH,`SW:
			Rt <= 5'd0;
		default: ;
		endcase
	end

// REGFETCH:
// Set operands from the register file, or the instruction register for
// immediate operands.
REGFETCH:
	begin
		goto(EXECUTE);
		a <= rfoa;
		b <= rfob;
		case(opcode)
		`R2:
			case(funct)
			`SHIFTW,`SHIFTB,`SHIFTC,`SHIFTH:
				begin
				case(func4)
				`SHLI,`SHRI,`ASLI,`ASRI,`ROLI,`RORI:
					b <= {ir[21],ir[15:11]};
				endcase
				end
			`OR,`XOR,`XCHG:
				c <= rfoc;
			`MUL,`MULU,`MULSU:
				mul_ld <= `TRUE;
			`DIVMOD,`DIVMODU,`DIVMODSU:
				div_ld <= `TRUE;
			`LB,`LBU,`LH,`LHU,`LC,`LCU,`LW,
			`SB,`SC,`SH,`SW:
				c <= rfoc;
    		`PUSH,`POP:
                c <= rfob;
			endcase
		`ADD,`CMP:
			b <= {{48{ir[31]}},ir[31:16]};
		`MUL:
			begin
			b <= {{48{ir[31]}},ir[31:16]};
			mul_ld <= `TRUE;
			end
		`DIVI,`MODI:
			begin
			b <= {{48{ir[31]}},ir[31:16]};
			div_ld <= `TRUE;
			end
		`SccI:
			begin
			case(ir[31:28])
			4'h2,4'h3,4'h4,4'h5,4'h6,4'h7:
				b <= {{52{ir[27]}},ir[27:16]};
			4'hC,4'hD,4'hE,4'hF:
				b <= {{52{1'b0}},ir[27:16]};
			endcase
			end
		`AND:
			begin
			b <= {{48{1'b0}},ir[31:16]};
			end
		`CMPU,`OR,`XOR:
			begin
			b <= {{48{1'b0}},ir[31:16]};
			end
		`MULU,`MULSU:
			begin
			b <= {{48{1'b0}},ir[31:16]};
			mul_ld <= `TRUE;
			end
		`DIVUI,`DIVSUI,`MODUI,`MODSUI:
			begin
			b <= {{48{1'b0}},ir[31:16]};
			div_ld <= `TRUE;
			end
		`QOPI:
			begin
				case(ir[10:8])
				3'd0,3'd3:	// OR, XOR
					case(ir[7:6])
					2'd0:	b <= {{48{1'b0}},ir[31:16]};
					2'd1:	b <= {{32{1'b0}},ir[31:16]} << 16;
					2'd2:	b <= {{16{1'b0}},ir[31:16]} << 32;
					2'd3:	b <= {ir[31:16]} << 48;
					endcase
				3'd1:	// ADD
					case(ir[7:6])
					2'd0:	b <= {{48{ir[31]}},ir[31:16]};
					2'd1:	b <= {{32{ir[31]}},ir[31:16]} << 16;
					2'd2:	b <= {{16{ir[31]}},ir[31:16]} << 32;
					2'd3:	b <= {ir[31:16]} << 48;
					endcase
				3'd2:	// AND
					case(ir[7:6])
					2'd0:	b <= {{48{1'b1}},ir[31:16]};
					2'd1:	b <= {{32{1'b1}},ir[31:16],16'hFFFF};
					2'd2:	b <= {{16{1'b1}},ir[31:16],32'hFFFFFFFF};
					2'd3:	b <= {ir[31:16],48'hFFFFFFFFFFFF};
					endcase
				default:	b <= 64'd0;
				endcase
			end
		`Bcc0,`Bcc1,`BccR,`BBc0,`BBc1:
			c <= rfoc;
		`BEQ0,`BEQ1:
			b <= {{55{ir[19]}},ir[19:11]};
		`JAL:
			b <= {{48{ir[31]}},ir[31:16]};
		`CALL:
			b <= 64'hFFFFFFFFFFFFFFF8;	// -8
		`RET:
			b <= {{48{ir[31]}},ir[31:16]};	// +8
		`LB,`LBU,`LH,`LHU,`LC,`LCU,`LW,
		`SB,`SC,`SH,`SW:
			begin
			b <= {{48{ir[31]}},ir[31:16]};
			c <= rfob;
			end
		endcase
	end

// EXECUTE:
// Execute the instruction. Compute results and begin any memory access.
EXECUTE:
	begin
		goto(IFETCH);
		case(opcode)
		`R2:
			case(funct)
			`R1:
				case(func5)
				`ABS:	begin res <= a[63] ? -a : a; rfwr <= `TRUE; end
				`NOT:   begin res <= a!=0 ? 64'd0 : 64'd1; rfwr <= `TRUE; end
				endcase
			`SEI:	im <= a[2:0] | ir[13:11];
			`UNLINK:
				begin
					res <= b + 32'd8;
					rfwr <= `TRUE;
					cyc_o <= `HIGH;
					stb_o <= `HIGH;
					sel_o <= 16'h0FF << {b[3],3'b0};
					adr_o <= b;
					goto(MEMORY);
					$display("%h: unlink", opc);
				end
			`SHIFTW:
			    begin
			    rfwr <= `TRUE;
			    res <= shiftwo;
                end
			`SHIFTH:
                begin
                rfwr <= `TRUE;
                case(func4)
                `SHL,`SHLI:    res <= {32'd0,shiftho};
                `SHR,`SHRI:    res <= {32'd0,shiftho};
                `ASL,`ASLI:    res <= {{32{shiftho[31]}},shiftho};
                `ASR,`ASRI:    res <= {{32{shiftho[31]}},shiftho};
                `ROL,`ROLI: begin
                            res[31:0] <= shiftho;
                            res[63:32] <= {32{shiftho[31]}};
                            end
                `ROR,`RORI: begin
                            res[31:0] <= shiftho;
                            res[63:32] <= {32{shiftho[31]}};
                            end
                endcase
                end
            `ADD:	begin
                    rfwr <= `TRUE;
                    case(opsize)
                    word:   res <= sum;
                    half:   res <= {{32{sum[31]}},sum[31:0]};
                    char:   res <= {{48{sum[15]}},sum[15:0]};
                    byt_:   res <= {{56{sum[7]}},sum[7:0]};
                    endcase
                    end
            `SUB:	begin
                    rfwr <= `TRUE;
                    case(opsize)
                    word:   res <= dif;
                    half:   res <= {{32{dif[31]}},dif[31:0]};
                    char:   res <= {{48{dif[15]}},dif[15:0]};
                    byt_:   res <= {{56{dif[7]}},dif[7:0]};
                    endcase
                    end
			`Scc:	begin
					rfwr <= `TRUE;
					case(ir[25:23])
					3'd0:	res <= $signed(a) < $signed(b) ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'h0 : 64'h1;
					3'd2:	res <= a==b;
					3'd3:	res <= a!=b;
					3'd4:	res <= $signed(a) < $signed(b);
					3'd5:	res <= $signed(a) >= $signed(b);
					3'd6:	res <= $signed(a) <= $signed(b);
					3'd7:	res <= $signed(a) > $signed(b);
					endcase
					end
			`Sccu:	begin
					rfwr <= `TRUE;
					case(ir[25:23])
					3'd0:	res <= a < b ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'h0 : 64'h1;
					3'd2:	res <= a==b;
					3'd3:	res <= a!=b;
					3'd4:	res <= a < b;
					3'd5:	res <= a >= b;
					3'd6:	res <= a <= b;
					3'd7:	res <= a > b;
					endcase
					end
			`MULU:	if (mul_done) begin res <= produ[63:0]; rfwr <= `TRUE; goto(MULDIV2); end else goto(EXECUTE);
			`MUL:	if (mul_done) begin res <= prods[63:0]; rfwr <= `TRUE; goto(MULDIV2); end else goto(EXECUTE);
			`MULSU:	if (mul_done) begin res <= prodsu[63:0]; rfwr <= `TRUE; goto(MULDIV2); end else goto(EXECUTE);
			// For divide stay in the EXECUTE state until the divide is done.
			`DIVMOD,`DIVMODU,`DIVMODSU:
					if (div_done) begin
						res <= div_qo;
						rfwr <= `TRUE;
						goto(MULDIV2);
					end
					else
						goto(EXECUTE);
			`AND:	begin res <= a & b; rfwr <= `TRUE; end
			`OR:	begin res <= a | b; rfwr <= `TRUE; end
			`XOR:	begin res <= a ^ b; rfwr <= `TRUE; end
			`XCHG:	begin res <= b; Rt <= ir[20:16]; rfwr <= `TRUE; goto(MULDIV2); end
			`LEAX:
				begin
					rfwr <= `TRUE;
					res <= eandx;
				end
			`LB,`LBU:
				begin
					cyc_o <= `HIGH;
					stb_o <= `HIGH;
					sel_o <= 16'h01 << eandx[3:0];
					adr_o <= eandx;
					goto(MEMORY);
				end
			`LC,`LCU:
				begin
					cyc_o <= `HIGH;
					stb_o <= `HIGH;
					sel_o <= 16'h03 << {eandx[3:1],1'b0};
					adr_o <= eandx;
					goto(MEMORY);
				end
			`LH,`LHU:
				begin
					cyc_o <= `HIGH;
					stb_o <= `HIGH;
					sel_o <= 16'h0F << {eandx[3:2],2'b0};
					adr_o <= eandx;
					goto(MEMORY);
				end
			`LW:
				begin
					cyc_o <= `HIGH;
					stb_o <= `HIGH;
					sel_o <= 16'hFF << {eandx[3],3'b0};
					adr_o <= eandx;
					goto(MEMORY);
				end
			`SB:
				begin
					cyc_o <= `HIGH;
					stb_o <= `HIGH;
					we_o <= `HIGH;
					sel_o <= 16'h01 << eandx[3:0];
					adr_o <= eandx;
					dat_o <= {16{c[7:0]}};
					goto(MEMORY);
				end
			`SC:
				begin
					cyc_o <= `HIGH;
					stb_o <= `HIGH;
					we_o <= `HIGH;
					sel_o <= 16'h03 << {eandx[3:1],1'b0};
					adr_o <= eandx;
					dat_o <= {8{c[15:0]}};
					goto(MEMORY);
				end
			`SH:
				begin
					cyc_o <= `HIGH;
					stb_o <= `HIGH;
					we_o <= `HIGH;
					sel_o <= 16'h0F << {eandx[3:2],2'b0};
					adr_o <= eandx;
					dat_o <= {4{c[31:0]}};
					goto(MEMORY);
				end
			`SW:
				begin
					cyc_o <= `HIGH;
					stb_o <= `HIGH;
					we_o <= `HIGH;
					sel_o <= 16'hFF << {eandx[3],3'b0};
					adr_o <= eandx;
					dat_o <= {2{c}};
					$display("%h: swx %h=%h",opc,eandx,c);
					goto(MEMORY);
				end
    		`PUSH:
                begin
                    cyc_o <= `HIGH;
                    stb_o <= `HIGH;
                    we_o <= `HIGH;
                    sel_o <= 16'hFF << {xIncea[3],3'b0};
                    adr_o <= xIncea;
                    dat_o <= {2{c}};
                    goto(MEMORY);
                    $display("%h: push %s", opc, regname(Rb));
                end
    		`POP:
                begin
                    cyc_o <= `HIGH;
                    stb_o <= `HIGH;
                    sel_o <= 16'hFF << {xIncea[3],3'b0};
                    adr_o <= xIncea;
                    rfwr <= `TRUE;
                    Rt <= ir[20:16];
                    res <= a + {{59{ir[25]}},ir[25:21]};
                    goto(MEMORY);
                    $display("%h: pop %s", opc, regname(Rb));
                end
			endcase
		`ADD:	begin res <= sum; rfwr <= `TRUE; end
		`CMP:	begin res <= $signed(a) < $signed(b) ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'h0 : 64'h1; rfwr <= `TRUE; end
		`CMPU:	begin res <= a < b ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'h0 : 64'h1; rfwr <= `TRUE; end
		`SccI:
				begin
				rfwr <= `TRUE;
				case(ir[31:28])
				4'd2:	res <= a==b;
				4'd3:	res <= a!=b;
				4'd4:	res <= $signed(a) < $signed(b);
				4'd5:	res <= $signed(a) >= $signed(b);
				4'd6:	res <= $signed(a) <= $signed(b);
				4'd7:	res <= $signed(a) > $signed(b);
				4'd12:	res <= a < b;
				4'd13:	res <= a >= b;
				4'd14:	res <= a <= b;
				4'd15:	res <= a > b;
				endcase
				end
		`MULU:	if (mul_done) begin res <= produ[63:0]; rfwr <= `TRUE; end else goto(EXECUTE);
		`MUL:	if (mul_done) begin res <= prods[63:0]; rfwr <= `TRUE; end else goto(EXECUTE);
		`MULSU:	if (mul_done) begin res <= prodsu[63:0]; rfwr <= `TRUE; end else goto(EXECUTE);
		// Stay in execute state until divide is done.
		`DIVI,`DIVUI,`DIVSUI:
				if (div_done) begin
					res <= div_qo;
					rfwr <= `TRUE;
				end
				else
					goto(EXECUTE);
		`MODI,`MODUI,`MODSUI:
				if (div_done) begin
					res <= div_ro;
					rfwr <= `TRUE;
				end
				else
					goto(EXECUTE);
		`BITFLD:	begin res <= bfo; rfwr <= `TRUE; end
		`AND:	begin res <= a & b; rfwr <= `TRUE; end
		`OR:	begin res <= a | b; rfwr <= `TRUE; end
		`XOR:	begin res <= a ^ b; rfwr <= `TRUE; end
		`QOPI:
		      begin
		      rfwr <= `TRUE;
		      case(ir[10:8])
		      3'd0:   res <= a | b;
		      3'd1:   res <= a + b;
		      3'd2:   res <= a & b;
		      3'd3:   res <= a ^ b;
		      endcase
		      end
		`Bcc0,`Bcc1,`BEQ0,`BEQ1,`BBc0,`BBc1:
			begin
				if (takb)
					pc <= pc + {{21{ir[31]}},ir[31:22],ir[0],2'b00};
				$display("%h: br %h", pc + {{21{ir[31]}},ir[31:22],ir[0],2'b00});
			end
		`BccR:
			begin
				if (takb)
					pc <= c;
				$display("%h: br %h", c);
			end
		`JAL:
			begin
				pc <= {sum[31:2],2'b00};
				rfwr <= `TRUE;
				res <= pc;
			end
		// b is set to -8 for call
		`CALL:	
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				we_o <= `HIGH;
				sel_o <= 16'hFF << {sum[3],3'b0};
				adr_o <= sum;
				dat_o <= {2{32'h0,pc}};
				pc <= {pc[31:28],ir[31:6],2'b00};
				res <= sum;
				rfwr <= `TRUE;
				goto(MEMORY);
				$display("%h: call %h", opc, {pc[31:28],ir[31:6],2'b00});
			end
		`CALLR:
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				we_o <= `HIGH;
				sel_o <= 16'hFF << {am8[3],3'b0};
				adr_o <= am8;
				dat_o <= {2{32'h0,pc}};
				pc <= b + {{48{ir[31]}},ir[31:16]};
				pc[1:0] <= 2'b00;
				goto(MEMORY);
				$display("%h: call %h", opc, b + {{48{ir[31]}},ir[31:16]});
			end
		`RET:
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				sel_o <= 16'hFF << {a[3],3'b0};
				adr_o <= a;
				res <= sum;
				rfwr <= `TRUE;
				$display("%h: ret #", opc, b);
				goto(MEMORY);
			end
		`REX:
			begin
				ol <= ir[13:11];
				case(ir[13:11])
				3'd0:		pl <= 8'h00;
				3'd1:		pl <= 8'h01;
				default:	pl <= (npl < 2) ? {5'd0,ir[13:11]} : npl;
				endcase
				if (ir[13:11]!=3'd0)
					pc <= tvec[ir[13:11]];
				im <= ir[26:24];
			end
		`CSR:
			begin
				case(ir[31:30])
				2'd0:	begin read_csr(ir[26:16],res); rfwr <= `TRUE; end
				default:begin
							rfwr <= `TRUE;
							read_csr(ir[26:16],res);
							write_csr(ir[26:16],ir[31:30],a);
						end
				endcase
			end
		`LINK:
			begin
				res <= am8;
				rfwr <= `TRUE;
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				we_o <= `HIGH;
				sel_o <= 16'h0FF << {am8[3],3'b0};
				adr_o <= am8;
				dat_o <= {2{b}};
				goto(MEMORY);
				$display("%h: link %s,#", opc, regname(Rb), b);
			end
		`LB,`LBU:
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				sel_o <= 16'h01 << sum[3:0];
				adr_o <= sum;
				goto(MEMORY);
				$display("%h: lb[u] %h", opc, sum);
			end
		`LC,`LCU:
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				sel_o <= 16'h03 << {sum[3:1],1'b0};
				adr_o <= sum;
				goto(MEMORY);
				$display("%h: lc[u] %h", opc, sum);
			end
		`LH,`LHU:
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				sel_o <= 16'h0F << {sum[3:2],2'b0};
				adr_o <= sum;
				goto(MEMORY);
				$display("%h: lh[u] %h", opc, sum);
			end
		`LW:
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				sel_o <= 16'hFF << {sum[3],3'b0};
				adr_o <= sum;
				goto(MEMORY);
				$display("%h: lw %h", opc, sum);
			end
		`SB:
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				we_o <= `HIGH;
				sel_o <= 16'h01 << sum[3:0];
				adr_o <= sum;
				dat_o <= {16{c[7:0]}};
				goto(MEMORY);
				$display("%h: sb %h <= %h", opc, sum, c[7:0]);
			end
		`SC:
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				we_o <= `HIGH;
				sel_o <= 16'h03 << {sum[3:1],1'b0};
				adr_o <= sum;
				dat_o <= {8{c[15:0]}};
				goto(MEMORY);
				$display("%h: sc %h <= %h", opc, sum, c[15:0]);
			end
		`SH:
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				we_o <= `HIGH;
				sel_o <= 16'h0F << {sum[3:2],2'b0};
				adr_o <= sum;
				dat_o <= {4{c[31:0]}};
				goto(MEMORY);
				$display("%h: sh %h <= %h", opc, sum, c[31:0]);
			end
		`SW:
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				we_o <= `HIGH;
				sel_o <= 16'hFF << {sum[3],3'b0};
				adr_o <= sum;
				dat_o <= {2{c}};
				goto(MEMORY);
				$display("%h: sw %h <= %h", opc, sum, c);
			end
		endcase
	end

// MEMORY:
// Finish memory cycle started in EXECUTE by waiting for an ack. Latch input
// data. The data is registered here before subsequent use because it's likely
// coming from a large mux. We don't want to cascade the mux and the shift
// operation required to align the data into a single clock cycle.

MEMORY:
	if (ack_i) begin
		goto(MEMORY_NACK);
		cyc_o <= `LOW;
		stb_o <= `LOW;
		we_o <= `LOW;
		sel_o <= 16'h0000;
		//adr_o <= 32'hFFFFFFFF;
	end

// Wait for ack to go back low again. Nomrally ack should go low immediately
// when the bus cycle is terminated within the same clock cycle. However some
// bus slaves don't put ack low until the clock edge when seeing the
// terminated bus cycle. We want to ensure that a second bus cycle isn't
// started until ack is low or the ack could be mistakenly accepted.
MEMORY_NACK:
	if (~ack_i) begin
		goto(IFETCH);
		case(opcode)
		`R2:
			case(funct)
			`UNLINK:	begin res <= word_in; Rt <= Rb; rfwr <= `TRUE; end
    		`LB:	begin res <= {{56{byte_in[7]}},byte_in}; rfwr <= `TRUE; end
            `LBU:   begin res <= {{56{1'b0}},byte_in}; rfwr <= `TRUE; end
            `LC:    begin res <= {{48{char_in[15]}},char_in}; rfwr <= `TRUE; end
            `LCU:   begin res <= {{48{1'b0}},char_in}; rfwr <= `TRUE; end
            `LH:    begin res <= {{32{half_in[31]}},half_in}; rfwr <= `TRUE; end
            `LHU:   begin res <= {{32{1'b0}},half_in}; rfwr <= `TRUE; end
            `LW:    begin res <= word_in; rfwr <= `TRUE; end
    		`POP:	begin res <= word_in; rfwr <= `TRUE; Rt <= ir[15:11]; end
            `PUSH:  begin res <= a + {{59{ir[25]}},ir[25:21]}; rfwr <= `TRUE; end
			endcase	
		`LINK:	begin res <= a - {{48{ir[31]}},ir[31:16]}; Rt <= Ra; rfwr <= `TRUE; end
		`CALL:	;
		`CALLR:	begin res <= am8; rfwr <= `TRUE; end
		`RET:	begin pc <= {word_in[31:2],2'b0}; end
		`LB:	begin res <= {{56{byte_in[7]}},byte_in}; rfwr <= `TRUE; end
		`LBU:	begin res <= {{56{1'b0}},byte_in}; rfwr <= `TRUE; end
		`LC:	begin res <= {{48{char_in[15]}},char_in}; rfwr <= `TRUE; end
		`LCU:	begin res <= {{48{1'b0}},char_in}; rfwr <= `TRUE; end
		`LH:	begin res <= {{32{half_in[31]}},half_in}; rfwr <= `TRUE; end
		`LHU:	begin res <= {{32{1'b0}},half_in}; rfwr <= `TRUE; end
		`LW:	begin res <= word_in; rfwr <= `TRUE; end
		endcase
	end

// Some operations produce two results and need a second register update cycle.
MULDIV2:
	begin
		rfwr <= `TRUE;
		Rt <= ir[25:21];
		case(funct)
		`MUL:	res <= prods[127:64];
		`MULU:	res <= produ[127:64];
		`MULSU:	res <= prodsu[127:64];
		`DIVMOD,`DIVMODU,`DIVMODSU:
				res <= div_ro;
		`XCHG:	begin res <= c; Rt <= ir[15:11]; end
		endcase
		goto(IFETCH);	
	end

endcase

// Handle the register file update. The update is caused in a couple of
// different states. There may be two updates for a single instruction.
// Note that r0 is always forced to zero. A write to r0 may be needed
// before it's used anywhere.
if (rfwr) begin
	regfile[Rt] <= |Rt ? res : 64'd0;
	if (|Rt)
		$display("%s=%h",regname(Rt),res);
end

end

always @(posedge tm_clk_i)
if (rst_i)
	wctime <= 64'd1;
else begin
	if (wctime[31:0]==WCTIME1S) begin
		wctime[31:0] <= 32'd1;
		wctime[63:32] <= wctime[63:32] + 32'd1;
	end
	else
		wctime[31:0] <= wctime[31:0] + 32'd1;
end
always @(posedge clk_i)
	times <= wctime;

task read_csr;
input [11:0] regno;
output [63:0] val;
begin
	casez(regno)
	`HARTID:	val <= hartid_i;
	`TICK:		val <= tick;
	`CAUSE:		val <= {55'd0,cause};
	`SCRATCH:	val <= scratch;
	`SEMA:		val <= sema;
	`TVEC:		val <= tvec[regno[2:0]];
	`TIME:		val <= times;
	`INSTRET:	val <= instret;
	endcase
end
endtask

task write_csr;
input [11:0] regno;
input [1:0] op;
input [63:0] val;
begin
	case(op)
	2'd0:	;	// read only
	2'd1:
		casez(regno)
		`CAUSE:	cause <= val[8:0];
		`SCRATCH:	scratch <= val;
		`SEMA:	sema <= val;
		`TVEC:	tvec[regno[2:0]] <= val;
		endcase
	2'd2:
		casez(regno)
		`SEMA:	sema <= sema | val;
		endcase
	2'd3:
		casez(regno)
		`SEMA:	sema <= sema & ~val;
		endcase
	endcase
end
endtask

task goto;
input [7:0] st;
begin
	state <= st;
end
endtask

endmodule
