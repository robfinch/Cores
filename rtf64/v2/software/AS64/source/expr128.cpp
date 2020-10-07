// ============================================================================
//        __
//   \\__/ o\    (C) 2014-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// A64 - Assembler
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

Int128 expr128();
extern int nsym;

// id
// const
// (expr)
// >expr
static Int128 primary()
{
    Int128 val;
    SYM *sym;
    static char buf[500];

    switch(token) {
    case tk_id:
         if (lastid[0]=='.')  // local label
            sprintf(buf, "%s%s", current_label, lastid);
         else
             strcpy(buf, lastid);
         sym = find_symbol(buf);
         if (!sym)
             sym = new_symbol(buf);
         Int128::Assign(&val, &sym->value);
         if (sym->segment < 5)
             nsym++;
         lastsym = sym;
         NextToken();
         if (token==tk_eol)
            prevToken();
         break;
    case tk_icon:
         val = ival;
         NextToken();
         if (token==tk_eol)
            prevToken();
         break;
    case '\'':
         inptr++;
		 if (*inptr=='\\') {
			 inptr++;
			 switch(*inptr) {
			 case '\r':	val.low = '\r'; val.high = 0; NextToken(); expect('\''); return (val);
			 case '\n':	val.low = '\n'; val.high = 0; NextToken(); expect('\''); return (val);
			 case '\t':	val.low = '\t'; val.high = 0; NextToken(); expect('\''); return (val);
			 case '\f':	val.low = '\f'; val.high = 0; NextToken(); expect('\''); return (val);
			 case '\b':	val.low = '\b'; val.high = 0; NextToken(); expect('\''); return (val);
			 }
		 }
         val.low = *inptr;
		 val.high = 0;
         NextToken();
         expect('\'');
         break;
    case '(':
         NextToken();
         val = expr128();
         expect(')');
         break;
    default:
       //printf("Syntax error.\r\n");
       val.low = val.high = 0;
       if (token != tk_eol)
           NextToken();
      break;
    }    
    return (val);
}
 
// !unary
// -unary
// +unary
// ~unary
//  primary
       
static Int128 unary()
{
    Int128 val;
    
    switch(token) {
    case '!':
		NextToken();
		val = unary();
		if (Int128::IsEqual(&val,Int128::Zero()))
			Int128::Assign(&val,Int128::One());
		else
			Int128::Assign(&val,Int128::Zero());
		return (val);
    case '-':
		NextToken();
		val = unary();
		Int128::Sub(&val,Int128::Zero(),&val);
		return (val);
    case '+':
		NextToken();
		val = unary();
		return (val);
    case '~':
		NextToken();
		val = unary();
		val.low = ~val.low;
		val.high = ~val.high;
		return (val);
    default:
        return (primary());
    }
}

// unary
// unary [*/%] unary

static Int128 mult_expr()
{
    Int128 val, a, rem;
    
    val = unary();
    while(1) {
        switch(token) {
        case '*':
			NextToken();
			a = unary();
			Int128::Mul(&val, &val, &a);
			break;
        case '/':
			NextToken();
			a = unary();
			Int128::Div(&val, &rem, &val, &a);
			break;
        case '%':
			NextToken();
			a = unary();
			Int128::Div(&rem, &val, &val, &a);
			break;
        default: goto j1;
        }
    }
j1:
    return (val);
}

// mult_expr
// mult_expr [+-] add_expr_list
//
static Int128 add_expr()
{
    Int128 val, a;
    
    val = mult_expr();
    while (1) {
        switch(token) {
        case '+':
			NextToken();
			a = mult_expr();
			Int128::Add(&val, &val, &a);
			break;
        case '-':
			NextToken();
			a = mult_expr();
			Int128::Sub(&val, &val, &a);
			break;
        default: goto j1;
        }
    }
j1:
    return (val);
}

static Int128 shift_expr()
{
    Int128 val, amt;
    int nn;

    val = add_expr();
    while(1) {
        switch(token) {
        case tk_lshift:
			NextToken();
			amt = add_expr();
			for (nn = 0; nn < 128 && nn < amt.low; nn++)
				Int128::Shl(&val, &val);
			break;
        case tk_rshift:
			NextToken();
			amt = add_expr();
			for (nn = 0; nn < 128 && nn < amt.low; nn++)
				Int128::Shr(&val, &val);
			break;
        default: goto j1;
        }
    }
j1:
    return (val);
}

static Int128 relational_expr()
{
    Int128 val, a;
    
    val = shift_expr();
    while (1) {
        switch(token) {
        case tk_lt:
			NextToken();
			a = shift_expr();
			if (Int128::IsLessThan(&val, &a))
				Int128::Assign(&val, Int128::One());
			else
				Int128::Assign(&val, Int128::Zero());
			break;
        case tk_le:
			NextToken();
			a = shift_expr();
			if (Int128::IsLessThan(&val, &a) || Int128::IsEqual(&val, &a))
				Int128::Assign(&val, Int128::One());
			else
				Int128::Assign(&val, Int128::Zero());
			break;
        case tk_gt:
			NextToken();
			a = shift_expr();
			if (!Int128::IsLessThan(&val, &a) && !Int128::IsEqual(&val, &a))
				Int128::Assign(&val, Int128::One());
			else
				Int128::Assign(&val, Int128::Zero());
			break;
        case tk_ge:
			NextToken();
			a = shift_expr();
			if (!Int128::IsLessThan(&val, &a) || Int128::IsEqual(&val, &a))
				Int128::Assign(&val, Int128::One());
			else
				Int128::Assign(&val, Int128::Zero());
			break;
        default: goto j1;
        }
    }
j1:
    return (val);
}

// relational_expr
// relational_expr & equals_expr_list
//
static Int128 equals_expr()
{
    Int128 val, a;
    
    val = relational_expr();
    while (1) {
        switch(token) {
		case tk_eq:
			NextToken();
			a = relational_expr();
			if (Int128::IsEqual(&val, &a))
				Int128::Assign(&val, Int128::One());
			else
				Int128::Assign(&val, Int128::Zero());
			break;
        case tk_ne:
			NextToken();
			a = relational_expr();
			if (!Int128::IsEqual(&val, &a))
				Int128::Assign(&val, Int128::One());
			else
				Int128::Assign(&val, Int128::Zero());
			break;
        default: goto j1;
        }
    }
j1:
    return (val);
}

// equals_expr
// equals_expr & bitwise_expr_list
//
static Int128 bitwise_expr()
{
    Int128 val, a;
    
    val = equals_expr();
    while (1) {
        switch(token) {
        case '&':
			NextToken();
			a = equals_expr();
			val.low = val.low & a.low;
			val.high = val.high & a.high;
			break;
        case '^':
			NextToken();
			a = equals_expr();
			val.low = val.low ^ a.low;
			val.high = val.high ^ a.high;
			break;
        case '|':
			NextToken();
			a = equals_expr();
			val.low = val.low | a.low;
			val.high = val.high | a.high;
			break;
        default: goto j1;
        }
    }
j1:
    return (val);
}

// bitwise_expr
// bitwise_expr && and_expr_list
//        
static Int128 and_expr()
{
    Int128 val, a;

    val = bitwise_expr();
    while(token==tk_land) {
        NextToken();
		a = bitwise_expr();
		if (Int128::IsEqual(&a,Int128::Zero()) || Int128::IsEqual(&val,Int128::Zero()))
			Int128::Assign(&val,Int128::Zero());
		else
			Int128::Assign(&val,Int128::One());
    }        
    return (val);
}

// and_expr
// and_expr || or_expr_list
//
static Int128 or_expr()
{
    Int128 val, a;
    
    val = and_expr();
    while(token==tk_lor) {
        NextToken(); 
		a = and_expr();
		if (!Int128::IsEqual(&a,Int128::Zero()) || !Int128::IsEqual(&val,Int128::Zero()))
			Int128::Assign(&val,Int128::One());
		else
			Int128::Assign(&val,Int128::Zero());
    }
    return (val);
}

Int128 expr128()
{
    Int128 val;

    nsym = 0;
    lastsym = (SYM*)NULL;    
    if (token=='#')
       NextToken();
    val = or_expr();
    // We only care about the symbol if relocatable output is being generated.
    // Setting the symbol to NULL will result in no rel records being output.
    if (nsym > 1 || !rel_out)
        lastsym = (SYM *)NULL;
    return val;
}

