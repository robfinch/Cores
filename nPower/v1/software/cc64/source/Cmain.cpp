// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2021  Robert Finch, Waterloo
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

void makename(char *s, char *e);
void summary();
int options(char *);
int openfiles(char *);
void closefiles();
int PreProcessFile(char *);

char irfile[256],
	infile[256],
                listfile[256],
                outfile[256],
				outfileG[256];
std::string	dbgfile;

extern TABLE    tagtable;
int		mainflag;
extern int      total_errors;
int uctran_off;
extern int lstackptr;

int64_t rand64()
{
	int64_t r;

	r = 0x0000000000000000LL;
	r |= (int64_t)rand() << 48LL;
	r |= (int64_t)rand() << 32LL;
	r |= (int64_t)rand() << 16LL;
	r |= (int64_t)rand();
	return (r);
}


int main(int argc, char **argv)
{
	Posit64 pst;
	Posit64 a, b, c, d, e;
	int cnt;
	txtoStream ofs;
	Int128 aa, bb, cc, qq, rr;
	aa = Int128::Convert(0x769bdd5fLL);
	bb = Int128::Convert(0xbcc6f09eLL);
	Int128::Mul(&cc, &aa, &bb);
	/*
	aa.low = 0;
	aa.high = 100;
	bb.low = 20;
	bb.high = 0;
	cc.Div(&qq, &rr, &aa, &bb);
	
	pst = pst.IntToPosit(100);
	a = a.IntToPosit(50);
	b = b.IntToPosit(50);
	c = a.Add(a, b);
	a = a.IntToPosit(100);
	b = b.IntToPosit(10);
	c = c.Divide(a, b);
	ofs.open("d:/cores2020/rtf64/v2/software/examples/positTest.txt", std::ios::out | std::ios::trunc);
	for (cnt = 0; cnt < 30000; cnt++) {
		switch (cnt) {
		case 0:
			a = a.IntToPosit(10);
			b = b.IntToPosit(10);
			break;
		case 1:
			a = a.IntToPosit(10);
			b = b.IntToPosit(1);
			break;
		case 2:
			a = a.IntToPosit(1);
			b = b.IntToPosit(10);
			break;
		case 3:
			a = a.IntToPosit(100);
			b = b.IntToPosit(10);
			break;
		case 4:
			a = a.IntToPosit(2);
			b = b.IntToPosit(2);
			break;
		case 5:
			a = a.IntToPosit(-10);
			b = b.IntToPosit(-10);
			break;
		default:
			a.val = rand64();
			b.val = rand64();
		}
		ofs.printf("%08I64X ", a.val);
		ofs.printf("%08I64X ", b.val);
		c = c.Add(a, b);
		ofs.printf("%08I64X ", c.val);
		d = d.Multiply(a, b);
		ofs.printf("%08I64X ", d.val);
		e = e.Divide(a, b);
		ofs.printf("%08I64X ", e.val);
		ofs.printf("\n");
	}
	ofs.flush();
	ofs.close();
	exit(0);
	*/
	opt_nopeep = FALSE;
	uctran_off = 0;
	optimize =1;
	exceptions=1;
	compiler.nogcskips = true;
	compiler.os_code = false;
	cpu.fileExt = ".asm";
	cpu.SupportsBand = false;
	cpu.SupportsBor = false;
	cpu.SupportsBBC = false;
	cpu.SupportsBBS = false;
	cpu.SupportsPop = false;
	cpu.SupportsPush = false;
	cpu.SupportsLink = false;
	cpu.SupportsUnlink = false;
	cpu.SupportsBitfield = false;
	cpu.SupportsLDM = false;
	cpu.SupportsSTM = false;
	cpu.SupportsPtrdif = false;
	cpu.SupportsEnter = false;
	cpu.SupportsLeave = false;
	cpu.SupportsIndexed = true;
	cpu.Addsi = false;
	cpu.bra_op = op_b;
	cpu.mov_op = op_mr;
	cpu.lea_op = op_la;
	cpu.ldi_op = op_li;
	cpu.ldbu_op = op_lbz;
	cpu.ldb_op = op_lb;
	cpu.ldo_op = op_ld;
	cpu.ldtu_op = op_lwz;
	cpu.ldt_op = op_lwz;
	cpu.ldwu_op = op_lwz;
	cpu.ldw_op = op_lha;
	cpu.stb_op = op_stb;
	cpu.sto_op = op_std;
	cpu.stt_op = op_stw;
	cpu.stw_op = op_sth;
	cpu.ret_op = op_blr;
	memset(cpu.argregs, -1, sizeof(cpu.argregs));
	memset(cpu.tmpregs, -1, sizeof(cpu.argregs));
	memset(cpu.regregs, -1, sizeof(cpu.argregs));
	cpu.argregs[0] = 3;
	cpu.argregs[1] = 4;
	cpu.argregs[2] = 5;
	cpu.argregs[3] = 6;
	cpu.argregs[4] = 7;
	cpu.argregs[5] = 8;
	cpu.argregs[6] = 9;
	cpu.argregs[7] = 10;
	cpu.tmpregs[0] = 11;
	cpu.tmpregs[1] = 12;
	cpu.tmpregs[2] = 13;
	cpu.tmpregs[3] = 14;
	cpu.tmpregs[4] = 15;
	cpu.tmpregs[5] = 16;
	cpu.tmpregs[6] = 17;
	cpu.tmpregs[7] = 18;
	cpu.regregs[0] = 19;
	cpu.regregs[1] = 20;
	cpu.regregs[2] = 21;
	cpu.regregs[3] = 22;
	cpu.regregs[4] = 23;
	cpu.regregs[5] = 24;
	cpu.regregs[6] = 25;
	cpu.regregs[7] = 26;

//	printf("c64 starting...\r\n");
	while(--argc) {
    if( **++argv == '-')
      options(*argv);
		else {
			if (PreProcessFile(*argv) == -1)
				break;
			if( openfiles(*argv)) {
				lineno = 0;
				initsym();
	compiler.compile();
//				compile();
				summary();
				MBlk::ReleaseAll();
//				ReleaseGlobalMemory();
				closefiles();
			}
    }
    dfs.printf("<CmdNext>Next on command line (%d).</CmdNext>\n", argc);
  }
	//getchar();
	dfs.printf("<Exit></Exit>\n");
	dfs.close();
 	exit(0);
	return (0);
}

int	options(char *s)
{
    int nn;
		int cnt;

		compiler.ipoll = false;
	if (s[1]=='o') {
        for (nn = 2; s[nn]; nn++) {
            switch(s[nn]) {
            case 'r':     opt_noregs = TRUE; break;
						case 'p':     ::opt_nopeep = TRUE; break;
            case 'x':     opt_noexpr = TRUE; break;
						case 'c':	  opt_nocgo = TRUE; break;
						case 's':		opt_size = TRUE; break;
						case 'l':	opt_loop_invariant = FALSE; break;
            }
        }
        if (nn==2) {
            opt_noregs = TRUE;
            ::opt_nopeep = TRUE;
            opt_noexpr = TRUE;
						opt_nocgo = TRUE;
            optimize = FALSE;
						opt_loop_invariant = FALSE;
        }
    }
	else if (s[1]=='f') {
		if (strcmp(&s[2],"no-exceptions")==0)
			exceptions = 0;
		if (strcmp(&s[2],"farcode")==0)
			farcode = 1;
		if (strncmp(&s[2], "poll",4) == 0) {
			compiler.ipoll = true;
			cnt = atoi(&s[6]);
			if (cnt > 0)
				compiler.pollCount = cnt;
		}
		if (strncmp(&s[2], "os_code", 7) == 0) {
			compiler.os_code = true;
		}
	}
	else if (s[1]=='a') {
        address_bits = atoi(&s[2]);
    }
	else if (s[1]=='p') {
        if (strcmp(&s[2],"FISA64")==0) {
             gCpu = FISA64;
             regLR = 31;
             regPC = 29;
             regSP = 30;
             regFP = 27;
             regGP = 26;
             regXLR = 28;
             use_gp = TRUE;
        }
				if (strcmp(&s[2], "riscv") == 0) {
					gCpu = RISCV;
					regLR = 1;
					regSP = 2;
					regFP = 8;
					regGP = 3;
					regZero = 0;
					regFirstArg = 10;
					regLastArg = 17;
					regFirstTemp = 28;
					regLastTemp = 31;
					regFirstRegvar = 18;
					regLastRegvar = 27;
					compiler.nogcskips = true;
					cpu.fileExt = ".r5a";
					cpu.SupportsBand = false;
					cpu.SupportsBor = false;
					cpu.SupportsBBC = false;
					cpu.SupportsBBS = false;
					cpu.SupportsPop = false;
					cpu.SupportsPush = false;
					cpu.SupportsLink = false;
					cpu.SupportsUnlink = false;
					cpu.SupportsBitfield = false;
					cpu.SupportsLDM = false;
					cpu.SupportsSTM = false;
					cpu.SupportsPtrdif = false;
					cpu.SupportsEnter = false;
					cpu.SupportsLeave = false;
					cpu.SupportsIndexed = false;
					cpu.Addsi = true;
					cpu.mov_op = op_mv;
					cpu.lea_op = op_la;
					cpu.ldi_op = op_l;
					cpu.ldbu_op = op_lbu;
					cpu.ldb_op = op_lb;
					cpu.ldo_op = op_ld;
					cpu.ldtu_op = op_lwu;
					cpu.ldt_op = op_lw;
					cpu.ldwu_op = op_lhu;
					cpu.ldw_op = op_lh;
					cpu.stb_op = op_sb;
					cpu.sto_op = op_sd;
					cpu.stt_op = op_sw;
					cpu.stw_op = op_sh;
				}
	}
	else if (s[1]=='w')
		wcharSupport = 0;
	else if (s[1]=='v') {
         if (s[2]=='0')
             verbose = 0;
         else
             verbose = 1;
    }
	else if (s[1] == 'r') {
		if (s[2] == 'v') {
			opt_vreg = TRUE;
			cpu.SetVirtualRegisters();
			nregs = 1024;
		}
		else
		{
			cpu.SetRealRegisters();
		}
	}
    else if (s[1]=='S')
        mixedSource = TRUE;
	return 0;
}

int PreProcessFile(char *nm)
{
	static char outname[1000];
	static char sysbuf[500];

	strcpy_s(outname, sizeof(outname), nm);
	makename(outname,".fpp");
//	snprintf(sysbuf, sizeof(sysbuf), "fpp /d /V -b %s %s", nm, outname);
	snprintf(sysbuf, sizeof(sysbuf), "fpp -b %s %s", nm, outname);
	return system(sysbuf);
}

int openfiles(char *s)
{
	char *p;
	strcpy_s(irfile, sizeof(irfile), s);
	strcpy_s(infile,sizeof(infile),s);
        strcpy_s(listfile,sizeof(listfile),s);
        strcpy_s(outfile,sizeof(outfile),s);
  dbgfile = s;

		//strcpy(outfileG,s);
		_splitpath(s,NULL,NULL,nmspace[0],NULL);
//		strcpy(nmspace[0],basename(s));
		p = strrchr(nmspace[0],'.');
		if (p)
			*p = '\0';
		makename(irfile, ".hir");
		makename(infile,".fpp");
        makename(listfile,".lis");
        makename(outfile,(char *)cpu.fileExt.c_str());
    dbgfile += ".xml";
		ifs = new std::ifstream();
		ifs->open(infile,std::ios::in);
/*
        if( (input = fopen(infile,"r")) == 0) {
				i = errno;
                printf(" cant open %s\n",infile);
                return 0;
                }
*/
/*
        ofl = creat(outfile,-1);
        if( ofl < 0 )
                {
                printf(" cant create %s\n",outfile);
                fclose(input);
                return 0;
                }
*/
        //oflg = _creat(outfileG,-1);
        //if( oflg < 0 )
        //        {
        //        printf(" cant create %s\n",outfileG);
        //        fclose(input);
        //        return 0;
        //        }
		ofs.open(outfile,std::ios::out|std::ios::trunc);
		dfs.open(dbgfile.c_str(),std::ios::out|std::ios::trunc);
//		irfs.open(irfile, std::ios::out | std::ios::trunc);
		irfs.level = 1;
		irfs.puts("CC64 Hex Intermediate File\n");
		dfs.level = 1;
		dfs.puts("<title>CC64 Compiler debug file</title>\n");
		dfs.level = 1;
		lfs.level = 1;
		ofs.level = 1;
/*
        if( (output = fdopen(ofl,"w")) == 0) {
                printf(" cant open %s\n",outfile);
                fclose(input);
                return 0;
                }
*/
        //if( (outputG = _fdopen(oflg,"w")) == 0) {
        //        printf(" cant open %s\n",outfileG);
        //        fclose(input);
        //        fclose(output);
        //        return 0;
        //        }
        try {
			lfs.open(listfile,std::ios::out|std::ios::trunc);
		}
		catch(...) {
			closefiles();
			return 0;
		}
/*
        if( (list = fopen(listfile,"w")) == 0) {
                printf(" cant open %s\n",listfile);
                fclose(input);
                fclose(output);
                //fclose(outputG);
                return 0;
                }
*/
        return 1;
}

void makename(char *s, char *e)
{
	int n;

	n = strlen(s);
	while(s[n]!='.' && n >= 0) n--;
	strcpy(&s[n],e);
	//while(*s != 0 && *s != '.')
 //       ++s;
 //   while(*s++ = *e++);
}

void summary()
{
//    if (verbose > 0)
  dfs.printf("<summary>\n");
    	printf("\n -- %d errors found.\n",total_errors);
    lfs.write("\f\n *** global scope typedef symbol table ***\n\n");
    ListTable(&gsyms[0],0);
    lfs.write("\n *** structures and unions ***\n\n");
    ListTable(&tagtable,0);
  dfs.printf("</summary>\n");
//	fflush(list);
}

void closefiles()
{ 
	dfs.printf("<closefiles>\n");
	ifs->close();
	delete ifs;
//	irfs.flush();
//	irfs.close();
	dfs.printf("A");
	lfs.close();
	dfs.printf("B");
	ofs.close();
	dfs.printf("C");
	dfs.printf("</closefiles>\n");
}

char *GetNamespace()
{
	return nmspace[0];
//	return nmspace[incldepth];
}
