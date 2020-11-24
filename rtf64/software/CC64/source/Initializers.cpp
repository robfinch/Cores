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
	std::streampos lblpoint;
	TYP *tp;
	int n;

	sp->storage_pos = ofs.tellp();
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
		seg(oseg==noseg ? (lastst==assign ? dataseg : bssseg) : oseg,algn);            /* initialize into data segment */
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
		lblpoint = ofs.tellp();
		gen_strlab(lbl);
	}
	if (lastst == kw_firstcall) {
        GenerateByte(1);
        goto xit;
    }
	else if( lastst != assign) {
		hasPointer = sp->tp->FindPointer();
		genstorage(sp->tp->size);
	}
	else {
		ENODE* node;
		Expression exp;

		NextToken();
		if (lastst == bitandd) {
			char buf[400];
			char buf2[40];
			if (sp->storage_class == sc_global)
				strcpy(buf2, "endpublic\n");
			else
				strcpy(buf2, "");
			sprintf(buf, "%s:\ndco %s_dat\n%s%s_dat:\n", lbl, sp->name->c_str(), buf2, lbl);
			ofs.seekp(lblpoint);
			ofs.write(buf);
			while (lastst != begin && lastst != semicolon && lastst != my_eof)
				NextToken();
		}
		hasPointer = sp->tp->FindPointer();
		typ_sp = 0;
		tp = sp->tp;
		push_typ(tp);
		while (tp = tp->GetBtp()) {
			push_typ(tp);
		}
		brace_level = 0;
		sp->tp->Initialize(nullptr, nullptr, 1);
		if (sp->tp->numele == 0) {
			if (sp->tp->GetBtp()) {
				if (sp->tp->GetBtp()->type == bt_char || sp->tp->GetBtp()->type == bt_uchar
					|| sp->tp->GetBtp()->type == bt_ichar || sp->tp->GetBtp()->type == bt_iuchar
					) {
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
xit:
	sp->storage_endpos = ofs.tellp();
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

int64_t initbyte(int opt)
{   
	GenerateByte(opt ? (int)GetIntegerExpression((ENODE **)NULL) : 0);
    return (1LL);
}

int64_t initchar(int opt)
{   
	GenerateChar(opt ? (int)GetIntegerExpression((ENODE **)NULL) : 0);
    return (2LL);
}

int64_t initshort(int opt)
{
	GenerateHalf(opt ? (int)GetIntegerExpression((ENODE **)NULL) : 0);
    return (4LL);
}

int64_t initlong(int opt)
{
	GenerateLong(opt ? GetIntegerExpression((ENODE **)NULL) : 0);
    return (8LL);
}

int64_t initquad(int opt)
{
	GenerateQuad(opt ? GetFloatExpression((ENODE **)NULL) : Float128::Zero());
	return (16LL);
}

int64_t initfloat(int opt)
{
	GenerateFloat(opt ? GetFloatExpression((ENODE **)NULL): Float128::Zero());
	return (8LL);
}

int64_t initPosit(int opt)
{
	GeneratePosit(opt ? GetPositExpression((ENODE**)NULL) : 0);
	return (8LL);
}

int64_t inittriple(int opt)
{
	GenerateQuad(opt ? GetFloatExpression((ENODE **)NULL) : Float128::Zero());
	return (12LL);
}

int64_t InitializePointer(TYP *tp2)
{   
	SYM *sp;
	ENODE *n = nullptr;
	int64_t lng;
	TYP *tp;
	bool need_end = false;
	Expression exp;

	sp = nullptr;
	if (lastst == begin) {
		need_end = true;
		NextToken();
		if (lastst == begin) {
			NextToken();
			lng = tp2->Initialize(nullptr, nullptr,1);
			needpunc(end, 13);
			needpunc(end, 14);
			return (lng);
		}
	}
    if(lastst == bitandd) {     /* address of a variable */
        NextToken();
				//tp = expression(&n);
				tp = exp.ParseNonCommaExpression(&n);
				opt_const(&n);
				if (n->nodetype != en_icon) {
					if (n->nodetype == en_ref) {
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
						else if (n->p[0]->nodetype == en_sub || n->p[0]->nodetype == en_ptrdif) {
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
    else if(lastst == sconst || lastst == asconst) {
			char *str;

			str = GetStrConst();
      GenerateLabelReference(stringlit(str),0);
			free(str);
    }
		else if (lastst == rconst) {
			GenerateLabelReference(quadlit(&rval128), 0);
			NextToken();
		}
		else if (lastst == pconst) {
			GeneratePosit(pval64);
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
//			GenerateLong((lng & 0xFFFFFFFFFFFLL)|0xFFF0100000000000LL);
			GenerateLong(lng);
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
