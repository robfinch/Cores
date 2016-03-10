#include "stdafx.h"

Finray::RayTracer rayTracer;

using namespace Finray;

namespace Finray {

void RayTracer::Init()
{
	objectList = nullptr;
	lightList = nullptr;
	viewPoint = nullptr;
	symbolTable.count = 0;
	recurseLevel = 0;
}

void RayTracer::Add(AnObject *obj) {
	if (objectList==nullptr) {
		objectList = obj;
		obj->next = nullptr;
	}
	else {
		obj->next = objectList;
		objectList = obj;
	}
}

void RayTracer::DeleteList(AnObject *list)
{
	AnObject *obj;

	while (list) {
		obj = list->next;
		delete list;
		list = obj;
	}
}

void RayTracer::DeleteList() {
	AnObject *obj;
	ALight *lobj;

	while (objectList) {
		DeleteList(objectList->obj);
		obj = objectList->next;
		delete objectList;
		objectList = obj;
	}
	while (lightList) {
		lobj = (ALight *)lightList->next;
		delete lightList;
		lightList = lobj;
	}
}

void RayTracer::Add(ALight *L)
{
	if (lightList) {
		L->next = lightList;
		lightList = L;
	}
	else {
		L->next = nullptr;
		lightList = L;
	}
}

};
