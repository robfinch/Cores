#ifndef SECTION_H
#define SECTION_H

class Section
{
public:
	char name[33];
	int number;
	unsigned __int64 counter;
	Section *next;
	Section *prev;
	unsigned __int64 Counter() { return counter; };
	void SetCounter(__int64 n) { counter = n; };
	int operator ++() { counter++; };
	void BuildELFSectionHeader();
};

#endif
