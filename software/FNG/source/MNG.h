#pragma once
#define uint	unsigned int

namespace FinitronClasses
{

class IHDR
{
public:
	int Width;
	int Height;
	__int8 BitDepth;
	__int8 ColorType;
	__int8 CompressionMethod;
	__int8 FilterMethod;
	__int8 InterlaceMethod;
public:
	unsigned int ReadInt(unsigned char *buf);
	void Read(std::ifstream& ifs);
};

class PLTE
{
public:
	unsigned int ReadInt(char *buf);
	void Read(std::ifstream& ifs);
};


class PNGStream
{
	static __int8 ibuf[4000000];	// compressed image buffer
	__int8 *bbuf;	// uncompressed image buffer
	int accSize;	// accumulated size
public:
	IHDR ihdr;
	PLTE plte;
	__int8 RenderingIntent;	// sRGB
	__int32 Gamma;
	gcroot<System::Drawing::Bitmap^> bmp;
private:
	void Uncompress();
public:
	PNGStream();
	~PNGStream();
	void Read(std::ifstream& ifs);
	void ReadEnd(std::ifstream& ifs);
};

class MHDR
{
public:
	int FrameWidth;
	int FrameHeight;
	int TicksPerSecond;
	int LayerCount;
	int FrameCount;
	int PlayTime;
	int Flags;
	PNGStream *pngs;
public:
	MHDR();
	void WriteInt(char *buf, unsigned int n);
	int Write(std::ofstream& ofs);
	unsigned int ReadInt(unsigned char *buf);
	int Read(std::ifstream& ifs);
};

class MNGFile
{
public:
	MHDR mhdr;
	PNGStream *pngs;
public:
	MNGFile();
	~MNGFile();
	void Save(std::string path);
	int WriteHeader(std::ofstream& ofs);
	int WriteTerm(std::ofstream& ofs);
	int WriteEnd(std::ofstream& ofs);
	void Load(std::string path);
	int ReadHeader(std::ifstream& ofs);
	int ReadTerm(std::ifstream& ofs);
	int ReadEnd(std::ifstream& ifs);
};

}
