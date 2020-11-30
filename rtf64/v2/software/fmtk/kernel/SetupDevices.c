#include <fmtk/config.h>
#include <fmtk/device.h>
#include <fmtk/types.h>

// Standard Devices are:
//
// #		Device					Standard name

// 0		NULL device 		NULL				(OS built-in)
// 1		Keyboard (sequential)	KBD		(OS built-in)
// 2		Video (sequential)		VID		(OS built-in)
// 3		Printer (parallel 1)	LPT
// 4		Printer (parallel 2)	LPT2
// 5		RS-232 1				COM1	(OS built-in)
// 6		RS-232 2				COM2
// 7		RS-232 3				COM3
// 8		RS-232 4				COM4
// 9		Parallel xfer	  PTI
// 10		Floppy					FD0
// 11		Floppy					FD1
// 12		Hard disk				HD0
// 13		Hard disk				HD1
// 14
// 15
// 16		SDCard					CARD1 	(OS built-in)
// 17
// 18
// 19
// 20
// 21
// 22
// 23
// 24
// 25
// 26
// 27
// 28		Audio						PSG1	(OS built-in)
// 29		Console					CON		(OS built-in)
// 30   Random Number		PRNG
// 31		Debug						DBG

extern hMBX hDevMailbox[64];
extern DCB DeviceTable[NR_DCB];
extern pascal int null_CmdProc(int cmd, int p1, int p2, int p3, int p4);
extern pascal int kbd_CmdProc(int cmd, int p1, int p2, int p3, int p4);
extern pascal int pti_CmdProc(int cmd, int p1, int p2, int p3, int p4);
extern pascal int dbg_CmdProc(int cmd, int p1, int p2, int p3, int p4);
extern pascal int prng_CmdProc(int cmd, int p1, int p2, int p3, int p4);
extern pascal int sdc_CmdProc(int cmd, int p1, int p2, int p3, int p4);
extern pascal int con_CmdProc(int cmd, int p1, int p2, int p3, int p4);

void SetupDevices()
{
	DCB *p;
	int n;

  for (n = 0; n < 32; n++) {
    FMTK_AllocMbx(&hDevMailbox[nn*2]);
    FMTK_AllocMbx(&hDevMailbox[nn*2+1]);
    p = &DeviceTable[nn];
    p->hMbxSend = hDevMailbox[nn*2];
    p->hMbxRcv = hDevMailbox[nn*2+1];
  }

	p = &DeviceTable[0];
	memsetW(p, 0, sizeof(DCB) * NR_DCB / sizeof(int));

	strncpy(p->name,"\x04NULL",12);
	p->type = DVT_Unit;
	p->UnitSize = 0;
	
	p = &DeviceTable[1];
	strncpy(p->name,"\x03KBD",12);
	p->type = DVT_Unit;
	p->UnitSize = 1;

	p = &DeviceTable[9];
	strncpy(p->name,"\x03PTI",12);
	p->type = DVT_Unit;
	p->UnitSize = 1;

	p = &DeviceTable[16];
	strncpy(p->name,"\x05CARD1",12);
	p->type = DVT_Block;
	p->UnitSize = 1;

	p = &DeviceTable[29];
	strncpy(p->name,"\x03CON",12);
	p->type = DVT_Unit;
	p->UnitSize = 1;

	p = &DeviceTable[30];
	strncpy(p->name,"\x04PRNG",12);
	p->type = DVT_Unit;
	p->UnitSize = 1;

	p = &DeviceTable[31];
	strncpy(p->name,"\x03DBG",12);
	p->type = DVT_Unit;
	p->UnitSize = 1;

}
