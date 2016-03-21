#include "stdafx.h"

extern std::string TypenoToChars(__int16 typeno);

TypeArray::TypeArray()
{
  length = 0;
  ZeroMemory(this,sizeof(this));
}

void TypeArray::Add(int tp)
{
  if (this==nullptr)
    return;
  if (length < sizeof(types) / sizeof(types[0])) {
    types[length] = tp;
    length++;
  }
}

void TypeArray::Add(TYP *tp)
{
  if (tp) {
    Add(tp->typeno);
  }
  else {
    Add(0);
  }
}

bool TypeArray::IsEmpty()
{
  int nn;

  if (this==nullptr)
    return true;
  for (nn = 0; nn < length; nn++) {
    if (types[nn]==bt_ellipsis)
      return true;
    if (types[nn])
      return false;
  }
  return true;
}

bool TypeArray::IsEqual(TypeArray *ta)
{
  int m;
  int nn;
  
  dfs.printf("IsEqual:");
  if (this==ta) {
    dfs.printf("T1");
    return true;
  }
  if (ta==nullptr && IsEmpty()) {
    dfs.printf("T2");
    return true;
  }
  if (this==nullptr || ta==nullptr) {
    dfs.printf("F1");
    return false;
 }
  m = (length > ta->length) ? length : ta->length;
  for (nn = 0; nn < m; nn++) {
    if (types[nn]==bt_ellipsis) {
      dfs.printf("T3");
      return true;
    }
    if (types[nn] != ta->types[nn]) {
      dfs.printf("F2");
      return false;
    }
  }
  dfs.printf("T3");
  return true;
}

TypeArray *TypeArray::Alloc()
{
  TypeArray *tp = (TypeArray *)allocx(sizeof(TypeArray)); 
  return tp;
}

void TypeArray::Clear()
{
  if (this) {
    memset(types,0,sizeof(types));
    length = 0;
  } 
}

void TypeArray::Print(txtoStream *fs)
{
  int nn;

  fs->printf("Type array:\n   ");
  if (this) {
    for (nn = 0; nn < length; nn++)
        fs->printf((char *)"%03d ",types[nn]);
  }
  fs->printf("\n");
}

void TypeArray::Print()
{
  Print(&dfs);
}

// Build a signature string.

std::string TypeArray::BuildSignature()
{
	static std::string str;
	int n;

	str = "";
	for (n = 0; n < length; n++) {
		str += TypenoToChars(types[n]);
	}
	return str;
}


