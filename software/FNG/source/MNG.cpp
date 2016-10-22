#include "stdafx.h"

using namespace FinitronClasses;
	using namespace std;
	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;
	using namespace System::Runtime::InteropServices;
	using namespace System::Threading;
	using namespace System::IO;

char *MNGHeaderString = "\x8AMNG\r\n\x1A\n";
__int8 PNGStream::ibuf[4000000];	// compressed image buffer

// Reverse byte order

int rbo(int n)
{
	int m;

	m = (n >> 24) & 0xff;
	m = m| (((n >> 16) & 0xff) << 8);
	m = m| (((n >> 8) & 0xff) << 16);
	m = m| ((n & 0xff) << 24);
	return m;
}

unsigned int IHDR::ReadInt(unsigned char *buf)
{
	unsigned int n;

	n = (unsigned int)buf[0] << 24;
	n = n | ((unsigned int)buf[1] << 16);
	n = n | ((unsigned int)buf[2] << 8);
	n = n | (unsigned int)buf[3];
	return n;
}

void IHDR::Read(std::ifstream& ifs)
{
	unsigned char buf[25];
	int crc;

	ifs.read((char *)buf,25);
	Width = ReadInt(&buf[8]);
	Height = ReadInt(&buf[12]);
	BitDepth = buf[16];
	ColorType = buf[17];
	CompressionMethod = buf[18];
	FilterMethod = buf[19];
	InterlaceMethod = buf[20];
	crc = ReadInt(&buf[21]);
}

MHDR::MHDR()
{
	Flags = 65;
}

void MHDR::WriteInt(char *buf, unsigned int n)
{
	buf[0] = n >> 24;
	buf[1] = n >> 16;
	buf[2] = n >> 8;
	buf[3] = n;
}

unsigned int MHDR::ReadInt(unsigned char *buf)
{
	unsigned int n;

	n = (unsigned int)buf[0] << 24;
	n = n | ((unsigned int)buf[1] << 16);
	n = n | ((unsigned int)buf[2] << 8);
	n = n | (unsigned int)buf[3];
	return n;
}

int MHDR::Read(std::ifstream &ifs)
{
	unsigned char buf[40];
	int crc,crc1;

	ifs.read((char *)buf, 40);
	FrameWidth = ReadInt(&buf[8]);
	FrameHeight = ReadInt(&buf[12]);
	TicksPerSecond = ReadInt(&buf[16]);
	LayerCount = ReadInt(&buf[20]);
	FrameCount = ReadInt(&buf[24]);
	PlayTime = ReadInt(&buf[28]);
	Flags = ReadInt(&buf[32]);
	crc = ~crc32(-1,(const Bytef *)&buf[4],32);
	crc1 = ReadInt(&buf[36]);
	return 40;
}

int MHDR::Write(std::ofstream &ofs)
{
	char buf[40];
	int crc;

	WriteInt(buf, 28);
	buf[4] = 'M';
	buf[5] = 'H';
	buf[6] = 'D';
	buf[7] = 'R';
	WriteInt(&buf[8], (uint)FrameWidth);
	WriteInt(&buf[12], (uint)FrameHeight);
	WriteInt(&buf[16], (uint)TicksPerSecond);
	WriteInt(&buf[20], (uint)LayerCount);
	WriteInt(&buf[24], (uint)FrameCount);
	WriteInt(&buf[28], (uint)PlayTime);
	WriteInt(&buf[32], (uint)Flags);
	crc = ~crc32(-1,(const Bytef *)&buf[4],32);
	WriteInt(&buf[36], (uint)crc);
	ofs.write(buf, 40);
	return 40;
}

MNGFile::MNGFile()
{
	pngs = nullptr;
}

MNGFile::~MNGFile()
{
	if (pngs)
		delete[] pngs;
}

int MNGFile::WriteEnd(std::ofstream& ofs)
{
	int crc;
	char buf[20];

	buf[0] = 0;
	buf[1] = 0;
	buf[2] = 0;
	buf[3] = 0;
	buf[4] = 'M';
	buf[5] = 'E';
	buf[6] = 'N';
	buf[7] = 'D';

	crc = ~crc32(-1,(const Bytef *)&buf[4],4);
	buf[8] = crc >> 24;
	buf[9] = crc >> 16;
	buf[10] = crc >> 8;
	buf[11] = crc;
	ofs.write(buf, 12);
	return 12;
}

int MNGFile::WriteHeader(std::ofstream& ofs)
{
	unsigned char buf[8];

	buf[0] = 0x8A;
	buf[1] = 'M';
	buf[2] = 'N';
	buf[3] = 'G';
	buf[4] = 0x0D;
	buf[5] = 0x0A;
	buf[6] = 0x1A;
	buf[7] = 0x0A;
	ofs.write((char *)buf, 8);
	return 8;
}

int MNGFile::ReadHeader(std::ifstream& ifs)
{
	char buf[8];
	ifs.read(buf, 8);
	return 8;
}

int MNGFile::ReadTerm(std::ifstream& ifs)
{
	char buf[22];
	ifs.read(buf, 22);
	return 22;
}

int MNGFile::WriteTerm(std::ofstream& ofs)
{
	char buf[24];
	int crc;

	buf[0] = 0;
	buf[1] = 0;
	buf[2] = 0;
	buf[3] = 10;
	buf[4] = 'T';
	buf[5] = 'E';
	buf[6] = 'R';
	buf[7] = 'M';
	buf[8] = 3;
	buf[9] = 0;

	// Delay in ticks before repeating
	buf[10] = 0;
	buf[11] = 0;
	buf[12] = 0;
	buf[13] = 0;

	// Maximum number of iterations
	buf[14] = 0;
	buf[15] = 0;
	buf[16] = 0;
	buf[17] = 10;

	crc = ~crc32(-1,(const Bytef *)&buf[4],14);
	buf[18] = crc >> 24;
	buf[19] = crc >> 16;
	buf[20] = crc >> 8;
	buf[21] = crc;
	ofs.write(buf, 22);
	return 22;
}

int MNGFile::ReadEnd(std::ifstream& ifs)
{
	char buf[12];

	ifs.read(buf, 12);
	return 12;
}

void MNGFile::Load(std::string path)
{
	int nn;

	System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::WaitCursor; 
	std::ifstream fp_in;
	fp_in.open(path,std::ios::in|std::ifstream::binary);
	ReadHeader(fp_in);
	mhdr.Read(fp_in);
	ReadTerm(fp_in);
	pngs = new PNGStream[mhdr.FrameCount];
	for (nn = 0; nn < mhdr.FrameCount; nn++) {
		pngs[nn].Read(fp_in);
	}
	ReadEnd(fp_in);
	fp_in.close();
	System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::Default; 
}

void MNGFile::Save(std::string path)
{
	System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::WaitCursor; 
	std::ofstream fp_out;
	fp_out.open(path,std::ios::out|std::ifstream::binary);
	WriteHeader(fp_out);
	fp_out.close();
	System::Windows::Forms::Cursor::Current = System::Windows::Forms::Cursors::Default; 
}

PNGStream::PNGStream()
{
	bbuf = nullptr;
}

PNGStream::~PNGStream()
{
	if (bbuf)
		delete[] bbuf;
}

void PNGStream::Uncompress()
{
	int dlen;
	int err;
	int xx,yy;
	__int32 *buf32;

	if (accSize <= 0)
		return;
	dlen = 4000000;
	err = uncompress((Bytef *)bbuf, (uLongf *)&dlen, (Bytef *)ibuf, accSize);
	if (err != Z_OK)
		;
	if (ihdr.ColorType != 2) {
	//-----------------------------------------------------------------------
	// These lines of code reformat the buffer with one byte less per
	// scanline. For some unknown reason there's an extra byte on each
	// scanline.
	//-----------------------------------------------------------------------
	for (yy = 0; yy < ihdr.Height; yy++) {
		for (xx = 1; xx <= ihdr.Width*4; xx++) {
			bbuf[xx-1+yy*ihdr.Width*4] = bbuf[xx+yy*(ihdr.Width*4+1)];
		}
	}
						
	//-----------------------------------------------------------------------
	// These lines of code flip around the red and blue bytes which are
	// backwards for the bitmap data.
	//-----------------------------------------------------------------------

	buf32 = (__int32 *)bbuf;
	for (xx = 0; xx < ihdr.Width * ihdr.Height; xx++) {
		buf32[xx] = 0xFF000000 | ((buf32[xx] >> 16) & 0xff) | (buf32[xx] & 0x00FF00) | ((buf32[xx] & 0xff) << 16);
	}
	}
	if (ihdr.ColorType==2) {
		for (yy = 0; yy < ihdr.Height; yy++) {
			for (xx = 1; xx <= ihdr.Width*3; xx++) {
				bbuf[xx-1+yy*ihdr.Width*3] = bbuf[xx+yy*(ihdr.Width*3+1)];
			}
		}
		bmp = gcnew System::Drawing::Bitmap(ihdr.Width, ihdr.Height, ihdr.Width*4, System::Drawing::Imaging::PixelFormat::Format24bppRgb, IntPtr(bbuf));
	}
	else
		bmp = gcnew System::Drawing::Bitmap(ihdr.Width, ihdr.Height, ihdr.Width*4, System::Drawing::Imaging::PixelFormat::Format32bppArgb, IntPtr(bbuf));
}

void PNGStream::Read(std::ifstream& ifs)
{
	int nn;
	char buf[4];
	__int32 i32;
	__int32 size;
	int idatCount;
	int offset = 0;
	int stpos,ndpos;
	MemoryStream^ ms = gcnew MemoryStream;
	array<System::Byte>^ byts = gcnew array<byte>(4000000);

	byts[0] = 0x89;
	byts[1] = 'P';
	byts[2] = 'N';
	byts[3] = 'G';
	byts[4] = '\r';
	byts[5] = '\n';
	byts[6] = '\x1A';
	byts[7] = '\n';

	ms->Write(byts, offset, 8);


	bbuf = new __int8[4000000];
	accSize = 0;
	idatCount =0;
	stpos = ifs.tellg();
	ihdr.Read(ifs);
	while (!ifs.eof()) {
		ifs.read((char *)&i32,4);
		size = rbo(i32);
		ifs.read(buf,4);
		switch(buf[0]) {
		case 'P': case 'p':
			switch(buf[1]) {
			case 'L': case 'l':
				switch(buf[2]) {
				case 'T': case 't':
					switch(buf[3]) {
					case 'E': case 'e':
						for (nn = 0; nn < size; nn++)
							ifs.read(buf,1);
						break;
						ifs.read((char *)&i32,4);
					}
					break;
				}
				break;
			case 'H': case 'h':
				switch(buf[2]) {
				case 'Y': case 'y':
					switch(buf[3]) {
					case 'S': case 's':
						ifs.read(buf,4);
						ifs.read(buf,4);
						ifs.read(buf,1);
						ifs.read(buf,4);
						break;
					}
				}
				break;
			}
			break;
		case 'I': case 'i':
			switch(buf[1]) {
			case 'D': case 'd':
				switch(buf[2]) {
				case 'A': case 'a':
					switch(buf[3]) {
					case 'T': case 't':
						idatCount++;
						ifs.read((char *)&ibuf[accSize], size);
						accSize += size;
						ifs.read((char *)&i32,4);
						break;
					}
					break;
				}
				break;
			case 'E': case 'e':
				switch(buf[2]) {
				case 'N': case 'n':
					switch(buf[3]) {
					case 'D': case 'd':
						ifs.read(buf,4);	// Discard checksum
						goto j1;
					}
					break;
				}
				break;
			}
			break;
		case 'S': case 's':
			switch(buf[1]) {
			case 'R': case 'r':
				switch(buf[2]) {
				case 'G': case 'g':
					switch(buf[3]) {
					case 'B': case 'b':
						ifs.read((char *)&RenderingIntent,1);
						ifs.read((char *)&i32,4);	// Discard checksum
					}
					break;
				}
				break;
			case 'B': case 'b':
				switch(buf[2]) {
				case 'I': case 'i':
					switch(buf[3]) {
					case 'T': case 't':
						switch(ihdr.ColorType) {
						case 0:	// greyscale
							ifs.read((char *)&i32,1);
							ifs.read((char *)&i32,4);
							break;
						case 2:	// truecolor
							ifs.read((char *)&i32,3);
							ifs.read((char *)&i32,4);
							break;
						case 3:	// indexed color
							ifs.read((char *)&i32,3);
							ifs.read((char *)&i32,4);
							break;
						case 4:	// greyscale+alpha
							ifs.read((char *)&i32,2);
							ifs.read((char *)&i32,4);
							break;
						case 6:	// truecolor+alpha
							ifs.read((char *)&i32,4);
							ifs.read((char *)&i32,4);
							break;
						}
						break;
					}
					break;
				}
				break;
			default:
				goto jUnimp;
			}
			break;
		// gAMA	- read and ignore
		case 'G': case 'g':
			switch(buf[1]) {
			case 'A': case 'a':
				switch(buf[2]) {
				case 'M': case 'm':
					switch(buf[3]) {
					case 'A': case 'a':
						ifs.read((char *)&i32,4);
						Gamma = rbo(i32);
						ifs.read((char *)&i32,4);
					}
					break;
				}
				break;
			}
			break;
		// Some other unrecognized chunk
		default:
jUnimp:
			for (nn =  0; nn < size; nn++)
				ifs.read((char *)buf,1);
			ifs.read((char *)&i32,4);
		}
	};
j1:	;
	ndpos = ifs.tellg();
	ifs.seekg(stpos);
	for (nn = stpos; nn < ndpos; nn++) {
		ifs.read((char *)buf,1);
		byts[8 + nn - stpos] = buf[0];
	}
	ms->Write(byts, 8, ndpos-stpos);
	bmp = gcnew System::Drawing::Bitmap(ms);
	ms->Close();
//	Uncompress();
}

void PNGStream::ReadEnd(std::ifstream& ifs)
{
	char buf[12];

	ifs.read(buf, 12);

}
