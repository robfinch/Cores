#pragma once
class clsSystem
{
	bool ROMWriteable;
	__int8 RAM[16777216];
	__int8 VideoRam[262144];	// 680x384
public:
	__int8 ROM[32768];
	clsSystem(void);
	~clsSystem(void);
	unsigned __int8 Read(__int32 ad);
	unsigned __int16 Read16(__int32 ad);
	unsigned __int32 Read24(__int32 ad);
	void Write(__int32 ad, unsigned __int8 db);
	void Write16(__int32 ad, unsigned __int16 db);
};
