// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	pti_driver.c
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
#include <fmtk/const.h>
#include <fmtk/device.h>
#include <ft64/io.h>

#define PTI				0xFFFFFFFFFFDC1200L
#define PTI_DAT		0x0
#define PTI_RST		0x1
#define PTI_RCL		0x2
#define PTI_RCH		0x3
#define PTI_WCL		0x4
#define PTI_WCH		0x5
#define PTI_TRG		0x6
#define XON				0x11
#define XOFF			0x13

pascal void pti_init()
{
	out8(PTI|PTI_RST,0);	// Trigger fifo reset, turn off loopback
}

pascal int pti_stat(int handle)
{
	int stat;

	// A write of any value to the RCL register will latch the
	// fifo status of both input and output fifo's.
	out8(PTI|PTI_RCL,0);
	stat  = (in8u(PTI | PTI_RCL));
	stat |= (in8u(PTI | PTI_RCH) << 8);
	stat |= (in8u(PTI | PTI_WCL) << 16);
	stat |= (in8u(PTI | PTI_WCH) << 24);
	return (stat);
}

pascal int pti_peek(int handle)
{
	int val;

	val = in8u(PTI|PTI_DAT);
	return (val);
}


pascal int pti_get(int handle)
{
	int val;

	val = in8u(PTI|PTI_DAT);
	out8(PTI|PTI_TRG,0);
	return (val);
}

pascal void pti_put(int handle,int val)
{
	out8(PTI|PTI_DAT,val);
}

// The fifo is 4kB in size. Potentially it could be full.

pascal void pti_flushi(int handle)
{
	int stat;

	stat = pti_stat();
	while ((stat & 0x8000) == 0) {
		pti_get();
		stat = pti_stat();
	}
}

pascal int pti_CmdProc(int cmd, int cmdParm1, int cmdParm2, int cmdParm3, int cmdParm4)
{
	int val;
	int err = E_Ok;

	switch(cmd) {
	case DVC_GetUnit:
		val = pti_get(cmdParm1);
		*(int *)cmdParm2 = val;
		break;
	case DVC_PutUnit:
		pti_put(cmdParm1,cmdParm2);
		break;
	case DVC_PeekUnit:
		val = pti_peek(cmdParm1);
		*(int *)cmdParm2 = val;
		break;
	case DVC_Open:
		pti_put(XON);
		if (cmdParm4)
			*(int *)cmdParm4 = 0;
		else
			err = E_Arg;
		break;
	case DVC_Close:
		pti_flushi(cmdParm1);
		break;
	case DVC_Status:
		*(int *)cmdParm2 = pti_stat(cmdParm1);
		break;
	case DVC_Nop:
		break;
	case DVC_Setup:
		DBGDisplayAsciiStringCRLF(B"PTI setup");
		break;
	case DVC_Initialize:
		pti_init();
		break;
	case DVC_FlushInput:
		pti_flushi(cmdParm1);
		break;
	case DVC_IsRemoveable:
		*(int *)cmdParm1 = 1;
		break;
	default:
		return err = E_BadDevOp;
	}
	return (err);
}
