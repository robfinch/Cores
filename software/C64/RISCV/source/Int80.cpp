// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// 80 bit integer class
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

bool Int80::EQ(Int80 *a, Int80 *b)
{
	int nn;

	for (nn = INT80_WORDS - 1; nn >= 0; nn--) {
		if (a->man[nn] != b->man[nn])
			return (false);
	}
	return (true);
}

bool Int80::GT(Int80 *a, Int80 *b)
{
	int nn;

	for (nn = INT80_WORDS - 1; nn >= 0; nn--) {
		if (a->man[nn] > b->man[nn])
			return (true);
		else if (a->man[nn] < b->man[nn])
			return (false);
	}
	return (false);
}

bool Int80::Add(Int80 *s, Int80 *a, Int80 *b)
{
	int nn;
	unsigned __int64 sum[INT80_WORDS];
	unsigned __int64 c;

	c = 0;
	for (nn = 0; nn < INT80_WORDS; nn++) {
		sum[nn] = (unsigned __int64)a->man[nn] + (unsigned __int64)b->man[nn] + c;
		c = (sum[nn] >> 32) & 1;
	}
	for (nn = 0; nn < INT80_WORDS; nn++) {
		s->man[nn] = (unsigned __int32)sum[nn];
	}
	return ((sum[INT80_WORDS - 1] & 0x80000000) != 0);
}

bool Int80::Sub(Int80 *s, Int80 *a, Int80 *b)
{
	int nn;
	unsigned __int64 sum[INT80_WORDS];
	unsigned __int64 c;

	c = 0;
	for (nn = 0; nn < INT80_WORDS; nn++) {
		sum[nn] = (unsigned __int64)a->man[nn] - (unsigned __int64)b->man[nn] - c;
		c = (sum[nn] >> 32) & 1;
	}
	for (nn = 0; nn < INT80_WORDS; nn++) {
		s->man[nn] = (unsigned __int32)sum[nn];
	}
	return ((sum[INT80_WORDS - 1] & 0x80000000) != 0);
}
