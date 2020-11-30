// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	device.h
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
// Device command opcodes
//
#include <fmtk/config.h>

#define	DVC_Nop					0
#define DVC_Setup				1
#define DVC_Initialize	2
#define DVC_Status			3
#define DVC_MediaCheck	4
#define DVC_BuildBPB		5
#define DVC_Open				6
#define DVC_Close				7
#define DVC_GetUnit			8
#define DVC_PeekUnit		9
#define DVC_GetUnitDirect		10
#define DVC_PeekUnitDirect	11
#define DVC_InputStatus	12
#define DVC_PutUnit			13
#define DVC_SetPosition	15
#define DVC_ReadBlock		16
#define DVC_WriteBlock	17
#define DVC_VerifyBlock	18
#define DVC_OutputStatus	19
#define DVC_FlushInput		20
#define DVC_FlushOutput		21
#define DVC_IRQ						22
#define	DVC_IsRemoveable	23
#define DVC_IOCTRL_READ		24
#define DVC_IOCTRL_WRITE	25
#define DVC_OutputUntilBusy	26
#define DVC_Shutdown  27

#define MAX_DEV_OP		31

#define DVT_Block			0
#define DVT_Unit			1

typedef struct _tagDCB {
	char name[12];		// first char is length, 11 chars max
	__int8 type;
	__int8 ReentCount;
	__int8 fSingleUser;
	__int8 UnitSize;
	__int8 pad1[4];
	int nBPB;
	int LastErc;			// last error code
	int StartBlock;
	int nBlocks;
	hMBX hMbxSend;
	hMBX hMbxRcv;
	int hJob;
	__int8 *pSema;
	int	resv1;
	int	resv2;
} DCB;

extern DCB DeviceTable[NR_DCB];
