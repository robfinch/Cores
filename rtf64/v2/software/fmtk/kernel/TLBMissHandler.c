#include <fmtk/const.h>
#include <fmtk/device.h>
#include <fmtk/config.h>
#include <fmtk/types.h>
#include <fmtk/glo.h>
#include <fmtk/proto.h>

extern PTE* root_page_table[1024];

typedef struct _tagTLBE align(8)
{
  unsigned int ppn : 20;
  unsigned int pad1 : 12;
  unsigned int vpn : 16;
  unsigned int x : 1;
  unsigned int w : 1;
  unsigned int r : 1;
  unsigned int c : 1;
  unsigned int u : 1;
  unsigned int a : 1;
  unsigned int d : 1;
  unsigned int g : 1;
  unsigned int asid : 8;
} TLBE;

typedef struct _tagTLBA align(8)
{
  unsigned int entryno : 10;
  unsigned int way : 2;
  unsigned int pad : 51;
  unsigned int wr : 1;    
} TLBA;

private naked inline int ReadWriteTLB(register int adr, register int dat)
{
	__asm {
		sync
		tlbrw $a0,$a0,$a1
	}
}

private naked inline int Setkey(register int pageno, register int key)
{
  __asm {
    sync
    setkey $a0,$a0,$a1
  }
}

// Update the TLB with the translation from table in memory.

int TLBMissHandler(unsigned int missAddr)
{
  static int way;
	PTE *p, * q;
	int hash0, hash1;
	unsigned int missPage = missAddr >> 14;
	int count;
	int asid;
	TLBE dat;
	TLBA adr;
	int depth;
	int pe;

  way++;
  p = root_page_table[asid*4+missAddr[63:62]];
  depth = p & 7;
  p = p & ~4095;
  if (depth > 4) {
    pe = (missAddr[61:52]) & 0x3ff;
    p = &p[pe];
    if ((p->x + p->w + p->r)==0)
    	return (E_NotAlloc);
  }
  if (depth > 3) {
    pe = (missAddr[51:42]) & 0x3ff;
    p = &p[pe];
    if ((p->x + p->w + p->r)==0)
    	return (E_NotAlloc);
  }
  if (depth > 2) {
    pe = (missAddr[41:32]) & 0x3ff;
    p = &p[pe];
    if ((p->x + p->w + p->r)==0)
    	return (E_NotAlloc);
  }
  if (depth > 1) {
    pe = (missAddr[31:22]) & 0x3ff;
    p = &p[pe];
    if ((p->x + p->w + p->r)==0)
    	return (E_NotAlloc);
  }
  if (depth > 0) {
    pe = (missAddr[21:12]) & 0x3ff;
    p = &p[pe];
    if ((p->x + p->w + p->r)==0)
    	return (E_NotAlloc);
  }
  dat.ppn = p->ppn;
  dat.vpn = pe;
  dat.x = p->x;
  dat.w = p->w;
  dat.r = p->r;
  dat.c = p->c;
  dat.g = p->g;
  dat.u = p->u;
  dat.a = 0;
  dat.d = 0;
  dat.asid = p->asid;

  adr.entryno = missPage[9:0];
  adr.way = way & 3;
  adr.wr = 1;

  ReadWriteTLB(adr,dat);
  Setkey(p->ppn,p->key);
	return (E_Ok);
}
