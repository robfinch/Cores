#ifndef _CONST_H
#define _CONST_H

enum e_bt {
		bt_none,
		bt_8, bt_8u, bt_16, bt_16u, bt_int32, bt_int32u, bt_40, bt_40u, bt_64, bt_64u, bt_80, bt_80u,
		bt_128, bt_128u,
		bt_byte, bt_ubyte,
        bt_char, bt_short, bt_long, bt_float, bt_double, bt_triple, bt_quad, bt_pointer,
		bt_uchar, bt_ushort, bt_ulong,
        bt_unsigned, bt_vector, bt_vector_mask,
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
		en_vadds, en_vsubs, en_vmuls, en_vdivs,

		en_object_list
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

enum e_am {
        am_reg, am_sreg, am_breg, am_fpreg, am_vreg, am_vmreg, am_ind, am_brind, am_ainc, am_adec, am_indx, am_indx2,
        am_direct, am_jdirect, am_immed, am_mask, am_none, am_indx3, am_predreg
	};

enum e_op {
        op_move, op_add, op_addu, op_addi, op_sub, op_subi, op_mov, op_mtspr, op_mfspr, op_ldi, op_ld,
        op_mul, op_muli, op_mulu, op_divi, op_modi, op_modui, 
        op_div, op_divs, op_divsi, op_divu, op_and, op_andi, op_eor, op_eori,
        op_or, op_ori, op_xor, op_xori, op_redor,
		op_asr, op_asri, op_shl, op_shr, op_shru, op_ror, op_rol,
		op_shli, op_shri, op_shrui, op_shlu, op_shlui, op_rori, op_roli,
		op_bfext, op_bfextu, op_bfins,
		op_jmp, op_jsr, op_mului, op_mod, op_modu,
		op_bmi, op_subu, op_lwr, op_swc, op_loop, op_iret,
		op_sext32,op_sext16,op_sext8, op_sxb, op_sxc, op_sxh, op_zxb, op_zxc, op_zxh,
		op_dw, op_cache,
		op_subui, op_addui, op_sei,
		op_sw, op_sh, op_sc, op_sb, op_outb, op_inb, op_inbu,
		op_sfd, op_lfd,
		op_call, op_jal, op_beqi, op_bnei, op_tst,

		op_beq, op_bne, op_blt, op_ble, op_bgt, op_bge,
		op_bltu, op_bleu, op_bgtu, op_bgeu,
		op_bltui, op_bleui, op_blti, op_blei, op_bgti, op_bgtui, op_bgei, op_bgeui,
		op_bbs, op_bbc, op_bor,

		op_brz, op_brnz, op_br,
		op_lft, op_sft,
		op_lw, op_lh, op_lc, op_lb, op_ret, op_sm, op_lm, op_ldis, op_lws, op_sws,
		op_lvb, op_lvc, op_lvh, op_lvw,
		op_inc, op_dec,
		op_lbu, op_lcu, op_lhu, op_sti,
		op_lf, op_sf,
        op_rts, op_rtd,
		op_push, op_pop, op_movs,
		op_seq, op_sne, op_slt, op_sle, op_sgt, op_sge, op_sltu, op_sleu, op_sgtu, op_sgeu,
		op_bra, op_bf, op_eq, op_ne, op_lt, op_le, op_gt, op_ge,
		op_feq, op_fne, op_flt, op_fle, op_fgt, op_fge,
		op_gtu, op_geu, op_ltu, op_leu, op_nr,
        op_bhi, op_bhs, op_blo, op_bls, op_ext, op_lea, op_swap,
        op_neg, op_not, op_com, op_cmp, op_clr, op_link, op_unlk, op_label,
        op_pea, op_cmpi, op_dc, op_asm, op_stop, op_fnname, 
        // FISA64
        op_lc0i, op_lc1i, op_lc2i, op_lc3i, op_chk, op_chki,
        op_cmpu, op_bsr, op_bun,
        op_sll, op_slli, op_srl, op_srli, op_sra, op_srai, op_asl, op_lsr, op_asli, op_lsri, op_rem,
        // floating point
		op_fbeq, op_fbne, op_fbor, op_fbun, op_fblt, op_fble, op_fbgt, op_fbge,
		op_fcvtsq,
		op_fadd, op_fsub, op_fmul, op_fdiv, op_fcmp, op_fneg,
		op_ftmul, op_ftsub, op_ftdiv, op_ftadd, op_ftneg, op_ftcmp,
		op_fdmul, op_fdsub, op_fddiv, op_fdadd, op_fdneg, op_fdcmp,
		op_fsmul, op_fssub, op_fsdiv, op_fsadd, op_fsneg, op_fscmp,
		op_fs2d, op_i2d, op_i2t, op_ftoi, op_itof, op_qtoi,
		op_fmov,
        op_fdmov, op_fix2flt, op_mtfp, op_mffp, op_flt2fix, op_mv2flt, op_mv2fix,
		// Vector
		op_lv, op_sv,
		op_vadd, op_vsub, op_vmul, op_vdiv,
		op_vadds, op_vsubs, op_vmuls, op_vdivs,
		op_vseq, op_vsne,
		op_vslt, op_vsge, op_vsle, op_vsgt,
		op_vex, op_veins,
		// DSD9
		op_ldd, op_ldb, op_ldp, op_ldw, op_ldbu, op_ldwu, op_ldpu, op_ldt, op_ldtu,
		op_std, op_stb, op_stp, op_stw, op_stt, op_calltgt,
		op_csrrw, op_nop,
		op_hint, op_hint2, op_rem2,
		// FT64
		op_rti, op_rte, op_bex,
		op_addq1, op_addq2, op_addq3,
		op_andq1, op_andq2, op_andq3,
		op_orq1, op_orq2, op_orq3,
		// Built in functions
		op_abs,
		op_phi,
        op_empty };

#endif
