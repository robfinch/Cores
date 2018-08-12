// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2018  Robert Finch, Waterloo
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
#include "..\..\..\c64libc\source\FT64\io.h"

#define PIC             0xFFDC0F00
#define PIC_IE          0xFFDC0F04
#define PIC_ES          0xFFDC0F10
#define PIC_RSTE        0xFFDC0F14
#define PIC_I29			0xFFDC0FF4
#define PIC_I30			0xFFDC0FF8
#define PIC_I31			0xFFDC0FFC

// ----------------------------------------------------------------------------
// 0 is highest priority, 31 is lowest
// 0    NMI (parity error)
// 1    Keyboard reset button
// ...
// 29   keyboard interrupt 
// 30	garbage collector
// 31   60Hz timer interrupt
// 
// 
// ----------------------------------------------------------------------------

void InitPIC()
{
	int n;

	// Default Everything:
	// - level sensitive
	// - irq disabled
	// - interrupt level 4
	//	- cause 0
	for (n = 0; n < 32; n = n + 1)
		out32(PIC+0x80+(n<<2),0x400);
//     out32(PIC_ES, 0x4000000C);  	

	// - cause 29
	// - interrupt level 2 (low priority)
	// - edge sensitive
	// - disabled
    out32(PIC_I29, 0x2021D);
	// - cause 30
	// - interrupt level 2 (low priority)
	// - edge sensitive
	// - disabled
    out32(PIC_I30, 0x2021E);
	// - cause 31
	// - interrupt level 1 (lowest priority)
	// - edge sensitive
	// - disabled
    out32(PIC_I31, 0x2011F);		// time slice interrupt(s) are edge sensitive
    if (getCPU()==0x1)
        out32(PIC_IE, 0x00000000);  //enable keyboard reset, timer interrupts
    else
     	// - enable keyboard irq
     	// - enable garbage collection irq
     	// - enable time slice irq
        out32(PIC_IE, 0xE0000000);  //enable keyboard reset, timer interrupts
}
