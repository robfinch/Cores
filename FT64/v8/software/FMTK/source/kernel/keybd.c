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
#define SC_DEL			0x71	// extend
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
extern void KeybdSetLED(register int val);
extern __int8 KeyState1;
extern __int8 KeyState2;
extern __int8 KeyLED;

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

extern int keybd_irq_stack[256];
extern hMBX hKeybdMbx = -1;

void interrupt KeybdIRQ()
{
    __int16 sc;
    __int16 kh, kt;
    hTCB ht;
    TCB *t;
    ACB *pACB;
    int nn;

    prolog asm {
		ldi		sp,#_keybd_irq_stack+1016
     }
     while (KeybdGetStatus() < 0) {    // Is there actually a scancode available ?
         sc = KeybdGetScancode();
         pACB = IOFocusNdx;            // Are there any jobs with focus ?     
         if (pACB) {
          	 if (LockKbdSemaphore(200)) {
                 KeybdClearRcv();              // clear recieve register
                 kh = pACB->KeybdHead;
                 kt = pACB->KeybdTail;
                 kh++;
                 kh &= 31;
                 if (kh <> kt) {
                     pACB->KeybdHead = kh;   
                     pACB->KeybdBuffer[kh] = sc;
                 }
                 UnlockKbdSemaphore();
             }
             // Trigger debugger if F12 pressed. Set a breakpoint at the IRET
             // return address.
             if (sc==SC_F12 && !pACB->KeyState1) {
                 __asm {
					 csrrd	r1,#$48,r0		// r1 = epc
                     //mtspr  dbad0,r1      ; Set breakpoint 0 address
                     //mfspr  r1,dbctrl
                     //or     r1,r1,#1      ; enable breakpoint #0
                     //and    r1,r1,#~0x30000
                     //mtspr  dbctrl,r1
                 }
             }
             // If CTRL-C is pressed, cause the tasks to return to the 
             // catch handler.
             if (pACB->KeyState2 & 4) {
                 if(sc == SC_C) {      // control-c ?
                 	 for (ht = pACB->thrd; ht >= 0 && ht < NR_TCB; ht = tcbs[ht].acbnext)
                         t = &tcbs[ht];
                         t->exception = 3;	// CTRL-C type exception
                     }
                 }
                 else if (sc==SC_T || sc==SC_Z) {
                      t = &tcbs[2];
                      t->exception = (((sc==SC_T) ? 20 : 26)) | (GetRunningTCB() << 32);
                 }
             }
             if ((pACB->KeyState2 & 2) && sc == SC_TAB)    // ALT + TAB ?
                 if (hFocusSwitchMbx > 0)
                     FMTK_SendMsg(hFocusSwitchMbx,-1,-1,-1);
//                 iof_switch++;
         }
         if (hKeybdMbx >= 0)
            FMTK_SendMsg(hKeybdMbx,-1,-1,-1);
     }
}


// Return -1 if there is a scancode available in the buffer.

int KeybdGetBufferStatus()
{
    ACB *j;
    __int16 kh, kt;

    kh = kt = 0;
    j = GetACBPtr();
    if (LockKbdSemaphore(200)) {
        kh = j->KeybdHead;
        kt = j->KeybdTail;
        UnlockKbdSemaphore();
    }
    if (kh<>kt)
        return -1;
    return 0;
            
}

// Get a scancode from the keyboard buffer.

__int8 KeybdGetBufferedScancode()
{
    ACB *j;
    __int16 kh, kt;
    __int16 sc;

    j = GetACBPtr();
    sc = 0;
    if (LockKbdSemaphore(200)) {
        kh = j->KeybdHead;
        kt = j->KeybdTail;
        if (kh <> kt) {
            sc = j->KeybdBuffer[kt];
            kt++;
            kt &= 31;
            j->KeybdTail = kt;
        }
        UnlockKbdSemaphore();
    }
    return sc;
}

private char KeybdGetBufferedChar()
{
    ACB *j;
    unsigned __int16 sc;
    char ch;
    int d1, d2, d3;

    if firstcall {
        FMTK_AllocMbx(&hKeybdMbx);
    }
    j = GetACBPtr();
    forever {
        while (KeybdGetBufferStatus() >= 0) {
            if (j->KeybdWaitFlag==0)
                return (-1);
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
                          return (ch);
                      }
                      else if (j->KeyState2 & 0x04) { // control ?
                          ch = keybdControlCodes[sc];
                          return (ch);
                      }
                      else if (j->KeyState2 & 0x01) { // shifted ?
                          ch = shiftedScanCodes[sc];
                          return (ch);
                      }
                      else {
                          ch = unshiftedScanCodes[sc];
                          return (ch);
                      }
                 }
            }
        }
    }
}

char KeybdGetBufferedCharWait() {
    ACB *j;
    j = GetACBPtr();
    j->KeybdWaitFlag = 1;
    return (KeybdGetBufferedChar());     
}

char KeybdGetBufferedCharNoWait() {
    ACB *j;
    j = GetACBPtr();
    j->KeybdWaitFlag = 0;
    return (KeybdGetBufferedChar());
}

int DBGCheckForKey()
{
	return (KeybdGetStatus());	
}

int DBGGetKey(int block)
{
	unsigned int sc;
	char ch;
	int count;

	forever {
		for (count = 0; (KeybdGetStatus() & 0x40) != 0 && count < 50000; count++);
		while ((KeybdGetStatus() & 0x80) == 0) {
			if (!block)
				return (-1);
		}
		
		sc = KeybdGetScancode() & 0xff;
		// Delay a little bit before trying to read the next scancode
		for (count = 0; count < 20; count++)
			;
	  switch(sc) {
	  case SC_KEYUP:
      KeyState1 = -1;
      break;
	  case SC_EXTEND:
      KeyState2 |= 0x80;
      break;
	  case SC_CTRL:
      if (KeyState1 >= 0)
        KeyState2 |= 4;
      else
        KeyState2 &= ~4;
      KeyState1 = 0;
      break;
	  case SC_RSHIFT:
      if (KeyState1 >= 0)
        KeyState2 |= 1;
      else
        KeyState2 &= ~1;
      KeyState1 = 0;
      break;
	  case SC_NUMLOCK:
      KeyState2 ^= 16;
      KeyLED ^= 2;
      KeybdSetLED(KeyLED);
      //KeybdSetLEDStatus();
      break;
	  case SC_CAPSLOCK:
      KeyState2 ^= 32;
      KeyLED ^= 4;
      //KeybdSetLEDStatus();
      KeybdSetLED(KeyLED);
      break;
	  case SC_SCROLLLOCK:
      KeyState2 ^= 64;
      //KeybdSetLEDStatus();
      KeyLED ^= 1;
      KeybdSetLED(KeyLED);
      break;
	  case SC_ALT:
      if (KeyState1 >= 0)
        KeyState2 |= 2;
      else
        KeyState2 &= ~2;
      KeyState1 = 0;
      break;
	  default:
	/*
	      if (sc == SC_TAB && (KeyState2 & 2) && KeyState1==0) {
	          iof_switch++;
	      }
	      else
	*/
	    {
				if (KeyState1) {
					KeyState1 = 0;
				}
				else {
					// Do a reset on CTRL-ALT-DEL
					if (((KeyState2 & 0x06)==0x06) && sc==SC_DEL) {
						__asm {
							jmp		$FFFC0100
						}
					}
					else if (KeyState2 & 0x80) { // Extended code ?
						KeyState2 &= ~0x80;
						ch = keybdExtendedCodes[sc];
						return (ch);
					}
					else if (KeyState2 & 0x04) { // control ?
						ch = keybdControlCodes[sc];
						return (ch);
					}
					else if (KeyState2 & 0x01) { // shifted ?
						ch = shiftedScanCodes[sc];
						return (ch);
					}
					else {
						ch = unshiftedScanCodes[sc];
						return (ch);
					}
				}
			}
		}
	}
}
