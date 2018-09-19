//===-- FT64MCTargetDesc.h - FT64 Target Descriptions ---------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file provides FT64 specific target descriptions.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_FT64_MCTARGETDESC_FT64MCTARGETDESC_H
#define LLVM_LIB_TARGET_FT64_MCTARGETDESC_FT64MCTARGETDESC_H

#include "llvm/Config/config.h"
#include "llvm/MC/MCTargetOptions.h"
#include "llvm/Support/DataTypes.h"
#include <memory>

namespace llvm {
class MCAsmBackend;
class MCCodeEmitter;
class MCContext;
class MCInstrInfo;
class MCObjectTargetWriter;
class MCRegisterInfo;
class MCSubtargetInfo;
class StringRef;
class Target;
class Triple;
class raw_ostream;
class raw_pwrite_stream;

Target &getTheFT6432Target();
Target &getTheFT6464Target();

MCCodeEmitter *createFT64MCCodeEmitter(const MCInstrInfo &MCII,
                                        const MCRegisterInfo &MRI,
                                        MCContext &Ctx);

MCAsmBackend *createFT64AsmBackend(const Target &T, const MCSubtargetInfo &STI,
                                    const MCRegisterInfo &MRI,
                                    const MCTargetOptions &Options);

std::unique_ptr<MCObjectTargetWriter> createFT64ELFObjectWriter(uint8_t OSABI,
                                                                 bool Is64Bit);
}

// Defines symbolic names for RISC-V registers.
#define GET_REGINFO_ENUM
#include "FT64GenRegisterInfo.inc"

// Defines symbolic names for RISC-V instructions.
#define GET_INSTRINFO_ENUM
#include "FT64GenInstrInfo.inc"

#define GET_SUBTARGETINFO_ENUM
#include "FT64GenSubtargetInfo.inc"

#endif
