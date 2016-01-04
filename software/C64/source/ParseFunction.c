// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2014  Robert Finch, Stratford
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
#include        <stdio.h>
#include <string.h>
#include        "c.h"
#include        "expr.h"
#include "Statement.h"
#include        "gen.h"
#include        "cglbdec.h"

SYM *makeint(char *name);

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

extern int funcdecl;
extern char *names[20];
extern int nparms;
extern char *stkname;

static Statement *ParseFunctionBody(SYM *sp);
void funcbottom(Statement *stmt);
void ListCompound(Statement *stmt);

static int round8(int n)
{
    while (n & 7) n++;
    return n;
}


/*      function compilation routines           */

/*
 *      funcbody starts with the current symbol being either
 *      the first parameter id or the begin for the local
 *      block. If begin is the current symbol then funcbody
 *      assumes that the function has no parameters.
 */
int ParseFunction(SYM *sp)
{
	int poffset, i;
	int oldglobal;
    SYM *sp1, *sp2;
	Statement *stmt;

	if (sp==NULL) {
		fatal("Compiler error: ParseFunction: SYM is NULL\r\n");
	}
	sp->stkname = stkname;
	if (verbose) printf("Parsing function: %s\r\n", sp->name);
		oldglobal = global_flag;
        global_flag = 0;
        poffset = 24;            /* size of return block */
        nparms = 0;
		iflevel = 0;
		// There could be unnamed parameters in a function prototype.
        if(lastst == id || 1) {              /* declare parameters */
                //while(lastst == id) {
                //        names[nparms++] = litlate(lastid);
                //        NextToken();
                //        if( lastst == comma)
                //                NextToken();
                //        else
                //                break;
                //        }
                //needpunc(closepa);
//                dodecl(sc_member);      /* declare parameters */
				sp->parms = (SYM *)NULL;
				ParseParameterDeclarations(1);
                for(i = 0;i < nparms;++i) {
                        if( (sp1 = search(names[i],&lsyms)) == NULL)
                                sp1 = makeint(names[i]);
						//if( sp1->tp->size < 8 )
						//{
						//	sp1->value.i = poffset;// + (8 - sp1->tp->size);
						//	poffset += 8;
						//}
						//else
						//{
						//	sp1->value.i = poffset;
						//	poffset += sp1->tp->size;
						//}
						sp1->value.i = poffset;
						// Check for aggregate types passed as parameters. Structs
						// and unions use the type size. 
					//	if (sp1->tp->type==bt_struct || sp1->tp->type==bt_union) {
    						poffset += round8(sp1->tp->size);
    						if (round8(sp1->tp->size) > 8)
    						   sp->IsLeaf = FALSE;
                    //     }
                    //     else
                    //         poffset += 8;
						//sp1->value.i = poffset;
						//poffset += 8;
                        sp1->storage_class = sc_auto;
						sp1->nextparm = (SYM *)NULL;
						// record parameter list
						if (sp->parms == (SYM *)NULL) {
							sp->parms = sp1;
						}
						else {
							sp1->nextparm = sp->parms;
							sp->parms = sp1;
						}
					}
					// Process extra hidden parameter
					if (sp->tp->btp->type==bt_struct || sp->tp->btp->type==bt_union) {
                         sp1 = makeint(litlate("_pHiddenStructPtr"));
                         sp1->value.i = poffset;
                         poffset += 8;
                         sp1->storage_class = sc_auto;
  	  	 	 	 	 	 sp1->nextparm = (SYM *)NULL;
						// record parameter list
						if (sp->parms == (SYM *)NULL) {
							sp->parms = sp1;
						}
						else {
							sp1->nextparm = sp->parms;
							sp->parms = sp1;
						}
						nparms++;
                    }
                }
		if (lastst == closepa)
			NextToken();
		if (sp->tp->type == bt_pointer) {
			if (lastst==assign) {
				doinit(sp);
			}
			sp->IsNocall = isNocall;
			sp->IsPascal = isPascal;
			sp->IsKernel = isKernel;
			sp->IsInterrupt = isInterrupt;
			sp->IsTask = isTask;
			sp->NumParms = nparms;
			isPascal = FALSE;
			isKernel = FALSE;
			isOscall = FALSE;
			isInterrupt = FALSE;
			isTask = FALSE;
			isNocall = FALSE;
		    ReleaseLocalMemory();        /* release local symbols (parameters)*/
			global_flag = oldglobal;
			return 1;
		}
		if (lastst == semicolon) {	// Function prototype
			sp->IsPrototype = 1;
			sp->IsNocall = isNocall;
			sp->IsPascal = isPascal;
			sp->IsKernel = isKernel;
			sp->IsInterrupt = isInterrupt;
			sp->IsTask = isTask;
			sp->NumParms = nparms;
			isPascal = FALSE;
			isKernel = FALSE;
			isOscall = FALSE;
			isInterrupt = FALSE;
			isTask = FALSE;
			isNocall = FALSE;
		    ReleaseLocalMemory();        /* release local symbols (parameters)*/
			goto j1;
		}
		else if(lastst != begin) {
//			NextToken();
			ParseParameterDeclarations(2);
			// for old-style parameter list
			//needpunc(closepa);
			if (lastst==semicolon) {
				sp->IsPrototype = 1;
				sp->IsNocall = isNocall;
				sp->IsPascal = isPascal;
    			sp->IsKernel = isKernel;
				sp->IsInterrupt = isInterrupt;
    			sp->IsTask = isTask;
				sp->NumParms = nparms;
				isPascal = FALSE;
    			isKernel = FALSE;
				isOscall = FALSE;
				isInterrupt = FALSE;
    			isTask = FALSE;
				isNocall = FALSE;
				ReleaseLocalMemory();        /* release local symbols (parameters)*/
			}
			// Check for end of function parameter list.
			else if (funcdecl==2 && lastst==closepa) {
				;
			}
			else {
				sp->IsNocall = isNocall;
				sp->IsPascal = isPascal;
    			sp->IsKernel = isKernel;
				sp->IsInterrupt = isInterrupt;
    			sp->IsTask = isTask;
				isPascal = FALSE;
    			isKernel = FALSE;
				isOscall = FALSE;
				isInterrupt = FALSE;
    			isTask = FALSE;
				isNocall = FALSE;
				sp->NumParms = nparms;
				stmt = ParseFunctionBody(sp);
				funcbottom(stmt);
			}
		}
//                error(ERR_BLOCK);
        else {
			sp->IsNocall = isNocall;
			sp->IsPascal = isPascal;
			sp->IsKernel = isKernel;
			sp->IsInterrupt = isInterrupt;
			sp->IsTask = isTask;
			isPascal = FALSE;
			isKernel = FALSE;
			isOscall = FALSE;
			isInterrupt = FALSE;
			isTask = FALSE;
			isNocall = FALSE;
			sp->NumParms = nparms;
			stmt = ParseFunctionBody(sp);
			funcbottom(stmt);
        }
j1:
		global_flag = oldglobal;
		return 0;
}

SYM     *makeint(char *name)
{       SYM     *sp;
        TYP     *tp;
        sp = allocSYM();
        tp = allocTYP();
        tp->type = bt_long;
        tp->size = 8;
        tp->btp = 0;
		tp->lst.head = 0;
        tp->sname = 0;
		tp->isUnsigned = FALSE;
		tp->isVolatile = FALSE;
        sp->name = name;
        sp->storage_class = sc_auto;
        sp->tp = tp;
		sp->IsPrototype = FALSE;
        insert(sp,&lsyms);
        return sp;
}

void check_table(SYM *head)
{   
	while( head != 0 ) {
		if( head->storage_class == sc_ulabel )
				fprintf(list,"*** UNDEFINED LABEL - %s\n",head->name);
		head = head->next;
	}
}

void funcbottom(Statement *stmt)
{ 
	Statement *s, *s1;
	nl();
    check_table(lsyms.head);
    lc_auto = 0;
    fprintf(list,"\n\n*** local symbol table ***\n\n");
    ListTable(&lsyms,0);
	// Should recurse into all the compound statements
	if (stmt==NULL)
		printf("DIAG: null statement in funcbottom.\r\n");
	else {
		if (stmt->stype==st_compound)
			ListCompound(stmt);
	}
    fprintf(list,"\n\n\n");
    ReleaseLocalMemory();        /* release local symbols */
	isPascal = FALSE;
	isKernel = FALSE;
	isOscall = FALSE;
	isInterrupt = FALSE;
	isNocall = FALSE;
}


static Statement *ParseFunctionBody(SYM *sp)
{    
	char lbl[200];
	Statement *stmt;
	Statement *plg;
	Statement *eplg;

	lbl[0] = 0;
	needpunc(begin);
     
    tmpReset();
	TRACE( printf("Parse function body: %s\r\n", sp->name); )
    //ParseAutoDeclarations();
	cseg();
	if (sp->storage_class == sc_static)
	{
		//strcpy(lbl,GetNamespace());
		//strcat(lbl,"_");
		strcpy(lbl,sp->name);
		//gen_strlab(lbl);
	}
	//	put_label((unsigned int) sp->value.i);
	else {
		if (sp->storage_class == sc_global)
			strcpy(lbl, "public code ");
		strcat(lbl,sp->name);
		//gen_strlab(lbl);
	}
	GenerateMonadic(op_fnname,0,make_string(litlate(lbl)));
	currentFn = sp;
	currentFn->IsLeaf = TRUE;
	currentFn->DoesThrow = FALSE;
	currentFn->UsesPredicate = FALSE;
	regmask = 0;
	bregmask = 0;
	currentStmt = (Statement *)NULL;
	stmt = ParseCompoundStatement();
//	stmt->stype = st_funcbody;
	if (isThor)
		GenerateFunction(sp, stmt);
	else if (isTable888)
		GenerateTable888Function(sp, stmt);
	else if (isRaptor64)
		GenerateRaptor64Function(sp, stmt);
	else if (is816)
		Generate816Function(sp, stmt);
	else if (isFISA64)
		GenerateFISA64Function(sp, stmt);

	flush_peep();
	if (sp->storage_class == sc_global) {
		fprintf(output,"endpublic\r\n\r\n");
	}
	fprintf(output,"%sSTKSIZE_ EQU %d\r\n", sp->name, tmpVarSpace() + lc_auto);
	return stmt;
}
