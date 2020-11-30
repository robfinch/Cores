// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2020  Robert Finch, Waterloo
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
#include <RTF64\io.h>

#define PIC             0xFFFFFFFFFFDC0F00L
#define PIC_IE          0xFFFFFFFFFFDC0F04L
#define PIC_ES          0xFFFFFFFFFFDC0F10L
#define PIC_RSTE        0xFFFFFFFFFFDC0F14L
#define PIC_I28			0xFFFFFFFFFFDC0FF0L
#define PIC_I29			0xFFFFFFFFFFDC0FF4L
#define PIC_I30			0xFFFFFFFFFFDC0FF8L
#define PIC_I31			0xFFFFFFFFFFDC0FFCL

// ----------------------------------------------------------------------------
// 0 is highest priority, 31 is lowest
// 0    NMI (parity error)
// 1    Keyboard reset button
// ...
// 28 keyboard interrupt 
// 29 garbage collector stop
// 30	garbage collector
// 31 60Hz timer interrupt
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

	// - cause 156
	// - interrupt level 2 (low priority)
	// - edge sensitive
	// - disabled
  out32(PIC_I28, 0x2029C);
	// - cause 157
	// - interrupt level 3 (low priority)
	// - edge sensitive
	// - disabled
  out32(PIC_I29, 0x2039D);
	// - cause 158
	// - interrupt level 2 (low priority)
	// - edge sensitive
	// - disabled
  out32(PIC_I30, 0x2029E);
	// - cause 159
	// - interrupt level 1 (lowest priority)
	// - edge sensitive
	// - disabled
  out32(PIC_I31, 0x2019F);		// time slice interrupt(s) are edge sensitive
  if (getCPU()==0x1)
    out32(PIC_IE, 0x00000000);  //enable keyboard reset, timer interrupts
  else
   	// - enable keyboard irq
   	// - enable garbage collection irq
   	// - enable time slice irq
    out32(PIC_IE, 0xF0000000);  //enable keyboard reset, timer interrupts
}
