#include "stdafx.h"

namespace Finray {

List::List

void List::Add(ListItem *item)
{
	if (first==nullptr) {
		first = item;
		first->next = nullptr;
	}
	else {
		item->next = first;
		first = item;
	}
}

int List::RemoveAll()
{
	ListItem *temp;
	int num = 0;

	while (first) {
		num++;
		temp = first;
		first = first->next;
	}
	first = nullptr;
}

int List::Print(ListItem *item)
{
	int num = 0;
	while (item) {
		item->Print();
		item = item->next;
		num++;
	}
	return num;
}

};
