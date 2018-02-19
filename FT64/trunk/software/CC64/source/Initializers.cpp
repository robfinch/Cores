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

extern int catchdecl;

/*
 *	68000 C compiler
 *
 *	Copyright 1984, 1985, 1986 Matthew Brandt.
 *  all commercial rights reserved.
 *
 *	This compiler is intended as an instructive tool for personal use. Any
 *	use for profit without the written consent of the author is prohibited.
 *
 *	This compiler may be distributed freely for non-commercial use as long
 *	as this notice stays intact. Please forward any enhancements or questions
 *	to:
 *
 *		Matthew Brandt
 *		Box 920337
 *		Norcross, Ga 30092
 */

int InitializeType(TYP *tp);
int InitializeStructure(TYP *tp);
int initbyte();
int initchar();
int initshort();
int initlong();
int inittriple();
int initfloat();
int initquad();
int InitializePointer();
void endinit();
int InitializeArray(TYP *tp);
extern int curseg;

void doinit(SYM *sp)
{
	char lbl[200];
  int algn;
  enum e_sg oseg;

  oseg = noseg;
	lbl[0] = 0;
	// Initialize constants into read-only data segment. Constants may be placed
	// in ROM along with code.
	if (sp->isConst) {
    oseg = rodataseg;
  }
	if (sp->storage_class == sc_thread) {
        if (sp->tp->type==bt_struct || sp->tp->type==bt_union)
           algn = imax(sp->tp->alignment,2);
        else if (sp->tp->type==bt_pointer && sp->tp->val_flag)
           algn = imax(sp->tp->GetBtp()->alignment,2);
        else
            algn = 2;
		seg(oseg==noseg ? tlsseg : oseg,algn);
		nl();
	}
	else if (sp->storage_class == sc_static || lastst==assign) {
        if (sp->tp->type==bt_struct || sp->tp->type==bt_union)
           algn = imax(sp->tp->alignment,2);
        else if (sp->tp->type==bt_pointer && sp->tp->val_flag)
           algn = imax(sp->tp->GetBtp()->alignment,2);
        else
            algn = 2;
		seg(oseg==noseg ? dataseg : oseg,algn);          /* initialize into data segment */
		nl();                   /* start a new line in object */
	}
	else {
        if (sp->tp->type==bt_struct || sp->tp->type==bt_union)
           algn = imax(sp->tp->alignment,2);
        else if (sp->tp->type==bt_pointer && sp->tp->val_flag)
           algn = imax(sp->tp->GetBtp()->alignment,2);
        else
            algn = 2;
		seg(oseg==noseg ? bssseg : oseg,algn);            /* initialize into data segment */
		nl();                   /* start a new line in object */
	}
	if(sp->storage_class == sc_static || sp->storage_class == sc_thread) {
		sp->realname = my_strdup(put_label((int)sp->value.i, (char *)sp->name->c_str(), GetNamespace(), 'D'));
	}
	else {
		if (sp->storage_class == sc_global) {
			strcpy_s(lbl, sizeof(lbl), "public ");
			if (curseg==dataseg)
				strcat_s(lbl, sizeof(lbl), "data ");
			else if (curseg==bssseg)
				strcat_s(lbl, sizeof(lbl), "bss ");
			else if (curseg==tlsseg)
				strcat_s(lbl, sizeof(lbl), "tls ");
		}
		strcat_s(lbl, sizeof(lbl), sp->name->c_str());
		gen_strlab(lbl);
	}
	if (lastst == kw_firstcall) {
        GenerateByte(1);
        return;
    }
	else if( lastst != assign) {
		genstorage(sp->tp->size);
	}
	else {
		NextToken();
		InitializeType(sp->tp);
	}
    endinit();
	if (sp->storage_class == sc_global)
		ofs.printf("\nendpublic\n");
}

int InitializeType(TYP *tp)
{   
	int nbytes;

  switch(tp->type) {
	case bt_ubyte:
	case bt_byte:
			nbytes = initbyte();
			break;
	case bt_uchar:
  case bt_char:
  case bt_enum:
            nbytes = initchar();
            break;
	case bt_ushort:
  case bt_short:
            nbytes = initshort();
            break;
  case bt_pointer:
    if( tp->val_flag)
			nbytes = InitializeArray(tp);
		else
			nbytes = InitializePointer();
    break;
  case bt_exception:
	case bt_ulong:
  case bt_long:
            nbytes = initlong();
            break;
  case bt_struct:
            nbytes = InitializeStructure(tp);
            break;
  case bt_quad:
		nbytes = initquad();
		break;
  case bt_float:
  case bt_double:
		nbytes = initfloat();
		break;
  case bt_triple:
		nbytes = inittriple();
		break;
  default:
        error(ERR_NOINIT);
        nbytes = 0;
    }
    return nbytes;
}

int InitializeArray(TYP *tp)
{     
	int nbytes;
    char *p;

    nbytes = 0;
    if( lastst == begin) {
        NextToken();               /* skip past the brace */
        while(lastst != end) {
			// Allow char array initialization like { "something", "somethingelse" }
			if (lastst == sconst && (tp->GetBtp()->type==bt_char || tp->GetBtp()->type==bt_uchar)) {
				nbytes = strlen(laststr) * 2 + 2;
				p = laststr;
				while( *p )
					GenerateChar(*p++);
				GenerateChar(0);
				NextToken();
			}
			else
				nbytes += InitializeType(tp->GetBtp());
            if( lastst == comma)
                NextToken();
            else if( lastst != end)
                error(ERR_PUNCT);
        }
        NextToken();               /* skip closing brace */
    }
    else if( lastst == sconst && (tp->GetBtp()->type == bt_char || tp->GetBtp()->type==bt_uchar)) {
        nbytes = strlen(laststr) * 2 + 2;
        p = laststr;
        while( *p )
            GenerateChar(*p++);
        GenerateChar(0);
        NextToken();
    }
    else if( lastst != semicolon)
        error(ERR_ILLINIT);
    if( nbytes < tp->size) {
        genstorage( tp->size - nbytes);
        nbytes = tp->size;
    }
    else if( tp->size != 0 && nbytes > tp->size)
        error(ERR_INITSIZE);    /* too many initializers */
    return nbytes;
}

int InitializeStructure(TYP *tp)
{
	SYM *sp;
    int nbytes;

    needpunc(begin,25);
    nbytes = 0;
    sp = sp->GetPtr(tp->lst.GetHead());      /* start at top of symbol table */
    while(sp != 0) {
		while(nbytes < sp->value.i) {     /* align properly */
//                    nbytes += GenerateByte(0);
            GenerateByte(0);
//                    nbytes++;
		}
        nbytes += InitializeType(sp->tp);
        if( lastst == comma)
            NextToken();
        else if(lastst == end)
            break;
        else
            error(ERR_PUNCT);
        sp = sp->GetNextPtr();
    }
    if( nbytes < tp->size)
        genstorage( tp->size - nbytes);
    needpunc(end,26);
    return tp->size;
}

int initbyte()
{   
	GenerateByte((int)GetIntegerExpression((ENODE **)NULL));
    return 1;
}

int initchar()
{   
	GenerateChar((int)GetIntegerExpression((ENODE **)NULL));
    return 2;
}

int initshort()
{
	GenerateWord((int)GetIntegerExpression((ENODE **)NULL));
    return 4;
}

int initlong()
{
	GenerateLong(GetIntegerExpression((ENODE **)NULL));
    return 8;
}

int initquad()
{
	GenerateQuad(GetFloatExpression((ENODE **)NULL));
	return (16);
}

int initfloat()
{
	GenerateFloat(GetFloatExpression((ENODE **)NULL));
	return (8);
}

int inittriple()
{
	GenerateQuad(GetFloatExpression((ENODE **)NULL));
	return (12);
}

int InitializePointer()
{   
	SYM *sp;
	ENODE *n = nullptr;
	int64_t lng;

    if(lastst == bitandd) {     /* address of a variable */
        NextToken();
        if( lastst != id)
            error(ERR_IDEXPECT);
		else if( (sp = gsearch(lastid)) == NULL)
            error(ERR_UNDEFINED);
        else {
            NextToken();
            if( lastst == plus || lastst == minus)
                GenerateReference(sp,(int)GetIntegerExpression((ENODE **)NULL));
            else
                GenerateReference(sp,0);
            if( sp->storage_class == sc_auto)
                    error(ERR_NOINIT);
        }
    }
    else if(lastst == sconst) {
        GenerateLabelReference(stringlit(laststr));
        NextToken();
    }
	else if (lastst == rconst) {
        GenerateLabelReference(quadlit(&rval128));
        NextToken();
	}
	//else if (lastst == id) {
	//	sp = gsearch(lastid);
	//	if (sp->tp->type == bt_func || sp->tp->type == bt_ifunc) {
	//		NextToken();
	//		GenerateReference(sp,0);
	//	}
	//	else
	//		GenerateLong(GetIntegerExpression(NULL));
	//}
	else {
		lng = GetIntegerExpression(&n);
		if (n && n->nodetype == en_cnacon) {
			if (n->sp->length()) {
				sp = gsearch(*n->sp);
				GenerateReference(sp,0);
			}
			else
				GenerateLong(lng);
		}
		else {
			GenerateLong(lng);
        }
	}
    endinit();
    return 8;       /* pointers are 8 bytes long */
}

void endinit()
{    
    if (catchdecl) {
        if (lastst!=closepa)
        		error(ERR_PUNCT);
    }
    else if( lastst != comma && lastst != semicolon && lastst != end) {
		error(ERR_PUNCT);
		while( lastst != comma && lastst != semicolon && lastst != end)
            NextToken();
    }
}
