// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2018  Robert Finch, Waterloo
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

extern int catchdecl;
extern void genstorageskip(int nbytes);

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
static bool FindPointerInType(TYP *tp);
extern int curseg;
static int64_t prev_cumulative;
static char glbl1[500];
static char glbl2[500];
bool hasPointer;
bool firstPrim;
std::streampos patchpoint;

static void pad(char *p, int n)
{
	int nn;

	nn = strlen(p);
	while (nn < n) {
		p[nn] = ' ';
		nn++;
	}
	p[nn] = '\n';
	p[nn + 1] = '\0';
}

static bool FindPointerInStruct(TYP *tp)
{
	SYM *sp;

	sp = sp->GetPtr(tp->lst.GetHead());      /* start at top of symbol table */
	while (sp != 0) {
		if (FindPointerInType(sp->tp))
			return (true);
		sp = sp->GetNextPtr();
	}
	return (false);
}

static bool FindPointerInType(TYP *tp)
{
	switch (tp->type) {
	case bt_pointer: return (tp->val_flag == FALSE);	// array ?
	case bt_struct: return (FindPointerInStruct(tp));
	case bt_union: return (FindPointerInStruct(tp));
	case bt_class: return (FindPointerInStruct(tp));
	}
	return (false);
}


bool IsSkipType(TYP *tp)
{
	switch (tp->type) {
	case bt_struct:	return(true);
	case bt_union: return(true);
	case bt_class: return(true);
	case bt_pointer:
		if (tp->val_flag == TRUE) {
			return (!FindPointerInType(tp->GetBtp()));
		}
		return(false);
	}
	return (false);
}

void doinit(SYM *sp)
{
	static bool first = true;
	char lbl[200];
  int algn;
  enum e_sg oseg;
  char buf[500];
  char buf2[500];
  std::streampos endpoint;

  hasPointer = false;
  if (first) {
	  firstPrim = true;
	  prev_cumulative = 0;
	  first = false;
  }

  oseg = noseg;
	lbl[0] = 0;
	// Initialize constants into read-only data segment. Constants may be placed
	// in ROM along with code.
	if (sp->isConst) {
    oseg = rodataseg;
  }
	if (sp->storage_class == sc_thread) {
        if (sp->tp->type==bt_struct || sp->tp->type==bt_union)
           algn = imax(sp->tp->alignment,8);
        else if (sp->tp->type==bt_pointer && sp->tp->val_flag)
           algn = imax(sp->tp->GetBtp()->alignment,8);
        else
            algn = 2;
		seg(oseg==noseg ? tlsseg : oseg,algn);
		nl();
	}
	else if (sp->storage_class == sc_static || lastst==assign) {
        if (sp->tp->type==bt_struct || sp->tp->type==bt_union)
           algn = imax(sp->tp->alignment,8);
        else if (sp->tp->type==bt_pointer && sp->tp->val_flag)
           algn = imax(sp->tp->GetBtp()->alignment,8);
        else
            algn = 2;
		seg(oseg==noseg ? dataseg : oseg,algn);          /* initialize into data segment */
		nl();                   /* start a new line in object */
	}
	else {
        if (sp->tp->type==bt_struct || sp->tp->type==bt_union)
           algn = imax(sp->tp->alignment,8);
        else if (sp->tp->type==bt_pointer && sp->tp->val_flag)
           algn = imax(sp->tp->GetBtp()->alignment,8);
        else
            algn = 2;
		seg(oseg==noseg ? bssseg : oseg,algn);            /* initialize into data segment */
		nl();                   /* start a new line in object */
	}
	
	if (sp->storage_class == sc_static || sp->storage_class == sc_thread) {
		//strcpy_s(glbl, sizeof(glbl), gen_label((int)sp->value.i, (char *)sp->name->c_str(), GetNamespace(), 'D'));
		if (IsSkipType(sp->tp)) {
			patchpoint = ofs.tellp();
			sprintf_s(buf, sizeof(buf), "\talign\t8\n\tdw\t$FFF0200000000001 ; GC_skip\n");
			ofs.printf(buf);
		}
		sp->realname = my_strdup(put_label((int)sp->value.i, (char *)sp->name->c_str(), GetNamespace(), 'D'));
		strcpy_s(glbl2, sizeof(glbl2), gen_label((int)sp->value.i, (char *)sp->name->c_str(), GetNamespace(), 'D'));
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
		if (IsSkipType(sp->tp)) {
			patchpoint = ofs.tellp();
			sprintf_s(buf, sizeof(buf), "\talign\t8\n\tdw\t$FFF0200000000001 ; GC_skip\n");
			ofs.printf(buf);
		}
		strcpy_s(glbl2, sizeof(glbl2), sp->name->c_str());
		gen_strlab(lbl);
	}
	if (lastst == kw_firstcall) {
        GenerateByte(1);
        return;
    }
	else if( lastst != assign) {
		hasPointer = FindPointerInType(sp->tp);
		genstorage(sp->tp->size);
	}
	else {
		NextToken();
		hasPointer = FindPointerInType(sp->tp);
		InitializeType(sp->tp);
	}
	if (!hasPointer && IsSkipType(sp->tp)) {
		endpoint = ofs.tellp();
		ofs.seekp(patchpoint);
		sprintf_s(buf, sizeof(buf), "\talign\t8\n\tdw\t$%I64X ", ((genst_cumulative + 7LL) >> 3LL) | 0xFFF0200000000000LL);
		ofs.printf(buf);
		ofs.seekp(endpoint);
		genst_cumulative = 0;
	}
	else if (IsSkipType(sp->tp)) {
		endpoint = ofs.tellp();
		ofs.seekp(patchpoint);
		sprintf_s(buf, sizeof(buf), "\talign\t8\n\t  \t                 ");
		ofs.printf(buf);
		ofs.seekp(endpoint);
		genst_cumulative = 0;
	}
    endinit();
	if (sp->storage_class == sc_global)
		ofs.printf("\nendpublic\n");
}

void doInitCleanup()
{
	std::streampos endpoint;
	char buf[500];
	char buf2[500];
	int nn;

	if (genst_cumulative) {
		endpoint = ofs.tellp();
		ofs.seekp(patchpoint);
		sprintf_s(buf, sizeof(buf), "\talign\t8\n\tdw\t$%I64X ; GC_skip\n", ((genst_cumulative + 7LL) >> 3LL) | 0xFFF0200000000000LL);
		ofs.printf(buf);
		ofs.seekp(endpoint);
		genst_cumulative = 0;
	}
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
			GenerateLong((lng & 0xFFFFFFFFFFFLL)|0xFFF0100000000000LL);
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
