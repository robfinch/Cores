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

void sdc_init()
{
	out32(SDC|SDC_TO,0x9c4);
	out32(SDC|SDC_RST,1);
	out32(SDC|SDC_CLKDV,2);	// 10MHz / 2
	out32(SDC|SDC_RST,0);
}

int sdc_SendCmd(int cmd, int arg)
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

int sdc_SendCMD8()
{
	return (sdc_SendCmd(0x81a,0x1aa));
}

void sdc_SendData(void *p, int blockno)
{
	int bds;

	do {
		bds = in32(SDC|SDC_BDS);	
	} until ((bds & 0xff) > 0);
	out32(SDC|SDC_TX,p);
	out32(SDC|SDC_TX,blockno);
}

void sdc_RecvData(void *p, int blockno)
{
	int bds;

	do {
		bds = in32(SDC|SDC_BDS);	
	} until ((bds & 0xff00) > 0);
	out32(SDC|SDC_RX,p);
	out32(SDC|SDC_RX,blockno);
}
