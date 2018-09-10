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

class InstFormat<bits<6> val> {
  bits<6> Value = val;
}
def InstFormatRI		: InstFormat<0>;
def InstFormatRI10		: InstFormat<1>;
def InstFormatR2		: InstFormat<2>;
def InstFormatR1		: InstFormat<3>;
def InstFormatSR		: InstFormat<4>;
def InstFormatSI		: InstFormat<5>;
def InstFormatBD		: InstFormat<7>;
def InstFormatBB		: InstFormat<8>;
def InstFormatBR		: InstFormat<9>;
def InstFormatBE		: InstFormat<10>;
def InstFormatMX		: InstFormat<11>;
def InstFormatCSR		: InstFormat<12>;
def InstFormatFLT		: InstFormat<13>;
def InstFormatJC		: InstFormat<14>;
def InstFormatOther		: InstFormat<15>;
def InstFormatPseudo	: InstFormat<16>;
def InstFormatLUI		: InstFormat<17>;

// Compressed instruction formats
def InstFormatCmpNop		: InstFormat<22>;
def InstFormatCmpAddiSp		: InstFormat<23>;
def InstFormatCmpAddi		: InstFormat<24>;
def InstFormatCmpLdiSys		: InstFormat<25>;
def InstFormatCmpAndi		: InstFormat<26>;
def InstFormatCmpShli		: InstFormat<27>;
def InstFormatCmpI			: InstFormat<28>;
def InstFormatCmpR2			: InstFormat<29>;
def InstFormatCmpCall		: InstFormat<30>;
def InstFormatCmpBra		: InstFormat<31>;
def InstFormatCmpBccZ		: InstFormat<32>;
def InstFormatCmpMov		: InstFormat<33>;
def InstFormatCmpAdd		: InstFormat<34>;
def InstFormatCmpJalr		: InstFormat<35>;
def InstFormatCmpStkLd		: InstFormat<36>;
def InstFormatCmpStkSt		: InstFormat<37>;
def InstFormatCmpLh			: InstFormat<38>;
def InstFormatCmpSh			: InstFormat<39>;
def InstFormatCmpLw			: InstFormat<40>;
def InstFormatCmpSw			: InstFormat<41>;
def InstFormatCmpRet		: InstFormat<42>;

// Extended instruction formats
def InstFormatExtR3		: InstFormat<50>;
def InstFormatExtRI		: InstFormat<51>;
def InstFormatExtLUI	: InstFormat<52>;
def InstFormatExtJC		: InstFormat<53>;
def InstFormatExtBF		: InstFormat<54>;


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


// ----------------------------------------------------------------------------
// 16-bit compressed instruction formats
// ----------------------------------------------------------------------------

class FTCmpInstNop<dag outs, dag ins, string opcodestr, string argstr>
    : FTInst16<outs, ins, opcodestr, argstr, [], InstFormatCmpNop> {
  let Inst{15-0} = 0x0080;
}

class FTCmpInstAddiSp<dag outs, dag ins, string opcodestr, string argstr>
    : FTInst16<outs, ins, opcodestr, argstr, [], InstFormatCmpAddiSp> {
  bits<8> amt;
  let Inst{15-12} = 0;
  let Inst{11-8} = amt{7-4};
  let Inst{7-6} = 2;
  let Inst{5} = amt{3};
  let Inst{4-0} = 31;
}

class FTCmpInstAddi<dag outs, dag ins, string opcodestr, string argstr>
    : FTInst16<outs, ins, opcodestr, argstr, [], InstFormatCmpAddi> {
  bits<5> amt;
  bits<5> Rt;
  let Inst{15-12} = 0;
  let Inst{11-8} = amt{4-1};
  let Inst{7-6} = 2;
  let Inst{5} = amt{0};
  let Inst{4-0} = Rt;
}

class FTCmpInstLdiSys<dag outs, dag ins, string opcodestr, string argstr>
    : FTInst16<outs, ins, opcodestr, argstr, [], InstFormatCmpLdiSys> {
  bits<5> amt;
  bits<5> Rt;
  let Inst{15-12} = 1;
  let Inst{11-8} = amt{4-1};
  let Inst{7-6} = 2;
  let Inst{5} = amt{0};
  let Inst{4-0} = Rt;
}

class FTCmpInstRet<dag outs, dag ins, string opcodestr, string argstr>
    : FTInst16<outs, ins, opcodestr, argstr, [], InstFormatCmpRet> {
  bits<8> amt;
  let Inst{15-12} = 2;
  let Inst{11-8} = amt{7-4};
  let Inst{7-6} = 2;
  let Inst{5} = amt{3};
  let Inst{4-0} = 0;
}

class FTCmpInstAndi<dag outs, dag ins, string opcodestr, string argstr>
    : FTInst16<outs, ins, opcodestr, argstr, [], InstFormatCmpAndi> {
  bits<5> amt;
  bits<5> Rt;
  let Inst{15-12} = 2;
  let Inst{11-8} = amt{4-1};
  let Inst{7-6} = 2;
  let Inst{5} = amt{0};
  let Inst{4-0} = Rt;
}

class FTCmpInstShli<dag outs, dag ins, string opcodestr, string argstr>
    : FTInst16<outs, ins, opcodestr, argstr, [], InstFormatCmpShli> {
  bits<5> amt;
  bits<5> Rt;
  let Inst{15-12} = 3;
  let Inst{11-8} = amt{4-1};
  let Inst{7-6} = 2;
  let Inst{5} = amt{0};
  let Inst{4-0} = Rt;
}

class FTCmpInstI<bits<2> Op2, dag outs, dag ins, string opcodestr, string argstr>
    : FTInst16<outs, ins, opcodestr, argstr, [], InstFormatCmpI> {
  bits<5> amt;
  bits<3> Rt;
  let Inst{15-12} = 4;
  let Inst{11-8} = amt{4-1};
  let Inst{7-6} = 2;
  let Inst{5} = amt{0};
  let Inst{4-3} = Op2;
  let Inst{2-0} = Rt;
}

class FTCmpInstR2<bits<2> Op2, dag outs, dag ins, string opcodestr, string argstr>
    : FTInst16<outs, ins, opcodestr, argstr, [], InstFormatCmpR2> {
  bits<5> amt;
  bits<3> Rb;
  bits<3> Rt;
  let Inst{15-12} = 4;
  let Inst{11-10} = Op2;
  let Inst{9-8} = Rb{2-1};
  let Inst{7-6} = 2;
  let Inst{5} = Rb{0};
  let Inst{4-3} = 3;
  let Inst{2-0} = Rt;
}

class FTCmpInstCall<dag outs, dag ins, string opcodestr, string argstr>
    : FTInst16<outs, ins, opcodestr, argstr, [], InstFormatCmpCall> {
  bits<11> addr;
  let Inst{15-12} = 5;
  let Inst{11-8} = addr{10-7};
  let Inst{7-6} = 2;
  let Inst{5-0} = addr{6-1};
}

class FTCmpInstBra<dag outs, dag ins, string opcodestr, string argstr>
    : FTInst16<outs, ins, opcodestr, argstr, [], InstFormatCmpBra> {
  bits<11> disp;
  let Inst{15-12} = 7;
  let Inst{11-8} = disp{10-7};
  let Inst{7-6} = 2;
  let Inst{5-0} = disp{6-1};
}

class FTCmpInstBccZ<bits<1> Op1, dag outs, dag ins, string opcodestr, string argstr>
    : FTInst16<outs, ins, opcodestr, argstr, [], InstFormatCmpBra> {
  bits<8> disp;
  bits<5> Ra;
  let Inst{15} = 1;
  let Inst{14} = Op1;
  let Inst{13-8} = disp{7-2};
  let Inst{7-6} = 2;
  let Inst{5} = disp{1};
  let Inst{4-0} = Ra;
}

class FTCmpInstMov<dag outs, dag ins, string opcodestr, string argstr>
    : FTInst16<outs, ins, opcodestr, argstr, [], InstFormatCmpMov> {
  bits<5> Rt;
  bits<5> Ra;
  let Inst{15-12} = 0;
  let Inst{11-8} = Rt{4-1};
  let Inst{7-6} = 3;
  let Inst{5} = Rt{1};
  let Inst{4-0} = Ra;
}

class FTCmpInstAdd<dag outs, dag ins, string opcodestr, string argstr>
    : FTInst16<outs, ins, opcodestr, argstr, [], InstFormatCmpAdd> {
  bits<5> Rt;
  bits<5> Rb;
  let Inst{15-12} = 1;
  let Inst{11-8} = Rb{4-1};
  let Inst{7-6} = 3;
  let Inst{5} = Rb{1};
  let Inst{4-0} = Rt;
}

class FTCmpInstJalr<dag outs, dag ins, string opcodestr, string argstr>
    : FTInst16<outs, ins, opcodestr, argstr, [], InstFormatCmpJalr> {
  bits<5> Rt;
  bits<5> Ra;
  let Inst{15-12} = 2;
  let Inst{11-8} = Rt{4-1};
  let Inst{7-6} = 3;
  let Inst{5} = Rt{1};
  let Inst{4-0} = Ra;
}

class FTCmpInstStkLh<bits<4> Op4, dag outs, dag ins, string opcodestr, string argstr>
    : FTInst16<outs, ins, opcodestr, argstr, [], InstFormatCmpLh> {
  bits<7> disp;
  bits<5> Rt;
  let Inst{15-12} = Op4;
  let Inst{11-8} = disp{6-3};
  let Inst{7-6} = 3;
  let Inst{5} = disp{2};
  let Inst{4-0} = Rt;
}

class FTCmpInstStkLw<bits<4> Op4, dag outs, dag ins, string opcodestr, string argstr>
    : FTInst16<outs, ins, opcodestr, argstr, [], InstFormatCmpLw> {
  bits<8> disp;
  bits<5> Rt;
  let Inst{15-12} = Op4;
  let Inst{11-8} = disp{7-4};
  let Inst{7-6} = 3;
  let Inst{5} = disp{3};
  let Inst{4-0} = Rt;
}

class FTCmpInstStkSh<bits<4> Op4, dag outs, dag ins, string opcodestr, string argstr>
    : FTInst16<outs, ins, opcodestr, argstr, [], InstFormatCmpSh> {
  bits<7> disp;
  bits<5> Rb;
  let Inst{15-12} = Op4;
  let Inst{11-8} = disp{6-3};
  let Inst{7-6} = 3;
  let Inst{5} = disp{2};
  let Inst{4-0} = Rb;
}

class FTCmpInstStkSw<bits<4> Op4, dag outs, dag ins, string opcodestr, string argstr>
    : FTInst16<outs, ins, opcodestr, argstr, [], InstFormatCmpSw> {
  bits<8> disp;
  bits<5> Rb;
  let Inst{15-12} = Op4;
  let Inst{11-8} = disp{7-4};
  let Inst{7-6} = 3;
  let Inst{5} = disp{3};
  let Inst{4-0} = Rb;
}


// ----------------------------------------------------------------------------
// 32-bit instruction formats
// ----------------------------------------------------------------------------

class FTInstLUI<FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst32<outs, ins, opcodestr, argstr, [], InstFormatLUI> {
  bits<19> imm19;
  bits<5> Rt;

  let Inst{31-13} = imm19;
  let Inst{12-8} = Rt;
  let Opcode = opcode.Value;
}

class FTInstRI<FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst32<outs, ins, opcodestr, argstr, [], InstFormatRI> {
  bits<14> imm;
  bits<5> Ra;
  bits<5> Rt;

  let Inst{31-18} = imm;
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

class FTInstJC<FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst32<outs, ins, opcodestr, argstr, [], InstFormatJC> {
  bits<24> addr;

  let Inst{31-8} = addr;
  let Opcode = opcode.Value;
}


// ----------------------------------------------------------------------------
// 48-bit extended instruction formats
// ----------------------------------------------------------------------------

class FTExtInstRI<FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst48<outs, ins, opcodestr, argstr, [], InstFormatExtRI> {
  bits<30> imm;
  bits<5> Ra;
  bits<5> Rt;

  let Inst{47-18} = imm;
  let Inst{17-13} = Rt;
  let Inst{12-8} = Ra;
  let Opcode = opcode.Value;
}

class FTExtInstLUI<FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst48<outs, ins, opcodestr, argstr, [], InstFormatExtLUI> {
  bits<35> imm35;
  bits<5> Rt;

  let Inst{47-13} = imm35;
  let Inst{12-8} = Rt;
  let Opcode = opcode.Value;
}

class FTExtInstJC<FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst32<outs, ins, opcodestr, argstr, [], InstFormatExtJC> {
  bits<40> addr;

  let Inst{47-8} = addr;
  let Opcode = opcode.Value;
}

class FTExtInstR3<bits<6> funct6, bits<6> Op2, bits<3> Sz3, FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst48<outs, ins, opcodestr, argstr, [], InstFormatExtR3> {
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

class FTExtInstBF<bits<4> funct4, bits<3> Rg3, FT64Opcode opcode, dag outs,
              dag ins, string opcodestr, string argstr>
    : FTInst48<outs, ins, opcodestr, argstr, [], InstFormatExtBF> {
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

