#include "diskio.h"

naked MMC_disk_initialize()
{
	asm {
		jsr	($8030)		; SDInit
		brnz r1,.j1
		jsr	($8048)		; SDReadPart - to get the disk size
.j1:
		rts
	}
}

int MMC_disk_read(byte *buff, int sector, int count)
{
	asm {
		lw	r1,40[bp]
		lw	r2,32[bp]
		lw	r3,48[bp]
		jsr	($8038)		; SDReadMultiple
	}
}

int MMC_disk_write(byte *buff, int sector, int count)
{
	asm {
		lw	r1,40[bp]
		lw	r2,32[bp]
		lw	r3,48[bp]
		jsr	($8040)		; SDWriteMultiple
	}
}

int MMC_disk_status()
{
	return 0;
}

int MMC_disk_ioctl(int cmd, void *buff)
{
	switch(cmd) {
	case CTRL_SYNC:			/* Flush disk cache (for write functions) (not required) */
		return 0;
	case GET_SECTOR_COUNT:	
		asm {
			jsr	($8050)		; get disk size
			lw	r2,40[bp]
			sw	r1,[r2]
		}
		return 0;
	case GET_SECTOR_SIZE:	/* Get sector size (for multiple sector size (_MAX_SS >= 1024)) */
		*(int *)buff = 512;
		return 0;
	case GET_BLOCK_SIZE:	/* Get erase block size (for only f_mkfs()) */
		*(int *)buff = 512;
		return 0;
	case CTRL_ERASE_SECTOR:	/* Force erased a block of sectors (for only _USE_ERASE) */
		return 0;
	}
}
