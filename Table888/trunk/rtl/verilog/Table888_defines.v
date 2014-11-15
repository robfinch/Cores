// ============================================================================
// Table888_defines.v
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
`ifndef TABLE888_DEFINES
`define TABLE888_DEFINES	1'b1

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
`define R		8'h01
`define SWAP		8'h03
`define MOV			8'h04
`define NEG			8'h05
`define COM			8'h06
`define NOT			8'h07
`define SXB			8'h08
`define SXC			8'h09
`define SXH			8'h0A
`define MOVS		8'h0E
`define LSL			8'h10
`define LAR			8'h11
`define LSB			8'h12
`define GRAN		8'h14
`define CPUID		8'h2A
`define SEI			8'h30
`define CLI			8'h31
`define PHP			8'h32
`define PLP			8'h33
`define ICON		8'h34
`define ICOFF		8'h35
`define CLP			8'h37
`define RTI			8'h40
`define STP			8'h41
`define MTSPR		8'h48
`define MFSPR		8'h49
`define VERR		8'h80
`define VERW		8'h81
`define VERX		8'h82
`define MRK1		8'hF0
`define MRK2		8'hF1
`define MRK3		8'hF2
`define MRK4		8'hF3
`define RR		8'h02
`define ADD			8'h04
`define SUB			8'h05
`define CMP			8'h06
`define MUL			8'h07
`define DIV			8'h08
`define MOD			8'h09
`define ADDU		8'h14
`define SUBU		8'h15
`define MULU		8'h17
`define DIVU		8'h18
`define MODU		8'h19
`define ADC			8'h1A
`define SBC			8'h1B
`define AND			8'h20
`define OR			8'h21
`define EOR			8'h22
`define ANDN		8'h23
`define NAND		8'h24
`define NOR			8'h25
`define ENOR		8'h26
`define ORN			8'h27
`define MSO			8'h28
`define SSO			8'h29
`define ARPL		8'h38
`define SHLI		8'h50
`define ROLI		8'h51
`define SHRI		8'h52
`define RORI		8'h53
`define ASRI		8'h54
`define SHL			8'h40
`define ROL			8'h41
`define SHR			8'h42
`define ROR			8'h43
`define ASR			8'h44
`define	SEQ			8'h60
`define SNE			8'h61
`define SGT			8'h68
`define SLE			8'h69
`define SGE			8'h6A
`define SLT			8'h6B
`define SHI			8'h6C
`define SLS			8'h6D
`define SHS			8'h6E
`define SLO			8'h6F
`define BITFIELD	8'h03
`define ADDI	8'h04
`define SUBI	8'h05
`define CMPI	8'h06
`define MULI	8'h07
`define DIVI	8'h08
`define MODI	8'h09
`define ANDI	8'h0C
`define ORI		8'h0D
`define EORI	8'h0F
`define ADDUI	8'h14
`define SUBUI	8'h15
`define LDI		8'h16
`define MULUI	8'h17
`define DIVUI	8'h18
`define MODUI	8'h19
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
`define JMP		8'h50
`define JSR		8'h51
`define JMP_IX	8'h52
`define JSR_IX	8'h53
`define JMP_DRN	8'h54
`define JSR_DRN	8'h55
`define BSR		8'h56
`define JGR		8'h57
`define BRZ		8'h58
`define BRNZ	8'h59
`define DBNZ	8'h5A
`define JAL		8'h5B
`define RTS		8'h60
`define JSP		8'h61
`define LINK	8'h62
`define RTD		8'h63
`define UNLK	8'h64
`define LB		8'h80
`define LBU		8'h81
`define LC		8'h82
`define LCU		8'h83
`define LH		8'h84
`define LHU		8'h85
`define LW		8'h86
`define LWS		8'h87
`define LBX		8'h88
`define LBUX	8'h89
`define LCX		8'h8A
`define LCUX	8'h8B
`define LHX		8'h8C
`define LHUX	8'h8D
`define LWX		8'h8E
`define LEAX	8'h8F
`define LEA		8'h92
`define LMR		8'h9C
`define SB		8'hA0
`define SC		8'hA1
`define SH		8'hA2
`define SW		8'hA3
`define CINV	8'hA4
`define SWS		8'hA5
`define PUSH	8'hA6
`define POP		8'hA7
`define SBX		8'hA8
`define SCX		8'hA9
`define SHX		8'hAA
`define SWX		8'hAB
`define CINVX	8'hAC
`define PUSHC	8'hAD
`define CAS		8'hAE
`define BMS		8'hB4
`define BMC		8'hB5
`define BMF		8'hB6
`define BMT		8'hB7
`define SMR		8'hBC
`define NOP		8'hEA

`define IMM1	8'hFD
`define IMM2	8'hFE

`define STW_NONE	5'd0
`define STW_CS	5'd1
`define STW_PC	5'd2
`define STW_A	5'd3
`define STW_B	5'd4
`define STW_C	5'd5
`define STW_SR	5'd6
`define STW_SPR	5'd8
`define STW_IMM	5'd9
`define STW_CSPC	5'd10
`define STW_CSSR	5'd11
`define STW_STK_FIFO	5'd12
`define STW_PREV_CS		5'd13
`define STW_PREV_PC		5'd14
`define STW_SS		5'd15
`define STW_SP		5'd16
`define STW_PREV_CSSR	5'd17

`define TICK		8'h00
`define VBR			8'h01
`define BEAR		8'h02
`define PTA			8'h04
`define CR0			8'h05
`define CLK			8'h06
`define FAULT_PC	8'h08
`define FAULT_CS	8'h09
`define IVNO		8'h0C
`define HISTORY		8'h0D
`define BITERR_CNT	8'h0E
`define BITHIST		8'h0F
`define SRAND1		8'h10
`define SRAND2		8'h11
`define RAND		8'h12
`define PROD_HIGH	8'h13
`define LDT_REG		8'h18
`define GDT_REG		8'h19
`define SEGx		8'h2x

`define JGR_NONE		4'd0
`define JGR_LOAD_FIFO	4'd1
`define JGR_LOAD_SP		4'd2
`define JGR_LOAD_SS		4'd3
`define JGR_LOAD_CALLGATE	4'd4
`define JGR_LOAD_CS		4'd5
`define JGR_LOAD_SS_DESC	4'd6
`define JGR_STORE_FIFO	4'd7

`endif
