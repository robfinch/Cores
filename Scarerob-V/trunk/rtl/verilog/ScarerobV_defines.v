// ============================================================================
// ScarerobV_defines.v
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
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
// ============================================================================
//
`ifndef ScarerobV_DEFINES
`define ScarerobV_DEFINES	1'b1

//`define SUPPORT_BITMAP_FNS		1'b1
`define SUPPORT_PAGING				1'b1
`define SUPPORT_ICACHE				1'b1
//`define SUPPORT_DCACHE				1'b1
`define SUPPORT_BITFIELD			1'b1
`define SUPPORT_CLKGATE				1'b1
`define TMR			1'b1
`define TMRX		1'b1
//`define TMR_BYPASS	1'b1		// bypass extra inconsequential loads
//`define TMR_CACHE		1'b1		// triple mode redundancy on cache
//`define TMR_REG		1'b1		// triple mode redundancy on register file

`define FEAT_DCACHE		1'b0
`define FEAT_ICACHE		1'b1
`define FEAT_PAGING		1'b1
`define FEAT_SEG		1'b1
`define FEAT_BITFIELD	1'b1
`define FEAT_BITMAP		1'b0
`define FEAT_CLK_GATE	1'b1
`define FEAT_TMR		1'b1

`define TRUE	1'b1
`define FALSE	1'b0

`define RST_VECT	32'h0000FFF0
`define NMI_VECT	32'h0000FFE0
`define IRQ_VECT	32'h0000FFD0
`define DBG_VECT	32'h0000FFC0
`define ALN_VECT	32'h0000FFB0

`define BRK		8'h00
`define TST		8'b00001xxx
`define CMPI	8'b00010xxx
`define R		8'h01
`define MRK1		4'h00
`define MRK2		4'h01
`define MRK3		4'h02
`define SWAP		4'h03
`define MOV			4'h04
`define NEG			4'h05
`define COM			4'h06
`define NOT			4'h07
`define SXB			4'h08
`define SXC			4'h09
`define SXH			4'h0A
`define CPUID		4'h0B
`define MTSPR		4'h0C
`define MFSPR		4'h0D
`define MOVS		4'h0E
`define GRAN		4'h0F
`define RR		8'h02
`define ADD			6'h00
`define SUB			6'h01
`define MUL			6'h02
`define DIV			6'h03
`define MOD			6'h04
`define MULU		6'h12
`define DIVU		6'h13
`define MODU		6'h14
`define ADC			6'h06
`define SBC			6'h07
`define AND			6'h08
`define OR			6'h09
`define EOR			6'h0A
`define ANDN		6'h0B
`define NAND		6'h0C
`define NOR			6'h0D
`define ENOR		6'h0E
`define ORN			6'h0F
`define	SEQ			6'h10
`define SNE			6'h11
`define SGT			6'h18
`define SLE			6'h19
`define SGE			6'h1A
`define SLT			6'h1B
`define SHI			6'h1C
`define SLS			6'h1D
`define SHS			6'h1E
`define SLO			6'h1F
`define SLL			6'h20
`define ROL			6'h21
`define SRL			6'h22
`define ROR			6'h23
`define SRA			6'h24
`define SLLI		6'h30
`define ROLI		6'h31
`define SRLI		6'h32
`define RORI		6'h33
`define SRAI		6'h34

`define BITFIELD	8'h03
`define TLS		8'h04
`define GS		8'h05
`define IO		8'h06
`define SEGX	8'h07

`define CMP		8'h18
`define SEGT	8'h1F

`define ADDI	8'h20
`define SUBI	8'h21
`define MULI	8'h22
`define DIVI	8'h23
`define MODI	8'h24
`define LDI10	8'h25
`define ADDI4	8'h26
`define SUBI4	8'h27
`define ANDI	8'h28
`define ORI		8'h29
`define EORI	8'h2A

`define MULUI	8'h32
`define DIVUI	8'h33
`define MODUI	8'h34
`define LDI18	8'h35

`define	SEQI	8'h30
`define SNEI	8'h31
`define SGTI	8'h38
`define SLEI	8'h39
`define SGEI	8'h3A
`define SLTI	8'h3B
`define SHII	8'h3C
`define SLSI	8'h3D
`define SHSI	8'h3E
`define SLOI	8'h3F

`define Bcc		8'b0100xxxx
`define BEQ		8'h40
`define BNE		8'h41
`define BVS		8'h42
`define BVC		8'h43
`define BMI		8'h44
`define BPL		8'h45
`define BRA		8'h46
`define BRN		8'h47
`define BGT		8'h48
`define BLE		8'h49
`define BGE		8'h4A
`define BLT		8'h4B
`define BHI		8'h4C
`define BLS		8'h4D
`define BHS		8'h4E
`define BLO		8'h4F

`define LBcc	8'b0101xxxx
`define LBEQ	8'h50
`define LBNE	8'h51
`define LBVS	8'h52
`define LBVC	8'h53
`define LBMI	8'h54
`define LBPL	8'h55
`define LBRA	8'h56
`define LBRN	8'h57
`define LBGT	8'h58
`define LBLE	8'h59
`define LBGE	8'h5A
`define LBLT	8'h5B
`define LBHI	8'h5C
`define LBLS	8'h5D
`define LBHS	8'h5E
`define LBLO	8'h5F

`define JSR_RN	8'h60
`define JSR_IX	8'h61
`define TRAPV	8'h62
`define RTS		8'h63
`define RTI		8'h64
`define RTD		8'h65
`define SWE		8'b0110011x
`define BRZ		8'h68
`define BRNZ	8'h69
`define BRMI	8'h6A
`define BRPL	8'h6B
`define DBNZ	8'h6C
`define SWE3	8'h6D
`define BSR16	8'h6E
`define JSP		8'h6F

`define BSR24	8'h70
`define JSR16	8'h71
`define JSR24	8'h72
`define JMP16	8'h73
`define JMP24	8'h74
`define JMP_RN	8'h75
`define JMP_IX	8'h76
`define JGR		8'h77
`define JGRR	8'h78
`define JSPR	8'h79

`define LB		8'h80
`define LBU		8'h81
`define LC		8'h82
`define LCU		8'h83
`define LH		8'h84
`define LHU		8'h85
`define LW		8'h86
`define LEA		8'h87
`define LBX		8'h88
`define LBUX	8'h89
`define LCX		8'h8A
`define LCUX	8'h8B
`define LHX		8'h8C
`define LHUX	8'h8D
`define LWX		8'h8E
`define LEAX	8'h8F

`define LB4		8'h90
`define LBU4	8'h91
`define LC4		8'h92
`define LCU4	8'h93
`define LH4		8'h94
`define LHU4	8'h95
`define LW4		8'h96
`define LxDT	8'h98

`define SB		8'hA0
`define SC		8'hA1
`define SH		8'hA2
`define SW		8'hA3
`define CINV	8'hA4
`define PUSH	8'hA6
`define POP		8'hA7
`define SBX		8'hA8
`define SCX		8'hA9
`define SHX		8'hAA
`define SWX		8'hAB
`define CINVX	8'hAC
`define PUSHC8	8'hAD
`define CAS		8'hAE

`define SB4		8'hB0
`define SC4		8'hB1
`define SH4		8'hB2
`define SW4		8'hB3
`define SWS		8'hB4
`define LWS		8'hB5
`define PUSHS	8'hB6
`define POPS	8'hB7
`define SxDT	8'hB8

`define PUSHC16	8'hBD

`define NOP		8'hEA

`define IMM1	8'hF1
`define IMM2	8'hF2
`define IMM3	8'hF3
`define IMM4	8'hF4
`define IMM5	8'hF5
`define IMM6	8'hF6
`define IMM7	8'hF7
`define IMM8	8'hF8
`define CLI		8'hFA
`define SEI		8'hFB

`define STW_NONE	4'd0
`define STW_CS	4'd1
`define STW_PC	4'd2
`define STW_A	4'd3
`define STW_B	4'd4
`define STW_C	4'd5
`define STW_SR	4'd6
`define STW_SPR	4'd8
`define STW_IMM	4'd9
`define STW_IDT	4'd10
`define STW_GDT	4'd11
`define STW_SRCS	4'd12

`define TICK		6'h00
`define VBR			6'h01
`define BEAR		6'h02
`define PTA			6'h04
`define CR0			6'h05
`define CLK			6'h06
`define SR			6'h07
`define FAULT_PC	6'h08
`define FAULT_CS	6'h09
`define IVNO		6'h0C
`define HISTORY		6'h0D
`define BITERR_CNT	6'h0E
`define BITHIST		6'h0F
`define SRAND1		6'h10
`define SRAND2		6'h11
`define RAND		6'h12
`define PROD_HIGH	6'h13
`define SEGS		6'h2x

`endif
