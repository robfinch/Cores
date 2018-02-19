// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// glo.h
// Global variables.
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
#ifndef _GLO_H
#define _GLO_H

extern int irq_stack[];
extern int FMTK_Inited;
extern ACB *ACBPtrs[64];
extern TCB tcbs[];
extern hTCB readyQ[];
extern hTCB freeTCB;
extern int sysstack[];
extern int stacks[][];
extern int sys_stacks[][];
extern int bios_stacks[][];
extern int fmtk_irq_stack[];
extern int fmtk_sys_stack[];
extern MBX mailbox[];
extern MSG message[];
extern int nMsgBlk;
extern int nMailbox;
extern hMSG freeMSG;
extern hMBX freeMBX;
extern ACB *IOFocusNdx;
extern int IOFocusTbl[];
extern int iof_switch;
extern int BIOS1_sema;
extern int iof_sema;
extern int sys_sema;
extern int kbd_sema;
extern int BIOS_RespMbx;
extern char hasUltraHighPriorityTasks;
extern int missed_ticks;
extern short int video_bufs[][];
extern hTCB TimeoutList;
extern hMBX hFocusSwitchMbx;

#endif
