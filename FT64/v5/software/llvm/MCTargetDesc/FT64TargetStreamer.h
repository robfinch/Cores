//===-- FT64TargetStreamer.h - FT64 Target Streamer ----------*- C++ -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_FT64_FT64TARGETSTREAMER_H
#define LLVM_LIB_TARGET_FT64_FT64TARGETSTREAMER_H

#include "llvm/MC/MCStreamer.h"

namespace llvm {

class FT64TargetStreamer : public MCTargetStreamer {
public:
  FT64TargetStreamer(MCStreamer &S);

  virtual void emitDirectiveOptionFTC() = 0;
  virtual void emitDirectiveOptionNoFTC() = 0;
};

// This part is for ascii assembly output
class FT64TargetAsmStreamer : public FT64TargetStreamer {
  formatted_raw_ostream &OS;

public:
  FT64TargetAsmStreamer(MCStreamer &S, formatted_raw_ostream &OS);

  void emitDirectiveOptionRVC() override;
  void emitDirectiveOptionNoRVC() override;
};

}
#endif
