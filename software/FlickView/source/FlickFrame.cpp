#include "stdafx.h"
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FlickFrame.cpp
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
FlickFrame::FlickFrame()
{
	m_pImage = nullptr;
	m_chunks = NULL;
	m_palette = nullptr;
	m_newPalette = false;
	m_origPalette = nullptr;
}

FlickFrame::~FlickFrame(void)
{
	if (m_chunks)
		delete[] m_chunks;
	if (m_origPalette)
		delete[] m_origPalette;
	if (m_newPalette && m_palette)
		delete[] m_palette;
	if (m_pImage)
		delete[] m_pImage;
}

void FlickFrame::load(std::ifstream& ifs)
{
	int nn;

	m_frameHeader.load(ifs);
	if (m_frameHeader.m_chunks < 0 || m_frameHeader.m_chunks > 100000)
		throw gcnew System::Exception("Bad flick frame header");
	m_chunks = new FlickChunk[m_frameHeader.m_chunks];
	for (nn = 0; nn < m_frameHeader.m_chunks; nn++) {
		m_chunks[nn].m_pFlickFrame = this;
		m_chunks[nn].m_pPrevFlickFrame = GetPrevFrame();
		m_chunks[nn].load(ifs);
	}
}

void FlickFrame::AllocateImageBuf()
{
	if (GetWidth() * GetHeight() > 10000000)
		throw gcnew System::Exception("FlickObject: Bad image size");
	m_pImage = new unsigned __int8[GetStride() * GetHeight()];
}

// AllocateFrames() must have been called before the frames can be copied.
void FlickFrame::Copy(FlickFrame *frm)
{
	int nn;

	m_num = frm->m_num;
	memcpy(&m_frameHeader, &frm->m_frameHeader, sizeof(m_frameHeader));
	m_chunks = nullptr;
//	m_pFlickObject = frm->m_pFlickObject;	// for now so we can get the width and height
	memcpy(m_pImage, frm->m_pImage, GetWidth() * GetHeight());
	m_newPalette = frm->m_newPalette;
	if (frm->m_newPalette) {
		m_palette = new __int32[256];
		m_newPalette = true;
		memcpy(m_palette, frm->m_palette, 256 * sizeof(__int32));
		m_origPalette = new __int32[256];
		memcpy(m_origPalette, frm->m_origPalette, 256 * sizeof(__int32));
	}
}

