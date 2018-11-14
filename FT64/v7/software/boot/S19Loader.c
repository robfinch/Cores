
extern int DBGCheckForKey();
extern int DBGGetKey(int block);
extern __int8 S19Abort;
extern __int8 S19Reclen;
extern unsigned int *S19Address;
extern unsigned int *S19StartAddress;
extern int pti_get(int *);

static char sGetChar()
{
	char ch;

	ch = pti_get(&S19Abort);
	return (ch);
}

static char sGetChar2()
{
	char ch;

	do {
		if (DBGCheckForKey() < 0) {
			if ((DBGGetKey(1) & 0xff) == 0x03) {
				S19Abort = 1;
			}
		}
	}	while ((ch = GetAuxIn())==0 && !S19Abort);	
	return (ch);
}

static NextRec()
{
	char ch;
	
	do {
		ch = sGetChar();
	} while (ch != 0x0A && !S19Abort);
}

static int AsciiToNybble(char ch)
{
	if (ch >= 'a' && ch <= 'f')
		return (ch - 'a' + 10);
	if (ch >= 'A' && ch <= 'F')
		return (ch - 'A' + 10);
	if (ch >= '0' && ch <= '9')
		return (ch - '0');
	return (-1);
}

static int GetByte()
{
	char ch;
	int num;

	ch = sGetChar();
	num = ASciiToNybble(ch);
	if (S19Abort)
		return (num);
	num <<= 4;
	ch = sGetChar();
	num |= ASciiToNybble(ch);
	return (num);
}

static void Get16BitAddress()
{
	int num;
	
	S19Address = GetByte();
	if (S19Abort)
		return;
	S19Address <<= 8;
	S19Address |= GetByte();
	return;
}

static void Get24BitAddress()
{
	int num;
	
	S19Address = GetByte();
	if (S19Abort)
		return;
	S19Address <<= 8;
	S19Address |= GetByte();
	if (S19Abort)
		return;
	S19Address <<= 8;
	S19Address |= GetByte();
	return;
}

static void Get32BitAddress()
{
	int num;
	
	S19Address = GetByte();
	if (S19Abort)
		return;
	S19Address <<= 8;
	S19Address |= GetByte();
	if (S19Abort)
		return;
	S19Address <<= 8;
	S19Address |= GetByte();
	if (S19Abort)
		return;
	S19Address <<= 8;
	S19Address |= GetByte();
	return;
}

static void PutMem()
{
	int n;
	int byt;

	for (n = 0; n < S19Reclen; n++) {
		byt = GetByte();
		if (S19Abort)
			break;
		*S19Address = byt;
		S19Address++;
	}
	// Get the checksum byte
	byt = GetByte();	
}

static void ProcessS1()
{
	Get16BitAddress();	
	PutMem();
}

static void ProcessS2()
{
	Get24BitAddress();	
	PutMem();
}

static void ProcessS3()
{
	Get32BitAddress();
	PutMem();
}

static void ProcessS7()
{
	Get16BitAddress();
	S19StartAddress = S19Address;
}

static void ProcessS8()
{
	Get24BitAddress();
	S19StartAddress = S19Address;
}

static void ProcessS8()
{
	Get32BitAddress();
	S19StartAddress = S19Address;
}

void S19Loader()
{
	char ch;
	char rectype;

	DBGDisplayStringCRLF("S19 Loader Active");
	S19Abort = 0;
	forever {
		ch = sGetChar();
		if (ch==0x1A)	// CTRL-Z ? (end of file)
			break;
		// The record must start with an 'S'
		if (ch != 'S')
			goto nextrec;
		// Followed by a single digit record type
		if (!isdigit(ch))
			goto nextrec;
		rectype = ch;
		// Followed by a byte record length
		S19Reclen = GetByte();
		if (S19Abort)
			break;
		switch(rectype) {
		case '0':	// manufacturer id - ignore
			goto nextrec;
		case '1':
			ProcessS1();
			break;
		case '2':
			ProcessS2();
			break;
		case '3':
			ProcessS3();
			break;
		case '5':	// record count - ignore
			goto nextrec;
		case '7':
			ProcessS7();
			goto xit;
		case '8':
			ProcessS8();
			goto xit;
		case '9':
			ProcessS9();
			goto xit;
		default:
			goto nextrec;
		}
nextrec:
		DBGDisplayChar('.');
		NextRec();
		if (S19Abort)
			break;
	}
xit:
	;
}

