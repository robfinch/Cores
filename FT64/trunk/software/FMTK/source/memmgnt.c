// We assume for this code that ints are 64 bit values.
#define NULL    (void *)0
#define MAXPAGE	8192

extern int highest_data_word;
// There are 1024 pages in each map. In the normal 64k page size that means a max of
// 64Mib of memory for an app. Since there is 512MB ram in the system that equates
// to 8192 x 64k pages. Two bits are used to represent the state of each page.
// So 16384 bits are needed for the mapping. This is 2048 bytes or 256 64 bit ints.
private unsigned int pam[256];	// page allocation map
private unsigned int start_bit;
int syspages;

private pascal void setLotReg(int lot, int val)
{
     asm {
         lw    r1,32[bp]
         lw    r2,40[bp]
         mtspr 40,r1
         mtspr 41,r2
     }
}

// Get a bit pair from the pam for the given page.
private int getPamBit(int wb)
{
     int bit;
     int ndx;

     bit = wb & 31;
     ndx = (wb >> 5) << 1;
     return (pam[ndx] >> (bit << 1)) & 3;
}

// Set a bit pair in the pam for a given page.
private void setPamBit(int wb, int val, int whofor, int purpose)
{
     int bit;
     int ndx;

     bit = wb & 31;
     ndx = (wb >> 5) << 1;
     pam[ndx] &= ~(3 << (bit << 1));
     pam[ndx] |= ((val & 3) << (bit << 1));
     setLotReg(wb << 16,((whofor & 0x3ff)<< 6)|((purpose & 7) << 3)|0x6);
}

// Set a string of pam bits
private pascal void setPambits(unsigned int wb, int val, unsigned int numbits, int whofor, int purpose)
{
     for (; numbits > 0; numbits--, wb++)
         setPambit(wb, val, whofor, purpose);
}

private unsigned int find(unsigned int nbits)
{
    unsigned int bitno;
    unsigned int nb;
    unsigned int sb;

    for(bitno = start_bit; bitno < MAXPAGE; bitno++) {
         if (getPamBit(bitno)==0) {
            nb = nbits;
            sb = bitno;
            while (getPamBit(bitno)==0 && nb > 0 && bitno < MAXPAGE) { bitno++, nb--; }
            if (nb <= 0)
                return (sb);
            if (bitno >= MAXPAGE)
                return (0);
        }
    }
    return (0);
}

private pascal unsigned int round64k(unsigned int amt)
{
    amt += 65535;
    amt &= 0xFFFFFFFFFFFF0000L;
    return amt;
}

pascal unsigned int *sys_alloc(unsigned int amt, int whofor, int purpose)
{
    unsigned int *phdw;
    unsigned int pg;
    int nn;
    unsigned int sb;
    unsigned int bits_in_row;

    if firstcall {
        memset(pam, 0, sizeof(pam));
        phdw = &highest_data_word;
        phdw = round64k(phdw);
        pg = (phdw >> 16) + 1;
        if (pg < MAXPAGE) { // It should be
            for (nn = 0; nn < pg; nn++) {
                //setPamBit(nn,1,1,0);
                // page1 and 2 are the bootrom, which is an executable space
                //setLotReg(nn << 16,(1<< 6)|((nn==1||nn==2) ? 0x7 : 0x6));
            }
            start_bit = pg;
            syspages = pg;
        }
    }
    amt = round64k(amt);
    if (amt==0)
        return (NULL);
    bits_in_row = amt >> 16;
    sb = find(bits_in_row);
    if (sb == 0)
        return (NULL);
    setPamBits(sb,1,bits_in_row,whofor,purpose);
    setPamBit(sb+bits_in_row-1,2,whofor,purpose);
    return (sb << 16);
}

pascal void sys_free(unsigned int *p)
{
    unsigned int pg;
    int val;

    if ((p & 0xFFFFL) != 0)
        return;
    pg = p >> 16;
    if (pg < start_bit or pg >= MAXPAGE)
        return;
    do {
        val = getPamBit(pg);
        if (val==1 or val==2)
            setPamBit(pg,0);
        setLotReg(pg << 16,0);
        pg++;
    } while (val==1 and pg < MAXPAGE);
}

