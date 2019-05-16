#include <fmtk/const.h>
#include <fmtk/device.h>
#include <ft64/io.h>

#define SDC		0xFFFFFFFFFFDC0B00L
#define SDC_ARG		0x00
#define SDC_CMD		0x04
#define SDC_RSP		0x0C	// command response
#define SDC_RST		0x28	// reset
#define SDC_TO		0x2C	// timeout
#define SDC_NIS		0x30	// Normal interrupt status
#define SDC_CLKDV	0x4C
#define SDC_BDS		0x50	// buffer descriptor status
#define SDC_RX		0x60
#define SDC_TX		0x80

extern void DBGDisplayString(char *);

pascal void sdc_init()
{
	out32(SDC|SDC_TO,0x9c4);
	out32(SDC|SDC_RST,1);
	out32(SDC|SDC_CLKDV,4);	// 20MHz / 4
	out32(SDC|SDC_RST,0);
}

pascal int sdc_SendCmd(int cmd, int arg)
{
	int stat;
	int resp;

	out32(SDC|SDC_CMD,cmd);
	out32(SDC|SDC_ARG,arg);
	do {
		stat = in32(SDC|SDC_NIS);
	} until (stat & 1);	// bit  0 = command complete
	out32(SDC|SDC_NIS,0);
	if (stat & 0x8000) {
		// read error
	}
	resp = in32(SDC|SDC_RSP);
	return (resp);
}

pascal int sdc_SendCMD8()
{
	return (sdc_SendCmd(0x81a,0x1aa));
}

pascal void sdc_WriteBlock(int handle, void *p, int blockno)
{
	int bds;

	do {
		bds = in32(SDC|SDC_BDS);	
	} until ((bds & 0xff) > 0);
	out32(SDC|SDC_TX,p);
	out32(SDC|SDC_TX,blockno);
}

pascal void sdc_ReadBlock(int handle, void *p, int blockno)
{
	int bds;

	do {
		bds = in32(SDC|SDC_BDS);	
	} until ((bds & 0xff00) > 0);
	out32(SDC|SDC_RX,p);
	out32(SDC|SDC_RX,blockno);
}

pascal int sdc_status(int handle)
{
	int bds, nis;

	nis = in32(SDC|SDC_NIS);
	bds = in32(SDC|SDC_BDS);
	return(nis | (bds << 16));	
}

pascal int sdc_CmdProc(int cmd, int cmdParm1, int cmdParm2, int cmdParm3, int cmdParm4)
{
	int val;
	int err = E_Ok;

	switch(cmd) {
	case DVC_ReadBlock:
		sdc_ReadBlock(cmdParm1, cmdParm2, cmdParm3);
		break;
	case DVC_WriteBlock:
		sdc_WriteBlock(cmdParm1, cmdParm2, cmdParm3);
		break;
	case DVC_Open:
		if (cmdParm4)
			*(int *)cmdParm4 = 0;
		else
			err = E_Arg;
		break;
	case DVC_Close:
		break;
	case DVC_Status:
		*(int *)cmdParm2 = sdc_status(cmdParm1);
		break;
	case DVC_Nop:
		break;
	case DVC_Setup:
		DBGDisplayAsciiStringCRLF(B"SDC setup");
		break;
	case DVC_Initialize:
		sdc_init();
		break;
	case DVC_FlushInput:
		break;
	case DVC_IsRemoveable:
		*(int *)cmdParm1 = 1;
		break;
	default:
		return err = E_BadDevOp;
	}
	return (err);
}
