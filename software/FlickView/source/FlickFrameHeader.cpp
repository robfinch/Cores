#include "stdafx.h"
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FlickFrameHeader.cpp
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
FlickFrameHeader::FlickFrameHeader(void)
{
}

FlickFrameHeader::~FlickFrameHeader(void)
{
}

void FlickFrameHeader::load(std::ifstream& ifs)
{
	ifs.read((char *)&m_size,sizeof(m_size));
	ifs.read((char *)&m_magic,sizeof(m_magic));
	ifs.read((char *)&m_chunks,sizeof(m_chunks));
	ifs.read((char *)&m_expand[0],8);
}
