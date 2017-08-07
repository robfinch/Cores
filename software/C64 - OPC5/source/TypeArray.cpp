// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C64 - 'C' derived language compiler
//  - 64 bit CPU
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// ============================================================================
//
#include "stdafx.h"

extern std::string *TypenoToChars(int typeno);

TypeArray::TypeArray()
{
  length = 0;
  ZeroMemory(this,sizeof(this));
}

// The most significant bit of the register number indicates if register is
// an auto var or not. auto vars consume stack space.

void TypeArray::Add(int tp, __int16 regno)
{
  if (this==nullptr)
    return;
  if (length < sizeof(types) / sizeof(types[0])) {
    types[length] = tp;
	preg[length] = regno;
    length++;
  }
}

void TypeArray::Add(TYP *tp, __int16 regno)
{
  if (tp) {
    Add(tp->typeno, regno);
  }
  else {
    Add(0,0);
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

bool TypeArray::IsChar(int typ)
{
	return (typ==bt_char || typ==bt_uchar);
}
bool TypeArray::IsShort(int typ)
{
	return (typ==bt_short || typ==bt_ushort);
}
bool TypeArray::IsLong(int typ)
{
	return (typ==bt_long || typ==bt_ulong);
}
bool TypeArray::IsInt(int typ)
{
	return (IsChar(typ)||IsShort(typ)||IsLong(typ));
}

bool TypeArray::IsEqual(TypeArray *ta)
{
  int m;
  int nn;
  int t,tat;
  
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
	t = types[nn];
	tat = ta->types[nn];
    if (t != tat) {
      if (t==bt_long && tat==bt_ulong)
        continue;
      if (t==bt_ulong && tat==bt_long)
        continue;
      if (t==bt_short && tat==bt_ushort)
        continue;
      if (t==bt_ushort && tat==bt_short)
        continue;
      if (t==bt_char && tat==bt_uchar)
        continue;
      if (t==bt_uchar && tat==bt_char)
        continue;
	  // Loose type matching
	  if (IsInt(t) && IsInt(tat))
		  continue;
      dfs.printf("F2");
      return false;
    }
  }
  dfs.printf("T3");
  return true;
}

TypeArray *TypeArray::alloc()
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

std::string *TypeArray::BuildSignature()
{
	static std::string *str;
	int n;

	str = new std::string("");
	for (n = 0; n < length; n++) {
		str->append(*TypenoToChars(types[n]));
	}
	return str;
}


