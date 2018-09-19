//===-- FT64MCAsmInfo.cpp - FT64 Asm properties -------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declarations of the FT64MCAsmInfo properties.
//
//===----------------------------------------------------------------------===//

#include "FT64MCAsmInfo.h"
#include "llvm/ADT/Triple.h"
using namespace llvm;

void FT64MCAsmInfo::anchor() {}

FT64MCAsmInfo::FT64MCAsmInfo(const Triple &TT) {
  CodePointerSize = CalleeSaveStackSlotSize = 8;
  CommentString = "#";
  AlignmentIsInBytes = false;
  SupportsDebugInformation = true;
  Data16bitsDirective = "\t.half\t";
  Data32bitsDirective = "\t.word\t";
}
