//===-- FT64TargetInfo.cpp - FT64 Target Implementation -----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "llvm/Support/TargetRegistry.h"
using namespace llvm;

namespace llvm {

Target &getTheFT6464Target() {
  static Target TheFT6464Target;
  return (TheFT6464Target);
}
}

extern "C" void LLVMInitializeFT64TargetInfo() {
  RegisterTarget<Triple::FT6464> Y(getTheFT6464Target(), "FT6464",
                                    "64-bit FT", "FT64");
}
