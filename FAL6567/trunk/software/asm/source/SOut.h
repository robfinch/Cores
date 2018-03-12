#define SOUT_H

#define S1	1
#define S2	2
#define S3	3

class CSOut
{
	char buf[80];
	__int8 ndx;
	int CheckSum;
	int s3Count;
	unsigned int RecType : 2;	// type of last record output S1, S2, or S3
	FILE *fp;
public:
	int open(char *fname);
	void putb(unsigned int byte);
	void flush();
	void close();
};
