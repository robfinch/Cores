// The keyboard semaphore is locked only for short durations, so the interrupt
// routine doesn't need to make many attempts to lock the semaphore.

#include "config.h"
#include "const.h"
#include "types.h"
#include "glo.h"
#include "proto.h"

#define SC_F12      0x07
#define SC_C        0x21
#define SC_T        0x2C
#define SC_Z        0x1A
#define SC_KEYUP	0xF0
#define SC_EXTEND   0xE0
#define SC_CTRL		0x14
#define SC_RSHIFT	0x59
#define SC_NUMLOCK	0x77
#define SC_SCROLLLOCK	0x7E
#define SC_CAPSLOCK	0x58
#define SC_ALT		0x11
/*
#define SC_LSHIFT	EQU		$12
SC_DEL		EQU		$71		; extend
SC_LCTRL	EQU		$58
*/
#define SC_TAB      0x0D

extern byte keybdExtendedCodes[];
extern byte keybdControlCodes[];
extern byte shiftedScanCodes[];
extern byte unshiftedScanCodes[];
extern signed byte KeybdGetStatus();
extern byte KeybdGetScancode();
extern void KeybdClearRcv();
int kbd_sema = 0;
int int_level;

//
// KeyState2_
// 876543210
// ||||||||+ = shift
// |||||||+- = alt
// ||||||+-- = control
// |||||+--- = numlock
// ||||+---- = capslock
// |||+----- = scrolllock
// ||+------ =
// |+------- = 
// +-------- = extended
//

int keybd_irq_stack[256];
static hMBX hKeybdMbx = -1;

void KeybdIRQ()
{
    __int16 sc;
    __int16 kh, kt;
    hTCB ht;
    TCB *t;
    JCB *jcb;
    int nn;

    prolog asm {
		lw		r1,_int_level
		bgtu	r1,#14,.j1
		add		r1,r1,#1
		sw		r1,_int_level
		ipush
		cli
		ld		sp,#keybd_irq_stack_+510
		push	r3
		push	r4
		push	r5
		push	r6
		push	r7
		push	r8
		push	r9
		push	r10
		push	r11
		push	r12
		push	r13
		push	r14
		push	r15
		push	r16
		push	r17
		push	r18
		push	r19
		push	r20
		push	r21
		push	r22
		push	r23
		push	r24
		push	r25
		push	r26
		push	r27
		push	r28
		push	r29
		push	r30
     }
     while (KeybdGetStatus() < 0) {    // Is there actually a scancode available ?
         sc = KeybdGetScancode();
         jcb = IOFocusNdx;             // Are there any jobs with focus ?     
         if (jcb) {
          	 if (LockSemaphore(&kbd_sema,200)) {
                 KeybdClearRcv();              // clear recieve register
                 kh = jcb->KeybdHead;
                 kt = jcb->KeybdTail;
                 kh++;
                 kh &= 31;
                 if (kh <> kt) {
                     jcb->KeybdHead = kh;   
                     jcb->KeybdBuffer[kh] = sc;
                 }
                 UnlockSemaphore(&kbd_sema);
             }
             // Trigger debugger if F12 pressed. Set a breakpoint at the IRET
             // return address.
             if (sc==SC_F12 && !jcb->KeyState1) {
                 asm {
					 csrrw	r1,#$40,r0		// r1 = epc
                     //mtspr  dbad0,r1      ; Set breakpoint 0 address
                     //mfspr  r1,dbctrl
                     //or     r1,r1,#1      ; enable breakpoint #0
                     //and    r1,r1,#~0x30000
                     //mtspr  dbctrl,r1
                 }
             }
             // If CTRL-C is pressed, cause the tasks to return to the 
             // catch handler.
             if (jcb->KeyState2 & 4) {
                 if(sc == SC_C) {      // control-c ?
                     for (nn = 0; nn < 8; nn++) {
                         if (jcb->tasks[nn]==-1)
                             break;
                         t = &tcbs[jcb->tasks[nn]];
                         t->exception = 512+3;     // CTRL-C type exception
                     }
                 }
                 else if (sc==SC_T || sc==SC_Z) {
                      t = &tcbs[2];
                      t->exception = (512 + ((sc==SC_T) ? 20 : 26)) | (GetRunningTCB() << 32);
                 }
             }
             if ((jcb->KeyState2 & 2) && sc == SC_TAB)    // ALT + TAB ?
                 if (hFocusSwitchMbx > 0)
                     FMTK_PostMsg(hFocusSwitchMbx,-1,-1,-1);
//                 iof_switch++;
         }
         if (hKeybdMbx >= 0)
            FMTK_PostMsg(hKeybdMbx,-1,-1,-1);
     }
     // Restore the processor registers and return using an RTI.
	epilog asm {
		pop		r30
		pop		r29
		pop		r28
		pop		r27
		pop		r26
		pop		r25
		pop		r24
		pop		r23
		pop		r22
		pop		r21
		pop		r20
		pop		r19
		pop		r18
		pop		r17
		pop		r16
		pop		r15
		pop		r14
		pop		r13
		pop		r12
		pop		r11
		pop		r10
		pop		r9
		pop		r8
		pop		r7
		pop		r6
		pop		r5
		pop		r4
		pop		r3
		sei
		dec		_int_level
		ipop
.j1:
        iret
     }
}


// Return -1 if there is a scancode available in the buffer.

int KeybdGetBufferStatus()
{
    JCB *j;
    __int16 kh, kt;

    kh = kt = 0;
    j = GetJCBPtr();
    if (LockSemaphore(&kbd_sema,200)) {
        kh = j->KeybdHead;
        kt = j->KeybdTail;
        UnlockSemaphore(&kbd_sema);
    }
    if (kh<>kt)
        return -1;
    return 0;
            
}

// Get a scancode from the keyboard buffer.

__int8 KeybdGetBufferedScancode()
{
    JCB *j;
    __int16 kh, kt;
    __int16 sc;

    j = GetJCBPtr();
    sc = 0;
    if (LockSemaphore(&kbd_sema,200)) {
        kh = j->KeybdHead;
        kt = j->KeybdTail;
        if (kh <> kt) {
            sc = j->KeybdBuffer[kt];
            kt++;
            kt &= 31;
            j->KeybdTail = kt;
        }
        UnlockSemaphore(&kbd_sema);
    }
    return sc;
}

private char KeybdGetBufferedChar()
{
    JCB *j;
    unsigned __int16 sc;
    char ch;
    int d1, d2, d3;

    if firstcall {
        FMTK_AllocMbx(&hKeybdMbx);
    }
    j = GetJCBPtr();
    forever {
        while (KeybdGetBufferStatus() >= 0) {
            if (j->KeybdWaitFlag==0)
                return -1;
            FMTK_WaitMsg(hKeybdMbx, &d1, &d2, &d3, 0x7FFFFFFF);
        }
        // The following typecast is needed to avoid a compiler bug in the
        // optimizer which removes the conversion from byte to word by zero
        // extension.
        sc = (unsigned __int8)KeybdGetBufferedScancode();
        switch(sc) {
        case SC_KEYUP:
            j->KeyState1 = -1;
            break;
        case SC_EXTEND:
            j->KeyState2 |= 0x80;
            break;
        case SC_CTRL:
            if (j->KeyState1 >= 0)
                j->KeyState2 |= 4;
            else
                j->KeyState2 &= ~4;
            j->KeyState1 = 0;
            break;
        case SC_RSHIFT:
            if (j->KeyState1 >= 0)
                j->KeyState2 |= 1;
            else
                j->KeyState2 &= ~1;
            j->KeyState1 = 0;
            break;
        case SC_NUMLOCK:
            j->KeyState2 ^= 16;
            //KeybdSetLEDStatus();
            break;
        case SC_CAPSLOCK:
            j->KeyState2 ^= 32;
            //KeybdSetLEDStatus();
            break;
        case SC_SCROLLLOCK:
            j->KeyState2 ^= 64;
            //KeybdSetLEDStatus();
            break;
        case SC_ALT:
            if (j->KeyState1 >= 0)
                j->KeyState2 |= 2;
            else
                j->KeyState2 &= ~2;
            j->KeyState1 = 0;
            break;
        default:
            if (sc == SC_TAB && (j->KeyState2 & 2) && j->KeyState1==0) {
                iof_switch++;
            }
            else {
                 if (j->KeyState1) {
                     j->KeyState1 = 0;
                 }
                 else {
                      if (j->KeyState2 & 0x80) { // Extended code ?
                          j->KeyState2 &= ~0x80;
                          ch = keybdExtendedCodes[sc];
                          return ch;
                      }
                      else if (j->KeyState2 & 0x04) { // control ?
                          ch = keybdControlCodes[sc];
                          return ch;
                      }
                      else if (j->KeyState2 & 0x01) { // shifted ?
                          ch = shiftedScanCodes[sc];
                          return ch;
                      }
                      else {
                          ch = unshiftedScanCodes[sc];
                          return ch;
                      }
                 }
            }
        }
    }
}

char KeybdGetBufferedCharWait() {
    JCB *j;
    j = GetJCBPtr();
    j->KeybdWaitFlag = 1;
    return KeybdGetBufferedChar();     
}

char KeybdGetBufferedCharNoWait() {
    JCB *j;
    j = GetJCBPtr();
    j->KeybdWaitFlag = 0;
    return KeybdGetBufferedChar();     
}

