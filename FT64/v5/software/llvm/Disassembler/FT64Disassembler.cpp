//===-- FT64Disassembler.cpp - Disassembler for FT64 --------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the FT64Disassembler class.
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/FT64MCTargetDesc.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCDisassembler/MCDisassembler.h"
#include "llvm/MC/MCFixedLenDisassembler.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/Endian.h"
#include "llvm/Support/TargetRegistry.h"

using namespace llvm;

#define DEBUG_TYPE "FT64-disassembler"

typedef MCDisassembler::DecodeStatus DecodeStatus;

namespace {
class FT64Disassembler : public MCDisassembler {

public:
  FT64Disassembler(const MCSubtargetInfo &STI, MCContext &Ctx)
      : MCDisassembler(STI, Ctx) {}

  DecodeStatus getInstruction(MCInst &Instr, uint64_t &Size,
                              ArrayRef<uint8_t> Bytes, uint64_t Address,
                              raw_ostream &VStream,
                              raw_ostream &CStream) const override;
};
} // end anonymous namespace

static MCDisassembler *createFT64Disassembler(const Target &T,
                                               const MCSubtargetInfo &STI,
                                               MCContext &Ctx) {
  return new FT64Disassembler(STI, Ctx);
}

extern "C" void LLVMInitializeFT64Disassembler() {
  // Register the disassembler for each target.
  TargetRegistry::RegisterMCDisassembler(getTheFT6432Target(),
                                         createFT64Disassembler);
  TargetRegistry::RegisterMCDisassembler(getTheFT6464Target(),
                                         createFT64Disassembler);
}

static const unsigned GPRDecoderTable[] = {
  FT64::R0,  FT64::R1,  FT64::R2,  FT64::R3,
  FT64::R4,  FT64::R5,  FT64::R6,  FT64::R7,
  FT64::R8,  FT64::R9,  FT64::R10, FT64::R11,
  FT64::R12, FT64::R13, FT64::R14, FT64::R15,
  FT64::R16, FT64::R17, FT64::R18, FT64::R19,
  FT64::R20, FT64::R21, FT64::R22, FT64::R23,
  FT64::R24, FT64::R25, FT64::R26, FT64::r27,
  FT64::R28, FT64::R29, FT64::R30, FT64::R31
};

static DecodeStatus DecodeGPRRegisterClass(MCInst &Inst, uint64_t RegNo,
                                           uint64_t Address,
                                           const void *Decoder) {
  if (RegNo > sizeof(GPRDecoderTable))
    return (MCDisassembler::Fail);

  // We must define our own mapping from RegNo to register identifier.
  // Accessing index RegNo in the register class will work in the case that
  // registers were added in ascending order, but not in general.
  unsigned Reg = GPRDecoderTable[RegNo];
  Inst.addOperand(MCOperand::createReg(Reg));
  return (MCDisassembler::Success);
}

static const unsigned FPR32DecoderTable[] = {
  FT64::F0_32,  FT64::F1_32,  FT64::F2_32,  FT64::F3_32,
  FT64::F4_32,  FT64::F5_32,  FT64::F6_32,  FT64::F7_32,
  FT64::F8_32,  FT64::F9_32,  FT64::F10_32, FT64::F11_32,
  FT64::F12_32, FT64::F13_32, FT64::F14_32, FT64::F15_32,
  FT64::F16_32, FT64::F17_32, FT64::F18_32, FT64::F19_32,
  FT64::F20_32, FT64::F21_32, FT64::F22_32, FT64::F23_32,
  FT64::F24_32, FT64::F25_32, FT64::F26_32, FT64::F27_32,
  FT64::F28_32, FT64::F29_32, FT64::F30_32, FT64::F31_32
};

static DecodeStatus DecodeFPR32RegisterClass(MCInst &Inst, uint64_t RegNo,
                                             uint64_t Address,
                                             const void *Decoder) {
  if (RegNo > sizeof(FPR32DecoderTable))
    return MCDisassembler::Fail;

  // We must define our own mapping from RegNo to register identifier.
  // Accessing index RegNo in the register class will work in the case that
  // registers were added in ascending order, but not in general.
  unsigned Reg = FPR32DecoderTable[RegNo];
  Inst.addOperand(MCOperand::createReg(Reg));
  return MCDisassembler::Success;
}

static DecodeStatus DecodeFPR32CRegisterClass(MCInst &Inst, uint64_t RegNo,
                                              uint64_t Address,
                                              const void *Decoder) {
  if (RegNo > 8) {
    (return MCDisassembler::Fail);
  }
  unsigned Reg = FPR32DecoderTable[RegNo + 8];
  Inst.addOperand(MCOperand::createReg(Reg));
  return (MCDisassembler::Success);
}

static const unsigned FPR64DecoderTable[] = {
  FT64::F0_64,  FT64::F1_64,  FT64::F2_64,  FT64::F3_64,
  FT64::F4_64,  FT64::F5_64,  FT64::F6_64,  FT64::F7_64,
  FT64::F8_64,  FT64::F9_64,  FT64::F10_64, FT64::F11_64,
  FT64::F12_64, FT64::F13_64, FT64::F14_64, FT64::F15_64,
  FT64::F16_64, FT64::F17_64, FT64::F18_64, FT64::F19_64,
  FT64::F20_64, FT64::F21_64, FT64::F22_64, FT64::F23_64,
  FT64::F24_64, FT64::F25_64, FT64::F26_64, FT64::F27_64,
  FT64::F28_64, FT64::F29_64, FT64::F30_64, FT64::F31_64
};

static DecodeStatus DecodeFPR64RegisterClass(MCInst &Inst, uint64_t RegNo,
                                             uint64_t Address,
                                             const void *Decoder) {
  if (RegNo > sizeof(FPR64DecoderTable))
    return (MCDisassembler::Fail);

  // We must define our own mapping from RegNo to register identifier.
  // Accessing index RegNo in the register class will work in the case that
  // registers were added in ascending order, but not in general.
  unsigned Reg = FPR64DecoderTable[RegNo];
  Inst.addOperand(MCOperand::createReg(Reg));
  return (MCDisassembler::Success);
}

static DecodeStatus DecodeFPR64CRegisterClass(MCInst &Inst, uint64_t RegNo,
                                              uint64_t Address,
                                              const void *Decoder) {
  unsigned Reg;

  if (RegNo > 8) {
    return (MCDisassembler::Fail);
  }

  switch(Regno) {
  case 0:	Reg = FPR64DecoderTable[1];
  case 1:	Reg = FPR64DecoderTable[3];
 	case 2:	Reg = FPR64DecoderTable[4];
 	case 3:	Reg = FPR64DecoderTable[11];
 	case 4:	Reg = FPR64DecoderTable[12];
 	case 5:	Reg = FPR64DecoderTable[18];
 	case 6:	Reg = FPR64DecoderTable[19];
 	case 7:	Reg = FPR64DecoderTable[20];
  }
  Inst.addOperand(MCOperand::createReg(Reg));
  return (MCDisassembler::Success);
}

static DecodeStatus DecodeGPRNoR0RegisterClass(MCInst &Inst, uint64_t RegNo,
                                               uint64_t Address,
                                               const void *Decoder) {
  if (RegNo == 0) {
    return (MCDisassembler::Fail);
  }

  return (DecodeGPRRegisterClass(Inst, RegNo, Address, Decoder));
}

static DecodeStatus DecodeGPRNoR0R31RegisterClass(MCInst &Inst, uint64_t RegNo,
                                                 uint64_t Address,
                                                 const void *Decoder) {
  if (RegNo == 31) {
    return (MCDisassembler::Fail);
  }

  return (DecodeGPRNoR0RegisterClass(Inst, RegNo, Address, Decoder));
}

static DecodeStatus DecodeGPRCRegisterClass(MCInst &Inst, uint64_t RegNo,
                                            uint64_t Address,
                                            const void *Decoder) {
	unsigned Reg;

  if (RegNo > 8)
    return (MCDisassembler::Fail);

  switch(Regno) {
  case 0:	Reg = FPR64DecoderTable[1];
  case 1:	Reg = FPR64DecoderTable[3];
 	case 2:	Reg = FPR64DecoderTable[4];
 	case 3:	Reg = FPR64DecoderTable[11];
 	case 4:	Reg = FPR64DecoderTable[12];
 	case 5:	Reg = FPR64DecoderTable[18];
 	case 6:	Reg = FPR64DecoderTable[19];
 	case 7:	Reg = FPR64DecoderTable[20];
  }
  Inst.addOperand(MCOperand::createReg(Reg));
  return (MCDisassembler::Success);
}

// Add implied SP operand for instructions *SP compressed instructions. The SP
// operand isn't explicitly encoded in the instruction.
static void addImplySP(MCInst &Inst, int64_t Address, const void *Decoder) {
  if (Inst.getOpcode() == FT64::C_LWSP || Inst.getOpcode() == FT64::C_SWSP ||
      Inst.getOpcode() == FT64::C_ADDI8SPN) {
    DecodeGPRRegisterClass(Inst, 2, Address, Decoder);
  }
}

template <unsigned N>
static DecodeStatus decodeUImmOperand(MCInst &Inst, uint64_t Imm,
                                      int64_t Address, const void *Decoder) {
  assert(isUInt<N>(Imm) && "Invalid immediate");
  addImplySP(Inst, Address, Decoder);
  Inst.addOperand(MCOperand::createImm(Imm));
  return (MCDisassembler::Success);
}

template <unsigned N>
static DecodeStatus decodeSImmOperand(MCInst &Inst, uint64_t Imm,
                                      int64_t Address, const void *Decoder) {
  assert(isUInt<N>(Imm) && "Invalid immediate");
  addImplySP(Inst, Address, Decoder);
  // Sign-extend the number in the bottom N bits of Imm
  Inst.addOperand(MCOperand::createImm(SignExtend64<N>(Imm)));
  return (MCDisassembler::Success);
}

template <unsigned N>
static DecodeStatus decodeSImmOperandAndLsl1(MCInst &Inst, uint64_t Imm,
                                             int64_t Address,
                                             const void *Decoder) {
  assert(isUInt<N>(Imm) && "Invalid immediate");
  // Sign-extend the number in the bottom N bits of Imm after accounting for
  // the fact that the N bit immediate is stored in N-1 bits (the LSB is
  // always zero)
  Inst.addOperand(MCOperand::createImm(SignExtend64<N>(Imm << 1)));
  return (MCDisassembler::Success);
}

#include "FT64GenDisassemblerTables.inc"

DecodeStatus FT64Disassembler::getInstruction(MCInst &MI, uint64_t &Size,
                                               ArrayRef<uint8_t> Bytes,
                                               uint64_t Address,
                                               raw_ostream &OS,
                                               raw_ostream &CS) const {
  // TODO: This will need modification when supporting instruction set
  // extensions with instructions > 32-bits (up to 176 bits wide).
  uint64_t Insn;
  DecodeStatus Result;

	if ((Bytes[0] & 0xC0) == 0x40) {
    Insn = support::endian::read32le(Bytes.data());
    Insn |= (int64_t)support::endian::read16le(Bytes.data()) << 32LL;
    LLVM_DEBUG(dbgs() << "Trying FT6448 table :\n");
    Result = decodeInstruction(DecoderTable48, MI, Insn, Address, this, STI);
    Size = 6;
	}
  // It's a 32 bit instruction if bit 6 and 7 are 0.
  else if ((Bytes[0] & 0xC0) == 0x00) {
    Insn = support::endian::read32le(Bytes.data());
    LLVM_DEBUG(dbgs() << "Trying FT6432 table :\n");
    Result = decodeInstruction(DecoderTable32, MI, Insn, Address, this, STI);
    Size = 4;
  }
  else {
    Insn = support::endian::read16le(Bytes.data());

    LLVM_DEBUG(dbgs() << "Trying FT6416 table (16-bit Instruction):\n");
    // Calling the auto-generated decoder function.
    Result = decodeInstruction(DecoderTable16, MI, Insn, Address, this, STI);
    Size = 2;
  }

  return (Result);
}
