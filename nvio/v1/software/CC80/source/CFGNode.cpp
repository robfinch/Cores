#include "stdafx.h"

Edge *CFGNode::MakeEdge(OCODE *ip1, OCODE *ip2)
{
	Edge *edge = nullptr;
/*
	edge = (Edge *)allocx(sizeof(Edge));
	edge->src = ip1;
	edge->dst = ip2;
	if (tail) {
		tail->next = edge;
		edge->prev = tail;
		tail = edge;
	}
	else {
		head = tail = edge;
	}
*/
	return (edge);
}
