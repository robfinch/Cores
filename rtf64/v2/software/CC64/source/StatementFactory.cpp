#include "stdafx.h"

Statement* StatementFactory::MakeStatement(int typ, int gt) {
	Statement* s = (Statement*)xalloc(sizeof(Statement));
	ZeroMemory(s, sizeof(Statement));
	s->stype = typ;
	s->predreg = -1;
	s->outer = currentStmt;
	s->s1 = (Statement*)NULL;
	s->s2 = (Statement*)NULL;
	s->ssyms.Clear();
	s->lptr = my_strdup(inpline);
	s->prediction = 0;
	s->depth = stmtdepth;
	//memset(s->ssyms,0,sizeof(s->ssyms));
	if (gt) NextToken();
	return s;
};

