#pragma once
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FlickObject.h
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
#include ".\FlickHeader.h"

class FlickFrame;

class FlickObject
{
public:
	FlickHeader m_flickHeader;
	FlickFrame  *m_frames;
	bool isGood;
	int m_numFrames;
	int SetPNGHeader(unsigned __int8 *buf);
	int SetPNG_IHDR(unsigned __int8 *buf, int pos);
	int SetPNG_PLTE(unsigned __int8 *buf, int pos);
	int SetPNG_IEND(unsigned __int8 *buf, int pos);
	void AllocateFrames();
public:
	FlickObject(void);
	~FlickObject(void);
	FlickObject *Clone(void);
	int GetWidth() { return m_flickHeader.m_width; };
	int GetHeight() { return m_flickHeader.m_height; };
	int GetStride() { 
		int stride = m_flickHeader.m_width;
		while(stride & 3) stride++;
		return stride; };
	int GetDirs() { return m_flickHeader.m_dirs; };
	int GetDirFrames() { return m_flickHeader.m_dirFrames; };
	System::Drawing::Bitmap ^GetFrame(int fndx);
	System::Drawing::Bitmap ^GetFrame(int row, int col);
	void load(std::ifstream& ifs);
	void load(std::string path);
	void SaveAsBmp(std::string path);
	void SaveAsBmp(std::ofstream& ofs);
	void SaveAsPNG(std::string path);
	void SaveAsPNG(std::ofstream& ofs);
//	void SaveAsBmp(System::IO::MemoryStream ms);
	int *GetPixels();
	int *GetBmpBuf();
	unsigned __int8 *GetPNGBuf(int *len);
	void BackupPalette();
	void RestorePalette();
	void SetTeamColor(int team);
};
