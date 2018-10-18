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

void endinit();
extern int curseg;
static char glbl1[500];
static char glbl2[500];
bool hasPointer;
bool firstPrim;
std::streampos patchpoint;
short int brace_level;

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

void doinit(SYM *sp)
{
	static bool first = true;
	char lbl[200];
  int algn;
  enum e_sg oseg;
  char buf[500];
  std::streampos endpoint;
	TYP *tp;

  hasPointer = false;
  if (first) {
	  firstPrim = true;
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
        else if (sp->tp->type==bt_pointer)// && sp->tp->val_flag)
           algn = imax(sp->tp->GetBtp()->alignment,8);
        else
            algn = 2;
		seg(oseg==noseg ? tlsseg : oseg,algn);
		nl();
	}
	else if (sp->storage_class == sc_static || lastst==assign) {
        if (sp->tp->type==bt_struct || sp->tp->type==bt_union)
           algn = imax(sp->tp->alignment,8);
        else if (sp->tp->type==bt_pointer)// && sp->tp->val_flag)
           algn = imax(sp->tp->GetBtp()->alignment,8);
        else
            algn = 2;
		seg(oseg==noseg ? dataseg : oseg,algn);          /* initialize into data segment */
		nl();                   /* start a new line in object */
	}
	else {
        if (sp->tp->type==bt_struct || sp->tp->type==bt_union)
           algn = imax(sp->tp->alignment,8);
        else if (sp->tp->type==bt_pointer)// && sp->tp->val_flag)
           algn = imax(sp->tp->GetBtp()->alignment,8);
        else
            algn = 2;
		seg(oseg==noseg ? bssseg : oseg,algn);            /* initialize into data segment */
		nl();                   /* start a new line in object */
	}
	
	if (sp->storage_class == sc_static || sp->storage_class == sc_thread) {
		//strcpy_s(glbl, sizeof(glbl), gen_label((int)sp->value.i, (char *)sp->name->c_str(), GetNamespace(), 'D'));
		if (sp->tp->IsSkippable()) {
			patchpoint = ofs.tellp();
			sprintf_s(buf, sizeof(buf), "\talign\t8\n\tdw\t$FFF0200000000001\n");
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
		if (sp->tp->IsSkippable()) {
			patchpoint = ofs.tellp();
			sprintf_s(buf, sizeof(buf), "\talign\t8\n\tdw\t$FFF0200000000001\n");
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
		hasPointer = sp->tp->FindPointer();
		genstorage(sp->tp->size);
	}
	else {
		NextToken();
		hasPointer = sp->tp->FindPointer();
		typ_sp = 0;
		tp = sp->tp;
		push_typ(tp);
		while (tp = tp->GetBtp()) {
			push_typ(tp);
		}
		brace_level = 0;
		sp->tp->Initialize(nullptr);
		if (sp->tp->numele == 0) {
			if (sp->tp->GetBtp()) {
				if (sp->tp->GetBtp()->type == bt_char || sp->tp->GetBtp()->type == bt_uchar) {
					sp->tp->numele = laststrlen;
					sp->tp->size = laststrlen;
				}
			}
		}
	}
	if (!hasPointer && sp->tp->IsSkippable()) {
		endpoint = ofs.tellp();
		ofs.seekp(patchpoint);
		sprintf_s(buf, sizeof(buf), "\talign\t8\n\tdw\t$%I64X\n", ((genst_cumulative + 7LL) >> 3LL) | 0xFFF0200000000000LL);
		ofs.printf(buf);
		ofs.seekp(endpoint);
		genst_cumulative = 0;
	}
	else if (sp->tp->IsSkippable()) {
		endpoint = ofs.tellp();
		ofs.seekp(patchpoint);
		sprintf_s(buf, sizeof(buf), "\talign\t8\n\t  \t                 \n");
		ofs.printf(buf);
		ofs.seekp(endpoint);
		genst_cumulative = 0;
	}
    endinit();
	if (sp->storage_class == sc_global)
		ofs.printf("\nendpublic\n");
}


// Patch the last gc_skip

void doInitCleanup()
{
	std::streampos endpoint;
	char buf[500];

	if (genst_cumulative && !hasPointer) {
		endpoint = ofs.tellp();
		if (patchpoint > 0) {
			ofs.seekp(patchpoint);
			sprintf_s(buf, sizeof(buf), "\talign\t8\n\tdw\t$%I64X\n", ((genst_cumulative + 7LL) >> 3LL) | 0xFFF0200000000000LL);
			ofs.printf(buf);
			ofs.seekp(endpoint);
		}
		genst_cumulative = 0;
	}
}

int64_t initbyte()
{   
	GenerateByte((int)GetIntegerExpression((ENODE **)NULL));
    return (1LL);
}

int64_t initchar()
{   
	GenerateChar((int)GetIntegerExpression((ENODE **)NULL));
    return (2LL);
}

int64_t initshort()
{
	GenerateHalf((int)GetIntegerExpression((ENODE **)NULL));
    return (4LL);
}

int64_t initlong()
{
	GenerateLong(GetIntegerExpression((ENODE **)NULL));
    return (8LL);
}

int64_t initquad()
{
	GenerateQuad(GetFloatExpression((ENODE **)NULL));
	return (16LL);
}

int64_t initfloat()
{
	GenerateFloat(GetFloatExpression((ENODE **)NULL));
	return (8LL);
}

int64_t inittriple()
{
	GenerateQuad(GetFloatExpression((ENODE **)NULL));
	return (12LL);
}

int64_t InitializePointer(TYP *tp2)
{   
	SYM *sp;
	ENODE *n = nullptr;
	int64_t lng;
	TYP *tp;
	bool need_end = false;

	sp = nullptr;
	if (lastst == begin) {
		need_end = true;
		NextToken();
		if (lastst == begin) {
			NextToken();
			lng = tp2->Initialize(nullptr);
			needpunc(end, 13);
			needpunc(end, 14);
			return (lng);
		}
	}
    if(lastst == bitandd) {     /* address of a variable */
        NextToken();
				tp = expression(&n);
				opt_const(&n);
				if (n->nodetype != en_icon) {
					if (n->nodetype == en_h_ref
						|| n->nodetype == en_uh_ref
						|| n->nodetype == en_w_ref
						|| n->nodetype == en_uw_ref) {
						if (n->p[0]->nodetype == en_add) {
							if (n->p[0]->p[0]->nodetype == en_labcon) {
								sp = n->p[0]->p[0]->sym;
								GenerateReference(n->p[0]->p[0]->sym, n->p[0]->p[1]->i);
							}
							else if (n->p[0]->p[1]->nodetype == en_labcon) {
								sp = n->p[0]->p[1]->sym;
								GenerateReference(n->p[0]->p[1]->sym, n->p[0]->p[0]->i);
							}
							else
								error(ERR_ILLINIT);
						}
						else if (n->p[0]->nodetype == en_sub) {
							if (n->p[0]->p[0]->nodetype == en_labcon) {
								sp = n->p[0]->p[0]->sym;
								GenerateReference(n->p[0]->p[0]->sym, -n->p[0]->p[1]->i);
							}
							else if (n->p[0]->p[1]->nodetype == en_labcon) {
								sp = n->p[0]->p[1]->sym;
								GenerateReference(n->p[0]->p[1]->sym, -n->p[0]->p[0]->i);
							}
							else
								error(ERR_ILLINIT);
						}
					}
				}
				else
					GenerateLong(n->i);
				if (sp)
					if (sp->storage_class == sc_auto)
						error(ERR_NOINIT);
				/*
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
				*/
    }
    else if(lastst == sconst) {
			char *str;

			str = GetStrConst();
      GenerateLabelReference(stringlit(str),0);
			free(str);
    }
	else if (lastst == rconst) {
        GenerateLabelReference(quadlit(&rval128),0);
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
		else if (n && n->nodetype == en_labcon) {
			GenerateLabelReference(n->i,0);
		}
		else if (n && n->nodetype == en_add) {
			if (n->p[0]->nodetype==en_labcon)
				GenerateLabelReference(n->p[0]->i, n->p[1]->i);
			else
				GenerateLabelReference(n->p[1]->i, n->p[0]->i);
		}
		else {
			GenerateLong((lng & 0xFFFFFFFFFFFLL)|0xFFF0100000000000LL);
        }
	}
	if (need_end)
		needpunc(end, 8);
	endinit();
    return (sizeOfPtr);       /* pointers are 8 bytes long */
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
