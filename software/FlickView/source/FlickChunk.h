#pragma once
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FlickChunk.h
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

class FlickChunk
{
public:
	FlickChunkHeader m_chunkHeader;
	FlickFrame *m_pFlickFrame;
	FlickFrame *m_pPrevFlickFrame;
	enum {
		COLOR_256 = 4,
		DELTA_FLC = 7,
		COLOR_64 = 11,
		BYTE_RUN = 15
	};
	void ProcessColor(std::ifstream& ifs);
	void ProcessByteRun(std::ifstream& ifs);
	void ProcessDeltaFlc(std::ifstream& ifs);
public:
	FlickChunk(void);
	~FlickChunk(void);
	void load(std::ifstream& ifs);
	unsigned __int8 *GetImageBuf() { return m_pFlickFrame->m_pImage; };
	unsigned __int8 *GetPrevImageBuf() { return m_pPrevFlickFrame ? m_pPrevFlickFrame->m_pImage : NULL; };
	int GetWidth() { return m_pFlickFrame->GetWidth(); };
	int GetHeight() { return m_pFlickFrame->GetHeight(); };
	int GetStride() { return m_pFlickFrame->GetStride(); };
	__int32 *GetPalette() { return m_pFlickFrame->GetPalette(); };
	__int32 *GetPrevPalette() { return m_pPrevFlickFrame->GetPalette(); };
	__int32 *SetPalette(__int32 *pal) { return m_pFlickFrame->SetPalette(pal); };
	__int32 *NewPalette() { return m_pFlickFrame->NewPalette(); };
};
