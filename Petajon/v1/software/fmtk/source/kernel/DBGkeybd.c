// The keyboard semaphore is locked only for short durations, so the interrupt
// routine doesn't need to make many attempts to lock the semaphore.
#include <fmtk/const.h>
#include <fmtk/device.h>
#include "config.h"
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

// Important! the array sizes *must* be specified or the compiler will assume
// they're zero.
extern byte keybdExtendedCodes[64];
extern byte keybdControlCodes[64];
extern byte shiftedScanCodes[128];
extern byte unshiftedScanCodes[128];
extern signed byte KeybdGetStatus() __attribute__(__no_temps);
extern byte KeybdGetScancode() __attribute__(__no_temps);
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

int DBGCheckForKey()
{
	return (KeybdGetStatus());	
}

int DBGGetKey(register int block)
{
	unsigned int sc;
	byte ch;
	int count;

	forever {
		for (count = 0; (KeybdGetStatus() & 0x40) != 0 && count < 40000; count++);
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

