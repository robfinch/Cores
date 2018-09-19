//===-- FT64MCAsmInfo.h - FT64 Asm Info ----------------------*- C++ -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declaration of the FT64MCAsmInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_FT64_MCTARGETDESC_FT64MCASMINFO_H
#define LLVM_LIB_TARGET_FT64_MCTARGETDESC_FT64MCASMINFO_H

#include "llvm/MC/MCAsmInfoELF.h"

namespace llvm {
class Triple;

class FT64MCAsmInfo : public MCAsmInfoELF {
  void anchor() override;

public:
  explicit FT64MCAsmInfo(const Triple &TargetTriple);
};

} // namespace llvm

#endif
