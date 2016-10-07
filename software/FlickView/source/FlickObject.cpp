#include "stdafx.h"
#include "zlib.h"
extern __int32 CalcTeamColor(int team, int r, int g, int b);
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FlickObject.cpp
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
	using namespace std;
	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;
	using namespace System::Runtime::InteropServices;
	using namespace System::Threading;

FlickObject::FlickObject(void)
{
	m_frames = NULL;
}

FlickObject::~FlickObject(void)
{
	if (m_frames)
		delete[] m_frames;
}

void FlickObject::AllocateFrames()
{
	int nn;

	if (m_numFrames > 300)
		throw gcnew Exception("Bad number of frames in Flick Object");
	m_frames = new FlickFrame[m_numFrames];
	if (m_frames==NULL)
		throw gcnew Exception("Failed to allocate flick frames");
	for (nn = 0; nn < m_numFrames; nn++) { //m_flickHeader.m_frames; nn++) {
		m_frames[nn].m_num = nn;
		m_frames[nn].m_pFlickObject = this;
		m_frames[nn].AllocateImageBuf();
		if (nn > 0)
			m_frames[nn].m_pPrevFrame = &m_frames[nn-1];
	}
	m_frames[0].m_pPrevFrame = &m_frames[nn-1];
}

void FlickObject::load(std::ifstream& ifs)
{
	int nn;
	char buf[200];

	m_flickHeader.load(ifs);
	if (m_flickHeader.m_magic != (unsigned)0xAF11 && m_flickHeader.m_magic != (unsigned)0xAF12) {
		sprintf_s(buf, sizeof(buf), "magic:%04X", m_flickHeader.m_size);
	System::Windows::Forms::MessageBox::Show(gcnew String(buf),"FlickObject.load",
		System::Windows::Forms::MessageBoxButtons::OK,
		System::Windows::Forms::MessageBoxIcon::Information);
		m_flickHeader.m_width = 0;
		m_flickHeader.m_height = 0;
		m_flickHeader.m_dirFrames = 0;
		m_flickHeader.m_dirs = 0;
		return;
//		throw new CArchiveException(CArchiveException::badClass,ar.GetFile()->GetFilePath());
	}
	m_numFrames = m_flickHeader.m_dirs * m_flickHeader.m_dirFrames;
	AllocateFrames();
/*
	sprintf(buf, "frames:%d", nframes);
	System::Windows::Forms::MessageBox::Show(gcnew String(buf),"FlickObject.load",
		System::Windows::Forms::MessageBoxButtons::OK,
		System::Windows::Forms::MessageBoxIcon::Information); */
	for (nn = 0; nn < m_numFrames; nn++) {
		if (nn == 0) {
			m_frames[nn].NewPalette();
		}
		else {
			m_frames[nn].SetPalette(m_frames[nn-1].m_palette);
//			memcpy(m_frames[nn].m_palette, m_frames[nn-1].m_palette, sizeof(__int32) * 256);
		}
		m_frames[nn].load(ifs);
	}
}

void FlickObject::load(std::string path)
{
	System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::WaitCursor; 
	std::ifstream fp_in;
	fp_in.open(path,std::ios::in|std::ifstream::binary);
	load(fp_in);
	System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::Default; 
}

int *FlickObject::GetPixels()
{
	int row, col, x, y, nn;
	int *buf = new int[GetDirs() * GetHeight() * GetDirFrames() * GetWidth()];
	if (buf==NULL)
		throw "Out of memory";
	nn = 0;
	for (row = 0; row < GetDirs(); row++)
		for (y = 0; y < GetHeight(); y++)
			for (col = 0; col < GetDirFrames(); col++)
				for (x = 0; x < GetWidth(); x++) {
					buf[nn] = m_frames[0].m_palette[m_frames[col + row * GetDirFrames()].m_pImage[x+y*GetWidth()]];
					nn++;
				}
	return buf;
}

System::Drawing::Bitmap ^FlickObject::GetFrame(int row, int col)
{
	int fndx = col + row * GetDirFrames();
	return GetFrame(fndx);
}

System::Drawing::Bitmap ^FlickObject::GetFrame(int fndx)
{
	int nn;
	System::Drawing::Bitmap^ bmp;
	System::Drawing::Imaging::ColorPalette^ cp;

	if (!m_frames[fndx].m_pImage)
		return nullptr;

	bmp = gcnew System::Drawing::Bitmap(GetWidth(), GetHeight(), GetStride(), 
		System::Drawing::Imaging::PixelFormat::Format8bppIndexed,
		IntPtr(m_frames[fndx].m_pImage));
	cp = bmp->Palette;
	for (nn = 0; nn < 256; nn++) {
		cp->Entries[nn] = Color::FromArgb(m_frames[fndx].m_palette[nn]);
	}
	bmp->Palette = cp;
	return bmp;
}

int *FlickObject::GetBmpBuf()
{
	int size;
	int loc = 1146;
	int row, col, x, y, nn, wf;
	int *buf = new int[GetDirs() * GetHeight() * GetDirFrames() * GetWidth()+1146];
	__int8 *buf8;
	__int16 *buf16;
	buf8 = (__int8 *)buf;
	buf16 = (__int16 *)buf;
	// Create the BMP header (14 bytes)
	buf8[0] = 'B';
	buf8[1] = 'M';
	size = (GetWidth() * GetHeight() * GetDirs() * GetDirFrames()) + 1146;
	buf8[2] = size;
	buf8[3] = size >> 8;
	buf8[4] = size >> 16;
	buf8[5] = size >> 24;
	buf8[6] = 0;
	buf8[7] = 0;
	buf8[8] = 0;
	buf8[9] = 0;
	buf8[10] = loc;
	buf8[11] = loc >> 8;
	buf8[12] = loc >> 16;
	buf8[13] = loc >> 24;
	// DIB v4
	buf8[14] = 108;
	buf8[15] = 0;
	buf8[16] = 0;
	buf8[17] = 0;
	size = GetWidth() * GetDirFrames();
	buf8[18] = size;
	buf8[19] = size >> 8;
	buf8[20] = size >> 16;
	buf8[21] = size >> 24;
	size = -GetHeight() * GetDirs();
	buf8[22] = size;
	buf8[23] = size >> 8;
	buf8[24] = size >> 16;
	buf8[25] = size >> 24;
	buf8[26] = 1;	// number of planes
	buf8[27] = 0;
	buf8[28] = 8;	// bits per pixel
	buf8[29] = 0;

	buf8[30] = 3;	// BI_BITFIELDS (no compression)
	buf8[31] = 0;
	buf8[32] = 0;
	buf8[33] = 0;
/*
	// Create the DIB header (40 bytes)
	buf8[14] = 40;
	buf8[15] = 0;
	buf8[16] = 0;
	buf8[17] = 0;
	size = GetWidth() * GetDirFrames();
	buf8[18] = size;
	buf8[19] = size >> 8;
	buf8[20] = size >> 16;
	buf8[21] = size >> 24;
	size = -GetHeight() * GetDirs();
//	size = GetHeight() * GetDirs();
	buf8[22] = size;
	buf8[23] = size >> 8;
	buf8[24] = size >> 16;
	buf8[25] = size >> 24;
	buf8[26] = 1;
	buf8[27] = 0;
	buf8[28] = 8;
	buf8[29] = 0;

	buf8[30] = 0;
	buf8[31] = 0;
	buf8[32] = 0;
	buf8[33] = 0;
	size = (GetWidth() * GetHeight() * GetDirs() * GetDirFrames());
//	buf8[34] = size;
//	buf8[35] = size >> 8;
//	buf8[36] = size >> 16;
//	buf8[37] = size >> 24;
	buf8[34] = 0;	// can be zero for BI_RGB
	buf8[35] = 0;
	buf8[36] = 0;
	buf8[37] = 0;

	buf8[38] = 0;
	buf8[39] = 10;
	buf8[40] = 0;
	buf8[41] = 0;

	buf8[42] = 0;
	buf8[43] = 10;
	buf8[44] = 0;
	buf8[45] = 0;

	buf8[46] = 0;
	buf8[47] = 1;
	buf8[48] = 0;
	buf8[49] = 0;

	buf8[50] = 0;
	buf8[51] = 0;
	buf8[52] = 0;
	buf8[53] = 0;
*/
	nn = 0;
	for (row = 0; row < GetDirs(); row++)
		for (y = 0; y < GetHeight(); y++) {
			wf = 0;
			for (col = 0; col < GetDirFrames(); col++) {
				for (x = 0; x < GetWidth(); x++) {
//					buf[272+nn] = m_frames[0].m_palette[m_frames[col + row * GetDirFrames()].m_pImage[x+y*GetWidth()]];
					buf8[1146+nn] = m_frames[col + row * GetDirFrames()].m_pImage[x+y*GetWidth()];
					nn++;
					wf++;
				}
			}
			while (wf & 3) {
				nn++;
				wf++;
			}
		}
	
	size = nn + 1146;
	buf8[2] = size;
	buf8[3] = size >> 8;
	buf8[4] = size >> 16;
	buf8[5] = size >> 24;
	// size of raw bitmap including padding
	size = nn;
	buf8[34] = size;
	buf8[35] = size >> 8;
	buf8[36] = size >> 16;
	buf8[37] = size >> 24;

	// print resolution of image
	// 72DPI = 2835 pixels per meter
	buf8[38] = 0x13;
	buf8[39] = 0x0B;
	buf8[40] = 0;
	buf8[41] = 0;

	buf8[42] = 0x13;
	buf8[43] = 0x0B;
	buf8[44] = 0;
	buf8[45] = 0;

	// number of colors in palette (256)
	buf8[46] = 0;
	buf8[47] = 1;
	buf8[48] = 0;
	buf8[49] = 0;

	// 0 means all colors are important
	buf8[50] = 0;
	buf8[51] = 0;
	buf8[52] = 0;
	buf8[53] = 0;

	// RED channel mask
	buf8[54] = 0;
	buf8[55] = 0;
	buf8[56] = -1;
	buf8[57] = 0;
	// Green channel mask
	buf8[58] = 0;
	buf8[59] = -1;
	buf8[60] = 0;
	buf8[61] = 0;
	// blue channel mask
	buf8[62] = -1;
	buf8[63] = 0;
	buf8[64] = 0;
	buf8[65] = 0;
	// alpha channel mask
	buf8[66] = 0;
	buf8[67] = 0;
	buf8[68] = 0;
	buf8[69] = -1;

	// "Win "
	buf8[70] = 0x20;
	buf8[71] = 0x6E;
	buf8[72] = 0x69;
	buf8[73] = 0x57;

	// 48 unused bytes (color space + gamma)
	for (x = 74; x < 121; x++)
		buf8[x] = 0;

	// write out palette
	for (x = 0; x < 256; x++) {
		buf8[x*4+122] = m_frames[0].m_palette[x];
		buf8[x*4+123] = m_frames[0].m_palette[x] >> 8;
		buf8[x*4+124] = m_frames[0].m_palette[x] >> 16;
		buf8[x*4+125] = m_frames[0].m_palette[x] >> 24;
	}

	return buf;
}

void FlickObject::SaveAsBmp(std::string path)
{
	System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::WaitCursor; 
	std::ofstream fp_out;
	fp_out.open(path,std::ios::out|std::ifstream::binary);
	SaveAsBmp(fp_out);
	fp_out.close();
	System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::Default; 
}

void FlickObject::SaveAsBmp(std::ofstream& fp_out)
{
	int size;
	int *buf = GetBmpBuf();

	size = (m_flickHeader.m_width * m_flickHeader.m_height * m_flickHeader.m_dirs * m_flickHeader.m_dirFrames) + 1088;
	fp_out.write((char*)buf,size);
	delete[] buf;
}

void FlickObject::SaveAsPNG(std::string path)
{
	System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::WaitCursor; 
	std::ofstream fp_out;
	fp_out.open(path,std::ios::out|std::ifstream::binary);
	SaveAsPNG(fp_out);
	fp_out.close();
	System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::Default; 
}

void FlickObject::SaveAsPNG(std::ofstream& fp_out)
{
	int size;
	unsigned __int8 *buf = GetPNGBuf(&size);

	fp_out.write((char*)buf,size);
	delete[] buf;
}

/*
void FlickObject::SaveAsBmp(System::IO::MemoryStream fp_out)
{
	int size;
	__int16 resv = 0;
	__int16 i16;
	__int32 i32;
	int loc = 1088;
	int row, col, x, y;
	__int8 *bmp = (__int8 *)GetBmpBuf();
	array<System::Byte>^ byts = gcnew array<byte>(GetWidth() * GetHeight() * GetDirs() * GetDirFrames()*4+1088);

	for (x = 0; x < GetWidth() * GetHeight() * GetDirs() * GetDirFrames()*4+1088; x++)
		byts[x] = bmp[x];

	fp_out.Write(byts, 0, GetWidth() * GetHeight() * GetDirs() * GetDirFrames()*4+1088);
}
*/

int FlickObject::SetPNGHeader(unsigned __int8 *buf)
{
	buf[0] = 0x89;
	buf[1] = 'P';
	buf[2] = 'N';
	buf[3] = 'G';
	buf[4] = 0x0D;
	buf[5] = 0x0A;
	buf[6] = 0x1A;
	buf[7] = 0x0A;
	return 8;
}

int FlickObject::SetPNG_IHDR(unsigned __int8 *buf, int pos)
{
	int crc;
	int size;

	// IHDR
	buf[8] = 0;
	buf[9] = 0;
	buf[10] = 0;
	buf[11] = 13;	// 13 data bytes in chunk
	buf[12] = 'I';
	buf[13] = 'H';
	buf[14] = 'D';
	buf[15] = 'R';

	// width
	size = GetWidth() * GetDirFrames();
	size--;
	buf[16] = size >> 24;
	buf[17] = size >> 16;
	buf[18] = size >> 8;
	buf[19] = size;

	//height
	size = GetHeight() * GetDirs();
	size--;
	buf[20] = size >> 24;
	buf[21] = size >> 16;
	buf[22] = size >> 8;
	buf[23] = size;

	buf[24] = 8;	// bit depth
	buf[25] = 3;	// color type 3=indexed color
	buf[26] = 0;	// compression method
	buf[27] = 0;	// filter method
	buf[28] = 0;	// interlace method (none)

	crc = ~crc32(-1,(const Bytef *)&buf[12],17);
	buf[29] = crc >> 24;
	buf[30] = crc >> 16;
	buf[31] = crc >> 8;
	buf[32] = crc;
	return 25;
}

int FlickObject::SetPNG_PLTE(unsigned __int8 *buf, int pos)
{
	int crc;
	int x;

	buf[33] = 0;
	buf[34] = 0;
	buf[35] = 3;	// 768 3x256 colors
	buf[36] = 0;
	buf[37] = 'P';
	buf[38] = 'L';
	buf[39] = 'T';
	buf[40] = 'E';

	// write out palette
	for (x = 0; x < 256; x++) {
		buf[x*3+41] = m_frames[0].m_palette[x] >> 16;	// Red
		buf[x*3+42] = m_frames[0].m_palette[x] >> 8;	// Green
		buf[x*3+43] = m_frames[0].m_palette[x];			// Blue
	}

	crc = ~crc32(-1,(const Bytef *)&buf[37],772);
	buf[809] = crc >> 24;
	buf[810] = crc >> 16;
	buf[811] = crc >> 8;
	buf[812] = crc;
	return 780;
}

int FlickObject::SetPNG_IEND(unsigned __int8 *buf, int pos)
{
	int crc;

	buf[pos] = 0;
	buf[pos+1] = 0;
	buf[pos+2] = 0;
	buf[pos+3] = 0;
	buf[pos+4] = 'I';
	buf[pos+5] = 'E';
	buf[pos+6] = 'N';
	buf[pos+7] = 'D';

	crc = ~crc32(-1,(const Bytef *)&buf[829],4);
	buf[pos+8] = crc >> 24;
	buf[pos+9] = crc >> 16;
	buf[pos+10] = crc >> 8;
	buf[pos+11] = crc;
	return 12;
}

unsigned __int8 *FlickObject::GetPNGBuf(int *len)
{
	unsigned __int8 *buf;
	__int8 *ucbuf, *cbuf;
	int x, y, row, col, wf;
	int nn;
	int clen, uclen;
	int crc;

	uclen = GetWidth() * GetHeight() * GetDirs() * GetDirFrames();
	ucbuf = new __int8[uclen+4*GetHeight()*GetDirs()];
	nn = 0;
	for (row = 0; row < GetDirs(); row++) {
		for (y = 0; y < GetHeight(); y++) {
			wf = 0;
			for (col = 0; col < GetDirFrames(); col++) {
				for (x = 0; x < GetWidth(); x++) {
					ucbuf[nn] = m_frames[col + row * GetDirFrames()].m_pImage[x+y*GetWidth()];
					nn++;
					wf++;
				}
			}
		}
	}
	// Compressed buffer must be 0.1% larger plus 12 bytes
	clen = (int)((double)1.0011 * (double)(nn)) + 12;
	cbuf = new __int8[clen];
	compress((Bytef *)cbuf, (uLongf *)&clen, (const Bytef *)ucbuf, nn);
	delete[] ucbuf;
	buf = new unsigned __int8[clen + 850];

	SetPNGHeader(buf);
	SetPNG_IHDR(buf,8);
	SetPNG_PLTE(buf,33);

	buf[813] = (clen+0)>>24;
	buf[814] = (clen+0)>>16;
	buf[815] = (clen+0)>>8;
	buf[816] = (clen+0);
	buf[817] = 'I';
	buf[818] = 'D';
	buf[819] = 'A';
	buf[820] = 'T';

	// insert zlib compressed data
	memcpy(&buf[821], cbuf, clen);
	delete[] cbuf;

	crc = ~crc32(-1,(const Bytef *)&buf[817],clen+4);
	buf[clen+821] = crc >> 24;
	buf[clen+822] = crc >> 16;
	buf[clen+823] = crc >> 8;
	buf[clen+824] = crc;

	SetPNG_IEND(buf,clen+825);
	if (len) *len = clen + 825 + 12;
	return buf;
}

void FlickObject::BackupPalette()
{
	int nn;

	for (nn = 0; nn < m_numFrames; nn++)
		if (m_frames[nn].m_newPalette)
			m_frames[nn].BackupPalette();
}

void FlickObject::RestorePalette()
{
	int nn;

	for (nn = 0; nn < m_numFrames; nn++)
		if (m_frames[nn].m_newPalette)
			m_frames[nn].RestorePalette();
}

void FlickObject::SetTeamColor(int team)
{
	int frame, nn;
	int red, green, blue;
	__int32 color;

	RestorePalette();

	for (frame = 0; frame < m_numFrames; frame++) {
		if (m_frames[frame].m_newPalette)
		for (nn = 0; nn < 64; nn = nn + 1) {
			red = (m_frames[frame].m_palette[nn] >> 16) & 0xff;
			green = (m_frames[frame].m_palette[nn] >> 8) & 0xff;
			blue = (m_frames[frame].m_palette[nn]) & 0xff;
			color = CalcTeamColor(team, red, green, blue);
			red = (color >> 16) & 0xff;
			green = (color >> 8) & 0xff;
			blue = color & 0xff;
			m_frames[frame].m_palette[nn] = 0xFF000000 | ((red&0xff)<<16) | ((green & 0xff) << 8) | (blue & 0xff);// | (((unsigned int)fo->m_frames[0].m_palette[32] * (unsigned int)fo->m_frames[0].m_palette[nn]) >> 8);
		}
	}
}

FlickObject *FlickObject::Clone()
{
	int nn;
	FlickObject *fo = new FlickObject;

	fo->isGood = isGood;
	fo->m_numFrames = m_numFrames;
	memcpy(&fo->m_flickHeader, &m_flickHeader, sizeof(m_flickHeader));
	fo->AllocateFrames();
	for (nn = 0; nn < m_numFrames; nn++) {
		fo->m_frames[nn].Copy(&m_frames[nn]);
		if (!fo->m_frames[nn].m_newPalette) {
			fo->m_frames[nn].m_palette = fo->m_frames[nn-1].m_palette;
			fo->m_frames[nn].m_origPalette = fo->m_frames[nn-1].m_origPalette;
		}
	}
	return fo;
}
