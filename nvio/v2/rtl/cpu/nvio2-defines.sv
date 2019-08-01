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
`define ZERO		64'd0
`define HIGH        1'b1
`define LOW         1'b0
`define TRUE        1'b1
`define FALSE       1'b0
`define INV		1'b0
`define VAL		1'b1

`define LDB		7'h00
`define LDW		7'h01
`define LDT		7'h02
`define LDO		7'h03
`define LDH		7'h04
`define LDHR	7'h05
`define LDBU	7'h08
`define LDWU	7'h09
`define LDTU	7'h0A
`define LDOU	7'h0B
`define AMO		7'h0E
`define MLX		7'h0F
`define LDBX		6'h00
`define LDWX		6'h01
`define LDTX		6'h02
`define LDOX		6'h03
`define LDHX		6'h04
`define LDHRX		6'h05
`define LDBUX		6'h08
`define LDWUX		6'h09
`define LDTUX		6'h0A
`define LDOUX		6'h0B
`define LDFSX		6'h12
`define LDFDX		6'h13
`define LDFQX		6'h14
`define LDFH	7'h11
`define LDFS	7'h12
`define LDFD	7'h13
`define LDFQ	7'h14

`define STB		7'h20
`define STW		7'h21
`define STT		7'h22
`define STO		7'h23
`define STH		7'h24
`define STHC	7'h25
`define CAS		7'h28
`define TLB		7'h2D
`define CACHE	7'h2E
`define MSX		7'h2F
`define STBX		6'h00
`define STWX		6'h01
`define STTX		6'h02
`define STOX		6'h03
`define STHX		6'h04
`define STHCX		6'h05
`define CASX		6'h08
`define CACHEX	6'h0E
`define STFSX		6'h12
`define STFDX		6'h13
`define STFQX		6'h14
`define MEMSB		6'h18
`define MEMDB		6'h19
`define STFH	7'h31
`define STFS	7'h32
`define STFD	7'h33
`define STFQ	7'h34

`define MULI	7'h40
`define MULUI	7'h41
`define DIVI	7'h42
`define DIVUI	7'h43
`define ADDI	7'h44
`define CSR		7'h45
`define CSRRD		3'd0
`define CSRRW		3'd1
`define CSRRS		3'd2
`define CSRRC		3'd3
`define CSRRWI	3'd5
`define CSRRSI	3'd6
`define CSRRCI	3'd7
`define MODI	7'h46
`define MODUI	7'h47
`define ANDI	7'h48
`define ORI		7'h49
`define XORI	7'h4A
`define LEA		7'h4B
`define BYTNDX	7'h4C
`define WYDNDX	7'h4D
`define DIFI	7'h4E
`define MULFI	7'h4F
`define SLTI	7'h50
`define SGEI	7'h51
`define SLEI	7'h52
`define SGTI	7'h53
`define SLTUI	7'h54
`define SGEUI	7'h55
`define SLEUI	7'h56
`define SGTUI	7'h57
`define SEQI	7'h58
`define SNEI	7'h59
`define R1		7'h5A
`define R3		7'h5B
`define MULH		6'h00
`define MULUH		6'h01
`define ADD			6'h04
`define SUB			6'h05
`define CMP			6'h06
`define CMPU		6'h07
`define AND			6'h08
`define OR			6'h09
`define XOR			6'h0A
`define SLT			6'h10
`define SGE			6'h11
`define SLE			6'h12
`define SGT			6'h13
`define SLTU		6'h14
`define SGEU		6'h15
`define SLEU		6'h16
`define SGTU		6'h17
`define SEQ			6'h18
`define SNE			6'h19
`define DIF			6'h1F
`define MUL			6'h20
`define MULU		6'h21
`define DIV			6'h22
`define DIVU		6'h23
`define MOD			6'h24
`define MODU		6'h25
`define SHL			6'h32
`define ASL			6'h33
`define SHR			6'h34
`define ASR			6'h35
`define ROL			6'h36
`define ROR			6'h37
`define SHLI		6'h38
`define ASLI		6'h39
`define SHRI		6'h3A
`define ASRI		6'h3B
`define ROLI		6'h3C
`define RORI		6'h3D
`define CMPI	7'h5E
`define CMPUI	7'h5F

`define V2BITS	6'h30
`define BITS2V	6'h31
// Vector mask operations
`define VMAND		6'h38
`define VMOR		6'h39
`define VMXOR		6'h3A
`define VMXNOR	6'h3B
`define VMFIRST	6'h3C
`define VMLAST	6'h3D
`define VMPOP		6'h3E
`define VMFILL	6'h3F

`define Bcc		7'h60
`define BEQ			3'd0
`define BNE			3'd1
`define BLT			3'd2
`define BGE			3'd3
`define BLTU		3'd6
`define BGEU		3'd7
`define BBc		7'h61
`define BEQI	7'h62
`define BNEI	7'h63
`define BRG		7'h64
`define BREQ		4'd0
`define BRNE		4'd1
`define BRLT		4'd2
`define BRGE		4'd3
`define BLcc	7'h65
`define FBcc	7'h66
`define FBEQ		3'd0
`define FBNE		3'd1
`define FBLT		3'd2
`define FBLE		3'd3
`define FBUN		3'd7
`define NOP		7'h67
`define JAL		7'h68
`define CALL	7'h69
`define RET		7'h6A
`define JMP		7'h6B
`define BMISC1	7'h6C
`define BMISC2	7'h6D
`define SEI			4'd3
`define CHK		7'h6E
`define CHKI	7'h6F

`define FLT1	7'h71
`define FCVTF2I	5'd02
`define FCVTI2F	5'd03
`define FCVTSQ	5'd10
`define FCVTDQ	5'd11
`define FSQRT		5'd13
`define FCVTQS	5'd26
`define FCVTQD	5'd27
`define FCLASS	5'd30
`define FMAX		5'd2
`define FMIN		5'd3
`define FADD		5'd4
`define FSUB		5'd5
`define FCMP		5'd6
`define FMUL		5'd8
`define FDIV		5'd9
`define FSLT		5'd16
`define FSGE		5'd17
`define FSLE		5'd18
`define FSGT		5'd19
`define FSEQ		5'd20
`define FSNE		5'd21
`define FSUN		5'd22
`define FSGNOP	5'd15
`define VEC2	7'h72
`define VEC1		6'h01
`define VCMPRSS		6'h14
`define FLT3	7'h73
`define FMA			3'd0
`define FMS			3'd1
`define FNMA		3'd2
`define FNMS		3'd3
`define FLT2I		3'd6
`define FLT2		3'd7
`define VFMA	7'h74
`define VFMS	7'h75
`define VFNMA	7'h76
`define VFNMS	7'h77


`define BF		7'h78
`define LILD	7'h7C
`define LIAS1	7'h7D
`define LIAS2	7'h7E
`define LIAS3	7'h7F


`define CC_ILLEGAL_INSN		4'd2

`define FLT_IFETCH	40'h0
