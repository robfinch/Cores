// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// TCB.c
// Task Control Block related functions.
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
#include "config.h"
#include "const.h"
#include "types.h"
#include "proto.h"
#include "glo.h"
#include "TCB.h"

extern char hasUltraHighPriorityTasks;
extern pascal prtdbl(double);

pascal int chkTCB(register TCB *p)
{
    __asm {
        chk   r1,r18,b48
    }
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

pascal int InsertIntoReadyList(register hTCB ht)
{
    hTCB hq;
    TCB *p, *q;

//    __check(ht >=0 && ht < NR_TCB);
    p = &tcbs[ht];
	if (p->priority > 077 || p->priority < 000)
		return E_BadPriority;
	if (p->priority < 003)
	   hasUltraHighPriorityTasks |= (1 << p->priority);
	p->status = TS_READY;
	hq = readyQ[p->priority>>3];
	// Ready list empty ?
	if (hq<0) {
		p->next = ht;
		p->prev = ht;
		readyQ[p->priority>>3] = ht;
		return E_Ok;
	}
	// Insert at tail of list
	q = &tcbs[hq];
	p->next = hq;
	p->prev = q->prev;
	tcbs[q->prev].next = ht;
	q->prev = ht;
	return E_Ok;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

pascal int RemoveFromReadyList(register hTCB ht)
{
    TCB *t;

//    __check(ht >=0 && ht < NR_TCB);
    t = &tcbs[ht];
	if (t->priority > 077 || t->priority < 000)
		return E_BadPriority;
    if (ht==readyQ[t->priority>>3])
       readyQ[t->priority>>3] = t->next;
    if (ht==readyQ[t->priority>>3])
       readyQ[t->priority>>3] = -1;
    tcbs[t->next].prev = t->prev;
    tcbs[t->prev].next = t->next;
    t->next = -1;
    t->prev = -1;
    t->status = TS_NONE;
    return E_Ok;
}


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

pascal int InsertIntoTimeoutList(register hTCB ht, register int to)
{
    TCB *p, *q, *t;

//    __check(ht >=0 && ht < NR_TCB);
    t = &tcbs[ht];
    if (TimeoutList<0) {
        t->timeout = to;
        TimeoutList = ht;
        t->next = -1;
        t->prev = -1;
        return E_Ok;
    }

    q = null;
    p = &tcbs[TimeoutList];

    while (to > p->timeout) {

        to -= p->timeout;
        q = p;
        p = &tcbs[p->next];

    }

    t->next = p - tcbs;
    t->prev = q - tcbs;
    if (p) {
        p->timeout -= to;
        p->prev = ht;
    }
    if (q)
        q->next = ht;
    else
        TimeoutList = ht;
    t->status |= TS_TIMEOUT;
    return E_Ok;

};

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

pascal int RemoveFromTimeoutList(register hTCB ht)
{
    TCB *t;
    
//    __check(ht >=0 && ht < NR_TCB);
    t = &tcbs[ht];
    if (t->next) {
       tcbs[t->next].prev = t->prev;
       tcbs[t->next].timeout += t->timeout;
    }
    if (t->prev >= 0)
       tcbs[t->prev].next = t->next;
    t->status = TS_NONE;
    t->next = -1;
    t->prev = -1;
}

// ----------------------------------------------------------------------------
// Pop the top entry from the timeout list.
// ----------------------------------------------------------------------------

hTCB PopTimeoutList()
{
    TCB *p;
    hTCB h;

    h = TimeoutList;
    if (TimeoutList >= 0 && TimeoutList < NR_TCB) {
        TimeoutList = tcbs[TimeoutList].next;
        if (TimeoutList >= 0 && TimeoutList < NR_TCB) {
            tcbs[TimeoutList].prev = h->prev;
            h->prev->next = TimeoutList;
        }
    }
    return h;
}


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void DumpTaskList()
{
     TCB *p, *q;
     int n;
     int kk;
     hTCB h, j;
   
//     printf("pi is ");
//     prtdbl(3.141592653589793238,10,6,'E');
     printf("CPU Pri Stat Task Prev Next Timeout\r\n");
     for (n = 0; n < 8; n++) {
         h = readyQ[n];
         if (h >= 0 && h < NR_TCB) {
             q = &tcbs[h];
             p = q;
             kk = 0;
             do {
//                 if (!chkTCB(p)) {
//                     printf("Bad TCB (%X)\r\n", p);
//                     break;
//                 }
                   j = p - tcbs;
                 printf("%3d %3d  %02X  %04X %04X %04X %08X %08X\r\n", p->affinity, p->priority, p->status, (int)j, p->prev, p->next, p->timeout, p->ticks);
                 if (p->next < 0 || p->next >= NR_TCB)
                     break;
                 p = &tcbs[p->next];
                 if (getcharNoWait()==3)
                    goto j1;
                 kk = kk + 1;
             } while (p != q && kk < 10);
         }
     }
     printf("Waiting tasks\r\n");
     h = TimeoutList;
     while (h >= 0 && h < NR_TCB) {
         p = &tcbs[h];
         printf("%3d %3d  %02X  %04X %04X %04X %08X %08X\r\n", p->affinity, p->priority, p->status, (int)j, p->prev, p->next, p->timeout, p->ticks);
         h = p->next;
         if (getcharNoWait()==3)
            goto j1;
     }
j1:  ;
}


