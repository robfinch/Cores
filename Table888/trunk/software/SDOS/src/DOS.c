#include "ff.h"
#include "stdio.h"

static FATFS fat1;
static char cmdbuf[200];
static char currentPath[300];

void DisplayPrompt()
{
	printf("\r\n%s>",currentPath);
}

void GetCmdLine()
{
	int ch;
	int nn;

	nn = 0;
	memset(cmdbuf, 0, sizeof(cmdbuf));
	asm {
		sb		r0,$7C	; turn off keyboard echo
	}
	do {
		ch = getchar();
		switch (ch) {
		case '\r':
			putch(ch);
			putch(0x0a);
			break;
		case '\b':
			if (nn > 0) {
				nn--;
				putstr("\b \b",3);
			}
			cmdbuf[nn] = 0;
			break;
		default:
			putch(ch);
			cmdbuf[nn] = ch;
			nn++;
		}
	} while (ch != '\r');
	cmdbuf[nn] = 0;
}

void DumpWindow(BYTE *p)
{
	int nn;
	int jj;

	for (nn = 0; nn < 512; nn++) {
		if (nn%16==0)
			printf("\r\n");
		printf("%2x",p[nn]);
		if (nn==256)
			getchar();
		if (nn%16==15) {
			printf("   ");
			for (jj = 0; jj < 16; jj++) {
				if (p[nn-15+jj] < 20 || p[nn-15+jj] > 'Z')
					putch('.');
				else
					putch(p[nn-15+jj]);
			}
		}
	}
}

// Execute code loaded at $C00200

private int xcode()
{
	asm {
		jsr	$C00200
	}
}

// ----------------------------------------------------------------------------
// Run a file.
// ----------------------------------------------------------------------------

void do_run()
{
	FIL fp;
	FRESULT res;
	UINT sz;
	UINT br;
	int er;
	int nn, ii;
	int inquotes;

	static char fname[200];
	char *mem = 0xC00000;

	inquotes = 0;
	nn = ii = 0;
	while (isspace(cmdbuf[nn])) nn++;	// skip leading spaces
	// skip over 'run'
	if (cmdbuf[nn]=='r') nn++; else return;
	if (cmdbuf[nn]=='u') nn++; else return;
	if (cmdbuf[nn]=='n') nn++; else return;
	while (isspace(cmdbuf[nn])) nn++;	// skip any spaces
	do {
		if (cmdbuf[nn] == 0) break;
		if (cmdbuf[nn]=='"') { nn++; inquotes = !inquotes; continue; }
		if (!inquotes && isspace(cmdbuf[nn])) break;
		fname[ii] = cmdbuf[nn];
		nn++; ii++;
	} while (ii < 200);
	if (ii == 0) return;	// no file name

	res = f_open(&fp,fname,FA_OPEN_EXISTING | FA_READ);
	if (res) goto err1;
	sz = f_size(&fp);
	res = f_read(&fp,(void *)mem,sz,&br);
	if (res) goto err1;
	f_close(&fp);
	if (br==0) {
		printf("Can't run file %s.\r\n", fname);
		return;
	}
	f_close(&fp);
	if (mem[0]=='R' && mem[1]=='U' && mem[2]=='N') {
		strcpy(mem,cmdbuf);
		res = xcode();
		if (res != 0)
			printf("%s returned %d\r\n", res);
	}
	else {
		printf("Not a runnable file.\r\n");
	}
	return;
err1:
	f_close(&fp);
	printf("Can't run file(%d) %s.\r\n", er, fname);
}

// ----------------------------------------------------------------------------
// Get a listing of the current directory.
// ----------------------------------------------------------------------------

FRESULT do_dir()
{
	DIR dir2;	// object padding
	DIR dir;
	FRESULT res;
	FILINFO fno;
	char *fn;
	int nn;
	static char lfn[300];
	static TCHAR path[300];

	res = f_getcwd(path, (UINT)sizeof(path)/sizeof(TCHAR));
	fno.lfname = lfn;
	fno.lfsize = sizeof lfn;
	res = f_opendir(&dir, path);
	putstr("\r\n",2);
	if (res == FR_OK) {
		do {
			res = f_readdir(&dir, &fno);
			if (res != FR_OK || fno.fname[0]==0)
				break;
			fn = *fno.lfname ? fno.lfname : fno.fname;
			putnum(fno.fsize,15,',');
			printf(" %s\r\n", fn);
			if (getcharNoWait()==3)
				break;
		} while (1);
	}
	f_closedir(&dir);
	printf("closed dir\r\n");
	return res;
}


// ----------------------------------------------------------------------------
// Change the current directory.
// ----------------------------------------------------------------------------

FRESULT do_cd()
{
	DIR dir;
	FRESULT res;
	static char npath[300];
	static char newpath[300];
	int nn;

	strcpy(newpath, currentPath);
	strcpy(npath, &cmdbuf[2]);
	trim(npath);
	//if (npath[0]=='.') {
	//	if (npath[1]=='.') {
	//		for (nn = strlen(newpath)-1; nn >= 0; nn--) {
	//			if (newpath[nn]=='/')
	//				strcpy(&newpath[nn],&npath[2]);
	//		}
	//	}
	//}
	printf("newpath:%s\r\n",npath);
	res = f_chdir(npath);

//	res = f_opendir(&dir, npath);
	if (res == FR_OK)
		strcpy(currentPath, npath);
	else
		printf("Can't change directory.");
//	f_closedir(&dir);
	return res;
}

private int ParseCmdLine()
{
	static char nm[300];

	if (strncmp(cmdbuf,"dir",3)==0)
		do_dir();
	else if (strncmp(cmdbuf,"cd",2)==0)
		do_cd();
	else if (strncmp(cmdbuf,"cls",3)==0) {
		ClearScreen();
		HomeCursor();
	}
	else if (strncmp(cmdbuf,"bye",3)==0)
		return 1;
	else if (strncmp(cmdbuf,"run",3)==0)
		do_run();
	return 0;
}

#define DATETIME_TIME	0xFFDC0400
#define DATETIME_DATE	0xFFDC0404
#define DATETIME_SNAPSHOT	0xFFDC0414

private naked datetime_snapshot()
{
	asm {
		sh	r0,DATETIME_SNAPSHOT
		rts
	}
}

private unsigned int get_date()
{
	asm {
		lhu	r1,DATETIME_DATE
	}
}

private unsigned int get_time()
{
	asm {
		lhu	r1,DATETIME_TIME
	}
}

void date_split(int date, int *year, int *month, int *day,
	int *hours, int *minutes, int *seconds, int *centiseconds)
{
	// BCD to binary convert
	if (day) {
		*day = (date >> 32) & 15;
		*day = *day + ((date >> 36) & 15) * 10;
	}
	if (month) {
		*month = (date >> 40) & 15;
		*month = *month + ((date >> 44) & 15) * 10;
	}
	if (year) {
		*year = (date >> 48) & 15;
		*year = *year + ((date >> 52) & 15) * 10;
		*year = *year + ((date >> 56) & 15) * 100;
		*year = *year + ((date >> 60) & 15) * 1000;
	}
	if (centiseconds) {
		*centiseconds = date & 15;
		*centiseconds = *centiseconds + ((date >> 4) & 15) * 10;
	}
	if (seconds) {
		*seconds = (date >> 8) & 15;
		*seconds = *seconds + ((date >> 12) & 15) * 10;
	}
	if (minutes) {
		*minutes = (date >> 16) & 15;
		*minutes = *minutes + ((date >> 20) & 15) * 10;
	}
	if (hours) {
		*hours = (date >> 24) & 15;
		*hours = *hours + ((date >> 28) & 15) * 10;
	}
}

// Get the date and time in FAT format.
// Does a lot of constant shifting and multiplication to convert from BCD to
// binary.

DWORD get_fattime()
{
	unsigned int year;
	unsigned int month;
	unsigned int day;
	unsigned int hours;
	unsigned int minutes;
	unsigned int seconds;
	unsigned int date;
	unsigned int time;
	DWORD dt;

	datetime_snapshot();
	date = get_date();
	time = get_time();
	// BCD to binary convert
	day = date & 15;
	day = day + ((date >> 4) & 15) * 10;
	month = (date >> 8) & 15;
	month = month + ((date >> 12) & 15) * 10;
	year = (date >> 16) & 15;
	year = year + ((date >> 20) & 15) * 10;
	year = year + ((date >> 24) & 15) * 100;
	year = year + ((date >> 28) & 15) * 1000;
	seconds = (time >> 8) & 15;
	seconds = seconds + ((time >> 12) & 15) * 10;
	minutes = (time >> 16) & 15;
	minutes = minutes + ((time >> 20) & 15) * 10;
	hours = (time >> 24) & 15;
	hours = hours + ((time >> 28) & 15) * 10;
	year = year - 1980;
	dt = (year << 25) || (month << 21) || (day << 16) ||
		 (hours << 11) || (minutes << 5) || (seconds >> 1);
	return dt;
}

WCHAR ff_convert (WCHAR wch, UINT dir)
{
	if (wch < 0x80) {
		return wch;
	}
	return 0;
}

WCHAR ff_wtoupper (WCHAR wch)
{
	if (wch < 0x80) {
		if (wch >= 'a' && wch <= 'z') {
			wch &= ~0x20;
		}
		return wch;
	}

	return 0;
}

naked ClearScreen()
{
	asm {
		jmp	($8000)
	}
}

naked HomeCursor()
{
	asm {
		jmp	($8008)
	}
}

void InitMem()
{
/*
	// The bootrom setup some pages so the operating system could load.
	asm {
		mfspr	r1,cr0
		ori		r1,r1,#$80000000	; turn on paging
		mtspr	cr0,r1
	}
*/
}

void main()
{
	int nn;

	ClearScreen();
	HomeCursor();
	putstr("Table888 DOS v1.0\r\n",20);
	asm {
		ldi	r1,#$07
		sb	r1,$FFDC0600	; LEDS
	}
	f_mount(&fat1,"3:/", 1);
	f_chdrive("3:/");
	strcpy(currentPath, "3:/");
	forever {
		DisplayPrompt();
		GetCmdLine();
		if (ParseCmdLine())
			break;
	}
}
