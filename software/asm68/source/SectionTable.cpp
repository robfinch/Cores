#include "SectionTable.h"

char *SectionTable::BuildNameStringTable()
{
	int maxlen;
	char *tbl;
	int nn;

	Section *s;
	maxlen = 1;
	for(s = head; s; s=s->next)
		maxlen = maxlen + strlen(s->name) + 1;
	tbl = new char[maxlen];
	memset(tbl,0,maxlen);
	nn = 1;
	for(s = head; s; s=s->next) {
		strcpy(&tbl[nn], s->name);
		nn += strlen(s->name) + 1;
	}
	return tbl;
}
