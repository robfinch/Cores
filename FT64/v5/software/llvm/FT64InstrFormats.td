//===-- FT64InstrFormats.td - FT64 Instruction Formats ---*- tablegen -*-===//
// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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
// Format specifies the encoding used by the instruction. This is used by
// FT64MCCodeEmitter to determine which form of fixup to use. These
// definitions must be kept in-sync with FT64BaseInfo.h.

class InstFormat<bits<5> val> {
  bits<5> Value = val;
}
def InstFormatRI14		: InstFormat<0>;
def InstFormatRI10		: InstFormat<1>;
def InstFormatR2		: InstFormat<2>;
def InstFormatR1		: InstFormat<3>;
def InstFormatSR		: InstFormat<4>;
def InstFormatSI		: InstFormat<5>;
def InstFormatBF		: InstFormat<6>;
def InstFormatBD		: InstFormat<7>;
def InstFormatBB		: InstFormat<8>;
def InstFormatBR		: InstFormat<9>;
def InstFormatBE		: InstFormat<10>;
def InstFormatMX		: InstFormat<11>;
def InstFormatCSR		: InstFormat<12>;
def InstFormatFLT		: InstFormat<13>;
def InstFormatJC24		: InstFormat<14>;
def InstFormatOther		: InstFormat<15>;
def InstFormatPseudo	: InstFormat<16>;
def InstFormatR3		: InstFormat<17>;
def InstFormatRI30		: InstFormat<18>;
def InstFormatLUI19		: InstFormat<19>;
def InstFormatLUI35		: InstFormat<20>;
def InstFormatJC40		: InstFormat<21>;

class FT64Opcode<bits<6> val> {
  bits<6> Value = val;
}
def OPC_BRK			: FT64Opcode<0x00>;
def OPC_R2			: FT64Opcode<0x02>;
def OPC_AUIPC		: FT64Opcode<0x03>;
def OPC_ADDI		: FT64Opcode<0x04>;
def OPC_CMPI		: FT64Opcode<0x06>;
def OPC_CMPUI		: FT64Opcode<0x07>;
def OPC_ANDI		: FT64Opcode<0x08>;
def OPC_ORI			: FT64Opcode<0x09>;
def OPC_XORI		: FT64Opcode<0x0A>;
def OPC_REX			: FT64Opcode<0x0D>;
def OPC_CSR			: FT64Opcode<0x0E>;
def OPC_FLT			: FT64Opcode<0x0F>;

def OPC_LH			: FT64Opcode<0x10>;
def OPC_LHU			: FT64Opcode<0x11>;
def OPC_LW			: FT64Opcode<0x12>;
def OPC_LB			: FT64Opcode<0x13>;
def OPC_SH			: FT64Opcode<0x14>;
def OPC_SB			: FT64Opcode<0x15>;
def OPC_SW			: FT64Opcode<0x16>;
def OPC_SWC			: FT64Opcode<0x17>;
def OPC_JAL			: FT64Opcode<0x18>;
def OPC_CALL		: FT64Opcode<0x19>;
def OPC_INC			: FT64Opcode<0x1A>;
def OPC_Scc			: FT64Opcode<0x1B>;
def OPC_NOP			: FT64Opcode<0x1C>;
def OPC_LWR			: FT64Opcode<0x1D>;
def OPC_CACHE		: FT64Opcode<0x1E>;
def OPC_EXEC		: FT64Opcode<0x1F>;

def OPC_LC			: FT64Opcode<0x20>;
def OPC_LCU			: FT64Opcode<0x21>;
def OPC_BITFLD		: FT64Opcode<0x22>;
def OPC_LBU			: FT64Opcode<0x23>;
def OPC_SC			: FT64Opcode<0x24>;
def OPC_CAS			: FT64Opcode<0x25>;
def OPC_BBc			: FT64Opcode<0x26>;
def OPC_LUI			: FT64Opcode<0x27>;
def OPC_JMP			: FT64Opcode<0x28>;
def OPC_RET			: FT64Opcode<0x29>;
def OPC_LT			: FT64Opcode<0x2A>;
def OPC_ST			: FT64Opcode<0x2B>;
def OPC_MODI		: FT64Opcode<0x2E>;

def OPC_Bcc			: FT64Opcode<0x30>;
def OPC_BEQI		: FT64Opcode<0x32>;
def OPC_CHK			: FT64Opcode<0x34>;
def OPC_SPTR		: FT64Opcode<0x35>;
def OPC_MULUI		: FT64Opcode<0x38>;
def OPC_MULI		: FT64Opcode<0x3A>;
def OPC_LVx			: FT64Opcode<0x3B>;
def OPC_DIVUI		: FT64Opcode<0x3C>;
def OPC_DIVI		: FT64Opcode<0x3E>;

// 16-bit compressed instructions

class FTInst16<dag outs, dag ins, string opcodestr, string argstr,
             list<dag> pattern, InstFormat format>
    : Instruction {
  field bits<16> Inst;
  // SoftFail is a field the disassembler can use to provide a way for
  // instructions to not match without killing the whole decode process. It is
  // mainly used for ARM, but Tablegen expects this field to exist or it fails
  // to build the decode table.
  field bits<16> SoftFail = 0;
  let Size = 2;

  let Inst{7} = 1;

  let Namespace = "FT64";

  dag OutOperandList = outs;
  dag InOperandList = ins;
  let AsmString = opcodestr # "\t" # argstr;
  let Pattern = pattern;

  let TSFlags{4-0} = format.Value;
}

class FTInst32<dag outs, dag ins, string opcodestr, string argstr,
             list<dag> pattern, InstFormat format>
    : Instruction {
  field bits<32> Inst;
  // SoftFail is a field the disassembler can use to provide a way for
  // instructions to not match without killing the whole decode process. It is
  // mainly used for ARM, but Tablegen expects this field to exist or it fails
  // to build the decode table.
  field bits<32> SoftFail = 0;
  let Size = 4;

  bits<6> Opcode = 0;

  let Inst{5-0} = Opcode;
  let Inst{7-6} = 0;

  let Namespace = "FT64";

  dag OutOperandList = outs;
  dag InOperandList = ins;
  let AsmString = opcodestr # "\t" # argstr;
  let Pattern = pattern;

  let TSFlags{4-0} = format.Value;
}

class FTInst48<dag outs, dag ins, string opcodestr, string argstr,
             list<dag> pattern, InstFormat format>
    : Instruction {
  field bits<48> Inst;
  // SoftFail is a field the disassembler can use to provide a way for
  // instructions to not match without killing the whole decode process. It is
  // mainly used for ARM, but Tablegen expects this field to exist or it fails
  // to build the decode table.
  field bits<48> SoftFail = 0;
  let Size = 4;

  bits<6> Opcode = 0;

  let Inst{5-0} = Opcode;
  let Inst{7-6} = 1;

  let Namespace = "FT64";

  dag OutOperandList = outs;
  dag InOperandList = ins;
  let AsmString = opcodestr # "\t" # argstr;
  let Pattern = pattern;

  let TSFlags{4-0} = format.Value;
}

// Pseudo instructions
class Pseudo<dag outs, dag ins, list<dag> pattern, string opcodestr = "", string argstr = "">
    : FTInst<outs, ins, opcodestr, argstr, pattern, InstFormatPseudo> {
  let isPseudo = 1;
  let isCodeGenOnly = 1;
}

class FTInstLUI19<FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst32<outs, ins, opcodestr, argstr, [], InstFormatLUI19> {
  bits<19> imm19;
  bits<5> Rt;

  let Inst{31-13} = imm19;
  let Inst{12-8} = Rt;
  let Opcode = opcode.Value;
}

class FTInstLUI35<FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst48<outs, ins, opcodestr, argstr, [], InstFormatLUI35> {
  bits<35> imm35;
  bits<5> Rt;

  let Inst{47-13} = imm35;
  let Inst{12-8} = Rt;
  let Opcode = opcode.Value;
}

class FTInstRI14<FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst32<outs, ins, opcodestr, argstr, [], InstFormatRI14> {
  bits<14> imm;
  bits<5> Ra;
  bits<5> Rt;

  let Inst{31-18} = imm;
  let Inst{17-13} = Rt;
  let Inst{12-8} = Ra;
  let Opcode = opcode.Value;
}

class FTInstRI30<FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst48<outs, ins, opcodestr, argstr, [], InstFormatRI30> {
  bits<30> imm;
  bits<5> Ra;
  bits<5> Rt;

  let Inst{47-18} = imm;
  let Inst{17-13} = Rt;
  let Inst{12-8} = Ra;
  let Opcode = opcode.Value;
}

class FTInstRI10< bits<4> cond4, FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst32<outs, ins, opcodestr, argstr, [], InstFormatRI10> {
  bits<10> imm;
  bits<5> Ra;
  bits<5> Rt;

  let Inst{31-28} = cond4;
  let Inst{27-18} = imm;
  let Inst{17-13} = Rt;
  let Inst{12-8} = Ra;
  let Opcode = opcode.Value;
}

class FTInstR2<bits<6> funct6, FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst32<outs, ins, opcodestr, argstr, [], InstFormatR2> {
  bits<5> Rb;
  bits<5> Ra;
  bits<5> Rt;

  let Inst{31-26} = funct6;
  let Inst{22-18} = Rt;
  let Inst{17-13} = Rb;
  let Inst{12-8} = Ra;
  let Opcode = opcode.Value;
}

class FTInstR1<bits<5> funct5, FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst32<outs, ins, opcodestr, argstr, [], InstFormatR1> {
  bits<5> Ra;
  bits<5> Rt;

  let Inst{31-26} = 1;
  let Inst{22-18} = funct5;
  let Inst{17-13} = Rt;
  let Inst{12-8} = Ra;
  let Opcode = opcode.Value;
}

class FTInstSR<bits<3> funct3, FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst32<outs, ins, opcodestr, argstr, [], InstFormatSR> {
  bits<5> Rb;
  bits<5> Ra;
  bits<5> Rt;

  let Inst{31-26} = 0x2f;
  let Inst{25-23} = funct3;
  let Inst{22-18} = Rt;
  let Inst{17-13} = Rb;
  let Inst{12-8} = Ra;
  let Opcode = opcode.Value;
}

class FTInstSI<bits<3> funct3, FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst32<outs, ins, opcodestr, argstr, [], InstFormatSI> {
  bits<6> imm;
  bits<5> Ra;
  bits<5> Rt;

  let Inst{31-26} = imm > 31 ? 0x1f : 0x0f;
  let Inst{25-23} = funct3;
  let Inst{22-18} = imm & 0x1f;
  let Inst{17-13} = Rt;
  let Inst{12-8} = Ra;
  let Opcode = opcode.Value;
}

class FTInstBF<bits<4> funct4, bits<3> Rg3, FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst48<outs, ins, opcodestr, argstr, [], InstFormatBF> {
  bits<16> Da;
  bits<6> Bo;
  bits<6> Bw;
  bits<5> Rt;

  let Inst{47-44} = funct4;
  let Inst{43-33} = Da{15-5};
  let Inst{32-30} = Rg3;
  let Inst{29} = Bw{5};
  let Inst{28} = Bo{5};
  let Inst{27-23} = Rt;
  let Inst{22-18} = Da{4-0};
  let Inst{17-13} = Bw{4-0};
  let Inst{12-8} = Bo{4-0};
  let Opcode = opcode.Value;
}

class FTInstBD<bits<3> cond3, FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst32<outs, ins, opcodestr, argstr, [], InstFormatBD> {
  bits<11> disp;
  bits<5> Rb;
  bits<5> Ra;

  let Inst{31-21} = disp;
  let Inst{20-18} = cond3;
  let Inst{17-13} = Rb;
  let Inst{12-8} = Ra;
  let Opcode = opcode.Value;
}

class FTInstBB<bits<2> cond2, FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst32<outs, ins, opcodestr, argstr, [], InstFormatBB> {
  bits<11> disp;
  bits<6> bitno;
  bits<5> Ra;

  let Inst{31-21} = disp;
  let Inst{20-19} = cond2;
  let Inst{18-13} = bitno;
  let Inst{12-8} = Ra;
  let Opcode = opcode.Value;
}

class FTInstBR<bits<3> cond3, FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst32<outs, ins, opcodestr, argstr, [], InstFormatBR> {
  bits<11> disp;
  bits<5> Rc;
  bits<5> Rb;
  bits<5> Ra;

  let Inst{25-23} = cond3;
  let Inst{22-18} = Rc;
  let Inst{17-13} = Rb;
  let Inst{12-8} = Ra;
  let Opcode = opcode.Value;
}

class FTInstBE<FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst32<outs, ins, opcodestr, argstr, [], InstFormatBE> {
  bits<11> disp;
  bits<8> imm;
  bits<5> Ra;

  let Inst{31-21} = disp;
  let Inst{20-13} = imm;
  let Inst{12-8} = Ra;
  let Opcode = opcode.Value;
}

class FTInstMX<bits<6> funct6, bits<2> Sc, FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst32<outs, ins, opcodestr, argstr, [], InstFormatMX> {
  bits<5> Rb;
  bits<5> Ra;
  bits<5> Rc;

  let Inst{31-26} = funct6;
  let Inst{24-23} = Sc;
  let Inst{22-18} = Rc;
  let Inst{17-13} = Rb;
  let Inst{12-8} = Ra;
  let Opcode = opcode.Value;
}

class FTInstCSR<bits<6> funct6, bits<2> Op2, FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst32<outs, ins, opcodestr, argstr, [], InstFormatCSR> {
  bits<2> ol;
  bits<10> csrno;
  bits<5> Ra;
  bits<5> Rt;

  let Inst{31-30} = Op2;
  let Inst{29-28} = ol;
  let Inst{27-18} = csrno;
  let Inst{17-13} = Rt;
  let Inst{12-8} = Ra;
  let Opcode = opcode.Value;
}

class FTInstFLT<bits<6> funct6, bits<3> Rm, FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst32<outs, ins, opcodestr, argstr, [], InstFormatFLT> {
  bits<5> Rb;
  bits<5> Ra;
  bits<5> Rt;

  let Inst{31-26} = funct6;
  let Inst{25-23} = Rm;
  let Inst{22-18} = Rt;
  let Inst{17-13} = Rb;
  let Inst{12-8} = Ra;
  let Opcode = opcode.Value;
}

class FTInstJC24<FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst32<outs, ins, opcodestr, argstr, [], InstFormatJC24> {
  bits<24> addr;

  let Inst{31-8} = addr;
  let Opcode = opcode.Value;
}

class FTInstJC40<FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst32<outs, ins, opcodestr, argstr, [], InstFormatJC40> {
  bits<40> addr;

  let Inst{47-8} = addr;
  let Opcode = opcode.Value;
}

class FTInstR3<bits<6> funct6, bits<6> Op2, bits<3> Sz3, FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst48<outs, ins, opcodestr, argstr, [], InstFormatR3> {
  bits<5> Rc;
  bits<5> Rb;
  bits<5> Ra;
  bits<5> Rt;

  let Inst{47-42} = funct6;
  let Inst{41-36} = Op2;
  let Inst{30-28} = Sz3;
  let Inst{27-23} = Rt;
  let Inst{22-18} = Rc;
  let Inst{17-13} = Rb;
  let Inst{12-8} = Ra;
  let Opcode = opcode.Value;
}
