#ifndef SECTION_TABLE_H
#define SECTION_TABLE_H

#include <stdio.h>
#include <string.h>
#include "section.h"

class SectionTable
{
	int nextSectionNumber;
	Section *head;
	Section *tail;
public:
	Section *activeSection;
	SectionTable() {
		nextSectionNumber = 1;
	};
	Section *AllocSection(char *nm) {
		Section *ns;
		ns = new Section;
		ns->number = nextSectionNumber++;
		ns->counter = 0;
		ns->next = NULL;
		ns->prev = tail;
		strncpy(ns->name,nm,32);
		if (head==NULL)
			head = ns;
		if (tail)
			tail->next = ns;
		tail = ns;
		return ns;
	};
	void SetActiveSection(int n) {
		Section *s;
		for(s = head; s; s=s->next)
			if (s->number == n)
				activeSection = s;
	};
	Section *SetActiveSection(char *p) {
		Section *s;
		for(s = head; s; s=s->next)
			if (strcmp(s->name,p)==0) {
				activeSection = s;
				return s;
			}
		return NULL;
	}
	void ZeroCounters() {
		Section *s;
		for(s = head; s; s=s->next)
			s->counter = 0;
	};
	Section *FindSection(char *p) {
		Section *s;
		for(s = head; s; s=s->next)
			if (strcmp(s->name,p)==0)
				return s;
		return NULL;
	}
	bool IsCurrentSection(char *p) {
		return strcmp(activeSection->name,p)==0;
	};
	bool IsCurrentSection(int n) { return activeSection->number == n; };
	char *BuildNameStringTable();
};

#endif
