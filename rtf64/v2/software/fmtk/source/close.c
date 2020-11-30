// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	close.c
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
#include <fmtk/config.h>
#include <fmtk/device.h>

int close(int handle)
{
	DCB *p;
  int d1,d2,d3;

	p = &DeviceTable[(handle >> 16) & 0x1f];
	FMTK_SendMsg(p->hSendMbx, DVC_Close, handle & 0xffff, 0);
  FMTK_WaitMsg(p->hRcvMbx, &d1, &d2, &d3, 100000);
  p->LastErc = d1;	
//	if (p->CmdProc)
//		p->LastErc = (*(p->CmdProc))(DVC_Close,handle & 0xffff,0,0,0);
//	else
//		return (E_Failed);
	return (E_Ok);
}
