// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2016  Robert Finch, Stratford
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

/*      expression tree descriptions    */

enum e_node {
        en_void,        /* used for parameter lists */

		en_cbu, en_ccu, en_chu,
		en_cubu, en_cucu, en_cuhu,
		en_cbw, en_ccw, en_chw,
		en_cubw, en_cucw, en_cuhw,

        en_cbc, en_cbh,
		en_cch,
		en_cwl, en_cld, en_cfd,
        en_icon, en_fcon, en_dcon, en_tcon, en_labcon, en_nacon, en_autocon, en_autofcon, en_classcon,
		en_clabcon, en_cnacon,
		en_dlabcon, en_dnacon, // 30<-
		
		en_c_ref, en_uc_ref, en_h_ref, en_uh_ref,
        en_b_ref, en_w_ref, en_ub_ref, en_uw_ref,
		en_struct_ref,
        en_fcall, en_ifcall,
         en_tempref, en_regvar, en_bregvar, en_fpregvar, en_tempfpref,
		en_add, en_sub, en_mul, en_mod,
		en_ftadd, en_ftsub, en_ftmul, en_ftdiv,
		en_fdadd, en_fdsub, en_fdmul, en_fddiv,
		en_fsadd, en_fssub, en_fsmul, en_fsdiv,
		en_i2d, en_i2t, en_d2i,// 63<-
        en_div, en_shl, en_shlu, en_shr, en_shru, en_asr, en_cond, en_assign, 
        en_asadd, en_assub, en_asmul, en_asdiv, en_asdivu, en_asmod, en_asmodu,
		en_asrsh, en_asrshu, en_asmulu, //81
        en_aslsh, en_asand, en_asor, en_asxor, en_uminus, en_not, en_compl,
        en_eq, en_ne, en_lt, en_le, en_gt, en_ge,
        en_feq, en_fne, en_flt, en_fle, en_fgt, en_fge,
		en_and, en_or, en_land, en_lor, //104
        en_xor, en_ainc, en_adec, en_mulu, en_udiv, en_umod, en_ugt,
        en_uge, en_ule, en_ult,
		en_ref, en_ursh,
		en_uwfieldref,en_wfieldref,en_bfieldref,en_ubfieldref,
		en_uhfieldref,en_hfieldref,en_ucfieldref,en_cfieldref,
		en_dbl_ref, en_flt_ref, en_triple_ref,
		en_chk
		};

class ENODE {
public:
    enum e_node nodetype;
	enum e_bt etype;
	long      esize;
    TYP *tp;
    SYM *sym;
    __int8 constflag;
    unsigned int predreg : 4;
	unsigned int isVolatile : 1;
	unsigned int isIO : 1;
	unsigned int isUnsigned : 1;
	unsigned int isDouble : 1;
	unsigned int isCheckExpr : 1;
	unsigned int isPascal : 1;
	__int8 bit_width;
	__int8 bit_offset;
	__int8 scale;
	// The following could be in a value union
  __int64 i;
  double f;
  double f1, f2;
  std::string *sp;
  std::string *msp;
	std::string *udnm;			// undecorated name
	void *ctor;
	void *dtor;
  ENODE *p[3];
  void SetType(TYP *t) { tp = t; };
};

//typedef struct enode ENODE;

typedef struct cse {
        struct cse      *next;
        ENODE *exp;           /* optimizable expression */
        int             uses;           /* number of uses */
        int             duses;          /* number of dereferenced uses */
        short int       voidf;          /* cannot optimize flag */
        short int       reg;            /* AllocateRegisterVarsd register */
        unsigned int    isfp : 1;
        } CSE;

#define TRACE(x)

