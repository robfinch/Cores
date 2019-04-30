#define OBJ_MAGIC	(('O' << 40) | ('B' << 32) | ('J' << 24) | ('E' << 16) | ('C' << 8) | 'T')

int TestQtr(int *qtr)
{
	if (!IsNullPointer(qtr)) {
		if (*qtr == OBJ_MAGIC) {
			return (21);
		}
	}
}
