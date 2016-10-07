#pragma once
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FlickFrame.h
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
// For the standard each frame has it's own palette. Since for our purposes the
// palette is the same for every frame in the flick a single palette is shared
// between all frames unless there's a chunk object that specifies a new one.
// It would be wasteful to have separate palette because there could be a large
// number of frames in the app, and each palette takes up 1kB of memory.
// Since the palette is shared an indicator is needed so that the palette is
// deleted only once when the frames are being deleted.
//
#include ".\FlickFrameHeader.h"
class FlickChunk;
#include ".\FlickObject.h"

class FlickFrame
{
public:
	int m_num;
	FlickFrameHeader m_frameHeader;
	FlickChunk *m_chunks;
	FlickObject *m_pFlickObject;
	unsigned __int8 *m_pImage;
	__int32 *m_palette;
	__int32 *m_origPalette;
	bool m_newPalette;
	FlickFrame *m_pPrevFrame;
public:
	FlickFrame();
	~FlickFrame(void);
	void AllocateImageBuf();
	void load(std::ifstream& ifs);
	int GetWidth() { return m_pFlickObject->m_flickHeader.m_width; };
	int GetHeight() { return m_pFlickObject->m_flickHeader.m_height; };
	int GetStride() { return m_pFlickObject->GetStride(); };
	__int32 *NewPalette() {
		if (m_newPalette && m_palette)
			delete[] m_palette;
		m_palette = new __int32[256];
		m_newPalette = true;
		return m_palette;
	};
	__int32 *GetPalette() { return m_palette; };
	__int32 *SetPalette(__int32 *pal) {
		if (m_newPalette && m_palette)
			delete[] m_palette;
		m_palette = pal;
		m_newPalette = false;
		return pal;
	};
	void BackupPalette() {
		int nn;
		if (m_origPalette==nullptr)
			m_origPalette = new __int32[256];
		if (m_origPalette==nullptr)
			return;
		for (nn = 0; nn < 256; nn++) {
			m_origPalette[nn] = m_palette[nn];
		}
	}
	void RestorePalette() {
		int nn;
		if (m_origPalette) {
			for (nn = 0; nn < 256; nn++) {
				m_palette[nn] = m_origPalette[nn];
			}
		}
	};
	FlickFrame *GetPrevFrame() { return m_pPrevFrame; };
	void Copy(FlickFrame *);
};
