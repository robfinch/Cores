#pragma once
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FlickHeader.h
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
#include "stdafx.h"

class FlickHeader
{
public:
	__int32 m_size;
	unsigned __int16 m_magic;
	__int16 m_frames;
	__int16 m_width;
	__int16 m_height;
	__int16 m_depth;
	__int16 m_flags;
	__int32 m_speed;
	__int16 m_resv1;
	__int32 m_created;
	__int32 m_creator;
	__int32 m_updated;
	__int32 m_updater;
	__int16 m_aspectdx;
	__int16 m_aspectdy;
	__int16 m_ext_flags;
	__int16 m_keyFrames;
	__int16 m_totalFrames;
	__int32 m_req_memory;
	__int16 m_max_regions;
	__int16 m_transp_num;
	__int8 m_resv2[24];
	__int32 m_oframe1;
	__int32 m_oframe2;
	__int8 m_resv3[8];
	__int16 m_dirs;
	__int16 m_dirFrames;
	__int8 m_resv4[28];
public:
	FlickHeader(void);
	~FlickHeader(void);
	void load(std::ifstream& ifs);
};
