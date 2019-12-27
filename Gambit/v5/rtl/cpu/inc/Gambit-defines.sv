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
`define TRUE			1'b1
`define FALSE			1'b0
`define VAL				1'b1
`define INV				1'b0
`define HIGH			1'b1
`define LOW				1'b0

`define CSR				7'h01
`define ADD_3R		7'h04
`define ADD_RI22	7'h14
`define ADD_RI35	7'h24
`define ADDIS			7'h23
`define ASL_3R		7'h0C
`define ASR_3R		7'h2D
`define SUB_3R		7'h05
`define SUB_RI22	7'h15
`define SUB_RI35	7'h25
`define CMP_3R		7'h06
`define CMP_RI22	7'h16
`define CMP_RI35	7'h26
`define CMPU_3R		7'h07
`define CMPU_RI22	7'h17
`define CMPU_RI35	7'h27
`define MUL_3R		7'h0E
`define MUL_RI22	7'h1E
`define MUL_RI35	7'h2E
`define PERM_3R		7'h20
`define LSR_3R		7'h0D
`define BRANCH0		7'h40
`define BRANCH1		7'h41
`define JAL				7'h42
`define RETGRP		7'h44
`define RET					2'd0
`define RTI					2'd1
`define WAIGRP		7'h02
`define PFI				9'h002
`define WAI				9'h102
`define STPGRP		7'h43
`define STP					2'd0
`define NOP					2'd1
`define MRK					2'd2
`define ROL_3R		7'h1C
`define AND_3R		7'h08
`define AND_RI22	7'h18
`define AND_RI35	7'h28
`define ANDIS			7'h22
`define BIT_3R		7'h55
`define BIT_RI22	7'h65
`define BIT_RI35	7'h75
`define BRKGRP		7'o34
`define RST					3'd0
`define NMI					3'd1
`define IRQ					3'd2
`define BRK					3'd3
`define ROR_3R		7'h1D
`define OR_3R			7'h09
`define OR_RI22		7'h19
`define OR_RI35		7'h29
`define ORIS			7'h2C
`define JAL_RN		7'h48
`define EOR_3R		7'h0A
`define EOR_RI22	7'h1A
`define EOR_RI35	7'h2A
`define LD_D8			7'h50
`define LD_D22		7'h60
`define LD_D35		7'h70
`define LDB_D8		7'h51
`define LDB_D22		7'h61
`define LDB_D35		7'h71
`define ST_D8			7'h58
`define ST_D22		7'h68
`define ST_D35		7'h78
`define STB_D8		7'h59
`define STB_D22		7'h69
`define STB_D35		7'h79
`define SEQ_3R		7'h4C
`define BNE_3R		7'h5C
`define SLT_3R		7'h4D
`define SLE_3R		7'h5D
`define SLTU_3R		7'h6D
`define SLEU_3R		7'h7D
`define MTx				7'h4A
`define MFx				7'h5A

`define UO_ADD		6'd0
`define UO_ADDu		6'd1
`define UO_SUB		6'd2
`define UO_SUBu		6'd3
`define UO_ANDu		6'd4
`define UO_ORu		6'd5
`define UO_EORu		6'd6
`define UO_LD			6'd7
`define UO_LDu		6'd8
`define UO_LDB		6'd9
`define UO_LDBu		6'd10
`define UO_ST			6'd11
`define UO_STB		6'd12
`define UO_ASLu		6'd13
`define UO_ROLu		6'd14
`define UO_LSRu		6'd15
`define UO_RORu		6'd16
`define UO_BRA		6'd17
`define UO_BEQ		6'd18
`define UO_BNE		6'd19
`define UO_BMI		6'd20
`define UO_BPL		6'd21
`define UO_BCS		6'd22
`define UO_BCC		6'd23
`define UO_BVS		6'd24
`define UO_BVC		6'd25
`define UO_SEP		6'd26
`define UO_REP		6'd27
`define UO_JMP		6'd28
`define UO_STP		6'd29
`define UO_WAI		6'd30
`define UO_CAUSE	6'd31
`define UO_BUC		6'd32
`define UO_BUS		6'd33
`define UO_JSI		6'd34
`define UO_NOP		6'd35

`define UOF_I			7'b0010000

`define OPCODE		6:0
`define RT				11:7
`define RA				16:12
`define RB				21:17

`define DRAMSLOT_AVAIL	3'b000
`define DRAMSLOT_BUSY		3'b001
`define DRAMSLOT_RMW		3'b010
`define DRAMSLOT_RMW2		3'b011
`define DRAMSLOT_REQBUS	3'b101
`define DRAMSLOT_HASBUS	3'b110
`define DRAMREQ_READY		3'b111


`define IB_CMP		0
`define IB_BT			13
`define IB_ALU		14
`define IB_FC			15
`define IB_LOAD		16
`define IB_STORE	17
`define IB_MEMSZ	18
`define IB_MEM		19
`define IB_JAL		20
`define IB_BR			21
`define IB_RFW		22
`define IB_CONST	73:23
`define IBTOP		74
