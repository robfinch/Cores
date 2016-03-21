#include "stdafx.h"

TYP *TYP::GetBtp() {
    if (btp==0)
      return nullptr;
    return &compiler.typeTable[btp];
};
TYP *TYP::GetPtr(int n) {
  if (n==0)
    return nullptr;
  return &compiler.typeTable[n];
};
int TYP::GetIndex() { return this - &compiler.typeTable[0]; };

TYP *TYP::Copy(TYP *src)
{
	TYP *dst = nullptr;
  TYP *t;
 
  dfs.printf("Enter TYP::Copy\n");
	if (src) {
		dst = allocTYP();
//		if (dst==nullptr)
//			throw gcnew C64::C64Exception();
		memcpy(dst,src,sizeof(TYP));
		dfs.printf("A");
		if (src->btp && src->GetBtp()) {
  		dfs.printf("B");
			dst->btp = Copy(src->GetBtp())->GetIndex();
		}
		dfs.printf("C");
		dst->lst.Clear();
		dst->sname = new std::string(*src->sname);
		dfs.printf("D");
		TABLE::CopySymbolTable(&dst->lst,&src->lst);
	}
  dfs.printf("Leave TYP::Copy\n");
	return dst;
}

TYP *TYP::Make(int bt, int siz)
{
	TYP *tp;
	dfs.printf("Enter TYP::Make()\n");
  tp = allocTYP();
  if (tp == nullptr)
     return nullptr;
  tp->val_flag = 0;
  tp->isArray = FALSE;
  tp->size = siz;
  tp->type = (e_bt)bt;
	tp->typeno = bt;
  tp->lst.Clear();
	tp->isUnsigned = FALSE;
	tp->isVolatile = FALSE;
	tp->isIO = FALSE;
	tp->isConst = FALSE;
	dfs.printf("Leave TYP::Make()\n");
  return tp;
}


