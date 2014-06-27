// ============================================================================
//        __
//   \\__/ o\    (C) 2012,2013  Robert Finch, Stratford
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
#include <stdio.h>
#include <string.h>
#include "c.h"
#include "expr.h"
#include "Statement.h"
#include "gen.h"
#include "cglbdec.h"
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
int InitializePointer();
void endinit();
int InitializeArray(TYP *tp);
extern int curseg;

void doinit(SYM *sp)
{
	char lbl[200];

	lbl[0] = 0;
	if (sp->storage_class == sc_thread) {
		seg(tlsseg);
		nl();
	}
	else if (sp->storage_class == sc_static || lastst==assign) {
		seg(dataseg);          /* initialize into data segment */
		nl();                   /* start a new line in object */
	}
	else {
		seg(bssseg);            /* initialize into data segment */
		nl();                   /* start a new line in object */
	}
	if(sp->storage_class == sc_static || sp->storage_class == sc_thread) {
		put_label(sp->value.i, sp->name, GetNamespace(), 'D');
	}
	else {
		if (sp->storage_class == sc_global) {
			strcpy(lbl, "public ");
			if (curseg==dataseg)
				strcat(lbl, "data ");
			else if (curseg==bssseg)
				strcat(lbl, "bss ");
			else if (curseg==tlsseg)
				strcat(lbl, "tls ");
		}
		strcat(lbl, sp->name);
		//gen_strlab(lbl);
	}
	if( lastst != assign) {
		genstorage(sp->tp->size);
	}
	else {
		NextToken();
		InitializeType(sp->tp);
	}
    endinit();
	if (sp->storage_class == sc_global)
		fprintf(output,"\nendpublic\n");
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
	case bt_ulong:
    case bt_long:
            nbytes = initlong();
            break;
    case bt_struct:
            nbytes = InitializeStructure(tp);
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
			if (lastst == sconst && (tp->btp->type==bt_char || tp->btp->type==bt_uchar)) {
				nbytes = strlen(laststr) * 2 + 2;
				p = laststr;
				while( *p )
					GenerateChar(*p++);
				GenerateChar(0);
				NextToken();
			}
			else
				nbytes += InitializeType(tp->btp);
            if( lastst == comma)
                NextToken();
            else if( lastst != end)
                error(ERR_PUNCT);
        }
        NextToken();               /* skip closing brace */
    }
    else if( lastst == sconst && (tp->btp->type == bt_char || tp->btp->type==bt_uchar)) {
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

    needpunc(begin);
    nbytes = 0;
    sp = tp->lst.head;      /* start at top of symbol table */
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
        sp = sp->next;
    }
    if( nbytes < tp->size)
        genstorage( tp->size - nbytes);
    needpunc(end);
    return tp->size;
}

int initbyte()
{   
	GenerateByte(GetIntegerExpression(NULL));
    return 1;
}

int initchar()
{   
	GenerateChar(GetIntegerExpression(NULL));
    return 2;
}

int initshort()
{
	GenerateWord(GetIntegerExpression(NULL));
    return 4;
}

int initlong()
{
	GenerateLong(GetIntegerExpression(NULL));
    return 8;
}

int InitializePointer()
{   
	SYM *sp;
	ENODE *n;
	long lng;

    if(lastst == and) {     /* address of a variable */
        NextToken();
        if( lastst != id)
            error(ERR_IDEXPECT);
		else if( (sp = gsearch(lastid)) == NULL)
            error(ERR_UNDEFINED);
        else {
            NextToken();
            if( lastst == plus || lastst == minus)
                GenerateReference(sp,GetIntegerExpression(NULL));
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
		if (n->nodetype == en_cnacon) {
			if (n->sp) {
				sp = gsearch(n->sp);
				GenerateReference(sp,0);
			}
			else
				GenerateLong(lng);
		}
		else
			GenerateLong(lng);
	}
    endinit();
    return 8;       /* pointers are 8 bytes long */
}

void endinit()
{    
	if( lastst != comma && lastst != semicolon && lastst != end) {
		error(ERR_PUNCT);
		while( lastst != comma && lastst != semicolon && lastst != end)
            NextToken();
    }
}
