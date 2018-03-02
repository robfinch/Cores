// ============================================================================
//  ALU
//  - perform datapath operations
//
//
//  (C) 2009-2018  Robert Finch
//  robfinch[remove]@finitron.ca
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
//
//  Verilog 
//
// ============================================================================
//

module FT8088Q_ALU(ir, w, a, b,
	pf_i, af_i, cf_i, sf_i, zf_i, vf_i,
	pf_o, af_o, cf_o, sf_o, zf_o, vf_o,
	o);
input [7:0] ir;
input w;
input [15:0] a;
input [15:0] b;
input pf_i;
input af_i;
input cf_i;
input sf_i;
input zf_i;
input vf_i;
output reg pf_o;
output reg af_o;
output reg cf_o;
output reg sf_o;
output reg zf_o;
output reg vf_o;
output reg [15:0] o;


function carry;
	input op;
	input a;
	input b;
	input s;

	begin
		carry = op ? (~a&b)|(s&~a)|(s&b) : (a&b)|(a&~s)|(b&~s);
	end

endfunction

function overflow;
	input op;
	input a;
	input b;
	input s;

	begin
		overflow = (op ^ s ^ b) & (~op ^ a ^ b);
	end

endfunction

wire amsb = w ? a[15] : a[7];
wire bmsb = w ? b[15] : b[7];
wire [15:0] as = {!a[15],a[14:0]};
wire [15:0] bs = {!b[15],b[14:0]};
wire signed [15:0] sa = a;
wire signed [15:0] sb = b;
wire signed [7:0] als = a[7:0];
wire signed [7:0] bls = b[7:0];
wire signed [15:0] p = als * bls;
wire signed [31:0] wp = sa * sb;
wire [15:0] p16 = a[7:0] * b[7:0];
wire [31:0] p32 = a * b;

// Compute AL/10
// - multiply by 1/10 = 26/256
wire [15:0] al26 = {al,4'b0} + {al,3'b0} + {al,1'b0};	// * 26
wire [7:0] aldv10 = al26[15:8];	// 256

wire [15:0] cmp_o = a - b;
wire eq  = a == b;
wire ltu = a < b;
wire lt  = as < bs;

wire [31:0] shlo = {16'h0000,b} << shftamt;
wire [31:0] shruo = {b,16'h0000} >> shftamt;
wire [15:0] shro = ~(~b >> shftamt);
wire [32:0] shlco = {16'h0000,b,cf} << shftamt;
wire [32:0] shrcuo = {cf,b,16'h0000} >> shftamt;

wire [15:0] shlo8 = {8'h00,b[7:0]} << shftamt;
wire [15:0] shruo8 = {b[7:0],8'h00} >> shftamt;
wire [ 7:0] shro8 = ~(~b[7:0] >> shftamt);
wire [16:0] shlco8 = {8'h00,b,cf} << shftamt;
wire [16:0] shrcuo8 = {cf,b[7:0],8'h00} >> shftamt;

wire div16_done;
wire div32_done;
wire [15:0] q16;
wire [7:0] r16;
wire [31:0] q32;
wire [15:0] r32;
wire [31:0] negdxax = -{dx,ax};

divr2 #(16) udiv1
(
	.rst(rst_i),
	.clk(clk_i),
	.ce(1'b1),
	.ld(ld_div16),
	.su(TTT[0]),
	.ri(1'b0),
	.a(ax),
	.b(b[7:0]),
	.i(8'h00),
	.q(q16),
	.r(r16),
	.divByZero(),
	.done(div16_done)
);


divr2 #(32) udiv2
(
	.rst(rst_i),
	.clk(clk_i),
	.ce(1'b1),
	.ld(ld_div32),
	.su(TTT[0]),
	.ri(1'b0),
	.a({dx,ax}),
	.b(b),
	.i(16'h0000),
	.q(q32),
	.r(r32),
	.divByZero(),
	.done(div32_done)
);


always @*	//(ir or ir2 or a or b or cf or af or al or ah or aldv10 or TTT)
		casez(ir)
		`MOV_M2AL,`MOV_M2AX,`LDS,`LES:
			o <= a;
		`MOV_MR,`MOV_R2S,
		`MOV_RR8,`MOV_RR16,
		`MOV_I8M,`MOV_I16M,
		`MOV_I2AL,`MOV_I2DL,`MOV_I2CL,`MOV_I2BL,`MOV_I2AH,`MOV_I2DH,`MOV_I2CH,`MOV_I2BH,
		`MOV_I2AX,`MOV_I2DX,`MOV_I2CX,`MOV_I2BX,`MOV_I2SP,`MOV_I2BP,`MOV_I2SI,`MOV_I2DI:
			o <= b;
		`XCHG_MEM:
			o <= b;
		`ADD,`ADD_ALI8,`ADD_AXI16: o <= a + b;
		`SUB,`SUB_ALI8,`SUB_AXI16: o <= a - b;
		`ADC,`ADC_ALI8,`ADC_AXI16: o <= a + b + cf_i;
		`SBB,`SBB_ALI8,`SBB_AXI16: o <= a - b - cf_i;
		`AND,`AND_ALI8,`AND_AXI16: o <= a & b;
		`TEST,`TEST_ALI8,`TEST_AXI16: o <= a & b;
		`OR, `OR_ALI8, `OR_AXI16:  o <= a | b;
		`XOR,`XOR_ALI8,`XOR_AXI16: o <= a ^ b;
		`CMP,`CMP_ALI8,`CMP_AXI16: o <= a - b;
		`SCASB,`SCASW,`CMPSB,`CMPSW: o <= a - b;
		`INC_REG: o <= a + 16'd1;
		`DEC_REG: o <= a - 16'd1;
//		`IMUL: alu_o <= w ? p : wp[15:0];
		`ALU_I2R8:
			case(TTT)
			3'd0:	o <= a + b;			// ADD
			3'd1:	o <= a | b;			// OR
			3'd2:	o <= a + b + cf_i;	// ADC
			3'd3:	o <= a - b - cf_i;	// SBB
			3'd4:	o <= a & b;			// AND
			3'd5:	o <= a - b;			// SUB
			3'd6:	o <= a ^ b;			// XOR
			default:	o <= 16'h0000;
			endcase
		// ToDo: fix sign extension / extra immediate byte ?
		`ALU_I2R16:
			case(TTT)
			3'd0:	o <= a + b;			// ADD
			3'd1:	o <= a | b;			// OR
			3'd2:	o <= a + b + cf_i;	// ADC
			3'd3:	o <= a - b - cf_i;	// SBB
			3'd4:	o <= a & b;			// AND
			3'd5:	o <= a - b;			// SUB
			3'd6:	o <= a ^ b;			// XOR
			default:	o <= 16'h0000;
			endcase
		8'hF6,8'hF7:
			begin
			case(TTT)
			3'd0:	o <= a & b;			// TEST
			3'd2:	o <= ~b;			// NOT
			3'd3:	o <= -b;			// NEG
			3'd4:	o <= w ? p32[15:0] : p16;		// MUL
			3'd5:	o <= w ? wp[15:0] : p[15:0];	// IMUL
			3'd6:	o <= 16'h0000;		// DIV
			3'd7:	o <= 16'h0000;		// IDIV
			default:	o <= 16'h0000;
			endcase
			end
// ToDo: fix +1 carry
		`DAA:
			begin
				alu_o <= 16'h0000;
				if (al[3:0]>4'h9 || af) begin
					alu_o[3:0] <= al[3:0] + 4'd6;
				end
				if (al[7:4]>4'h9 || cf) begin
					alu_o[7:4] <= al[7:4] + 4'd6;
				end
			end
// ToDo: fix +1 carry
		`DAS:
			begin
				alu_o <= 16'h0000;
				if (al[3:0]>4'h9 || af) begin
					alu_o[3:0] <= al[3:0] - 4'd6;
				end
				if (al[7:4]>4'h9 || cf) begin
					alu_o[7:4] <= al[7:4] - 4'd6;
				end
			end

		`MORE1:
			casex(ir2)
			`AAM:
				begin
					alu_o[ 7:0] <= al - aldv10;
					alu_o[15:8] <= aldv10;
				end
			default:
				alu_o <= 16'h0000;
			endcase
		`MORE2:
			casex(ir2)
			`AAD:
				begin
					alu_o[ 7:0] <= {ah,3'b0} + {ah,1'b0} + al;
					alu_o[15:8] <= 8'h00;
				end
			default:
				alu_o <= 16'h0000;
			endcase
		default: alu_o <= 16'h0000;
		endcase

always @*
	begin
		pf_o <= pf_i;
		af_o <= af_i;
		cf_o <= cf_i;
		sf_o <= sf_i;
		zf_o <= zf_i;
		vf_o <= vf_i;
		casez(ir)
		`DAA:
			begin
			end

		`ALU_I2R8,`ALU_I2R16,`ADD,`ADD_ALI8,`ADD_AXI16,`ADC,`ADC_ALI8,`ADC_AXI16:
			begin
				pf_o <= pres;
				af_o <= carry (1'b0,a[3],b[3],o[3]);
				cf_o <= carry (1'b0,amsb,bmsb,resn);
				vf_o <= overflow(1'b0,amsb,bmsb,resn);
				sf_o <= resn;
				zf_o <= resz;
			end

		`AND,`OR,`XOR,`AND_ALI8,`OR_ALI8,`XOR_ALI8,`AND_AXI16,`OR_AXI16,`XOR_AXI16:
			begin
				pf_o <= pres;
				cf_o <= 1'b0;
				vf_o <= 1'b0;
				sf_o <= resn;
				zf_o <= resz;
			end

		`TEST:
			begin
				pf_o <= pres;
				cf_o <= 1'b0;
				vf_o <= 1'b0;
				sf_o <= resn;
				zf_o <= resz;
			end

		`CMP,`CMP_ALI8,`CMP_AXI16:
			begin
				pf_o <= pres;
				af_o <= carry (1'b1,a[3],b[3],o[3]);
				cf_o <= carry (1'b1,amsb,bmsb,resn);
				vf_o <= overflow(1'b1,amsb,bmsb,resn);
				sf_o <= resn;
				zf_o <= resz;
			end

		`SBB,`SUB,`SBB_ALI8,`SUB_ALI8,`SBB_AXI16,`SUB_AXI16:
			begin
				pf_o <= pres;
				af_o <= carry   (1'b1,a[3],b[3],o[3]);
				cf_o <= carry   (1'b1,amsb,bmsb,resn);
				vf_o <= overflow(1'b1,amsb,bmsb,resn);
				sf_o <= resn;
				zf_o <= resz;
			end

		8'hF6,8'hF7:
			begin
				case(TTT)
				3'd0:	// TEST
					begin
						pf_o <= pres;
						cf_o <= 1'b0;
						vf_o <= 1'b0;
						sf_o <= resn;
						zf_o <= resz;
					end
				3'd2:	// NOT
					begin
					end
				3'd3:	// NEG
					begin
						pf_o <= pres;
						af_o <= carry   (1'b1,1'b0,b[3],o[3]);
						cf_o <= carry   (1'b1,1'b0,bmsb,resn);
						vf_o <= overflow(1'b1,1'b0,bmsb,resn);
						sf_o <= resn;
						zf_o <= resz;
					end
				// Normally only a single register update is required, however with 
				// multiply word both AX and DX need to be updated. So we bypass the
				// regular update here.
				3'd4:
					begin
						if (w) begin
							ax <= p32[15:0];
							dx <= p32[31:16];
							cf_o <= p32[31:16]!=16'd0;
							vf_o <= p32[31:16]!=16'd0;
						end
						else begin
							ax <= p16;
							cf_o <= p16[15:8]!=8'd0;
							vf_o <= p16[15:8]!=8'd0;
						end
					end
				3'd5:
					begin
						if (w) begin
							ax <= wp[15:0];
							dx <= wp[31:16];
							cf <= p32[31:16]!=16'd0;
							vf <= p32[31:16]!=16'd0;
						end
						else begin
							ax <= p;
							cf <= p[15:8]!=8'd0;
							vf <= p[15:8]!=8'd0;
						end
					end
				3'd6,3'd7:
					begin
						$display("state <= DIVIDE1");
						state <= DIVIDE1;
					end
				default:	;
				endcase
			end

		`INC_REG:
			begin
				pf_o <= pres;
				af_o <= carry   (1'b0,a[3],b[3],o[3]);
				vf_o <= overflow(1'b0,a[15],b[15],resnw);
				sf_o <= resnw;
				zf_o <= reszw;
			end
		`DEC_REG:
			begin
				pf_o <= pres;
				af_o <= carry   (1'b1,a[3],b[3],o[3]);
				vf_o <= overflow(1'b1,a[15],b[15],resnw);
				sf_o <= resnw;
				zf_o <= reszw;
			end
	//		`IMUL:
	//			begin
	//				state <= IFETCH;
	//				wrregs <= 1'b1;
	//				w <= 1'b1;
	//				rrr <= 3'd0;
	//				res <= alu_o;
	//				if (w) begin
	//					cf <= wp[31:16]!={16{resnw}};
	//					vf <= wp[31:16]!={16{resnw}};
	//					dx <= wp[31:16];
	//				end
	//				else begin
	//					cf <= ah!={8{resnb}};
	//					vf <= ah!={8{resnb}};
	//				end
	//			end


		//-----------------------------------------------------------------
		// Memory Operations
		//-----------------------------------------------------------------
			
		// registers not allowed on LEA
		// invalid opcode
		//
		`LEA:
			begin
				w <= 1'b1;
				res <= ea;
				if (mod==2'b11) begin
					int_num <= 8'h06;
					state <= INT;
				end
				else begin
					state <= IFETCH;
					wrregs <= 1'b1;
				end
			end
		`LDS:
			begin
				wrsregs <= 1'b1;
				res <= alu_o;
				rrr <= 3'd3;
				state <= IFETCH;
			end
		`LES:
			begin
				wrsregs <= 1'b1;
				res <= alu_o;
				rrr <= 3'd0;
				state <= IFETCH;
			end

		`MOV_RR8,`MOV_RR16,
		`MOV_MR,
		`MOV_M2AL,`MOV_M2AX,
		`MOV_I2AL,`MOV_I2DL,`MOV_I2CL,`MOV_I2BL,`MOV_I2AH,`MOV_I2DH,`MOV_I2CH,`MOV_I2BH,
		`MOV_I2AX,`MOV_I2DX,`MOV_I2CX,`MOV_I2BX,`MOV_I2SP,`MOV_I2BP,`MOV_I2SI,`MOV_I2DI:
			begin
				state <= IFETCH;
				wrregs <= 1'b1;
				res <= alu_o;
			end
		`XCHG_MEM:
			begin
				wrregs <= 1'b1;
				if (mod==2'b11) rrr <= rm;
				res <= alu_o;
				b <= rrro;
				state <= mod==2'b11 ? IFETCH : XCHG_MEM;
			end
		`MOV_I8M,`MOV_I16M:
			begin
				res <= alu_o;
				state <= rrr==3'd0 ? STORE_DATA : INVALID_OPCODE;
			end

		`MOV_S2R:
			begin
				w <= 1'b1;
				rrr <= rm;
				res <= b;
				if (mod==2'b11) begin
					state <= IFETCH;
					wrregs <= 1'b1;
				end
				else
					state <= STORE_DATA;
			end
		`MOV_R2S:
			begin
				wrsregs <= 1'b1;
				res <= alu_o;
				state <= IFETCH;
			end

		`LODSB:
			begin
				state <= IFETCH;
				wrregs <= 1'b1;
				w <= 1'b0;
				rrr <= 3'd0;
				res <= a[7:0];
				if ( df) si <= si_dec;
				if (!df) si <= si_inc;
			end
		`LODSW:
			begin
				state <= IFETCH;
				wrregs <= 1'b1;
				w <= 1'b1;
				rrr <= 3'd0;
				res <= a;
				if ( df) si <= si - 16'd2;
				if (!df) si <= si + 16'd2;
			end

		8'hD0,8'hD1,8'hD2,8'hD3,8'hC0,8'hC1:
			begin
				state <= IFETCH;
				wrregs <= 1'b1;
				rrr <= rm;
				if (w)
					case(rrr)
					3'b000:	// ROL
						begin
							res <= shlo[15:0]|shlo[31:16];
							cf <= bmsb;
							vf <= bmsb^b[14];
						end
					3'b001:	// ROR
						begin
							res <= shruo[15:0]|shruo[31:16];
							cf <= b[0];
							vf <= cf^b[15];
						end
					3'b010:	// RCL
						begin
							res <= shlco[16:1]|shlco[32:17];
							cf <= b[15];
							vf <= b[15]^b[14];
						end
					3'b011:	// RCR
						begin
							res <= shrcuo[15:0]|shrcuo[31:16];
							cf <= b[0];
							vf <= cf^b[15];
						end
					3'b100:	// SHL
						begin
							res <= shlo[15:0];
							cf <= shlo[16];
							vf <= b[15]^b[14];
						end
					3'b101:	// SHR
						begin
							res <= shruo[31:16];
							cf <= shruo[15];
							vf <= b[15];
						end
					3'b111:	// SAR
						begin
							res <= shro;
							cf <= b[0];
							vf <= 1'b0;
						end
					endcase
				else
					case(rrr)
					3'b000:	// ROL
						begin
							res <= shlo8[7:0]|shlo8[15:8];
							cf <= b[7];
							vf <= b[7]^b[6];
						end
					3'b001:	// ROR
						begin
							res <= shruo8[15:8]|shruo8[7:0];
							cf <= b[0];
							vf <= cf^b[7];
						end
					3'b010:	// RCL
						begin
							res <= shlco8[8:1]|shlco8[16:9];
							cf <= b[7];
							vf <= b[7]^b[6];
						end
					3'b011:	// RCR
						begin
							res <= shrcuo8[15:8]|shrcuo8[7:0];
							cf <= b[0];
							vf <= cf^b[7];
						end
					3'b100:	// SHL
						begin
							res <= shlo8[7:0];
							cf <= shlo8[8];
							vf <= b[7]^b[6];
						end
					3'b101:	// SHR
						begin
							res <= shruo8[15:8];
							cf <= shruo8[7];
							vf <= b[7];
						end
					3'b111:	// SAR
						begin
							res <= shro8;
							cf <= b[0];
							vf <= 1'b0;
						end
					endcase
			end

		//-----------------------------------------------------------------
		//-----------------------------------------------------------------
		`GRPFF:
			begin
				case(rrr)
				3'b000:		// INC
					begin
						af_o <= carry   (1'b0,a[3],b[3],alu_o[3]);
						vf_o <= overflow(1'b0,a[15],b[15],alu_o[15]);
						w <= 1'b1;
						res <= alu_o;
						rrr <= rm;
						pf <= pres;
						sf <= resnw;
						zf <= reszw;
					end
				3'b001:		// DEC
					begin
						state <= IFETCH;
						wrregs <= 1'b1;
						af <= carry   (1'b1,a[3],b[3],alu_o[3]);
						vf <= overflow(1'b1,a[15],b[15],alu_o[15]);
						w <= 1'b1;
						res <= alu_o;
						rrr <= rm;
						pf <= pres;
						sf <= resnw;
						zf <= reszw;
					end
				3'b010:	begin sp <= sp_dec; state <= CALL_IN; end
				// These two should not be reachable here, as they would
				// be trapped by the EACALC.
				3'b011:	state <= CALL_FIN;	// CALL FAR indirect
				3'b101:	// JMP FAR indirect
					begin
						ip <= offset;
						cs <= selector;
						state <= IFETCH;
					end
				3'b110:	begin sp <= sp_dec; state <= PUSH; end
				default:
					begin
						af <= carry   (1'b0,a[3],b[3],alu_o[3]);
						vf <= overflow(1'b0,a[15],b[15],alu_o[15]);
					end
				endcase
			end

		default:	;
		endcase
	end

assign pres = ~^o[7:0];
assign reszw = o==16'h0000;
assign reszb = o[7:0]==8'h00;
assign resnb = o[7];
assign resnw = o[15];

assign resz = w ? reszw : reszb;
assign resn = w ? resnw : resnb;


endmodule
