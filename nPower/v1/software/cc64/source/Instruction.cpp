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

static short int opmap[op_last+1];
static CSet* es;

void Instruction::SetMap()
{
	int nn;
	Instruction *p;
	es = CSet::MakeNew();
	char buf[10000];

	for (nn = 0; nn <= op_last; nn++) {
		opmap[nn] = 2;	// op_empty
		if (p = GetMapping(nn)) {
			opmap[nn] = p - &opl[0];
		}
		else {
			es->add(nn);
		}
	}
	es->sprint(buf, sizeof(buf));
	dfs.printf("Instructions not in outcode table.\n");
	dfs.printf(buf);
}

// brk and rti ???
bool Instruction::IsFlowControl()
{
	if (opcode == op_jal ||
		opcode == op_bal ||
		opcode == op_jmp ||
		opcode == cpu.ret_op ||
		opcode == op_rts ||
		opcode == op_call ||
		opcode == op_jsr ||
		opcode == op_jal ||
		opcode == cpu.bra_op ||
		opcode == op_beq ||
		opcode == op_bne ||
		opcode == op_blt ||
		opcode == op_ble ||
		opcode == op_bgt ||
		opcode == op_bge ||
		opcode == op_bltu ||
		opcode == op_bleu ||
		opcode == op_bgtu ||
		opcode == op_bgeu ||
		opcode == op_beqi ||
		opcode == op_bnei ||
		opcode == op_bbs ||
		opcode == op_bbc ||
		opcode == op_bnand ||
		opcode == op_bnor ||
		//opcode == op_ibne ||
		//opcode == op_dbnz ||
		opcode == op_bchk
		)
		return (true);
	return (false);
}

bool Instruction::IsLoad()
{
	if (this == nullptr)
		return (false);
	if (opcode == op_ldb
		|| opcode == op_ldd
		|| opcode == op_ldw
		|| opcode == op_ldt
		|| opcode == op_ldp
		|| opcode == op_ldo
		|| opcode == op_ldh
		|| opcode == op_ldbu
		|| opcode == op_ldwu
		|| opcode == op_ldtu
		|| opcode == op_ldpu
		|| opcode == op_lddr
		|| opcode == op_ldf
		|| opcode == op_ldfd
		|| opcode == op_ldft
		|| opcode == op_fldo
		|| opcode == op_pldo
		)
		return (true);
	return (false);
}

bool Instruction::IsIntegerLoad()
{
	if (this == nullptr)
		return (false);
	if (opcode == op_ldb
		|| opcode == op_ldd
		|| opcode == op_ldw
		|| opcode == op_ldt
		|| opcode == op_ldp
		|| opcode == op_ldh
		|| opcode == op_ldo
		|| opcode == op_ldbu
		|| opcode == op_ldwu
		|| opcode == op_ldtu
		|| opcode == op_ldpu
		|| opcode == op_lddr
		)
		return (true);
	return (false);
}

bool Instruction::IsStore()
{
	if (this == nullptr)
		return (false);
	if (opcode == op_stb
		|| opcode == op_std
		|| opcode == op_stw
		|| opcode == op_sth
		|| opcode == op_stt
		|| opcode == op_stp
		|| opcode == op_sto
		|| opcode == op_sth
		|| opcode == op_stdc
		|| opcode == op_stf
		|| opcode == op_stfd
		|| opcode == op_stft
		|| opcode == op_fsto
		|| opcode == op_psto
		|| opcode == op_push
		)
		return (true);
	return (false);
}

bool Instruction::IsExt()
{
	if (this == nullptr)
		return (false);
	if (opcode == op_sxb
		|| opcode == op_sxw
		|| opcode == op_sxt
		|| opcode == op_extsb
		|| opcode == op_extsh
		|| opcode == op_extsw
		|| opcode == op_zxb
		|| opcode == op_zxw
		|| opcode == op_zxt
		)
		return (true);
	return (false);
}

short Instruction::InvertSet()
{
	switch (opcode) {
	case op_seq:	return(op_sne);
	case op_sne:	return(op_seq);
	case op_slt:	return(op_sge);
	case op_sge:	return(op_slt);
	case op_sle:	return(op_sgt);
	case op_sgt:	return(op_sle);
	case op_sltu:	return(op_sgeu);
	case op_sgeu:	return(op_sltu);
	case op_sleu:	return(op_sgtu);
	case op_sgtu:	return(op_sleu);
	}
	return (opcode);
}

static int fbmcmp(const void *a, const void *b)
{
	Instruction *ib;

	ib = (Instruction *)b;
	return (strcmp((char *)a, ib->mnem));
}

Instruction *Instruction::FindByMnem(std::string& mn)
{
	return ((Instruction *)bsearch(mn.c_str(), &opl[1], sizeof(opl) / sizeof(Instruction) - sizeof(Instruction), sizeof(Instruction), fbmcmp));
}

// It would be slow to get a pointer to the instruction information by
// searching the list. So a map is setup when the compiler initializes.
// Searching for all the opcodes is done only once at compiler startup.

Instruction *Instruction::Get(int op)
{
	// This test really not needed in a properly working compiler.
	// It could be assumed that the ops passed are only valid ones.
	op &= 0x7fff;
	if (op >= op_last || op < 0)
		return (nullptr);	// Should throw an exception here.
	return (&opl[opmap[op]]);
}

// For initializing the mapping table.

Instruction *Instruction::GetMapping(int op)
{
	int i;

	for (i = 0; i < sizeof(opl) / sizeof(Instruction); i++)
		if (opl[i].opcode == op)
			return (&opl[i]);
	return (nullptr);
}

int Instruction::store(txtoStream& ofs)
{
//	if (strnicmp(mnem, ";empty", 6)==0)
//		printf("hi");
	if (mnem[0] == ';') {
		ofs.write("#");
		ofs.write(&mnem[1]);
	}
	else
		ofs.write(mnem);
	return (strlen(mnem));
}

int Instruction::storeHRR(txtoStream& ofs)
{
	ofs.write(mnem);
	return (strlen(mnem));
}

int Instruction::storeHex(txtoStream& ofs)
{
	char buf[20];

	sprintf_s(buf, sizeof(buf), "I%03X", opcode);
	ofs.write(buf);
	return (0);
}

Instruction *Instruction::loadHex(std::ifstream& ifs)
{
	char buf[10];
	int op;

	ifs.read(buf, 3);
	buf[4] = '\0';
	op = atoi(buf);
	return (GetInsn(op));
}

int Instruction::load(std::ifstream& ifs, Instruction **p)
{
	int nn;
	char buf[20];
	std::streampos pos;

	do {
		ifs.read(buf, 1);
	} while (isspace(buf[0]));
	pos = ifs.tellg();
	for (nn = 0; nn < sizeof(buf); nn++) {
		ifs.read(&buf[nn], 1);
		if (isspace(buf[nn]))
			break;
	}
	// If too long, can't be an instruction
	if (nn >= sizeof(buf)) {
		ifs.seekg(pos);
		return (0);
	}
	// Given the mnemonic figure out the opcode
	*p = FindByMnem(std::string(buf));
	return (nn);
}

