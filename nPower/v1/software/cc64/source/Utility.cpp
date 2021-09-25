// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// CC64 - 'C' derived language compiler
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

int round2(int n)
{
	while (n & 1) n++;
	return (n);
}

int64_t round10(int64_t n)
{
	while (n % 10LL) n++;
	return (n);
}

int64_t round8(int64_t n)
{
	while (n % 8LL) n++;
	return (n);
}

int popcnt(int64_t m)
{
	int n;
	int cnt;

	cnt = 0;
	for (n = 0; n < 64; n = n + 1)
		if (m & (1LL << n)) cnt = cnt + 1;
	return (cnt);
}

std::string TraceName(SYM *sp)
{
	std::string namebuf;
	SYM *vector[64];
	int deep = 0;

	do {
		vector[deep] = sp;
		sp = sp->GetParentPtr();
		deep++;
		if (deep > 63) {
			break; // should be an error
		}
	} while (sp);
	deep--;
	namebuf = "";
	while (deep > 0) {
		namebuf += *vector[deep]->name;
		namebuf += "_";
		deep--;
	}
	namebuf += *vector[deep]->name;
	return namebuf;
}

// Count the number of leading bits that are the same as the topmost bit.

int countLeadingBits(int64_t val)
{
	int64_t b;
	int64_t mask;
	int count;

	mask = 0x8000000000000000LL;
	b = val & mask;
	for (count = 0; ((val & mask) == b) && count < 64; count++)
		val = val << 1LL;
	return (count);
}

int countLeadingZeros(int64_t val)
{
	int64_t b;
	int64_t mask;
	int count;

	mask = 0x8000000000000000LL;
	for (count = 0; ((val & mask) == 0LL) && count < 64; count++)
		val = val << 1LL;
	return (count);
}

double log2(double n)
{
	return (log(n) / log(2));
}

double clog2(double n)
{
	return (ceil(log2(n)));
}
