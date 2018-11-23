#include <fmtk/config.h>
#include <fmtk/device.h>

extern DCB DeviceTable[NR_DCB];
extern int pti_CmdProc(int cmd, int p1, int p2, int p3, int p4);
extern int dbg_CmdProc(int cmd, int p1, int p2, int p3, int p4);

void SetupDevices()
{
	DCB *p;
	int n;

	p = &DeviceTable[0];
	memsetW(p, 0, sizeof(DCB) * NR_DCB / sizeof(int));

	strncpy(p->name,"\x04NULL",12);
	p->type = DVT_Unit;
	p->UnitSize = 0;
	
	p = &DeviceTable[9];
	strncpy(p->name,"\x03PTI",12);
	p->type = DVT_Unit;
	p->UnitSize = 1;
	p->CmdProc = pti_CmdProc;
	(*(p->CmdProc))(DVC_Setup, 0, 0, 0, 0);

	p = &DeviceTable[31];
	strncpy(p->name,"\x03DBG",12);
	p->type = DVT_Unit;
	p->UnitSize = 1;
	p->CmdProc = dbg_CmdProc;
	(*(p->CmdProc))(DVC_Setup, 0, 0, 0, 0);

}
