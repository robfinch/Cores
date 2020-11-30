// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	read.c
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
#include <fmtk/proto.h>

int read(int handle, __int8 *buf, int count)
{
	DCB *p;
	int devnum = (handle >> 16) & 0x1f;
	int d1,d2,d3;
	hMBX hMbxSend, hMbxRcv;

	p = DeviceTable[devnum];
	hMbxSend = p->hMbxSend;
	hMbxRcv = p->hMbxRcv;

	switch(p->type) {
	case DVT_Block:
    FMTK_SendMsg(hMbxSend, ((handle & 0xffff) << 16)|DVC_ReadBLock, (int)buf, count);
    FMTK_WaitMsg(hMbxRcv, &d1, &d2, &d3, 100000);
    p->LastErc = d1;
		//p->LastErc = (*(p->CmdProc))(DVC_ReadBlock,handle & 0xffff,buf,count,0);
		break;
	case DVT_Unit:
		for (; count > 0; count--) {
      FMTK_SendMsg(hMbxSend, ((handle & 0xffff) << 16)|DVC_GetUnit, (int)buf, 0);
      FMTK_WaitMsg(hMbxRcv, &d1, &d2, &d3, 100000);
      p->LastErc = d1;
			//p->LastErc = (*(p->CmdProc))(DVC_GetUnit,handle & 0xffff,buf,0,0);
			buf += p->UnitSize;
			if (p->LastErc < 0)
				break;
		}
		break;
	default:
		return (E_BadDevNum);
	}
	return (p->LastErc < 0 ? E_Failed : E_Ok);
}
