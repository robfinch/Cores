#include "ff.h"
#include "stdio.h"

static FATFS fat1;
static char cmdbuf[200];
static char currentPath[300];

void DisplayPrompt()
{
	putstr("\r\n>",3);
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

FRESULT do_dir()
{
	DIR dir;
	FRESULT res;
	FILINFO fno;
	char *fn;
	static char lfn[300];

	fno.lfname = lfn;
	fno.lfsize = sizeof lfn;
	res = f_opendir(&dir, currentPath);
	if (res == FR_OK) {
		forever {
			res = f_readdir(&dir, &fno);
			if (res != FR_OK || fno.fname[0]==0)
				break;
			fn = *fno.lfname ? fno.lfname : fno.fname;
			printf("%s\r\n", fn);
		}
	}
	f_closedir(&dir);
	return res;
}

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
	if (npath[0]=='.') {
		if (npath[1]=='.') {
			for (nn = strlen(newpath)-1; nn >= 0; nn--) {
				if (newpath[nn]=='/')
					strcpy(&newpath[nn],&npath[2]);
			}
		}
	}
	res = f_opendir(&dir, newpath);
	if (res == FR_OK)
		strcpy(currentPath, newpath);
	else
		printf("Can't change directory.");
}

void ParseCmdLine()
{
	if (strncmp(cmdbuf,"dir",3)==0)
		do_dir();
	else if (strncmp(cmdbuf,"cd",2)==0)
		do_cd();
}

#define DATETIME_TIME	0xFFDC0400
#define DATETIME_DATE	0xFFDC0404
#define DATETIME_SNAPSHOT	0xFFDC0414

static naked datetime_snapshot()
{
	asm {
		sh	r0,DATETIME_SNAPSHOT
		rts
	}
}

static unsigned int get_date()
{
	asm {
		lhu	r1,DATETIME_DATE
	}
}

static unsigned int get_time()
{
	asm {
		lhu	r1,DATETIME_TIME
	}
}

// Get the date and time in FAT format

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

void main()
{
	ClearScreen();
	HomeCursor();
	asm {
		ldi	r1,#$07
		sb	r1,$FFDC0600	; LEDS
	}
	putstr("Table888 DOS v1.1\r\n",20);
	asm {
		ldi	r1,#$07
		sb	r1,$FFDC0600	; LEDS
	}
	f_mount(&fat1,"3:/", 1);
	strcpy(currentPath, "3:/");
	forever {
		DisplayPrompt();
		GetCmdLine();
		ParseCmdLine();
	}
}

