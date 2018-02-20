// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
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
//#define PIT             0xFFDC1100
//#define PIT_MAXCNT0		0x04
//#define PIT_ONTIME0		0x08
//#define PIT_CONTROL		0x0C
//#define PIT_MAXCNT1		0x14
//#define PIT_ONTIME1		0x18
//#define PIT_MAXCNT2		0x24
//#define PIT_ONTIME2		0x28

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
		align	16
_InitPIT:
		ldi		r2,#$FFDC1100
		ldi		r1,#333333		// 20MHz / 60 Hz
		sh		r1,$04[r2]
		ldi		r1,#20			// 20 cycles on
		sh		r1,$08[r2]
		ldi		r1,#111111		// 180 Hz
		sh		r1,$14[r2]
		ldi		r1,#20
		sh		r1,$18[r2]		// 20 cycles on
//		0 = 1 = load, automatically clears
//	    1 = 1 = enable counting, 0 = disable counting
//		2 = 1 = auto-reload on terminal count, 0 = no reload
//		3 = 1 = use external clock, 0 = internal clk_i
//      4 = 1 = use gate to enable count, 0 = ignore gate
		ldi		r1,#$000707
		sh		r1,$0C[r2]
		ret
