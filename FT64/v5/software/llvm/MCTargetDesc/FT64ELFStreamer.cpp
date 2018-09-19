//===-- FT64ELFStreamer.cpp - FT64 ELF Target Streamer Methods ----------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file provides FT64 specific target streamer methods.
//
//===----------------------------------------------------------------------===//

#include "FT64ELFStreamer.h"
#include "FT64MCTargetDesc.h"
#include "llvm/BinaryFormat/ELF.h"
#include "llvm/MC/MCSubtargetInfo.h"

using namespace llvm;

// This part is for ELF object output.
FT64TargetELFStreamer::FT64TargetELFStreamer(MCStreamer &S,
                                               const MCSubtargetInfo &STI)
    : FT64TargetStreamer(S) {
  MCAssembler &MCA = getStreamer().getAssembler();

  const FeatureBitset &Features = STI.getFeatureBits();

  unsigned EFlags = MCA.getELFHeaderEFlags();

  MCA.setELFHeaderEFlags(EFlags);
}

MCELFStreamer &FT64TargetELFStreamer::getStreamer() {
  return (static_cast<MCELFStreamer &>(Streamer));
}

void FT64TargetELFStreamer::emitDirectiveOptionFTC() {}
void FT64TargetELFStreamer::emitDirectiveOptionNoFTC() {}
