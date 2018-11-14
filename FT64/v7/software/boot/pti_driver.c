#define PTI				0xFFFFFFFFFFDC1200L
#define PTI_DAT		0x00
#define PTI_STAT	0x08
#define PTI_TRG		0x10

extern int pti_rbuf;
extern int pti_wbuf;
extern int pti_rcnt;
extern int pti_wcnt;
extern int in64(int port);

void pti_init()
{
	pti_wbuf = 0;
	pti_rbuf = 0;
	pti_rcnt = 0;
	pti_wcnt = 0;
}

int pti_get(int *abortt)
{
	int val;
	int stat;

	if (pti_rcnt == 0) {
		do {
			if (DBGCheckForKey() < 0) {
				if ((DBGGetKey(1) & 0xff) == 0x03) {
					*abortt = 1;
					break;
				}
			}
			stat = in64(PTI|PTI_STAT);
		} until (stat > 0);
		in64(PTI|PTI_TRG);
		pti_rbuf = in64(PTI|PTI_DAT);
	}
	val = (pti_rbuf >> (pti_rcnt << 3)) & 0xff;
	pti_rcnt++;
	pti_rcnt &= 7;
	return (val);
}

void pti_put(int val)
{
	pti_wbuf |= ((val & 0xff) << (pti_wcnt << 3));		
	if (pti_wcnt==7) {
		out64(PTI|PTI_DAT,pti_wbuf);
		pti_wbuf = 0;
	}
	pti_wcnt++;
	pti_wcnt &= 7;
}

void pti_flush()
{
	while (pti_wcnt != 0)
		pti_put(' ');
}
