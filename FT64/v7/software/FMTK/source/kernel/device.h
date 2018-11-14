// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
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
typedef struct _tagDCB {
	char name[12];		// first char is length, 11 chars max
	__int8 type;
	__int8 ReentCount;
	__int8 fSingleUser;
	__int8 pad1[5];
	int nBPB;
	int LastErc;			// last error code
	int StartBlock;
	int nBlocks;
	int (*CmdProc)();
	int hJob;
	__int8 *pSema;
	int	resv1;
	int	resv2;
} DCB;

extern DCB DeviceTable[32];
