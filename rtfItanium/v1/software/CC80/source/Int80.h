#pragma once
// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2019  Robert Finch, Waterloo
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
#define INT80_WORDS	3

class Int80
{
public:
	int32_t man[INT80_WORDS];
	static bool EQ(Int80 *a, Int80 *b);
	static bool GT(Int80 *a, Int80 *b);
	static bool Add(Int80 *s, Int80 *a, Int80 *b);
	static bool Sub(Int80 *s, Int80 *a, Int80 *b);
	static void Mul(Int80 *p, Int80 *a, Int80 *b);
	static void Div(Int80 *q, Int80 *a, Int80 *b);
};