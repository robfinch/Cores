#include "ListObject.h"

namespace RTFClasses
{

	void ListObject::insertBefore(ListObject *obj) {
		if (obj) {
			next = obj;
			prev = obj->prev;
			if (obj->prev)
				obj->prev->next = this;
			obj->prev = this;
		}
		else
			prev = next = (ListObject *)0;
	}

	void ListObject::removeFromList() {
		if (next)
			next->prev = prev;
		if (prev)
			prev->next = next;
		next = prev = (ListObject *)0;
	}
}
