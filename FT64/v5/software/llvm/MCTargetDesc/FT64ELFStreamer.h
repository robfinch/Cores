//===-- FT64ELFStreamer.h - FT64 ELF Target Streamer ---------*- C++ -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_FT64_FT64ELFSTREAMER_H
#define LLVM_LIB_TARGET_FT64_FT64ELFSTREAMER_H

#include "FT64TargetStreamer.h"
#include "llvm/MC/MCELFStreamer.h"

namespace llvm {

class FT64TargetELFStreamer : public FT64TargetStreamer {
public:
  MCELFStreamer &getStreamer();
  FT64TargetELFStreamer(MCStreamer &S, const MCSubtargetInfo &STI);

  virtual void emitDirectiveOptionFTC();
  virtual void emitDirectiveOptionNoFTC();
};
}
#endif
