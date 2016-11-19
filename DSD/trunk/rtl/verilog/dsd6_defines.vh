// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DSD6_defines.v
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
// ============================================================================
//
`ifndef BRK

`define TRUE      1'b1
`define FALSE     1'b0

`define BRK0    7'h00
`define BRK1    7'h01
`define BccI    7'h02
`define BccUI   7'h03
`define ADDI    7'h04
`define CMPI    7'h05
`define CMPUI   7'h06
`define ANDI    7'h08
`define ORI     7'h09
`define EORI    7'h0A
`define CSRI    7'h0F
`define R2      7'h30
`define R3      7'h31
`define BITFLD  7'h32
`define JMP     7'h34
`define CALL    7'h34
`define Bcc     7'h36
`define BccU    7'h37
`define LDT     7'h38
`define CSR     7'h3F
`define LB      7'h40
`define LBU     7'h41
`define LC      7'h42
`define LCU     7'h43
`define LH      7'h44
`define LHU     7'h45
`define LW      7'h46
`define LWR     7'h47
`define SB      7'h48
`define SC      7'h49
`define SH      7'h4A
`define SW      7'h4B
`define SWC     7'h4C
`define HUFFMAN 7'b1010xxx
`define NOP     7'h58
`define RET     7'h59
`define MEM     7'h5A
`define SYS     7'h5C
`define BRK20   7'h5E
`define BRK21   7'h5F
`define MULI    7'h60
`define MULUI   7'h61
`define MULSUI  7'h62
`define MULHI   7'h63
`define MULUHI  7'h64
`define MULSUHI 7'h65
`define DIVI    7'h68
`define DIVUI   7'h69
`define DIVSUI  7'h6A
`define REMI    7'h6B
`define REMUI   7'h6C
`define REMSUI  7'h6D
`define WAI     7'h7C

// R2 ops
`define WFI     7'h01
`define ADD     7'h04
`define CMP     7'h05
`define CMPU    7'h06
`define SUB     7'h07
`define AND     7'h08
`define OR      7'h09
`define EOR     7'h0A
`define NAND    7'h0C
`define NOR     7'h0D
`define ENOR    7'h0E
`define R2CSRI  7'h0F
`define SHL     7'h10
`define SHR     7'h11
`define ASR     7'h12
`define ROL     7'h13
`define ROR     7'h14
`define SHLI    7'h18
`define SHRI    7'h19
`define ASRI    7'h1A
`define ROLI    7'h1B
`define RORI    7'h1C
`define R2CSR   7'h3F
`define LBX     7'h40
`define LBUX    7'h41
`define LCX     7'h42
`define LCUX    7'h43
`define LHX     7'h44
`define LHUX    7'h45
`define LWX     7'h46
`define LWRX    7'h47
`define SBX     7'h48
`define SCX     7'h49
`define SHX     7'h4A
`define SWX     7'h4B
`define SWCX    7'h4C
`define NOP2    7'h58
`define MUL     7'h60
`define MULU    7'h61
`define MULSU   7'h62
`define MULH    7'h63
`define MULUH   7'h64
`define MULSUH  7'h65
`define DIV     7'h68
`define DIVU    7'h69
`define DIVSU   7'h6A
`define REM     7'h6B
`define REMU    7'h6C
`define REMSU   7'h6D
`define RTE     7'h72
`define REX     7'h73

// Bcc ops
`define BEQ     3'h0
`define BNE     3'h1
`define BLT     3'h4
`define BGE     3'h5
`define BLE     3'h6
`define BGT     3'h7
`define BLTU    3'h4
`define BGEU    3'h5
`define BLEU    3'h6
`define BGTU    3'h7

// BccI ops
`define BEQI    3'h0
`define BNEI    3'h1
`define BLTI    3'h4
`define BGEI    3'h5
`define BLEI    3'h6
`define BGTI    3'h7
`define BLTUI   3'h4
`define BGEUI   3'h5
`define BLEUI   3'h6
`define BGTUI   3'h7

// Bit-field ops
`define BFSET     3'd0
`define BFCLR     3'd1
`define BFCHG     3'd2 
`define BFINS     3'd3
`define BFINSI    3'd4
`define BFEXT     3'd5
`define BFEXTU    3'd6

// Mem ops
`define LTCB    4'h0
`define STCB    4'h1
`define PUSH    4'h2
`define POP     4'h3
`define JMPR    4'h4
`define CALLR   4'h5

// SYS ops
`define IRET        4'd2
`define IPUSH       4'd4
`define IPOP        4'd5
`define SYNC        4'd7
`define MEMSB       4'd8
`define MEMDB       4'd9
`define CLI         4'd10
`define SEI         4'd11
`define WAI         4'd12

`define CSRRW     2'b00
`define CSRRS     2'b01
`define CSRRC     2'b10

`define CSR_HARTID  11'h001
`define CSR_TICK    11'h002
`define CSR_PTA     11'h003
`define VBA     11'h004
`define CAUSE   11'h006
`define BADADDR 11'h007
`define ETR     11'h008
`define CSR_SCRATCH     11'h009
`define CSR_LC1         11'h00A
`define CSR_LC2         11'h00B
`define CSR_LC3         11'h00C
`define SP      11'h00D
`define CSR_SBL         11'h00E
`define CSR_SBU         11'h00F
`define TR      11'h010
`define CSR_CISC        11'h011
`define CSR_STATUS      11'h012
`define CSR_INSRET      11'h013
`define CSR_TIME        11'h014
`define CSR_CS_BASE     11'h020
`define CSR_CS_LIMIT    11'h021
`define CSR_CS_ACR      11'h022
`define CSR_DS_BASE     11'h023
`define CSR_DS_LIMIT    11'h024
`define CSR_DS_ACR      11'h025
`define CSR_ES_BASE     11'h026
`define CSR_ES_LIMIT    11'h027
`define CSR_ES_ACR      11'h028
`define CSR_FS_BASE     11'h029
`define CSR_FS_LIMIT    11'h02A
`define CSR_FS_ACR      11'h02B
`define CSR_GS_BASE     11'h02C
`define CSR_GS_LIMIT    11'h02D
`define CSR_GS_ACR      11'h02E
`define CSR_HS_BASE     11'h02F
`define CSR_HS_LIMIT    11'h030
`define CSR_HS_ACR      11'h031
`define CSR_JS_BASE     11'h032
`define CSR_JS_LIMIT    11'h033
`define CSR_JS_ACR      11'h034
`define CSR_EPC         11'h040
`define CSR_ECS_BASE    11'h041
`define CSR_ECS_LIMIT   11'h042
`define CSR_ECS_ACR     11'h043
`define CSR_ER1         11'h044
`define CSR_ER2         11'h045
`define CSR_ER29        11'h046
`define CSR_EFLAGS      11'h047
`define CSR_CONFIG      11'h7F0

// Exception vector numbers
`define FLT_UNIMPINSN       9'd487
`define FLT_PAGENOTPRESENT  9'd496
`define FLT_EXEC            9'd497
`define SEG_BOUNDS          9'd500
`define FLT_SEGBOUNDS       9'd500
`define PRIV                9'd501
`define FLT_PRIV            9'd501
`define STACK_FAULT         9'd504
`define FLT_STACK           9'd504
`define FLT_CODEPAGE        9'd505
`define FLT_DATAPAGE        9'd506

// Machine operating levels
`define OL_MACHINE    2'b00
`define OL_HYPERVISOR 2'b01
`define OL_SUPERVISOR 2'b10
`define OL_USER       2'b11

`define _2NOPINSN {9'h00,`NOP,9'h0,`NOP}
`define WFI_INSN  {`WFI,18'h0,`R2}

`endif
