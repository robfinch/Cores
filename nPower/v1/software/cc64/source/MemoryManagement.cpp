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
#include <stdexcept>
#include "stdafx.h"
#include <stdlib.h>
#include <malloc.h>

#define BLKSIZE		8000

struct blk {
	char name[8];			// string overwrite area
    struct blk *next;
    char       m[1];           /* memory area */
};

MBlk *MBlk::first = 0;

void *allocx(int sz)
{
	return MBlk::alloc(sz);
}

void *MBlk::alloc(int sz)
{
  MBlk* p;
  std::exception e;

//  dfs.printf("Enter MBlk::alloc()\n");
  try {
    p = (MBlk*)new char[sz + sizeof(MBlk) + 15];
  }
  catch (std::exception& e) {
    printf("hi");
  }
	if (p==0)
	   return p;
	ZeroMemory((void *)p,sz+sizeof(MBlk));
	p->next = first;
	first = p;
//  dfs.printf("Leave MBlk::alloc()\n");
	return &p[1];
}

void MBlk::ReleaseAll()
{
	MBlk *mbk;
	while (first) {
		mbk = first->next;
		delete[] first;
		first = mbk;
	}
}

static int      glbsize = 0,    /* size left in current global block */
                locsize = 0,    /* size left in current local block */
                glbindx = 0,    /* global index */
                locindx = 0;    /* local index */

static struct blk       *locblk = 0,    /* pointer to local block */
                        *glbblk = 0;    /* pointer to global block */

char    *xalloc(int siz)
{   
	struct blk *bp;
    char       *rv;

	while(siz % 8)	// align word
		siz++;
    if( global_flag ) {
        if( glbsize >= siz ) {
            rv = &(glbblk->m[glbindx]);
            glbsize -= siz;
            glbindx += siz;
            return (rv);
        }
        else {
            bp = (struct blk *)calloc(1,sizeof(struct blk) + BLKSIZE);
			if( bp == (struct blk *)NULL )
			{
				printf(" not enough memory.\n");
				exit(1);
			}
			strcpy_s(bp->name,8,"C64    ");
            bp->next = glbblk;
            glbblk = bp;
            glbsize = BLKSIZE - siz;
            glbindx = siz;
            return (glbblk->m);
        }
    }
    else    {
        if( locsize >= siz ) {
            rv = &(locblk->m[locindx]);
            locsize -= siz;
            locindx += siz;
            return (rv);
        }
        else {
            bp = (struct blk *)calloc(1,sizeof(struct blk) + BLKSIZE);
			if( bp == NULL )
			{
				printf(" not enough local memory.\n");
				exit(1);
			}
			strcpy_s(bp->name,8,"C64    ");
            bp->next = locblk;
            locblk = bp;
            locsize = BLKSIZE - siz;
            locindx = siz;
            return (locblk->m);
        }
    }
}

void ReleaseLocalMemory()
{
	struct blk      *bp1, *bp2;
    int             blkcnt;
    blkcnt = 0;
    bp1 = locblk;
    while( bp1 != NULL ) {
		if (strcmp(bp1->name,"C64    "))
			printf("Block corrupted.");
        bp2 = bp1->next;
        free( bp1 );
        ++blkcnt;
        bp1 = bp2;
    }
    locblk = (struct blk *)NULL;
    locsize = 0;
	currentStmt = (Statement *)NULL;
	if (verbose) printf(" releasing %d bytes local tables.\n",blkcnt * BLKSIZE);
}

void ReleaseGlobalMemory()
{
	struct blk      *bp1, *bp2;
  int             blkcnt;

  dfs.printf("Enter ReleaseGlobalMemory\n");
  bp1 = glbblk;
  blkcnt = 0;
  while( bp1 != (struct blk *)NULL ) {
		if (strcmp(bp1->name,"C64    "))
		  dfs.printf("Block corrupted.");
    bp2 = bp1->next;
    free(bp1);
    ++blkcnt;
    bp1 = bp2;
  }
  glbblk = (struct blk *)NULL;
  glbsize = 0;
//    gsyms.head = NULL;         /* clear global symbol table */
//	gsyms.tail = NULL;
	memset(gsyms,0,sizeof(gsyms));
	if (verbose) printf(" releasing %d bytes global tables.\n",blkcnt * BLKSIZE);
    strtab = (struct slit *)NULL;             /* clear literal table */
 dfs.printf("Leave ReleaseGlobalMemory\n");
}

SYM *allocSYM() {
	SYM *sym = (SYM *)&compiler.symbolTable[compiler.symnum];
	ZeroMemory(sym,sizeof(SYM));
	sym->id = compiler.symnum;
	sym->name = new std::string("");
	sym->name2 = new std::string("");
	sym->name3 = new std::string("");
	sym->shortname = new std::string("");
	sym->lsyms.SetOwner(compiler.symnum);
  	compiler.symnum++;
	if (compiler.symnum > 32760) {
	  dfs.printf("Too many symbols.\n");
    throw new C64PException(ERR_TOOMANY_SYMBOLS,1);
  }
	return sym;
};

void FreeFunction(Function *fn)
{
	fn->valid = FALSE;
}

TYP *allocTYP()
{
//  printf("allocTYP()\r\n");
	TYP *tp = (TYP *)&compiler.typeTable[compiler.typenum];
	ZeroMemory(tp,sizeof(TYP));
	tp->sname = new std::string("");
  tp->bit_width = nullptr;
//	printf("Leave allocTYP():%p\r\n",tp);
  compiler.typenum++;
	if (compiler.typenum > 32760) {
	  dfs.printf("Too many types\n");
    throw new C64PException(ERR_TOOMANY_SYMBOLS,1);
  }
	return tp;
};

Statement *allocSnode() { return (Statement *)xalloc(sizeof(Statement)); };
ENODE *allocEnode() {
  ENODE *p;
  p = (ENODE *)allocx(sizeof(ENODE));
  ZeroMemory(p, sizeof(ENODE));
  p->sp = new std::string();
  return (p);
};
Operand *allocOperand() { return (Operand *)xalloc(sizeof(Operand)); };
CSE *allocCSE() { return (CSE *)xalloc(sizeof(CSE)); };

