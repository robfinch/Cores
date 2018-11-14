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
extern unsigned int *S19Address;
extern unsigned int *S19StartAddress;
extern unsigned int (*ExecAddress)();
extern int HexChecksum;
extern void pti_init();
extern int pti_get(int *);
extern void pti_put(char);
extern void pti_flush();

static int GetChar()
{
	int ch;

	ch = pti_get(&S19Abort, 100);
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
	num = ASciiToNybble(ch);
	if (S19Abort)
		return (num);
	num <<= 4;
	ch = GetChar();
	num |= ASciiToNybble(ch);
	HexChecksum += num;
	return (num);
}

static void Get16BitAddress()
{
	int num;
	
	S19Address &= 0xFFFF0000;
	S19Address |= GetByte() << 8;
	if (S19Abort)
		return;
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
		if (S19Abort)
			break;
		*S19Address = byt;
		S19Address++;
	}
	// Get the checksum byte
	byt = GetByte();	
}

static void NextRec()
{
	char ch;
	
	do {
		ch = GetChar();
	} while (ch != 0x0A && !S19Abort);
}

void HexLoader()
{
	char ch;
	char rectype;
	FILE *fp;
	
	pti_init();
	fp = fopen("PTI",0,0);
	fputc(XON,fp);
//	pti_put(XON);
	DBGDisplayStringCRLF("Intel Hex Loader Active");
	S19Address = 0;
	S19Abort = 0;
	ExecAddress = 0;
	forever {
		ch = GetChar();
		if (ch == -1)
			continue;
		// The record must start with a ':'
		if (ch != ':')
			goto nextrec;
		// Followed by number of data bytes
		HexChecksum = 0;
		S19Reclen = GetByte();
		if (S19Abort)
			break;
		Get16BitAddress();
		rectype = GetByte();
		if (S19Abort)
			break;
		switch(rectype) {
		case 00:	PutMem(); break;
		case 01:	NextRec(); goto xit;
		case 02:	GetAddressExtension16(); break;
		case 04:	GetAddressExtension(); break;
		case 05:	GetExecAddress(); break;
		default:	;
		}
nextrec:
		if ((HexChecksum & 0xff) != 0)
			DBGDisplayChar('E');
		DBGDisplayChar('.');
		NextRec();
		if (S19Abort)
			break;
	}
xit:
	pti_put('O');
	pti_put('K');
	pti_put('\r');
	pti_put('\n');
	pti_flush();
	if (fp)
		fclose(fp);
	if (ExecAddress)
		(*ExecAddress)();
}
