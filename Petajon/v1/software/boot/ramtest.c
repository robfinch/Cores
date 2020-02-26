// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// ramtest.c
// Test the system ram.
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
#define BTNC	16
#define BTNU	8
#define BTND	4
#define BTNL	2
#define BTNR	1

#define RAMBOT	0x30000
#define RAMTOP	0x1FFF8000

extern void puthexnum(register int num, register int wid, register int ul, register char padchar);
extern void prtnum(register int num, register int wid, register int base);
extern void putch(register char ch);
extern void PutString(register char *p);
extern void DBGHideCursor(int);
extern void PutHexWord(register int w);

static naked inline int RTGetButton()
{
	asm {
		ldtu	$v0,BUTTONS
	}
}

static void TwoSpaces()
{
	putch(' ');
	putch(' ');
}

void dumpaddr(int *p)
{
	TwoSpaces();
	PutHexWord((int)p);
	putch(' ');
	PutHexWord(p[0]);
	putch('\r');
	putch('\n');
}

static void SetMem(int n1, int n2)
{
	__int32 *p;

	for (p = (__int32 *)RAMBOT; p < (__int32 *)RAMTOP; p+=2) {
		if ((p & 0xFFF)==0) {
			TwoSpaces();
			PutHexWord((int)p>>12);
			putch('\r');
			if (RTGetButton() == BTND)
				return;
		}
		p[0] = (__int32)n1;
		p[1] = (__int32)n2;
	}
}

static void CheckMem(int n1, int n2)
{
	__int32 *p;

	int badcount = 0;
	for (p = (__int32 *)RAMBOT; p < (__int32 *)RAMTOP; p+=2) {
		if ((p & 0xFFF)==0) {
			TwoSpaces();
			PutHexWord((int)p>>12);
			putch('\r');
			if (RTGetButton() == BTND)
				return;
		}
		if (p[0] != (__int32)n1) {
			badcount++;
			dumpaddr(p);
		}
		if (p[1] != (__int32)n2) {
			badcount++;
			dumpaddr(p);
		}
		if (badcount > 10)
			break;
	}
	putch('\r');
	putch('\n');
}

// Basic procedure is to set all memory to the checkerboard pattern:
//     AAAAAAAA
//     55555555
// then read back all memory verifying that what was stored is correct.
// Next the checkerboard pattern is reversed, and checked again.
//
void ramtest()
{
	int *p;

	DBGHideCursor(1);
	PutString(B"  RAM Test\r\n");
	SetMem(0xAAAAAAAA,0x55555555);
	CheckMem(0xAAAAAAAA,0x55555555);
	putch('\r');
	putch('\n');
	SetMem(0x55555555,0xAAAAAAAA);
	CheckMem(0x55555555,0xAAAAAAAA);
	DBGHideCursor(0);
}

