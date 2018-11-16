// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	HexLoader.c
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
// ============================================================================
//
#include <stdio.h>

#define XON				0x11
#define XOFF			0x13
extern int DBGCheckForKey();
extern int DBGGetKey(int block);
extern __int8 S19Abort;
extern __int8 S19Reclen;
extern unsigned __int8 *S19Address;
extern unsigned int *S19StartAddress;
extern unsigned int (*ExecAddress)();
extern __int16 spinner;
extern int HexChecksum;
extern void pti_init();
extern int pti_get(int *);
extern void pti_put(char);
extern void pti_flush();

static int GetChar()
{
	int ch;
	int *p;
	
	p = 0xFFFFFFFFFFD00178L;
	p[0] = (p[0] & 0xFFFFFFFFFFFF0000) | spinner;
	spinner++;
	ch = pti_get();
	if (ch > 0)
		DBGDisplayChar(ch);
	return (ch);
}

static int AsciiToNybble(char ch)
{
	if (ch >= 'a' && ch <= 'f')
		return (ch - 'a' + 10);
	if (ch >= 'A' && ch <= 'F')
		return (ch - 'A' + 10);
	if (ch >= '0' && ch <= '9')
		return (ch - '0');
	return (-1);
}

static int GetByte()
{
	char ch;
	int num;

	ch = GetChar();
	num = AsciiToNybble(ch);
	num <<= 4;
	ch = GetChar();
	num |= AsciiToNybble(ch);
	HexChecksum += num;
	return (num);
}

static void Get16BitAddress()
{
	int num;
	
	S19Address &= 0xFFFFFFFFFFFF0000;
	S19Address |= GetByte() << 8;
	S19Address |= GetByte();
	return;
}

static void GetAddressExtension16()
{
	int num;

	S19Address &= 0xFFFF;
	num = GetByte() << 8;
	num |= GetByte();
	num <<= 4;
	S19Address += num;
	GetByte();	// get checksum
}

static void GetAddressExtension()
{
	S19Address &= 0xFFFF;
	S19Address |= GetByte() << 24;
	S19Address |= GetByte() << 16;
	GetByte();	// get checksum
}

static void GetExecAddress()
{
	ExecAddress = 0;
	ExecAddress |= GetByte() << 24;
	ExecAddress |= GetByte() << 16;
	ExecAddress |= GetByte() << 8;
	ExecAddress |= GetByte();
	GetByte();	
}

static void PutMem()
{
	int n;
	int byt;

	for (n = 0; n < S19Reclen; n++) {
		byt = GetByte();
		*S19Address = byt;
		S19Address++;
	}
	// Get the checksum byte
	byt = GetByte();	
}

static void PutString(char *str)
{
	char ch;
	while (ch = *str) { pti_put(ch); str++; }
}

void HexLoader()
{
	char ch;
	char rectype;
	FILE *fp;
	
	fp = 0;
	pti_init();
	//fp = fopen("PTI",0,0);
	//fputc(XON,fp);
//	pti_put(XON);
//	PutString("Intel Hex Loader Active\n");
//	PutString("Send file\n");
	DBGDisplayStringCRLF("Intel Hex Loader Active");
	S19Address = 0;
	S19Abort = 0;
	ExecAddress = 0;
	forever {
		ch = DBGGetKey(0);
		if (ch == 'C' || ch=='c' || ch == 0x03)
			break;
		ch = GetChar();
		if (ch == -1)
			continue;
		// The record must start with a ':'
		if (ch != ':')
			continue;
		// Followed by number of data bytes
		HexChecksum = 0;
		S19Reclen = GetByte();
		Get16BitAddress();
		rectype = GetByte();
		switch(rectype) {
		case 00:	PutMem(); break;
		case 01:	goto xit;
		case 02:	GetAddressExtension16(); break;
		case 04:	GetAddressExtension(); break;
		case 05:	GetExecAddress(); break;
		default:	;
		}
		if ((HexChecksum & 0xff) != 0)
			DBGDisplayChar('E');
		DBGDisplayChar('.');
	}
xit:
	;
//	PutString("OK\n");
//	pti_flushi();
//	if (fp)
//		fclose(fp);
//	if (ExecAddress)
//		(*ExecAddress)();
}
