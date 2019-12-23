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

`define ADD_3R		6'o00
`define ADD_I23		6'o01
`define ADD_I36		6'o02
`define JMP				6'o04
`define ASL_3R		6'o06
`define SUB_3R		6'o10
`define SUB_I23		6'o11
`define SUB_I36		6'o12
`define JSR				6'o14
`define LSR_3R		6'o16
`define RETGRP		6'o24
`define RTS					3'd0
`define RTI					3'd1
`define PFI					3'd2
`define WAI					3'd4
`define STP					3'd6
`define NOP					3'd7
`define ROL_3R		6'o26
`define AND_3R		6'o30
`define AND_I23		6'o31
`define AND_I36		6'o32
`define BRKGRP		6'o34
`define RST					3'd0
`define NMI					3'd1
`define IRQ					3'd2
`define BRK					3'd3
`define ROR_3R		6'o36
`define OR_3R			6'o40
`define OR_I23		6'o41
`define OR_I36		6'o42
`define JMP_RN		6'o44
`define SEP				6'o46
`define EOR_3R		6'o50
`define EOR_I23		6'o51
`define EOR_I36		6'o52
`define JSR_RN		6'o54
`define REP				6'o56
`define LD_D9			6'o60
`define LD_D23		6'o61
`define LD_D36		6'o62
`define LDB_D36		6'o64
`define PLP				6'o65
`define POP				6'o66
`define ST_D9			6'o70
`define ST_D23		6'o71
`define ST_D36		6'o72
`define STB_D36		6'o74
`define PHP				6'o75
`define PSH				6'o76
`define BccD4a		6'o05
`define BccD4b		6'o25
`define BccD17a		6'o15
`define BccD17b		6'o35

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

`define OPCODE		5:0
`define RT				10:6
`define RA				15:11
`define RB				20:16

`define DRAMSLOT_AVAIL	3'b000
`define DRAMSLOT_BUSY		3'b001
`define DRAMSLOT_RMW		3'b010
`define DRAMSLOT_RMW2		3'b011
`define DRAMSLOT_REQBUS	3'b101
`define DRAMSLOT_HASBUS	3'b110
`define DRAMREQ_READY		3'b111


`define IB_CMP		0
`define IB_SRC1		4:1
`define IB_SRC2		8:5
`define IB_DST		12:9
`define IB_BT			13
`define IB_ALU		14
`define IB_FC			15
`define IB_LOAD		16
`define IB_STORE	17
`define IB_MEMSZ	18
`define IB_MEM		19
`define IB_JMP		20
`define IB_BR			21
`define IB_RFW		22
`define IB_NEED_SR	23
`define IBTOP		24
