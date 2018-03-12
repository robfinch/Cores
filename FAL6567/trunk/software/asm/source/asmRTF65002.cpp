/* ===============================================================
	(C) 2003 Bird Computer
	All rights reserved.

	asmW65C816S.cpp

		Please read the Licensing Agreement included in
	license.html. Use of this file is subject to the
	license agreement.

	You are free to use and modify this code for non-commercial
	or evaluation purposes.
	
	If you do modify the code, please state the origin and
	note that you have modified the code.
	
		Handles 6502 opcodes

=============================================================== */

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include "Assembler.h"
#include "operands65002.h"
#include "asmRTF65002.h"

namespace RTFClasses
{
}

namespace RTFClasses
{
	void AsmRTF65002::emitSz()
	{
		int ch = theAssembler.gSzChar;

		if (ch != 'W') {
			if (ch == ('U' << 8) + 'B')
				theAssembler.emit8(0xA7);
			else if (ch== ('U'<<8) + 'C' || ch==('U'<<8) + 'H')
				theAssembler.emit8(0xB7);
			else if (ch=='B')
				theAssembler.emit8(0x87);
			else if (ch=='C' || ch=='H')
				theAssembler.emit8(0x97);
		}
	}

	void AsmRTF65002::mvn(Opa *o)
	{
		emitSz();
		theAssembler.emit8(o->oc & 0xff);
	}

	void AsmRTF65002::sxb(Opa *o)
	{
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		theAssembler.emit16((o->oc & 0xffff)|(Rt<<8));
	}

	void AsmRTF65002::pop(Opa *o)
	{
		int Ra = 0;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rb = 0;

		if (Rt==4)
			theAssembler.emit8(0x2f);
		else {
			theAssembler.emit8(o->oc & 0xff);
			theAssembler.emit8((Rt<<4)|Ra);
		}
	}

	void AsmRTF65002::push(Opa *o)
	{
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rt = 0;
		int Rb = 0;

		if (Ra==4)
			theAssembler.emit8(0x0F);
		else {
			theAssembler.emit8(o->oc & 0xff);
			theAssembler.emit8((Rb<<4)|Ra);
		}
	}

	void AsmRTF65002::r(Opa *o)
	{
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		theAssembler.emit8(o->oc & 0xff);
		theAssembler.emit8((Rt<<4)|Ra);
	}

	void AsmRTF65002::cmp_rr(Opa *o)
	{
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[1].r1;

		theAssembler.emit8(o->oc & 0xff);
		theAssembler.emit8((Rb<<4)|Ra);
	}

	void AsmRTF65002::rn(Opa *o)
	{
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[2].r1;

		theAssembler.emit8(o->oc & 0xff);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(((o->oc>>8)) | Rt);
	}

	void AsmRTF65002::rn2(Opa *o)
	{
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		theAssembler.emit8(o->oc & 0xff);
		theAssembler.emit8(((o->oc>>8)) |(Rt<<4)|Ra);
	}

	void AsmRTF65002::rn1(Opa *o)
	{
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		theAssembler.emit8(o->oc & 0xff);
		theAssembler.emit8((o->oc >> 8)|(Rt<<4)|Ra);
	}

	// Accumulator implied register direct addressing
	//
	void AsmRTF65002::acc_rn(Opa *o)
	{
		int Ra = 1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rt = 1;

		theAssembler.emit8(o->oc & 0xff);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(((o->oc>>8)& 0xf0) | Rt);
	}

	void AsmRTF65002::rnbit(Opa *o)
	{
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rt = 0;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[1].r1;

		theAssembler.emit8(o->oc & 0xff);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(((o->oc>>8)& 0xf0) | Rt);
	}

	void AsmRTF65002::imm4(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		theAssembler.emit8(op);
		theAssembler.emit8(((data & 0xf)<<4)|Ra);
	}

	void AsmRTF65002::imm8(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[2].val.value;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		theAssembler.emit8(op);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit8(data);
	}

	void AsmRTF65002::mul_imm8(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[2].val.value;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		theAssembler.emit16(op);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit8(data);
	}
	void AsmRTF65002::acc_imm8(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		int Ra = 1;
		int Rt = 1;

		theAssembler.emit8(op);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit8(data);
	}

	void AsmRTF65002::bit_acc_imm8(Opa *o)
	{
		int op = o->oc;
		int data;
		int Ra = 1;
		int Rt = 0;

		try {
		data = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		theAssembler.emit8(op);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit8(data);
		}
		catch (...) {
			printf("exception bit_acc_imm8\r\n");
		}
	}

	void AsmRTF65002::imm8bit(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		theAssembler.emit8(op);
		theAssembler.emit8(Ra);
		theAssembler.emit8(data);
	}

	void AsmRTF65002::imm8ld(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;
		int Ra = 0;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		theAssembler.emit8(op);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit8(data);
	}

	void AsmRTF65002::imm8lda(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		int Ra = 0;
		int Rt = 1;

		theAssembler.emit8(op);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit8(data);
	}

	void AsmRTF65002::imm16(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[2].val.value;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		theAssembler.emit8(op);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit16(data);
	}

	void AsmRTF65002::mul_imm16(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[2].val.value;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		theAssembler.emit16(op);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit16(data);
	}
	void AsmRTF65002::imm16bit(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		theAssembler.emit8(op);
		theAssembler.emit8(Ra);
		theAssembler.emit16(data);
	}

	void AsmRTF65002::imm16ld(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;
		int Ra = 0;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		theAssembler.emit8(op);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit16(data);
	}

	void AsmRTF65002::imm16lda(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		int Ra = 0;
		int Rt = 1;

		theAssembler.emit8(op);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit16(data);
	}

	void AsmRTF65002::acc_imm16(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		int Ra = 1;
		int Rt = 1;

		theAssembler.emit8(op);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit16(data);
	}

	void AsmRTF65002::bit_acc_imm16(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		int Ra = 1;
		int Rt = 0;

		theAssembler.emit8(op);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit16(data);
	}

	void AsmRTF65002::imm32(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[2].val.value;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		theAssembler.emit8(op);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit32(data);
	}

	void AsmRTF65002::mul_imm32(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[2].val.value;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		theAssembler.emit16(op);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit32(data);
	}

	void AsmRTF65002::imm32bit(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		theAssembler.emit8(op);
		theAssembler.emit8(Ra);
		theAssembler.emit32(data);
	}

	void AsmRTF65002::imm32ld(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;
		int Ra = 0;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		theAssembler.emit8(op);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit32(data);
	}

	void AsmRTF65002::imm32lda(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		int Ra = 0;
		int Rt = 1;

		theAssembler.emit8(op);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit32(data);
	}

	void AsmRTF65002::Ximm32(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;

		theAssembler.emit8(op);
		theAssembler.emit32(data);
	}

	void AsmRTF65002::Ximm16(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;

		theAssembler.emit8(op);
		theAssembler.emit16(data);
	}

	void AsmRTF65002::Ximm8(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;

		theAssembler.emit8(op);
		theAssembler.emit8(data);
	}

	void AsmRTF65002::sub_sp_imm32(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;

		theAssembler.emit8(op);
		theAssembler.emit32(data);
	}

	void AsmRTF65002::sub_sp_imm16(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;

		theAssembler.emit8(op);
		theAssembler.emit16(data);
	}

	void AsmRTF65002::sub_sp_imm8(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;

		theAssembler.emit8(op);
		theAssembler.emit8(data);
	}

	void AsmRTF65002::acc_imm32(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		int Ra = 1;
		int Rt = 1;

		theAssembler.emit8(op);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit32(data);
	}

	void AsmRTF65002::bit_acc_imm32(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		int Ra = 1;
		int Rt = 0;

		theAssembler.emit8(op);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit32(data);
	}

	void AsmRTF65002::zp(Opa *op)
	{
		Operand o;
		__int32 d;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[2].r1;
		d = ((Operands65002 *)getCpu()->getOp())->op[2].val.value;
		emitSz();
		theAssembler.emit8(op->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit16(((d<<4)&0xfff0)|Rt);
	}


	void AsmRTF65002::zp2(Opa *op)
	{
		Operand o;
		__int32 d;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(op->oc);
		theAssembler.emit16(((d<<4)&0xfff0)|Ra);
	}

	void AsmRTF65002::bms_zp(Opa *op)
	{
		Operand o;
		__int32 d;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit16(op->oc);
		theAssembler.emit16(((d<<4)&0xfff0)|Ra);
	}

	void AsmRTF65002::zpld(Opa *op)
	{
		Operand o;
		__int32 d;
		int Ra = 0;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		d = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;
		emitSz();
		if (op->oc & 0xff00)
			theAssembler.emit16(op->oc);
		else
			theAssembler.emit8(op->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit16(((d<<4)&0xfff0)|Rt);
	}

	void AsmRTF65002::lb_zp(Opa *op)
	{
		Operand o;
		__int32 d;
		int Ra = 0;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		d = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;
		emitSz();
		theAssembler.emit8(op->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit16(((d<<4)&0xfff0)|Rt);
	}

	void AsmRTF65002::orb_zp(Opa *op)
	{
		Operand o;
		__int32 d;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rb = 0;
		d = ((Operands65002 *)getCpu()->getOp())->op[2].val.value;
		emitSz();
		theAssembler.emit8(op->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit16(((d<<4)&0xfff0)|Rt);
	}

	void AsmRTF65002::orb_zpx(Opa *op)
	{
		Operand o;
		__int32 d;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[2].r1;
		d = ((Operands65002 *)getCpu()->getOp())->op[2].val.value;
		emitSz();
		theAssembler.emit8(op->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit16(((d<<4)&0xfff0)|Rt);
	}

	void AsmRTF65002::zplda(Opa *op)
	{
		Operand o;
		__int32 d;
		int Ra = 0;
		int Rt = 1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(op->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit16(((d<<4)&0xfff0)|Rt);
	}

	void AsmRTF65002::zpsta(Opa *op)
	{
		Operand o;
		__int32 d;
		int Ra = 1;
		int Rt = 0;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(op->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit16(((d<<4)&0xfff0)|Rt);
	}

	void AsmRTF65002::zpbit(Opa *op)
	{
		Operand o;
		__int32 d;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		int Rt = 0;
		d = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;
		emitSz();
		theAssembler.emit8(op->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit16(((d<<4)&0xfff0)|Rt);
	}

	void AsmRTF65002::bit_acc_zpx(Opa *op)
	{
		Operand o;
		__int32 d;
		int Ra = 1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rt = 0;
		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(op->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit16(((d<<4)&0xfff0)|Rt);
	}

	void AsmRTF65002::sb_zp(Opa *op)
	{
		Operand o;
		__int32 d;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		d = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;
		emitSz();
		theAssembler.emit8(op->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit16((d<<4));
	}

	void AsmRTF65002::acc_zp(Opa *op)
	{
		Operand o;
		__int32 d;
		int Ra = 1;
		int Rt = 1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(op->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit16(((d<<4)&0xfff0)|Rt);
	}

	void AsmRTF65002::stz_zp(Opa *op)
	{
		Operand o;
		__int32 d;
		int Ra = 0;
		int Rt = 0;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(op->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit16(((d<<4)&0xfff0)|Rt);
	}

	void AsmRTF65002::abs(Opa *o)
	{
		unsigned __int64 d;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		d = ((Operands65002 *)getCpu()->getOp())->op[2].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::acc_abs(Opa *o)
	{
		unsigned __int64 d;
		int Ra = 1;
		int Rt = 1;

		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::bit_acc_abs(Opa *o)
	{
		unsigned __int64 d;
		int Ra = 1;
		int Rt = 0;

		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::bit_acc_absx(Opa *o)
	{
		unsigned __int64 d;
		int Ra = 1;
		int Rb;
		int Rt = 0;

		Rb = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(Rt);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::absbit(Opa *o)
	{
		unsigned __int64 d;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rt = 0;

		d = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::abssb(Opa *o)
	{
		unsigned __int64 d;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rt = 0;

		d = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::absld(Opa *o)
	{
		unsigned __int64 d;
		int Ra = 0;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		d = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;
		emitSz();
		if (o->oc & 0xff00)
			theAssembler.emit16(o->oc);
		else
			theAssembler.emit8(o->oc);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::absldb(Opa *o)
	{
		unsigned __int64 d;
		int Ra = 0;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		d = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::abslda(Opa *o)
	{
		unsigned __int64 d;
		int Ra = 0;
		int Rt = 1;

		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::abssta(Opa *o)
	{
		unsigned __int64 d;
		int Ra = 1;
		int Rt = 0;

		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::abs2(Opa *o)
	{
		U64 d;
		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::bms_abs(Opa *o)
	{
		U64 d;
		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit16(o->oc);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::orb_abs(Opa *o)
	{
		U64 d;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		d = ((Operands65002 *)getCpu()->getOp())->op[2].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::stz_abs(Opa *o)
	{
		U64 d;
		int Ra = 0;
		int Rt = 0;

		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::jmp_abs(Opa *o)
	{
		U64 d;
		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit16(d & 0xffff);
	}

	void AsmRTF65002::jml_abs(Opa *o)
	{
		U64 d;
		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		theAssembler.emit8(o->oc);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::absx(Opa *o)
	{
		U64 d;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[2].r1;

		d = ((Operands65002 *)getCpu()->getOp())->op[2].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(Rt);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::acc_absx(Opa *o)
	{
		U64 d;
		int Ra = 1;
		int Rt = 1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(Rt);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::bit_absx(Opa *o)
	{
		U64 d;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rt = 0;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[1].r1;

		d = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(Rt);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::sb_absx(Opa *o)
	{
		U64 d;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rt = 0;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[1].r1;

		d = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(Rt);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::absxld(Opa *o)
	{
		U64 d;
		int Ra = 0;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[1].r1;

		d = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;
		emitSz();
		if (o->oc & 0xff00)
			theAssembler.emit16(o->oc);
		else
			theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(Rt);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::absxldb(Opa *o)
	{
		U64 d;
		int Ra = 0;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[1].r1;

		d = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(Rt);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::absxlda(Opa *o)
	{
		U64 d;
		int Ra = 0;
		int Rt = 1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(Rt);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::absxsta(Opa *o)
	{
		U64 d;
		int Ra = 1;
		int Rt = 0;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(Rt);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::absx2(Opa *o)
	{
		U64 d;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Ra<<4)|Ra);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::bms_absx(Opa *o)
	{
		U64 d;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit16(o->oc);
		theAssembler.emit8((Ra<<4)|Ra);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::orb_absx(Opa *o)
	{
		U64 d;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[2].r1;

		d = ((Operands65002 *)getCpu()->getOp())->op[2].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(Rt);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::ldx_absx(Opa *o)
	{
		U64 d;
		int Ra = 0;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::ldx_abs(Opa *o)
	{
		U64 d;

		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::stx_absx(Opa *o)
	{
		U64 d;
		int Ra = 2;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(0);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::sty_absx(Opa *o)
	{
		U64 d;
		int Ra = 3;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(0);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::stz_absx(Opa *o)
	{
		U64 d;
		int Ra = 0;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(0);
		theAssembler.emit32(d);
	}

	void AsmRTF65002::rind(Opa *o)
	{
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[2].r1;

		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(Rt);
	}

	void AsmRTF65002::acc_rind(Opa *o)
	{
		int Ra = 1;
		int Rt = 1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(Rt);
	}

	void AsmRTF65002::rindbit(Opa *o)
	{
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rt = 0;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[1].r1;

		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(Rt);
	}

	void AsmRTF65002::rindld(Opa *o)
	{
		int Ra = 0;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[1].r1;

		emitSz();
		if (o->oc & 0xff00)
			theAssembler.emit16(o->oc);
		else
			theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(Rt);
	}

	void AsmRTF65002::rindlda(Opa *o)
	{
		int Ra = 0;
		int Rt = 1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(Rt);
	}
	void AsmRTF65002::rindldx(Opa *o)
	{
		int Ra = 0;
		int Rt = 2;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(Rt);
	}

	void AsmRTF65002::ldy_rind(Opa *o)
	{
		int Ra = 0;
		int Rt = 3;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
		theAssembler.emit8(Rt);
	}

	void AsmRTF65002::st_rind(Opa *o)
	{
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rt = 0;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[1].r1;

		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
	}

	void AsmRTF65002::stx_rind(Opa *o)
	{
		int Ra = 2;
		int Rt = 0;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
	}

	void AsmRTF65002::sty_rind(Opa *o)
	{
		int Ra = 3;
		int Rt = 0;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
	}

	void AsmRTF65002::sta_rind(Opa *o)
	{
		int Ra = 1;
		int Rt = 0;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
	}

	void AsmRTF65002::stz_rind(Opa *o)
	{
		int Ra = 0;
		int Rt = 0;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
	}

	void AsmRTF65002::rind_jmp(Opa *o)
	{
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;

		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8(Ra);
	}

	void AsmRTF65002::trs(Opa *o)
	{
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rb = ((Operands65002 *)getCpu()->getOp())->op[1].r1;

		emitSz();
		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rb<<4)|Ra);
	}

	void AsmRTF65002::tsr_imm(Opa *o)
	{
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		int data = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;

		theAssembler.emit8(o->oc);
		theAssembler.emit8((Rt<<4)|(data&0xf));
	}
	
	void AsmRTF65002::dsp(Opa *op)
	{
		Operand o;
		__int32 d;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[1].r1;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		d = ((Operands65002 *)getCpu()->getOp())->op[2].val.value;
		emitSz();
		theAssembler.emit8(op->oc);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit8(d&0xff);
	}
	void AsmRTF65002::acc_dsp(Opa *op)
	{
		Operand o;
		__int32 d;
		int Ra = 1;
		int Rt = 1;
		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(op->oc);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit8(d&0xff);
	}
	void AsmRTF65002::ld_dsp(Opa *op)
	{
		Operand o;
		__int32 d;
		int Ra = 0;
		int Rt = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		d = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;
		emitSz();
		if (op->oc & 0xff00)
			theAssembler.emit16(op->oc);
		else
			theAssembler.emit8(op->oc);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit8(d&0xff);
	}
	void AsmRTF65002::ld_acc_dsp(Opa *op)
	{
		Operand o;
		__int32 d;
		int Ra = 0;
		int Rt = 1;
		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		if (op->oc & 0xff00)
			theAssembler.emit16(op->oc);
		else
			theAssembler.emit8(op->oc);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit8(d&0xff);
	}
	void AsmRTF65002::st_dsp(Opa *op)
	{
		Operand o;
		__int32 d;
		int Ra = ((Operands65002 *)getCpu()->getOp())->op[0].r1;
		int Rt = 0;
		d = ((Operands65002 *)getCpu()->getOp())->op[1].val.value;
		emitSz();
		theAssembler.emit8(op->oc);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit8(d&0xff);
	}
	void AsmRTF65002::st_acc_dsp(Opa *op)
	{
		Operand o;
		__int32 d;
		int Ra = 1;
		int Rt = 0;
		d = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;
		emitSz();
		theAssembler.emit8(op->oc);
		theAssembler.emit8((Rt<<4)|Ra);
		theAssembler.emit8(d&0xff);
	}


/* ---------------------------------------------------------------
	Description:
		beq/bne/bpl/bmi/bcc/bcs/bvc/bvs/bra
--------------------------------------------------------------- */

void AsmRTF65002::br(Opa *o)
{
	__int64 loc;

    theAssembler.emit8(o->oc);
	loc = ((Operands65002 *)getCpu()->getOp())->op[0].val.value; //expeval(theAssembler.gOperand[0], NULL);
	// it's possible the symbol could have been defined
	// if it was a backwards reference
	if (theAssembler.getPass() > 1)// || val.bDefined)
	{
    	loc -= (theAssembler.getProgramCounter().val) + 1;
		if (loc > 127 || loc < -128)
	    {
			loc -= 2;
			if (loc >= -32768 && loc < 32768) {
				theAssembler.emit8(0xFF);		// long branch postfix
				theAssembler.emit8(loc & 0xff);
				loc >>= 8;
			}
			else {
				printf("Program counter: %I32x loc: %I64x op:%s\r\n", theAssembler.getProgramCounter().val,
					((Operands65002 *)getCpu()->getOp())->op[0].val.value,
					((Operands65002 *)getCpu()->getOp())->op[0].buf()
					);
				Err(E_BRANCH, loc);     // Branch out of range.
				loc = 0xff;
			}
	    }
    	theAssembler.emit8(loc & 0xff);
	}
	else
	{
		// branch displacment unknown
		theAssembler.emit8(0x01);		// long branch postfix
    	theAssembler.emit16(0xffff);
	}
}


	void AsmRTF65002::brl(Opa *o)
	{
		long loc;

		theAssembler.emit8(o->oc);
		loc = ((Operands65002 *)getCpu()->getOp())->op[0].val.value; //expeval(theAssembler.gOperand[0], NULL);
		// it's possible the symbol could have been defined
		// if it was a backwards reference
		if (theAssembler.getPass() > 1)// || val.bDefined)
		{
    		loc -= (theAssembler.getProgramCounter().val) + 2;
			if (loc > 32767 || loc < -32768)
			{
				Err(E_BRANCH, loc);     // Branch out of range.
				loc = 0xffffffff;
			}
    		theAssembler.emit16(loc & 0xffff);
		}
		else
		{
			// branch displacment unknown
    		theAssembler.emit16(0xffff);
		}
	}

	void AsmRTF65002::int_(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands65002 *)getCpu()->getOp())->op[0].val.value;

		theAssembler.emit8(op|((data & 0x100)>>8));
		theAssembler.emit8(data);
	}

}
