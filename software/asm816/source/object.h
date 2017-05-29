#pragma once

#include "HashVal.h"

class Object
{
public:
	virtual HashVal getHash(int);
};

class ListObject : public Object
{
public:
	ListObject *next;
	ListObject *prev;
public:
	void insertBefore(ListObject *obj) {
		if (obj) {
			next = obj;
			prev = obj->prev;
			if (obj->prev)
				obj->prev->next = this;
			obj->prev = this;
		}
		else {
			prev = next = NULL;
	};
	void removeFromList() {
		if (next)
			next->prev = prev;
		if (prev)
			prev->next = next;
	}
};

