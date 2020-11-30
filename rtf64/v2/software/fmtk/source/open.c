// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	open.c
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

int open(char *name, int p1, int p2)
{
	int n, j;
	int handle;
	DCB *p;
	int d1,d2,d3;

	// Search the device table for a device with the requested name	
	p = &DeviceTable[0];
	for (n = 0; n < NR_DCB; n++, p++) {
		for (j = 0; j < p->name[0]; ) {
			if (name[j] != p->name[++j])
				goto j1;
		}
		if (name[j]!='/' && name[j]!='\0')
			goto j1;
		// Found device name
		p = &DeviceTable[n];
		handle = n << 16;
		FMTK_SendMsg(p->hSendMbx, handle | DVC_Open, &name[++j], p1);
		FMTK_WaitMsg(p->hRcvMbx, &d1, &d2, &d3, 100000);
		p->LastErc = d1;
		handle = d2;
		//p->LastErc = (*(p->CmdProc))(DVC_Open,&name[++j],p1,p2,&handle);
		if (p->LastErc==E_Ok)
			return ((n << 16) | (handle & 0xffff));
		return (E_Failed);
j1:	;
	}
	return (E_FileNotFound);
}
