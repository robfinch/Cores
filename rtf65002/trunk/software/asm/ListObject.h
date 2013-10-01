#pragma once

#include <stdio.h>
#include "Object.h"

namespace RTFClasses
{
	class ListObject : public Object
	{
	public:
		ListObject *next;
		ListObject *prev;
	public:
		ListObject() { next = prev = NULL; };
		virtual ~ListObject() {};
		ListObject *getNext() const { return next; };
		ListObject *getPrev() const { return prev; };
		void insertBefore(ListObject *obj);
		void removeFromList();
		void sort(ListObject **) const;
		virtual void print(FILE *fp) {};
		virtual int cmp(Object *o) { return 0; };
	};
}
