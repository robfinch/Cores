// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Waterloo
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

extern pascal void puthexnum(register int num, register int wid, register int ul, register char padchar);
extern pascal void putch(register char ch);
extern void DBGDisplayString(register char *p);
extern void DBGHideCursor(int);

static naked inline int RTGetButton()
{
	asm {
		lw		r1,BUTTONS
	}
}

static void TwoSpaces()
{
	putch(' ');
	putch(' ');
}

void puthex(register int num)
{
	asm {
		mov		r1,r18
		call	_DisplayWord
	}
}

void dumpaddr(register int *p)
{
	TwoSpaces();
	puthex((int)p);
	putch(' ');
	puthex(p[0]);
	putch('\r');
	putch('\n');
}

static void SetMem(register int n1, register int n2)
{
	int *p;

	for (p = (int *)0x10000; p < (int *)67108864; p+=2) {
		if ((p & 0xFFF)==0) {
			TwoSpaces();
			puthex((int)p>>12);
			putch('\r');
			if (RTGetButton() == BTND)
				return;
		}
		p[0] = n1;
		p[1] = n2;
	}
}

static void CheckMem(register int n1, register int n2)
{
	int *p;

	int badcount = 0;
	for (p = (int *)0x10000; p < (int *)67108864; p+=2) {
		if ((p & 0xFFF)==0) {
			TwoSpaces();
			puthex((int)p>>12);
			putch('\r');
			if (RTGetButton() == BTND)
				return;
		}
		if (p[0] != n1) {
			badcount++;
			dumpaddr(p);
		}
		if (p[1] != n2) {
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

//	DBGHideCursor(1);
	DBGDisplayString("  RAM Test\r\n");
	SetMem(0xAAAAAAAA,0x55555555);
	CheckMem(0xAAAAAAAA,0x55555555);
	putch('\r');
	putch('\n');
	SetMem(0x55555555,0xAAAAAAAA);
	CheckMem(0x55555555,0xAAAAAAAA);
//	DBGHideCursor(0);
}

