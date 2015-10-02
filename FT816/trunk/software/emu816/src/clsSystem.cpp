#include "StdAfx.h"
#include "clsSystem.h"


clsSystem::clsSystem(void)
{
	ROMWriteable = true;
}


clsSystem::~clsSystem(void)
{
}

unsigned __int8 clsSystem::Read(__int32 ad)
{
	if (ad >= 0x8000 && ad <= 0xFFFF)
		return ROM[ad & 0x7FFF];
	else if (ad >= 0x40000 && ad < 0x80000)
		return VideoRam[ad & 0x3FFFF];
	else
		return RAM[ad];
}

unsigned __int16 clsSystem::Read16(__int32 ad)
{
	unsigned __int16 val;

	val = Read(ad);
	val = val | (Read(ad+1)<<8);
	return val;
}

unsigned __int32 clsSystem::Read24(__int32 ad)
{
	unsigned __int32 val;

	val = Read(ad);
	val = val | (Read(ad+1)<<8);
	val = val | (Read(ad+2)<<16);
	return val;
}

void clsSystem::Write(__int32 ad, unsigned __int8 db)
{
	if (ad >= 0x8000 && ad <= 0xFFFF) {
		if (ROMWriteable)
			ROM[ad & 0x7FFF] = db;
	} 
	else if (ad >= 0x40000 && ad < 0x80000)
		VideoRam[ad & 0x3FFFF] = db;
	else
		RAM[ad] = db;
}

void clsSystem::Write16(__int32 ad, unsigned __int16 db)
{
	Write(ad,db&0xff);
	Write(ad+1,db >> 8);
}

