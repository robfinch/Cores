#include "stdafx.h"
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FlickChunkHeader.cpp
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
FlickChunkHeader::FlickChunkHeader(void)
{
}

FlickChunkHeader::~FlickChunkHeader(void)
{
}

void FlickChunkHeader::load(std::ifstream& ifs)
{
	ifs.read((char *)&m_size,sizeof(m_size));
	ifs.read((char *)&m_type,sizeof(m_type));
//	if (m_size & 1) m_size++;	// round to even size
}
