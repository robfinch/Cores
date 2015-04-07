
char *msgBadAddr = "bad at address: \0";

private void putaddr(unsigned int ad)
{
    asm {
        push  lr
        lw    r1,24[bp]
        bsr   DisplayHalf
        ldi   r1,#'\r'
        bsr   DisplayChar
        pop   lr
    }
}

private void badaddr(unsigned int ad)
{
    asm {
        push   lr
        lea    r1,msgBadAddr
        bsr    DisplayString16
        lw     r1,24[bp]
        bsr    DisplayHalf
        ldi    r1,#'='
        bsr    DisplayChar
        lw     r1,24[bp]
        lw     r1,[r1]
        bsr    DisplayHalf
        bsr    CRLF
        pop    lr
        }
}

// ----------------------------------------------------------------------------
// Test the RAM in the machine above $400000 (Above the DOS area).
// If there is bad memory detected, then the DOS area is likely bad as well
// because it's the same DRAM. However we may be able to tell a specific
// bank or range of addresses that are bad.
// ----------------------------------------------------------------------------

private void ramtest_between(unsigned int stadr, unsigned int endadr, unsigned int testpat)
{
	int *mem;
	int badcnt;
	char ch;

    stadr >>= 3;                       // convert to word addresses
    endadr >>= 3;
    mem = (int *)stadr;
	badcnt = 0;
	for (mem = (int *)stadr; mem < (int *)endadr; mem++) {
		mem[0] = testpat;
		if ((mem & 0xfff)==0) {
            putaddr(mem >> 12);
			ch = getcharNoWait();
			if (ch==3)
				goto j1;
		}
	}
	asm { bsr CRLF };
	for (mem = (int *)stadr; mem < (int *)endadr; mem++) {
		if (mem[0] != testpat) {
			badaddr(mem);
			badcnt++;
		}
		if (badcnt > 10)
			break;
		if ((mem & 0xfff)==0) {
            putaddr(mem >> 12);
			ch = getcharNoWait();
			if (ch==3)
				goto j1;
		}
	}
j1:	;
}

void ramtest()
{
     ramtest_between(0x8000, 0x10000, 0xAAAA5555AAAA5555L);
     ramtest_between(0x8000, 0x10000, 0x5555AAAA5555AAAAL);
     ramtest_between(0x20000, 0x8000000, 0xAAAA5555AAAA5555L);
     ramtest_between(0x20000, 0x8000000, 0x5555AAAA5555AAAAL);
}
