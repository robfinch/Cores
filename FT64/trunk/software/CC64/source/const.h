#ifndef _CONST_H
#define _CONST_H

enum e_node {
        en_void,        /* used for parameter lists */
		en_list, en_aggregate,
		en_cbu, en_ccu, en_chu,
		en_cubu, en_cucu, en_cuhu,
		en_cbw, en_ccw, en_chw,
		en_cubw, en_cucw, en_cuhw,

        en_cbc, en_cbh,
		en_cch,
		en_cwl, en_cld, en_cfd,
        en_icon, en_fcon, en_fqcon, en_dcon, en_tcon, en_labcon, en_nacon, en_autocon, en_autofcon, en_classcon,
		en_clabcon, en_cnacon,
		en_dlabcon, en_dnacon, // 30<-
		
		en_c_ref, en_uc_ref, en_h_ref, en_uh_ref,
        en_b_ref, en_w_ref, en_ub_ref, en_uw_ref,
		en_ref32, en_ref32u,
		en_struct_ref,
        en_fcall, en_ifcall,
         en_tempref, en_regvar, en_fpregvar, en_tempfpref,
		en_add, en_sub, en_mul, en_mod,
		en_ftadd, en_ftsub, en_ftmul, en_ftdiv,
		en_fdadd, en_fdsub, en_fdmul, en_fddiv,
		en_fsadd, en_fssub, en_fsmul, en_fsdiv,
		en_fadd, en_fsub, en_fmul, en_fdiv,
		en_i2d, en_i2t, en_i2q, en_d2i, en_q2i, en_s2q, en_t2i, // 63<-
        en_div, en_asl, en_shl, en_shlu, en_shr, en_shru, en_asr, en_rol, en_ror,
		en_cond, en_assign, 
        en_asadd, en_assub, en_asmul, en_asdiv, en_asdivu, en_asmod, en_asmodu,
		en_asrsh, en_asrshu, en_asmulu, //81
        en_aslsh, en_asand, en_asor, en_asxor, en_uminus, en_not, en_compl,
        en_eq, en_ne, en_lt, en_le, en_gt, en_ge,
        en_feq, en_fne, en_flt, en_fle, en_fgt, en_fge,
        en_veq, en_vne, en_vlt, en_vle, en_vgt, en_vge,
		en_and, en_or, en_land, en_lor, //104
        en_xor, en_ainc, en_adec, en_mulu, en_udiv, en_umod, en_ugt,
        en_uge, en_ule, en_ult,
		en_ref, en_ursh,
		en_uwfieldref,en_wfieldref,en_bfieldref,en_ubfieldref,
		en_uhfieldref,en_hfieldref,en_ucfieldref,en_cfieldref,
		en_dbl_ref, en_flt_ref, en_triple_ref, en_quad_ref,
		en_chk,
		en_abs, en_max, en_min,
		// Vector
		en_autovcon, en_autovmcon, en_vector_ref, en_vex, en_veins,
		en_vadd, en_vsub, en_vmul, en_vdiv,
		en_vadds, en_vsubs, en_vmuls, en_vdivs
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

#endif
