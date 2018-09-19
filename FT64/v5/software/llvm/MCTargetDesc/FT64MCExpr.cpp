//===-- FT64MCExpr.cpp - FT64 specific MC expression classes ------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the implementation of the assembly expression modifiers
// accepted by the FT64 architecture (e.g. ":lo14:", ":gottprel_g1:", ...).
//
//===----------------------------------------------------------------------===//

#include "FT64.h"
#include "FT64MCExpr.h"
#include "llvm/MC/MCAssembler.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSymbolELF.h"
#include "llvm/MC/MCValue.h"
#include "llvm/Object/ELF.h"
#include "llvm/Support/ErrorHandling.h"

using namespace llvm;

#define DEBUG_TYPE "FT64mcexpr"

const FT64MCExpr *FT64MCExpr::create(const MCExpr *Expr, VariantKind Kind,
                                       MCContext &Ctx) {
  return (new (Ctx) FT64MCExpr(Expr, Kind));
}

void FT64MCExpr::printImpl(raw_ostream &OS, const MCAsmInfo *MAI) const {
  bool HasVariant =
      ((getKind() != VK_FT64_None) && (getKind() != VK_FT64_CALL_24) && (getKind() != VK_CALL_40));
  if (HasVariant)
    OS << '%' << getVariantKindName(getKind()) << '(';
  Expr->print(OS, MAI);
  if (HasVariant)
    OS << ')';
}

bool FT64MCExpr::evaluateAsRelocatableImpl(MCValue &Res,
                                            const MCAsmLayout *Layout,
                                            const MCFixup *Fixup) const {
  if (!getSubExpr()->evaluateAsRelocatable(Res, Layout, Fixup))
    return (false);

  // Some custom fixup types are not valid with symbol difference expressions
  if (Res.getSymA() && Res.getSymB()) {
    switch (getKind()) {
    default:
      return (true);
    case VK_FT64_LO14:
    case VK_FT64_LO30:
    case VK_FT64_MID35:
    case VK_FT64_HI34:
    case VK_FT64_PCREL_LO14:
    case VK_FT64_PCREL_LO30:
    case VK_FT64_PCREL_MID35:
    case VK_FT64_PCREL_HI34:
      return (false);
    }
  }
  return (true);
}

void FT64MCExpr::visitUsedExpr(MCStreamer &Streamer) const {
  Streamer.visitUsedExpr(*getSubExpr());
}

FT64MCExpr::VariantKind FT64MCExpr::getVariantKindForName(StringRef name) {
  return StringSwitch<FT64MCExpr::VariantKind>(name)
  		.Case("lo14", VK_FT64_LO14)
  		.Case("lo30", VK_FT64_LO30)
  		.Case("mid35", VK_FT64_MID35)
  		.Case("hi34", VK_FT64_HI34)
  		.Case("pcrel_lo14", VK_FT64_PCREL_LO14)
  		.Case("pcrel_lo30", VK_FT64_PCREL_LO30)
  		.Case("pcrel_mid35", VK_FT64_PCREL_MID35)
  		.Case("pcrel_hi34", VK_FT64_PCREL_HI34)
      .Default(VK_FT64_Invalid);
}

StringRef FT64MCExpr::getVariantKindName(VariantKind Kind) {
  switch (Kind) {
  default:
    llvm_unreachable("Invalid ELF symbol kind");
  case VK_FT64_LO14:
    return ("lo14");
  case VK_FT64_LO30:
    return ("lo30");
  case VK_FT64_MID35:
    return ("mid35");
  case VK_FT64_HI34:
    return ("hi34");
  case VK_FT64_PCREL_LO14:
    return ("pcrel_lo14");
  case VK_FT64_PCREL_LO30:
    return ("pcrel_lo30");
  case VK_FT64_PCREL_MID35:
    return ("pcrel_mid35");
  case VK_FT64_PCREL_HI34:
    return ("pcrel_hi34");
  }
}

bool FT64MCExpr::evaluateAsConstant(int64_t &Res) const {
  MCValue Value;

	if (  Kind == VK_FT64_PCREL_HI34 || Kind == VK_FT64_PCREL_MID35
		 || Kind == VK_FT64_PCREL_LO14 || Kind == VK_FT64_PCREL_LOW30
		 || Kind == VK_FT64_CALL_24 || Kind == VK_FT64_CALL_40)
    return (false);

  if (!getSubExpr()->evaluateAsRelocatable(Value, nullptr, nullptr))
    return (false);

  if (!Value.isAbsolute())
    return (false);

  Res = evaluateAsInt64(Value.getConstant());
  return (true);
}

int64_t FT64MCExpr::evaluateAsInt64(int64_t Value) const {
  switch (Kind) {
  default:
    llvm_unreachable("Invalid kind");
  case VK_FT64_LO14:
    return (SignExtend64<14>(Value));
  case VK_FT64_LO30:
    return (SignExtend64<30>(Value));
  case VK_FT64_MID35:
    // Add 1 if bit 13 is 1, to compensate for low 14 bits being negative.
    return ((Value + 0x2000) >> 14) & 0x7ffffffffLL;
  case VK_FT64_HI34:
    // Add 1 if bit 29 is 1, to compensate for low 12 bits being negative.
    return ((Value + 0x20000000) >> 30) & 0x7ffffffffLL;
  }
}
