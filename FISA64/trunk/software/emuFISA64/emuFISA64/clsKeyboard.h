#pragma once
class clsKeyboard
{
	unsigned __int8 stack[20];
	int sp;
public:
	volatile unsigned __int8 scancode;
	volatile unsigned __int8 status;
	clsKeyboard(void);
	~clsKeyboard(void);
	void Push(unsigned __int8 sc) {
		if (sp > 0) {
			sp--;
			stack[sp] = sc;
		}
	};
	unsigned __int8 Pop() {
		unsigned __int8 sc;

		if (sp < sizeof(stack)) {
			sc = stack[sp];
			sp++;
		}
		return sc;
	};
	unsigned __int8 GetStatus() {
		if (sp < sizeof(stack))
			return 0x80;
		else
			return 0x00;
	};
};

