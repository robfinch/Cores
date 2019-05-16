// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	null_driver.c
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

private pascal void null_init()
{
}

private pascal int null_stat(int handle)
{
	return (0);
}

private pascal int null_peek(int handle)
{
	return (0);
}

private pascal int null_get(int handle)
{
	return (0);
}

private pascal void null_put(int handle,int val)
{
}

private pascal void null_flushi(int handle)
{
}

pascal int null_CmdProc(int cmd, int cmdParm1, int cmdParm2, int cmdParm3, int cmdParm4)
{
	int val;
	int err = E_Ok;

	switch(cmd) {
	case DVC_GetUnit:
		val = null_get(cmdParm1);
		*(int *)cmdParm2 = val;
		break;
	case DVC_PutUnit:
		null_put(cmdParm1,cmdParm2);
		break;
	case DVC_PeekUnit:
		val = null_peek(cmdParm1);
		*(int *)cmdParm2 = val;
		break;
	case DVC_Open:
		if (cmdParm4)
			*(int *)cmdParm4 = 0;
		else
			err = E_Arg;
		break;
	case DVC_Close:
		null_flushi(cmdParm1);
		break;
	case DVC_Status:
		*(int *)cmdParm2 = null_stat(cmdParm1);
		break;
	case DVC_Nop:
		break;
	case DVC_Setup:
		DBGDisplayStringCRLF("NULL setup");
		break;
	case DVC_Initialize:
		null_init();
		break;
	case DVC_FlushInput:
		null_flushi(cmdParm1);
		break;
	case DVC_IsRemoveable:
		*(int *)cmdParm1 = 0;
		break;
	default:
		return err = E_BadDevOp;
	}
	return (err);
}
