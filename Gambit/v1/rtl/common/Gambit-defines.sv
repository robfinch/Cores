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

`define ADD_3R		6'o00
`define ADD_I23		6'o01
`define ADD_I36		6'o02
`define JMP				6'o04
`define ASL_3R		6'o06
`define SUB_3R		6'o10
`define SUB_I23		6'o11
`define SUB_I36		6'o12
`define JSR				6'o14
`define LSR_R3		6'o16
`define RETGRP		6'o24
`define RTS					3'd0
`define RTI					3'd1
`define PFI					3'd2
`define WAI					3'd4
`define STP					3'd6
`define NOP					3'd7
`define ROL_R3		6'o26
`define AND_3R		6'o30
`define AND_I23		6'o31
`define AND_I36		6'o32
`define BRKGRP		6'o34
`define RST					3'd0
`define NMI					3'd1
`define IRQ					3'd2
`define BRK					3'd3
`define ROR_R3		6'o36
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

`define OPCODE		5:0
