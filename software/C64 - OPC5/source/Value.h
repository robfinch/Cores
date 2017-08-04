#ifndef _VALUE_H
#define _VALUE_H

class TYP;

class Value {
public:
	int length;
	TYP *tp;
	Value *first;
	Value *next;
	Value *subvalue;
	union {
		int i;
		unsigned int u;
		double f;
		uint16_t wa[8];
		char *s;
	} val;
	Value() { length = 0; };
	~Value();
};

#endif
