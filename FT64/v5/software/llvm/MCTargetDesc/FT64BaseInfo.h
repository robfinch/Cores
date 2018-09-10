//===-- FT64BaseInfo.h - Top level definitions for FT64 MC ----*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains small standalone enum definitions for the FT64 target
// useful for the compiler back-end and the MC libraries.
//
//===----------------------------------------------------------------------===//
#ifndef LLVM_LIB_TARGET_FT64_MCTARGETDESC_FT64BASEINFO_H
#define LLVM_LIB_TARGET_FT64_MCTARGETDESC_FT64BASEINFO_H

#include "FT64MCTargetDesc.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/StringSwitch.h"

namespace llvm {

// FT64II - This namespace holds all of the target specific flags that
// instruction info tracks. All definitions must match FT64InstrFormats.td.
namespace FT64II {
enum {
	InstFormatRI = 0,
	InstFormatRI10 = 1,
	InstFormatR2 = 2,
	InstFormatR1 = 3,
	InstFormatSR = 4,
	InstFormatSI = 5,
	InstFormatBD = 7,
	InstFormatBR = 9,
	InstFormatBE = 10,
	InstFormatMX = 11,
	InstFormatCSR = 12,
	InstFormatFLT = 13,
	InstFormatJC = 14,
	InstFormatOther = 15,
  InstFormatPseudo = 16,
	InstFormatLUI = 17,
	
	InstFormatCmpNop = 22,
	InstFormatCmpAddiSp = 23,
	InstFormatCmpAddi = 24,
	InstFormatCmpLdiSys = 25,
	InstFormatCmpAndi = 26,
	InstFormatCmpShli = 27,
	InstFormatCmpI = 28,
	InstFormatCmpR2 = 29,
	InstFormatCmpCall = 30,
	InstFormatCmpBra = 31,
	InstFormatCmpBccZ = 32,
	InstFormatCmpMov = 33,
	InstFormatCmpAdd = 34,
	InstFormatCmpJalr = 35,
	InstFormatCmpStkLd = 36,	// Fix this for lh/lw
	InstFormatCmpStkSt = 37,
	InstFormatCmpLh = 38,
	InstFormatCmpSh = 39,
	InstFormatCmpLw = 40,
	InstFormatCmpSw = 41,
	InstFormatCmpRet = 42,
	
	InstFormatExtR3 = 50,
	InstFormatExtRI = 51,
	InstFormatExtLUI = 52,
	InstFormatExtJC = 53,
	InstFormatExtBF = 54,

  InstFormatMask = 63
};

enum {
  MO_None,
  MO_LO,
  MO_HI,
  MO_PCREL_HI,
};
} // namespace FT64II

// Describes the supported floating point rounding mode encodings.
namespace FT64FPRndMode {
enum RoundingMode {
  RNE = 0,
  RTZ = 1,
  RDN = 2,
  RUP = 3,
  RMM = 4,
  DYN = 7,
  Invalid
};

inline static StringRef roundingModeToString(RoundingMode RndMode) {
  switch (RndMode) {
  default:
    llvm_unreachable("Unknown floating point rounding mode");
  case FT64FPRndMode::RNE:
    return "rne";
  case FT64FPRndMode::RTZ:
    return "rtz";
  case FT64FPRndMode::RDN:
    return "rdn";
  case FT64FPRndMode::RUP:
    return "rup";
  case FT64FPRndMode::RMM:
    return "rmm";
  case FT64FPRndMode::DYN:
    return "dyn";
  }
}

inline static RoundingMode stringToRoundingMode(StringRef Str) {
  return StringSwitch<RoundingMode>(Str)
      .Case("rne", FT64FPRndMode::RNE)
      .Case("rtz", FT64FPRndMode::RTZ)
      .Case("rdn", FT64FPRndMode::RDN)
      .Case("rup", FT64FPRndMode::RUP)
      .Case("rmm", FT64FPRndMode::RMM)
      .Case("dyn", FT64FPRndMode::DYN)
      .Default(FT64FPRndMode::Invalid);
}
} // namespace FT64FPRndMode
} // namespace llvm

#endif
