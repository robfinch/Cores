#ifndef _CONST_H
#define _CONST_H

// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C64 - 'C' derived language compiler
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

enum e_sym {
  tk_nop,
        id, cconst, iconst, lconst, sconst, rconst, plus, minus,
        star, divide, lshift, rshift, modop, eq, neq, lt, leq, gt,
        geq, assign, asplus, asminus, astimes, asdivide, asmodop,
		aslshift, asrshift, asand, asor, asxor, autoinc, autodec, hook, cmpl,
        comma, colon, semicolon, double_colon, uparrow, openbr, closebr, begin, end,
        openpa, closepa, pointsto, dot, lor, land, nott, bitorr, bitandd,
		ellipsis,

		kw_int, kw_byte, kw_int8, kw_int16, kw_int32, kw_int40, kw_int64, kw_int80,
		kw_icache, kw_dcache, kw_thread,
        kw_void, kw_char, kw_float, kw_double, kw_triple,
        kw_struct, kw_union, kw_class,
        kw_long, kw_short, kw_unsigned, kw_auto, kw_extern,
        kw_register, kw_typedef, kw_static, kw_goto, kw_return,
        kw_sizeof, kw_break, kw_continue, kw_if, kw_else, kw_elsif,
		kw_for, kw_forever, kw_signed,
		kw_firstcall, kw_asm, kw_fallthru, kw_until, kw_loop,
		kw_try, kw_catch, kw_throw, kw_typenum, kw_const, kw_volatile,
        kw_do, kw_while, kw_switch, kw_case, kw_default, kw_enum,
		kw_interrupt, kw_vortex, kw_pascal, kw_oscall, kw_nocall, kw_naked,
		kw_intoff, kw_inton, kw_then,
		kw_private,kw_public,kw_stop,kw_critical,kw_spinlock,kw_spinunlock,kw_lockfail,
		kw_cdecl, kw_align, kw_prolog, kw_epilog, kw_check, kw_exception, kw_task,
		kw_unordered, kw_inline, kw_kernel, kw_inout, kw_leafs,
    kw_unique, kw_virtual, kw_this,
		kw_new, kw_delete, kw_using, kw_namespace, kw_not, kw_attribute,
		kw_no_temps, kw_no_parms, kw_floatmax, kw_no_regs,
        my_eof };

enum e_sc {
        sc_static, sc_auto, sc_global, sc_thread, sc_external, sc_type, sc_const,
        sc_member, sc_label, sc_ulabel, sc_typedef, sc_register };

enum e_bt {
		bt_none,
		bt_8, bt_8u, bt_16, bt_16u, bt_int32, bt_int32u, bt_40, bt_40u, bt_64, bt_64u, bt_80, bt_80u,
		bt_byte, bt_ubyte,
        bt_char, bt_short, bt_long, bt_float, bt_double, bt_triple, bt_quad, bt_pointer,
		bt_uchar, bt_ushort, bt_ulong,
        bt_unsigned, bt_array,
        bt_struct, bt_union, bt_class, bt_enum, bt_void,
        bt_func, bt_ifunc, bt_label,
		bt_interrupt, bt_oscall, bt_pascal, bt_kernel, bt_bitfield, bt_ubitfield,
		bt_exception, bt_ellipsis,
        bt_last};

enum e_node {
        en_void,        /* used for parameter lists */
		en_list, en_aggregate,
		en_cbu, en_ccu, en_chu,
		en_cubu, en_cucu, en_cuhu,
		en_cbw, en_ccw, en_chw,
		en_cubw, en_cucw, en_cuhw,
		en_lul, en_cuwul, en_cwl, en_cuwl, en_cwul,
		en_clw, en_cluw,

        en_cbc, en_cbh,
		en_cch,
		en_cld, en_cfd,
        en_icon, en_fcon, en_fqcon, en_dcon, en_tcon, en_labcon, en_nacon, en_autocon, en_autofcon, en_classcon,
		en_clabcon, en_cnacon,
		en_dlabcon, en_dnacon, // 30<-
		
		en_c_ref, en_uc_ref, en_h_ref, en_uh_ref,
        en_b_ref, en_w_ref, en_ub_ref, en_uw_ref,
		en_lw_ref, en_ulw_ref,
		en_ref32, en_ref32u,
		en_struct_ref, en_array_ref,
        en_fcall, en_ifcall,
         en_tempref, en_regvar, en_fpregvar, en_tempfpref,
		en_add, en_sub, en_mul, en_mod,
		en_ftadd, en_ftsub, en_ftmul, en_ftdiv,
		en_fdadd, en_fdsub, en_fdmul, en_fddiv,
		en_fsadd, en_fssub, en_fsmul, en_fsdiv,
		en_fadd, en_fsub, en_fmul, en_fdiv,
		en_i2d, en_i2t, en_i2q, en_d2i, en_q2i, en_s2q, en_t2i, // 63<-
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
		en_dbl_ref, en_flt_ref, en_triple_ref, en_quad_ref,
		en_chk, en_mac
		};

enum e_stmt {
		st_empty, st_funcbody,
        st_expr, st_compound, st_while, 
		st_until, st_forever, st_firstcall, st_asm,
		st_dountil, st_doloop,
		st_try, st_catch, st_throw, st_critical, st_spinlock, st_spinunlock,
		st_for,
		st_do, st_if, st_switch, st_default,
        st_case, st_goto, st_break, st_continue, st_label,
        st_return, st_vortex, st_intoff, st_inton, st_stop, st_check };

enum e_pop { pop_always, pop_nop, pop_z, pop_nz, pop_c, pop_nc, pop_mi, pop_pl };

enum e_op {
        op_add, op_addi, op_adc, op_sub, op_sbc, op_subi, op_mov,
		op_ld, op_sto,
        op_and, op_andi,
        op_or, op_ori, op_xor, op_xori,
		op_ror, op_asr, op_lsr,
		op_rori,
		op_jsr,
		op_bmi,
		op_out, op_in,
		op_beq, op_bne, op_blt, op_ble, op_bgt, op_bge,
		op_bltu, op_bleu, op_bgtu, op_bgeu,
		op_inc, op_dec,
        op_rti,
		op_push, op_pop,
        op_not, op_cmp, op_cmpc, op_label, op_ilabel,
        op_cmpi, op_asm,
		op_nop, op_rem,
		op_hint,
		op_preload,
		op_fnname,
		op_dc,
		op_mul, op_div,
		op_mulu, op_divu, op_putpsr,
        op_empty };

enum e_seg {
	op_ns = 0,
	op_ds = 1 << 8,
	op_ts = 2 << 8,
	op_bs = 3 << 8,
	op_rs = 4 << 8,
	op_es = 5 << 8,
	op_seg6 = 6 << 8,
	op_seg7 = 7 << 8,
	op_seg8 = 8 << 8,
	op_seg9 = 9 << 8,
	op_seg10 = 10 << 8,
	op_seg11 = 11 << 8, 
	op_seg12 = 12 << 8,
	op_seg13 = 13 << 8,
	op_ss = 14 << 8,
	op_cs = 15 << 8
};

enum e_sg { noseg, codeseg, dataseg, stackseg, bssseg, idataseg, tlsseg, rodataseg };

enum e_am {
        am_reg, am_sreg, am_breg, am_fpreg, am_ind, am_brind, am_ainc, am_adec, am_indx, am_indx2,
		am_mem_ind, am_mem_indx,
        am_direct, am_jdirect, am_immed, am_mask, am_none, am_indx3, am_predreg
	};

#define F_REG   1       /* register direct mode allowed */
#define F_BREG	2		/* branch register */
#define F_MEM   4       /* memory alterable modes allowed */
#define F_IMMED 8       /* immediate mode allowed */
#define F_ALT   7       /* alterable modes */
#define F_DALT  5       /* data alterable modes */
#define F_VOL   16      /* need volitile operand */
#define F_IMMED18	64	// 18-bit immediate constant
#define F_IMM0	128		/* immediate value 0 */
#define F_IMM8	256
#define F_IMMED13  512
#define F_FPREG 1024
#define F_IMM6  2048
#define BF_ASSIGN	4096
#define F_ALL   (15|1024)      /* all modes allowed */
#define F_NOVALUE 32768		/* dont need result value */

#define DS		0x21
#define BSS		0x23
#define LS		0x29
#define XLS		0x2A
#define SS		0x2E
#define CS		0x2F

#define MAX_STRLEN      120
#define MAX_STLP1       121
#define ERR_SYNTAX      0
#define ERR_ILLCHAR     1
#define ERR_FPCON       2
#define ERR_ILLTYPE     3
#define ERR_UNDEFINED   4
#define ERR_DUPSYM      5
#define ERR_PUNCT       6
#define ERR_IDEXPECT    7
#define ERR_NOINIT      8
#define ERR_INCOMPLETE  9
#define ERR_ILLINIT     10
#define ERR_INITSIZE    11
#define ERR_ILLCLASS    12
#define ERR_BLOCK       13
#define ERR_NOPOINTER   14
#define ERR_NOFUNC      15
#define ERR_NOMEMBER    16
#define ERR_LVALUE      17
#define ERR_DEREF       18
#define ERR_MISMATCH    19
#define ERR_EXPREXPECT  20
#define ERR_WHILEXPECT  21
#define ERR_NOCASE      22
#define ERR_DUPCASE     23
#define ERR_LABEL       24
#define ERR_PREPROC     25
#define ERR_INCLFILE    26
#define ERR_CANTOPEN    27
#define ERR_DEFINE      28
#define ERR_CATCHEXPECT	29
#define ERR_BITFIELD_WIDTH	30
#define ERR_EXPRTOOCOMPLEX	31
#define ERR_ASMTOOLONG	32
#define ERR_TOOMANYCASECONSTANTS	33
#define ERR_CATCHSTRUCT		34
#define ERR_SEMA_INCR	35
#define ERR_SEMA_ADDR	36
#define ERR_UNDEF_OP	37
#define ERR_INT_CONST	38
#define ERR_BAD_SWITCH_EXPR	39
#define ERR_NOT_IN_LOOP	40
#define ERR_CHECK       41
#define ERR_BADARRAYNDX	42
#define ERR_TOOMANYDIMEN	43
#define ERR_OUTOFPREDS  44 
#define ERR_PARMLIST_MISMATCH	45
#define ERR_PRIVATE		46
#define ERR_CALLSIG2	47
#define ERR_METHOD_NOTFOUND	48
#define ERR_OUT_OF_MEMORY   49
#define ERR_TOOMANY_SYMBOLS 50
#define ERR_TOOMANY_PARAMS  51
#define ERR_THIS            52
#define ERR_BADARG			53
#define ERR_CSETABLE		54
#define ERR_UBLTZ			55
#define ERR_UBGEQ			56
#define ERR_INFINITELOOP	57
#define ERR_TOOMANYELEMENTS 58
#define ERR_INTEGER			59
#define ERR_CVTLS			60
#define ERR_NULLPOINTER		1000
#define ERR_CIRCULAR_LIST 1001

/*      alignment sizes         */

#define AL_BYTE			1
#define AL_CHAR         1
#define AL_SHORT        1
#define AL_LONG         2
#define AL_POINTER      1
#define AL_FLOAT        2
#define AL_DOUBLE       4
#define AL_QUAD			8
#define AL_STRUCT       1
#define AL_TRIPLE       6

#define TRUE	1
#define FALSE	0
//#define NULL	((void *)0)

#endif
