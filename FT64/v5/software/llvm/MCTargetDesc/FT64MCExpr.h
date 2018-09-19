//===-- FT64MCExpr.h - FT64 specific MC expression classes ----*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file describes FT64-specific MCExprs, used for modifiers like
// "%hi" or "%lo" etc.,
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_FT64_MCTARGETDESC_FT64MCEXPR_H
#define LLVM_LIB_TARGET_FT64_MCTARGETDESC_FT64MCEXPR_H

#include "llvm/MC/MCExpr.h"

namespace llvm {

class StringRef;
class MCOperand;
class FT64MCExpr : public MCTargetExpr {
public:
  enum VariantKind {
    VK_FT64_None,
    VK_FT64_LO14,
    VK_FT64_LO30,
    VK_FT64_MID35,
    VK_FT64_HI34,
    VK_FT64_PCREL_LO14,
    VK_FT64_PCREL_LO30,
    VK_FT64_PCREL_MID35,
    VK_FT64_PCREL_HI34,
    VK_FT64_CALL_24,
    VK_FT64_CALL_40,
    VK_FT64_Invalid
  };

private:
  const MCExpr *Expr;
  const VariantKind Kind;

  int64_t evaluateAsInt64(int64_t Value) const;

  explicit FT64MCExpr(const MCExpr *Expr, VariantKind Kind)
      : Expr(Expr), Kind(Kind) {}

public:
  static const FT64MCExpr *create(const MCExpr *Expr, VariantKind Kind,
                                   MCContext &Ctx);

  VariantKind getKind() const { return Kind; }

  const MCExpr *getSubExpr() const { return Expr; }

  void printImpl(raw_ostream &OS, const MCAsmInfo *MAI) const override;
  bool evaluateAsRelocatableImpl(MCValue &Res, const MCAsmLayout *Layout,
                                 const MCFixup *Fixup) const override;
  void visitUsedExpr(MCStreamer &Streamer) const override;
  MCFragment *findAssociatedFragment() const override {
    return (getSubExpr()->findAssociatedFragment());
  }

  // There are no TLS FT64MCExprs at the moment.
  void fixELFSymbolsInTLSFixups(MCAssembler &Asm) const override {}

  bool evaluateAsConstant(int64_t &Res) const;

  static bool classof(const MCExpr *E) {
    return (E->getKind() == MCExpr::Target);
  }

  static bool classof(const FT64MCExpr *) { return (true); }

  static VariantKind getVariantKindForName(StringRef name);
  static StringRef getVariantKindName(VariantKind Kind);
};

} // end namespace llvm.

#endif
