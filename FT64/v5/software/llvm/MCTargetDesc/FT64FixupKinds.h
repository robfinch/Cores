//===-- FT64FixupKinds.h - FT64 Specific Fixup Entries --------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_FT64_MCTARGETDESC_FT64FIXUPKINDS_H
#define LLVM_LIB_TARGET_FT64_MCTARGETDESC_FT64FIXUPKINDS_H

#include "llvm/MC/MCFixup.h"

#undef FT64

namespace llvm {
namespace FT64 {
enum Fixups {
	fixup_FT64_none = FirstTargetFixupKind,
  // fixup_FT64_hi34 - 34-bit fixup corresponding to hi(foo) for
  // instructions like lui
  fixup_FT64_hi34,
  // fixup_FT64_mid35 - 35 bit fixup corresponding to mid(foo) for
  // instructions like lui.
  fixup_FT64_mid35,
  // fixup_FT64_lo30_i - 30-bit fixup corresponding to lo(foo) for
  // instructions like addi
  fixup_FT64_lo30_i,
  // fixup_FT64_lo14_i - 14-bit fixup corresponding to lo(foo) for
  // instructions like addi
  fixup_FT64_lo14_i,
  // fixup_FT64_pcrel_hi34 - 34-bit fixup corresponding to pcrel_hi(foo) for
  // instructions like auipc
  fixup_FT64_pcrel_hi34,
  // fixup_FT64_pcrel_mid35 - 35-bit fixup corresponding to pcrel_mid(foo) for
  // instructions like auipc
  fixup_FT64_pcrel_mid35,
  // fixup_FT64_pcrel_lo12_i - 12-bit fixup corresponding to pcrel_lo(foo) for
  // instructions like addi
  fixup_FT64_pcrel_lo14_i,
  // fixup_FT64_pcrel_lo30_i - 30-bit fixup corresponding to pcrel_lo(foo) for
  // instructions like addi
  fixup_FT64_pcrel_lo30_i,
  // fixup_FT64_call - 24-bit fixup for symbol references in the call
  // instruction
  fixup_FT64_call_24,
  // fixup_FT64_call - 40-bit fixup for symbol references in the call
  // instruction
  fixup_FT64_call_40,
  // fixup_FT64_branch - 11-bit fixup for symbol references in the branch
  // instructions
  fixup_FT64_branch,
  // fixup_FT64_cmp_branch - 7 bit fixup for symbol references in compressed
  // conditional branch instruction
  fixup_FT64_cmp_branch,
  // fixup_FT64_cmp_branch - 13 bit fixup for symbol references in compressed
  // unconditional branch instruction
  fixup_FT64_cmp_bra,
  // fixup_FT64_cmp_branch - 13 bit fixup for symbol references in compressed
  // call instruction
  fixup_FT64_cmp_call,

  fixup_FT64_relax,

  // fixup_FT64_invalid - used as a sentinel and a marker, must be last fixup
  fixup_FT64_invalid,
  NumTargetFixupKinds = fixup_FT64_invalid - FirstTargetFixupKind
};
} // end namespace FT64
} // end namespace llvm

#endif
