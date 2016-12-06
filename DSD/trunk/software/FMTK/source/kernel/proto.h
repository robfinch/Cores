#ifndef PROTO_H
#define PROTO_H

// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2016  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// proto.h
// Function prototypes.
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
// JCB functions
JCB *GetJCBPtr();                   // get the JCB pointer of the running task

pascal int chkTCB(register TCB *p);
pascal int InsertIntoReadyList(register hTCB ht);
pascal int RemoveFromReadyList(register hTCB ht);
pascal int InsertIntoTimeoutList(register hTCB ht, register int to);
pascal int RemoveFromTimeoutList(register hTCB ht);
void DumpTaskList();

pascal void SetBound48(TCB *ps, TCB *pe, int algn);
pascal void SetBound49(JCB *ps, JCB *pe, int algn);
pascal void SetBound50(MBX *ps, MBX *pe, int algn);
pascal void SetBound51(MSG *ps, MSG *pe, int algn);

pascal void set_vector(register unsigned int, register unsigned int);
int getCPU();
int GetVecno();          // get the last interrupt vector number
void outb(register unsigned int, register int);
void outc(register unsigned int, register int);
void outh(register unsigned int, register int);
void outw(register unsigned int, register int);
pascal int LockSemaphore(register int *sema, register int retries);
naked inline void UnlockSemaphore(register int *sema) __attribute__(__no_temps)
{
	asm {
		sw	r0,[r18]
	}
}
naked inline void SetVBA(register int value)  __attribute__(__no_temps)
{
	asm {
		csrrw	r0,#4,r18
	}
}

// The following causes a privilege violation if called from user mode
#define check_privilege() asm { }

// tasks
void FocusSwitcher();

naked inline void LEDS(register int val)  __attribute__(__no_temps)
{
    asm {
        sh    r18,LEDS
    }
}

#endif
