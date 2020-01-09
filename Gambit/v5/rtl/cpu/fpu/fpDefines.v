// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2020  Robert Finch, Waterloo
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
//
//	fp_defines.v
// ============================================================================
//

`define	QINFOS		23'h7FC000		// info
`define QSUBINF		4'd1
`define QINFDIV		4'd2
`define QZEROZERO	4'd3
`define QINFZERO	4'd4
`define QSQRTINF	4'd5
`define QSQRTNEG	4'd6

`define	QSUBINFS	31'h7FC00001	// - infinity - infinity
`define QINFDIVS	31'h7FC00002	// - infinity / infinity
`define QZEROZEROS	31'h7FC00003	// - zero / zero
`define QINFZEROS	31'h7FC00004	// - infinity X zero
`define QSQRTINF	31'h7FC00005	// - square root of infinity
`define QSQRTNEG	31'h7FC00006	// - square root of negaitve number

`define	QINFO52			41'h1FF00000000		// info
`define	QSUBINF52 	51'h7FF0000000001	// - infinity - infinity
`define QINFDIV52 	51'h7FF0000000002	// - infinity / infinity
`define QZEROZERO52 51'h7FF0000000003	// - zero / zero
`define QINFZERO52	51'h7FF0000000004	// - infinity X zero
`define QSQRTINF52	51'h7FF0000000005	// - square root of infinity
`define QSQRTNEG52	51'h7FF0000000006	// - square root of negaitve number

`define	QINFOD		52'hFF80000000000		// info
`define	QSUBINFD 	63'h7FF0000000000001	// - infinity - infinity
`define QINFDIVD 	63'h7FF0000000000002	// - infinity / infinity
`define QZEROZEROD  63'h7FF0000000000003	// - zero / zero
`define QINFZEROD	63'h7FF0000000000004	// - infinity X zero
`define QSQRTINFD	63'h7FF0000000000005	// - square root of infinity
`define QSQRTNEGD	63'h7FF0000000000006	// - square root of negaitve number

`define	QINFODX		64'hFF800000_00000000		// info
`define	QSUBINFDX 	79'h7FFF000000_0000000001	// - infinity - infinity
`define QINFDIVDX 	79'h7FFF000000_0000000002	// - infinity / infinity
`define QZEROZERODX 79'h7FFF000000_0000000003	// - zero / zero
`define QINFZERODX	79'h7FFF000000_0000000004	// - infinity X zero
`define QSQRTINFDX	79'h7FFF000000_0000000005	// - square root of infinity
`define QSQRTNEGDX	79'h7FFF000000_0000000006	// - square root of negaitve number

`define	QINFOQ		112'hFF800000_0000000000_0000000000		// info
`define	QSUBINFQ 	127'h7F_FF00000000_0000000000_0000000001	// - infinity - infinity
`define QINFDIVQ 	127'h7F_FF00000000_0000000000_0000000002	// - infinity / infinity
`define QZEROZEROQ  127'h7F_FF00000000_0000000000_0000000003	// - zero / zero
`define QINFZEROQ	127'h7F_FF00000000_0000000000_0000000004	// - infinity X zero
`define QSQRTINFQ	127'h7F_FF00000000_0000000000_0000000005	// - square root of infinity
`define QSQRTNEGQ	127'h7F_FF00000000_0000000000_0000000006	// - square root of negaitve number

`define	POINT5S		32'h3F000000
`define POINT5SX	40'h3F80000000
`define POINT5D		64'h3FE0000000000000
`define POINT5DX	80'h3FFE0000000000000000
`define ZEROS			32'h00000000
`define ZEROSX		40'h0000000000
`define ZERO52		52'h0000000000000
`define ZEROD			64'h0000000000000000
`define ZERODX		80'h00000000000000000000

`define AIN			3'd0
`define BIN			3'd1
`define CIN			3'd2
`define RES			3'd3
`define POINT5	3'd4
`define ZERO		3'd5


