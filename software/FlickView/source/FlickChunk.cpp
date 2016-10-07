#include "StdAfx.h"
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FlickChunk.cpp
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
FlickChunk::FlickChunk(void)
{
}

FlickChunk::~FlickChunk(void)
{
}

void FlickChunk::ProcessColor(std::ifstream& ifs)
{
	int nn, xx;
	int palndx;
	__int32 *pal;
	__int32 *prevPal;
	__int16 pc16;
	__int8 skipCnt;
	__int8 copyCnt;
	unsigned __int8 red,green,blue;

	prevPal = GetPrevPalette();
	pal = NewPalette();
	palndx = 0;
	ifs.read((char *)&pc16,2);
	for (nn = 0; nn < pc16; nn++) {
		ifs.read((char *)&skipCnt,1);
		ifs.read((char *)&copyCnt,1);
		for (xx = 0; xx < skipCnt; xx++, palndx++)
			if (palndx < 256)
				pal[palndx] = prevPal[palndx];
		if (copyCnt==0)
			xx = 256;
		else
			xx = copyCnt;
		for (; xx > 0; xx--) {
			ifs.read((char *)&blue,1);
			ifs.read((char *)&green,1);
			ifs.read((char *)&red,1);
			if (palndx < 256) {
				if (m_chunkHeader.m_type == COLOR_64)
					pal[palndx] = ((unsigned int)red<<18)|((unsigned int)green<<10)|(blue<<2);
				else
					pal[palndx] = ((unsigned int)red<<16)|((unsigned int)green<<8)|(blue<<0);
				switch(palndx) {
				case 224: case 225: case 226: case 227: case 228: case 229: case 230: case 231: case 232:
				case 233: case 234: case 235: case 236: case 237: case 238: case 239: case 240: case 241:
				case 242: case 243: case 244: case 245: case 246: case 247: case 248: case 249: case 250:
				case 251: case 252: case 253:
				case 254:	pal[palndx] |= 0x3f000000; break;
				case 255:	pal[palndx] |= 0; break;
				default:	pal[palndx] |= 0xFF000000;
				}
			}
			palndx++;
		}
	}
}

void FlickChunk::ProcessDeltaFlc(std::ifstream& ifs)
{
	int yy;
	int kk,jj;
	int ln;
	__int16 i16;
	__int8 i8;
	__int16 pc16;
	int cnt2;
	__int8 skipCnt;
	__int8 copyCnt;
	unsigned __int8 *image = GetImageBuf();
	unsigned __int8 *prevImage = GetPrevImageBuf();
	__int16 numLines;
	unsigned __int16 opcode;
	__int16 opc;
	__int16 lineSkipCount;
	int wd;
	int stride;

	stride = GetStride();
	memset(image, prevImage[0], stride * GetHeight());
	cnt2 = 6;
	ifs.read((char *)&numLines,2);
	cnt2 += 2;
	for (yy = ln = 0; ln < numLines; ln++, yy++) {
		pc16 = 0;
		lineSkipCount = 0;
		do {
			ifs.read((char *)&opcode,2);
			cnt2 += 2;
			switch((opcode>>14)&3) {
			case 0:	pc16 = opcode & 0x3fff; goto j1;	// packet count (always the last opcode).
			case 1: break;	// undefined
			case 2: image[yy*stride + GetWidth()-1] = opcode & 0xff; break;	// store opcodes low byte to last pixel of line
			case 3:	opc = opcode; lineSkipCount = abs(opc); break;	// line skip count
			}
		}
		while(1);
j1:;
		if (lineSkipCount > 0) {
			for (jj = 0; jj < lineSkipCount; jj++, yy++) {
				for (kk = 0; kk < GetWidth(); kk++) {
//						image[(yy+jj)*GetWidth() + kk] = prevImage[(yy+jj)*GetWidth() + kk];
					image[yy*stride + kk] = prevImage[yy*stride + kk];
				}
			}
		}
		wd = 0;
		if (pc16 == 0) {
			for (kk = 0; kk < GetWidth()-1; kk++) {
//					image[(yy+jj)*GetWidth() + kk] = prevImage[(yy+jj)*GetWidth() + kk];
				image[yy*stride + kk] = prevImage[yy*stride + kk];
			}
		}
		else
		for (; pc16 > 0; pc16--) {
			ifs.read((char *)&skipCnt,1);
			ifs.read((char *)&copyCnt,1);
			cnt2 += 2;
			for (kk = 0; kk < skipCnt; kk++) {
				image[yy*stride + wd] = prevImage[yy*stride + wd];
				wd++;
			}
//				cnt2 += 1;
			if (copyCnt > 0) {
				for (; copyCnt > 0; copyCnt--) {
					ifs.read((char*)&image[yy*stride + wd],1);
					ifs.read((char*)&image[yy*stride + wd+1],1);
					wd+=2;
					cnt2 += 2;
				}
			}
			else if (copyCnt < 0) {
				ifs.read((char*)&i16,2);
				cnt2 += 2;
				copyCnt = abs(copyCnt);
				for (; copyCnt > 0; copyCnt--) {
					image[yy*stride + wd] = i16 & 0xff;
					image[yy*stride + wd+1] = i16 >> 8;
					wd+=2;
				}
			}
		}
		for (; wd < GetWidth(); wd++)
			image[yy*stride + wd] = prevImage[yy*stride + wd];
		for (; wd < stride; wd++)
			image[yy*stride + wd] = -1;
	}
	while (cnt2 < m_chunkHeader.m_size) {
		ifs.read((char *)&i8,1);
		cnt2++;
	}
}

// The first frame of the .flc is often stored as a BYTE_RUN, subsequent frames
// are then stored as delta's from the first frame.

void FlickChunk::ProcessByteRun(std::ifstream& ifs)
{
	int nn,yy;
	__int8 cnt;
	int cnt2;
	int wd;
	unsigned __int8 i8u;
	__int8 i8;
	unsigned __int8 *image = GetImageBuf();
	int stride;

	nn = 0;
	cnt2 = 6;
	stride = GetStride();
	for (yy = 0; yy < GetHeight(); yy++) {
		wd = 0;
		// The standard says this byte should be read and discarded as
		// there could be more than 255 packets on a line. The standard
		// says to keep looking for packets until the width of the line
		// is reached.
		ifs.read((char *)&i8u,1);	// discard packet count
		cnt2++;
		do {// for (; i8u > 0; i8u--) {
			ifs.read((char *)&cnt,1);
			cnt2++;
			if (cnt < 0) {
				cnt = -cnt;
				ifs.read((char *)&image[yy*stride + wd],cnt);
				cnt2 += cnt;
				wd += cnt;
			}
			else if (cnt > 0) {
				ifs.read((char *)&i8,1);
				cnt2++;
				memset(&image[yy*stride + wd],i8,cnt);
				wd += cnt;
			}
			else {
				ifs.read((char *)&i8,1);
				cnt2++;
			}
		} while (wd < GetWidth());
		while(wd < stride) {
			image[yy*stride + wd] = -1;
			wd++;
		}
	}
	while (cnt2 < m_chunkHeader.m_size) {
		ifs.read((char *)&i8,1);
		cnt2++;
	}
}

void FlickChunk::load(std::ifstream& ifs)
{
	m_chunkHeader.load(ifs);
	switch(m_chunkHeader.m_type) {
	case COLOR_256:
	case COLOR_64:
		ProcessColor(ifs);
		break;
	case DELTA_FLC:
		ProcessDeltaFlc(ifs);
		break;
	case BYTE_RUN:
		ProcessByteRun(ifs);
		break;
	}
}
