//===-- FT64TargetStreamer.cpp - FT64 Target Streamer Methods -----------===//
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

#include "FT64TargetStreamer.h"
#include "llvm/Support/FormattedStream.h"

using namespace llvm;

FT64TargetStreamer::FT64TargetStreamer(MCStreamer &S) : MCTargetStreamer(S) {}

// This part is for ascii assembly output
FT64TargetAsmStreamer::FT64TargetAsmStreamer(MCStreamer &S,
                                               formatted_raw_ostream &OS)
    : FT64TargetStreamer(S), OS(OS) {}

void FT64TargetAsmStreamer::emitDirectiveOptionRVC() {
  OS << "\t.option\tftc\n";
}

void FT64TargetAsmStreamer::emitDirectiveOptionNoRVC() {
  OS << "\t.option\tnoftc\n";
}
