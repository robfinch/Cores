// ============================================================================
//        __
//   \\__/ o\    (C) 2014-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// AS64 - Assembler
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

int64_t expr();
int nsym;

// id
// const
// (expr)
// >expr
int64_t primary(int64_t* def)
{
  int64_t val;
  SYM *sym;
  static char buf[500];

	ZeroMemory(buf,sizeof(buf));
  *def = 1;
  switch(token) {
  case tk_id:
    if (lastid[0]=='.')  // local label
      sprintf(buf, "%s%s", current_label, lastid);
    else
      strcpy(buf, lastid);
    sym = find_symbol(buf);
    if (!sym)
      sym = new_symbol(buf);
    if (current_symbol) {
      sym->parent = current_symbol->ord;
    }
    val = sym->value.low;
    if (sym->segment < 5)
      nsym++;
    lastsym = sym;
    sym->referenced++;
    *def = sym->defined;
    NextToken();
    if (token==tk_eol)
      prevToken();
    break;
  case tk_icon:
    val = ival.low;
    NextToken();
    if (token==tk_eol)
      prevToken();
    break;
  case '\'':
    inptr++;
		if (*inptr=='\\') {
			inptr++;
			switch(*inptr) {
			case '\r':	val = '\r'; NextToken(); expect('\''); return (val);
			case '\n':	val = '\n'; NextToken(); expect('\''); return (val);
			case '\t':	val = '\t'; NextToken(); expect('\''); return (val);
			case '\f':	val = '\f'; NextToken(); expect('\''); return (val);
			case '\b':	val = '\b'; NextToken(); expect('\''); return (val);
			}
		}
    val = *inptr;
    NextToken();
    expect('\'');
    break;
  case '(':
    NextToken();
    val = expr();
    expect(')');
    break;
  default:
    if (token=='>' && gCpu==5) {
      val = expr();
      val >>= 12;
    }
    else if (token=='<' && gCpu==5) {
      val = expr();
      val &= 0xFFF;
    }
    else {
      //printf("Syntax error.\r\n");
      val = 0;
      if (token != tk_eol)
        NextToken();
    }
    break;
  }    
  return val;
}
 
// !unary
// -unary
// +unary
// ~unary
//  primary
       
int64_t unary(int64_t* def)
{
    int64_t val;
    
    switch(token) {
    case '!': NextToken(); return !unary(def);
    case '-': NextToken(); return -unary(def);
    case '+': NextToken(); return +unary(def);
    case '~': NextToken(); return ~unary(def);
    default:
        return primary(def);
    }
}

// unary
// unary [*/%] unary

int64_t mult_expr(int64_t* def)
{
    int64_t val;
    int64_t def1, def2;

    val = unary(&def1);
    while(1) {
        switch(token) {
        case '*': NextToken(); val = val * unary(&def2);
          *def = *def && (def1 && def2);
          break;
        case '/': NextToken(); val = val / unary(&def2);
          *def = *def && (def1 && def2);
          break;
        case '%': NextToken(); val = val % unary(&def2);
          *def = *def && (def1 && def2);
          break;
        default: goto j1;
        }
    }
j1:
    return val;
}

// mult_expr
// mult_expr [+-] add_expr_list
//
int64_t add_expr(int64_t* def)
{
    int64_t val;
    int64_t def1, def2;

    val = mult_expr(&def1);
    while (1) {
        switch(token) {
        case '+': NextToken(); val = val + mult_expr(&def2);
          *def = *def && (def1 && def2);
          break;
        case '-': NextToken(); val = val - mult_expr(&def2);
          *def = *def && (def1 && def2);
          break;
        default: goto j1;
        }
    }
j1:
    return val;
}

int64_t shift_expr(int64_t* def)
{
    int64_t val;
    int64_t def1, def2;

    val = add_expr(&def1);
    while(1) {
        switch(token) {
        case tk_lshift: NextToken(); val = val << add_expr(&def2);
          *def = *def && (def1 && def2);
          break;
        case tk_rshift: NextToken(); val = val >> add_expr(&def2);
          *def = *def && (def1 && def2);
          break;
        default: goto j1;
        }
    }
j1:
    return val;
}

int64_t relational_expr(int64_t* def)
{
    int64_t val;
    int64_t def1, def2;

    val = shift_expr(&def1);
    while (1) {
        switch(token) {
        case tk_lt: NextToken(); val = val <shift_expr(&def2);
          *def = *def && (def1 && def2);
          break;
        case tk_le: NextToken(); val = val<=shift_expr(&def2);
          *def = *def && (def1 && def2);
          break;
        case tk_gt: NextToken(); val = val >shift_expr(&def2);
          *def = *def && (def1 && def2);
          break;
        case tk_ge: NextToken(); val = val>=shift_expr(&def2);
          *def = *def && (def1 && def2);
          break;
        default: goto j1;
        }
    }
j1:
    return val;
}

// relational_expr
// relational_expr & equals_expr_list
//
int64_t equals_expr(int64_t* def)
{
    int64_t val;
    int64_t def1, def2;

    val = relational_expr(&def1);
    while (1) {
        switch(token) {
        case tk_eq: NextToken(); val = val == relational_expr(&def2);
          *def = *def && (def1 && def2);
          break;
        case tk_ne: NextToken(); val = val != relational_expr(&def2);
          *def = *def && (def1 && def2);
          break;
        default: goto j1;
        }
    }
j1:
    return val;
}

// equals_expr
// equals_expr & bitwise_expr_list
//
int64_t bitwise_expr(int64_t* def)
{
    int64_t val;
    int64_t def1, def2;

    val = equals_expr(&def1);
    while (1) {
        switch(token) {
        case '&': NextToken(); val = val & equals_expr(&def2);
          *def = *def && (def1 && def2);
          break;
        case '^': NextToken(); val = val ^ equals_expr(&def2);
          *def = *def && (def1 && def2);
          break;
        case '|': NextToken(); val = val | equals_expr(&def2);
          *def = *def && (def1 && def2);
          break;
        default: goto j1;
        }
    }
j1:
    return val;
}

// bitwise_expr
// bitwise_expr && and_expr_list
//        
int64_t and_expr(int64_t* def)
{
    int64_t val;
    int64_t def1, def2;
    
    val = bitwise_expr(&def1);
    while(token==tk_land) {
        NextToken(); 
        val = val && bitwise_expr(&def2);
        *def = *def && (def1 && def2);
    }
    return val;
}

// and_expr
// and_expr || or_expr_list
//
int64_t or_expr(int64_t* def)
{
    int64_t val;
    int64_t def1, def2;
    
    val = and_expr(&def1);
    while(token==tk_lor) {
        NextToken(); 
        val = val || and_expr(&def2);
        *def = *def && (def1 && def2);
    }
    return val;
}

int64_t expr()
{
    int64_t val;
    int64_t def;

    nsym = 0;
    lastsym = (SYM*)NULL;    
    if (token=='#')
       NextToken();
    val = or_expr(&def);
    // We only care about the symbol if relocatable output is being generated.
    // Setting the symbol to NULL will result in no rel records being output.
    if (nsym > 1 || !rel_out)
        lastsym = (SYM *)NULL;
    return val;
}

int64_t expr_def(int64_t *def)
{
  int64_t val;

  nsym = 0;
  lastsym = (SYM*)NULL;
  if (token == '#')
    NextToken();
  val = or_expr(def);
  // We only care about the symbol if relocatable output is being generated.
  // Setting the symbol to NULL will result in no rel records being output.
  if (nsym > 1 || !rel_out)
    lastsym = (SYM*)NULL;
  return val;
}

