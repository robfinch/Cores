// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
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

extern __int8 pti_onoff;
extern int in8u(int port);
extern void out8(int port, int val);
extern void putnum(int, int, char, char);
extern void puthexnum(int, int, int, char);

void pti_init()
{
	pti_onoff = 0;				// off
	out8(PTI|PTI_RST,0);	// Trigger fifo reset
}

int pti_stat()
{
	int stat;

	// A write of any value to the RCL register will latch the
	// fifo status of both input and output fifo's.
	out8(PTI|PTI_RCL,0);
	stat = in8u(PTI|PTI_RCL) | (in8u(PTI|PTI_RCH) << 8)
				| (in8u(PTI|PTI_WCL) << 16) | (in8u(PTI|PTI_WCH) << 24);
	puthexnum(stat,8,1,'0');
	DBGDisplayChar('\r');
	return (stat);
}

int pti_get(int *abortt, int retries)
{
	int val;
	int stat;

	if (pti_onoff==0)
		pti_put(XON);
	for (; retries != 0; retries--) {
		stat = pti_stat();
		if (stat & 0xffff)	// Is there something to read?
			break;
	}
	out8(PTI|PTI_TRG,0);
	val = in8u(PTI|PTI_DAT);
	if (retries <= 0)
		val = -1;
	return (val);
}

void pti_put(int val)
{
	if (val==XON)
		pti_onoff = 1;
	else if (val==XOFF)
		pti_onoff = 0;
	out8(PTI|PTI_DAT,val);
}

// The fifo is 4kB in size. Potentially it could be full.
// An XOFF is sent back to the host to terminate transmission.

void pti_flushi()
{
	int stat;

	stat = pti_stat();
	while ((stat & 0xffff) != 0) {
		pti_get();
		stat = pti_stat();
		pti_put(XOFF);
	}
}

int pti_CmdProc(int cmd, int cmdParm1, int cmdParm2, int cmdParm3, int cmdParm4)
{
	int val;
	int err = E_Ok;

	switch(cmd) {
	case DVC_GetUnit:
		val = pti_get(0,100);
		*(int *)cmdParm1 = val;
		break;
	case DVC_PutUnit:
		pti_put(cmdParm1);
		break;
	case DVC_Open:
		pti_put(XON);
		if (cmdParm4)
			*(int *)cmdParm4 = 0;
		else
			err = E_Arg;
		break;
	case DVC_Close:
		pti_flushi();
		break;
	case DVC_Status:
		*(int *)cmdParm1 = pti_stat();
		break;
	case DVC_Nop:
		break;
	case DVC_Setup:
		break;
	case DVC_Initialize:
		pti_init();
		break;
	case DVC_FlushInput:
		pti_flushi();
		break;
	case DVC_IsRemoveable:
		*(int *)cmdParm1 = 1;
		break;
	default:
		return err = E_BadDevOp;
	}
	return (err);
}
