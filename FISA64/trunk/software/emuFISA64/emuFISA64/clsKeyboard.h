#pragma once
class clsKeyboard
{
	unsigned __int8 buffer[32];
	int head;
	int tail;
public:
	volatile unsigned __int8 scancode;
	volatile unsigned __int8 status;
	clsKeyboard(void);
	~clsKeyboard(void);
	bool IsSelected(unsigned int ad) { return ((ad & 0xFFFFFFF0)==0xFFDC0000); };
	void Put(unsigned __int8 sc) {
		scancode = sc;
		buffer[head] = sc;
		head++;
		head &= 31;
	};
	unsigned __int8 Get() {
		unsigned __int8 sc;

		sc = 0;
		if (head != tail) {
			sc = buffer[tail];
			tail++;
			tail &= 31;
		}
		return sc;
	};
	unsigned __int8 Peek(int amt) {
		unsigned __int8 sc;
		int ndx;

		ndx = tail + amt;
		ndx &= 31;
		sc = buffer[ndx];
		return sc;
	};
	unsigned __int8 GetStatus() {
		if (head != tail)
			return 0x80;
		else
			return 0x00;
	};
};

