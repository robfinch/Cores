// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2019  Robert Finch, Waterloo
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

void Instruction::SetMap()
{
	int nn;
	Instruction *p;

	for (nn = 0; nn <= op_last; nn++) {
		opmap[nn] = 2;	// op_empty
		if (p = GetMapping(nn)) {
			opmap[nn] = p - &opl[0];
		}
	}
}

// brk and rti ???
bool Instruction::IsFlowControl()
{
	if (opcode == op_jal ||
		opcode == op_jmp ||
		opcode == op_ret ||
		opcode == op_call ||
		opcode == op_bra ||
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
	if (opcode == op_lb
		|| opcode == op_lc
		|| opcode == op_lh
		|| opcode == op_lw
		|| opcode == op_lbu
		|| opcode == op_lcu
		|| opcode == op_lhu
		|| opcode == op_lwr
		|| opcode == op_lf
		|| opcode == op_lfd
		|| opcode == op_lft
		)
		return (true);
	return (false);
}

bool Instruction::IsIntegerLoad()
{
	if (this == nullptr)
		return (false);
	if (opcode == op_lb
		|| opcode == op_lc
		|| opcode == op_lh
		|| opcode == op_lw
		|| opcode == op_lbu
		|| opcode == op_lcu
		|| opcode == op_lhu
		|| opcode == op_lwr
		)
		return (true);
	return (false);
}

bool Instruction::IsStore()
{
	if (this == nullptr)
		return (false);
	if (opcode == op_sb
		|| opcode == op_sc
		|| opcode == op_sh
		|| opcode == op_sw
		|| opcode == op_swc
		|| opcode == op_sf
		|| opcode == op_sfd
		|| opcode == op_sft
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
		|| opcode == op_sxc
		|| opcode == op_sxh
		|| opcode == op_zxb
		|| opcode == op_zxc
		|| opcode == op_zxh
		)
		return (true);
	return (false);
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

