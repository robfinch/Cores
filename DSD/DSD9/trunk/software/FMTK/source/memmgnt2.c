#define NULL    (void *)0

extern int highest_data_word;
unsigned __int32 *mmu_entries;

// There are 1024 pages in each map. In the normal 64k page size that means a max of
// 64Mib of memory for an app. Since there is 512MB ram in the system that equates
// to 8192 x 64k pages.
#define NPAGES	8192
private __int16 pam[NPAGES];	// page allocation map (links like a DOS FAT)
// There are 128, 4MB pages in the system. Each 4MB page is composed of 64 64kb pages.
private int pam4mb[NPAGES/64];	// 4MB page allocation map (bit for each 64k page)
private __int16 freelist;
int syspages;					// number of pages reserved at the start for the system
int sys_pages_available;	// number of available pages in the system
int sys_4mbpages_available;

private pascal unsigned int round64k(unsigned int amt)
{
    amt += 65535;
    amt &= 0xFFFFFFFFFFFF0000L;
    return amt;
}


// Must be called to initialize the memory system before any
// other calls to the memory system are made.

void init_sys_pages()
{
    int *phdw;
	int pg;
    int nn;

	// Setup linked list of free pages
	for (nn = 0; nn < NPAGES; nn++) {
		pam[nn] = nn+1;
	}
	pam[NPAGES-1] = 0xffff;
	for (nn = 0; nn < NPAGES/64; nn++) {
		pam4mb[nn] = nn+1;
	}
	pam4mb[NPAGES/64-1] = 0xffffffffffffffffL;

    phdw = &highest_data_word;
    phdw = round64k(phdw);
    pg = (phdw >> 16) + 1;
	sys_pages_available = 0;
    if (pg < NPAGES) { // It should be
		freelist = pg;
		freelist4 = (pg >> 6) + ((pg & 63) != 0);
        syspages = pg;
		sys_4mbpages_available = 128-freelist4;
		sys_pages_available = 8192-pg;
    }
}

pascal int alloc_sys_page()
{
    int sb, pg4;

	if (freelist < syspages || freelist >= NPAGES)
		return 0xffff;
	sb = freelist;
	freelist = pam[freelist];
	sys_pages_available--;
	pg4 = (sb >> 6);
	pam4mb[pg4] |= (1 << (sb & 63));
	return sb;
}

// Takes a page number allocated with sys_alloc and returns it to
// available memory pool.
pascal void free_sys_page(int pg)
{
	int pg4;

    if (pg < syspages || pg >= NPAGES)
        return;
	pam[pg] = freelist;
	freelist = pg;
	sys_pages_available++;
	pg4 = (pg >> 6);
	pam4mb[pg4] &= ~(1 << (pg & 63));
}

pascal int alloc_4MB_page()
{
	int cnt;
	int a, c;

	for (a = 0; a < 128; a++) {
		if (pam4mb[a]==0) {
			// Must transverse the free list of 64k pages and remove
			// the allocated pages from the free list.
			for (c = freelist; c >=0 && c < NPAGES; c = pam[freelist]) {
				if (c>>6==a) {
					c = freelist = pam[freelist];
					sys_pages_available--;
				}
			}
			pam4mb[a] = 0xFFFFFFFFFFFFFFFFL;
			return a;
		}
	}	
	return 0xffff;
}

pascal void free_4MB_page(int pg)
{
	int p, cnt;

	if (pg < 0 || pg > 127)
		return;
	p = pg << 6;
	for (cnt = 0; cnt < 64; cnt++, p++)
		free_sys_page(p);
	pam4mb[pg] = 0x0000000000000000L;
}


// In the page table there will be up to 1024 entries.
// Need to find npages of consecutive free entries in the page table.

pascal int findMMUPages(int npages)
{
	int nn, mm;

	if (npages <= 0 || npages > 1024)
		return 0xffff;

	for (nn = 0; nn < 1024; nn++) {
		if ((mmu_entries[nn] & 0x180000) == 0) {	// found an empty entry ?
			mm = nn;
			np = npages;
			while (np > 0) {
				if ((mmu_entries[mm] & 0x180000) != 0) {
					goto L1;
				}
				mm++;
				np--;
			}
			return nn;
		}
L1:	;
	}
	return 0xffff;
}

// Allocate npages from the page table
//
private pascal int allocMMUPages(int npages, int acr)
{
	int first_page;
	int page;
	int n;

	if (acr <= 0 || acr > 7)
		return 0xffff;
	if (npages <= 0 || npages > sys_pages_available)
		return 0xffff;
	first_page = findMMUPages(npages);
	if (first_page==0xffff)
		return first_page;
	for (n = first_page; n < first_page + npages - 1; n++) {
		page = alloc_sys_page();
		mmu_entries[n] = (1 << 19) | (acr << 16) | (page & 0xFFFF);
	}
	page = alloc_sys_page();
	mmu_entries[n] = (2 << 19) | (acr << 16) | (page & 0xffff);
	return first_page;
}

private pascal int alloc4MBMMUPages(int npages, int acr)
{
	int first_page;
	int page;
	int n;

	if (acr <= 0 || acr > 7)
		return 0xffff;
	if (npages*64 <= 0 || npages*64 > sys_pages_available)
		return 0xffff;
	first_page = findMMUPages(npages);
	if (first_page==0xffff)
		return first_page;
	for (n = first_page; n < first_page + npages - 1; n++) {
		page = alloc_sys_page();
		mmu_entries[n] = (1 << 19) | (acr << 16) | (page & 0xFFFF);
	}
	page = alloc_sys_page();
	mmu_entries[n] = (2 << 19) | (acr << 16) | (page & 0xffff);
	return first_page;
}

void freeMMUPages(int first_page)
{
	int n;

	if (first_page < 0 || first_page > 1023)
		return;

	n = first_page;
	while ((mmu_entries[n] & 0x180000)!=100000 && n < 1024) {	// last page ?
		free_sys_page(mmu_entries[n] & 0xffff);
		mmu_entries[n] &= 0x07FFFF;
		n++;
	}
	free_sys_page(mmu_entries[n] & 0xffff);
	mmu_entries[n] &= 0x07FFFF;
}

void free4MBMMUPages(int first_page)
{
	int n;

	if (first_page < 0 || first_page > 1023)
		return;

	n = first_page;
	while ((mmu_entries[n] & 0x180000)!=100000 && n < 1024) {	// last page ?
		free_4MB_page((mmu_entries[n] & 0xffff) >> 6);
		mmu_entries[n] &= 0x07FFFF;
		n++;
	}
	free_4MB_page((mmu_entries[n] & 0xffff) >> 6);
	mmu_entries[n] &= 0x07FFFF;
}

pascal char *mmu_alloc(int amt, int acr)
{
	int page;

	mmu_entries = (unsigned __int32 *)0xFFDC4000;
	if (Is4MBPages()) {
		amt = (amt >> 22) + ((amt & 0x3fffff) != 0);
		page = alloc4MBMMUPages(amt, acr);
	}
	else {
		amt = (amt >> 16) + ((amt & 0xffff) != 0);
		page = allocMMUPages(amt, acr);
	}
	if (page==0xffff)
		return (char *)0;
	else if (Is4MBPages())
		return (char *)(page << 22);
	else
		return (char *)(page << 16);
}

pascal void mmu_free(char *pmem)
{
	mmu_entries = (unsigned __int32 *)0xFFDC4000;
	if (Is4MBPages())
		free4MBMMUPages((int)(pmem >> 22));
	else
		freeMMUPages((int)(pmem >> 16));
}


// The access key for the mmu needs to be setup before the
// page tables can be referenced.

pascal void mmu_setAccessKey()
{
	asm {
		call	_GetMMUMapnum	// get map number in R1
		csrrw	r2,#3,r0	// get PCR
		and		r2,r2,#$FFFF00FF	// mask off access key
		shl		r1,r1,#8
		or		r2,r2,r1	// set access key for map
		csrrw	r0,#3,r2	// set PCR
	}
}