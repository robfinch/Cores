#include "config.h"
#include "const.h"
#include "types.h"
#include "glo.h"
#include "proto.h"

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

unsigned int keybd_irq_stack[512];

void KeybdIRQ()
{
    __int8 sc;
    __int8 kh, kt;
    JCB *jcb;

     prolog asm {
         lea   sp,keybd_irq_stack_+4088
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
     if (KeybdGetStatus() < 0) {       // Is there actually a scancode available
         sc = KeybdGetScancode();
         jcb = IOFocusNdx;             // Are there any jobs with focus ?     
         if (jcb) {
          	 if (LockSemaphore(&sys_sema,10000)) {
                 KeybdClearRcv();              // clear recieve register
                 kh = jcb->KeybdHead;
                 kt = jcb->KeybdTail;
                 kh++;
                 kh &= 15;
                 if (kh <> kt) {
                     jcb->KeybdHead = kh;   
                     jcb->KeybdBuffer[kh] = sc;
                 }
                 UnlockSemaphore(&sys_sema);
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

    j = GetJCBPtr();
    if (LockSemaphore(&sys_sema,-1)) {
        kh = j->KeybdHead;
        kt = j->KeybdTail;
        UnlockSemaphore(&sys_sema);
    }
    if (kh<>kt)
        return -1;
    return 0;
            
}

int KeybdGetBufferedScancode()
{
    JCB *j;
    __int8 kh, kt;
    __int8 sc;

    j = GetJCBPtr();
    if (LockSemaphore(&sys_sema,-1)) {
        kh = j->KeybdHead;
        kt = j->KeybdTail;
        if (kh <> kt) {
            sc = j->KeybdBuffer[kt];
            kt++;
            kt &= 15;
            j->KeybdTail = kt;
        }
        else sc = 0;
        UnlockSemaphore(&sys_sema);
    }
    return sc;
}

private char KeybdGetBufferedChar()
{
    JCB *j;
    __int8 sc;
    char ch;

    j = GetJCBPtr();
    forever {
        while (KeybdGetBufferStatus() >= 0) {
            if (j->KeybdWaitFlag==0)
                return -1;
        }
        sc = KeybdGetBufferedScancode();
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
                break;
            }
            else {
                 if (j->KeyState1) {
                     j->KeyState1 = 0;
                     break;
                 }
                 else {
                      if (j->KeyState2 & 0x80) { // Extended code ?
                          ch = keybdExtendedCodes[sc];
                          j->KeyState1 = 0;
                          j->KeyState2 &= 0x7F;
                          return ch;
                      }
                      else if (j->KeyState2 & 0x04) { // control ?
                          ch = keybdControlCodes[sc];
                          j->KeyState2 &= 0xFB;
                          return ch;
                      }
                      else if (j->KeyState2 & 0x01) { // shifted ?
                          ch = shiftedScanCodes[sc];
                          j->KeyState2 &= 0xFE;
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

