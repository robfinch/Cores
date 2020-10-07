
class DSD9_Instr
{
public:
	__int8 size;
	__int64 address;
	__int64 opcode;
	char *source;
};

class DSD9_Section
{
public:
	__int64 address;
	unsigned int bufndx;
	DSD9_Instr buf[1000000];
	void Add(__int64 oc, int sz, char *src) {
		if (bufndx < 1000000) {
			buf[bufndx].opcode = oc;
			buf[bufndx].size = sz;
			buf[bufndx].source = src;
			buf[bufndx].address = address;
			bufndx++;
			address += sz;
		}
	};
};
