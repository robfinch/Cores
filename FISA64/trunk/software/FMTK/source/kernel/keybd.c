// The keyboard semaphore is locked only for short durations, so the interrupt
// routine doesn't need to make many attempts to lock the semaphore.

#include "config.h"
#include "const.h"
#include "types.h"
#include "glo.h"
#include "proto.h"

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

unsigned int keybd_irq_stack[256];

void KeybdIRQ()
{
    __int8 sc;
    __int8 kh, kt;
    hTCB ht;
    TCB *t;
    JCB *jcb;
    int nn;

     prolog asm {
         lea   sp,keybd_irq_stack_+2040
         sw    r1,8+312[tr]
         sw    r2,16+312[tr]
         sw    r3,24+312[tr]
         sw    r4,32+312[tr]
         sw    r5,40+312[tr]
         sw    r6,48+312[tr]
         sw    r7,56+312[tr]
         sw    r8,64+312[tr]
         sw    r9,72+312[tr]
         sw    r10,80+312[tr]
         sw    r11,88+312[tr]
         sw    r12,96+312[tr]
         sw    r13,104+312[tr]
         sw    r14,112+312[tr]
         sw    r15,120+312[tr]
         sw    r16,128+312[tr]
         sw    r17,136+312[tr]
         sw    r18,144+312[tr]
         sw    r19,152+312[tr]
         sw    r20,160+312[tr]
         sw    r21,168+312[tr]
         sw    r22,176+312[tr]
         sw    r23,184+312[tr]
         sw    r24,192+312[tr]
         sw    r25,200+312[tr]
         sw    r26,208+312[tr]
         sw    r27,216+312[tr]
         sw    r28,224+312[tr]
         sw    r29,232+312[tr]
         sw    r30,240+312[tr]
         sw    r31,248+312[tr]
         mfspr r1,cr0
         sw    r1,304[tr]
     }
     while (KeybdGetStatus() < 0) {    // Is there actually a scancode available ?
         sc = KeybdGetScancode();
         jcb = IOFocusNdx;             // Are there any jobs with focus ?     
         if (jcb) {
          	 if (ILockSemaphore(&kbd_sema,200)) {
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
                 iof_switch++;       
         }
     }
     // Restore the processor registers and return using an RTI.
     epilog asm {
         lw    r1,304[tr]
         mtspr cr0,r1
         lw    r1,8+312[tr]
         lw    r2,16+312[tr]
         lw    r3,24+312[tr]
         lw    r4,32+312[tr]
         lw    r5,40+312[tr]
         lw    r6,48+312[tr]
         lw    r7,56+312[tr]
         lw    r8,64+312[tr]
         lw    r9,72+312[tr]
         lw    r10,80+312[tr]
         lw    r11,88+312[tr]
         lw    r12,96+312[tr]
         lw    r13,104+312[tr]
         lw    r14,112+312[tr]
         lw    r15,120+312[tr]
         lw    r16,128+312[tr]
         lw    r17,136+312[tr]
         lw    r18,144+312[tr]
         lw    r19,152+312[tr]
         lw    r20,160+312[tr]
         lw    r21,168+312[tr]
         lw    r22,176+312[tr]
         lw    r23,184+312[tr]
         lw    r25,200+312[tr]
         lw    r26,208+312[tr]
         lw    r27,216+312[tr]
         lw    r28,224+312[tr]
         lw    r29,232+312[tr]
         lw    r31,248+312[tr]
         rti
     }
}


// Return -1 if there is a scancode available in the buffer.

int KeybdGetBufferStatus()
{
    JCB *j;
    __int8 kh, kt;

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
    __int8 kh, kt;
    __int8 sc;

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
    unsigned __int8 sc;
    char ch;

    j = GetJCBPtr();
    forever {
        while (KeybdGetBufferStatus() >= 0) {
            if (j->KeybdWaitFlag==0)
                return -1;
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
                          ch = keybdExtendedCodes[sc];
                          j->KeyState1 = 0;
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

