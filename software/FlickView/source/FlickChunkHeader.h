#pragma once
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FlickChunkHeader.h
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
//
// ============================================================================
//
#include <Windows.h>
#include <iostream>
#include <fstream>
#include <iomanip>
#include <string>
#include <vcclr.h>
#include <string.h>
#include "stdafx.h"

class FlickChunkHeader
{
public:
	__int32 m_size;
	__int16 m_type;
	__int8 *m_bytes;
public:
	FlickChunkHeader(void);
	~FlickChunkHeader(void);
	void load(std::ifstream& ifs);
};
