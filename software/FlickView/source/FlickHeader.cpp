#include "stdafx.h"
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FlickHeader.cpp
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
FlickHeader::FlickHeader(void)
{
}

FlickHeader::~FlickHeader(void)
{
}

void FlickHeader::load(std::ifstream& ifs)
{
	ifs.read((char *)&m_size,sizeof(m_size));
	ifs.read((char *)&m_magic,sizeof(m_magic));
	ifs.read((char *)&m_frames,2);
	ifs.read((char *)&m_width,2);
	ifs.read((char *)&m_height,2);
	ifs.read((char *)&m_depth,2);
	ifs.read((char *)&m_flags,2);
	ifs.read((char *)&m_speed,4);
	ifs.read((char *)&m_resv1,2);
	ifs.read((char *)&m_created,4);
	ifs.read((char *)&m_creator,4);
	ifs.read((char *)&m_updated,4);
	ifs.read((char *)&m_updater,4);
	ifs.read((char *)&m_aspectdx,2);
	ifs.read((char *)&m_aspectdy,2);
	ifs.read((char *)&m_ext_flags,2);
	ifs.read((char *)&m_keyFrames,2);
	ifs.read((char *)&m_totalFrames,2);
	ifs.read((char *)&m_req_memory,4);
	ifs.read((char *)&m_max_regions,2);
	ifs.read((char *)&m_transp_num,2);
	ifs.read((char *)&m_resv2[0],24);
	ifs.read((char *)&m_oframe1,4);
	ifs.read((char *)&m_oframe2,4);
	ifs.read((char *)&m_resv3[0],8);
	ifs.read((char *)&m_dirs,2);
	ifs.read((char *)&m_dirFrames,2);
	ifs.read((char *)&m_resv4[0],28);
	m_dirFrames++;	// dir frames is stored as one less
/*
	ifs >> m_size;
	ifs >> m_magic;
	ifs >> m_frames;
	ifs >> m_width;
	ifs >> m_height;
	ifs >> m_depth;
	ifs >> m_flags;
	ifs >> m_speed;
	ifs >> m_resv1;
	ifs >> m_created;
	ifs >> m_creator;
	ifs >> m_updated;
	ifs >> m_updater;
	ifs >> m_aspectdx;
	ifs >> m_aspectdy;
	ifs >> m_ext_flags;
	ifs >> m_keyFrames;
	ifs >> m_totalFrames;
	ifs >> m_req_memory;
	ifs >> m_max_regions;
	ifs >> m_transp_num;
	for (nn = 0; nn < 24; nn++)
		ifs >> m_resv2[nn];
	ifs >> m_oframe1;
	ifs >> m_oframe2;
	for (nn = 0; nn < 8; nn++)
		ifs >> m_resv3[nn];
	ifs >> m_dirs;
	ifs >> m_dirFrames;
	for (nn = 0; nn < 28; nn++)
		ifs >> m_resv4[nn];
*/
}
