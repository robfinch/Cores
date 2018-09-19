//===-- FT64.h - Top-level interface for FT64 -----------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the entry points for global functions defined in the LLVM
// FT64 back-end.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_FT64_FT64_H
#define LLVM_LIB_TARGET_FT64_FT64_H

#include "MCTargetDesc/FT64BaseInfo.h"

namespace llvm {
class FT64TargetMachine;
class AsmPrinter;
class FunctionPass;
class MCInst;
class MCOperand;
class MachineInstr;
class MachineOperand;
class PassRegistry;

void LowerFT64MachineInstrToMCInst(const MachineInstr *MI, MCInst &OutMI,
                                    const AsmPrinter &AP);
bool LowerFT64MachineOperandToMCOperand(const MachineOperand &MO,
                                         MCOperand &MCOp, const AsmPrinter &AP);

FunctionPass *createFT64ISelDag(FT64TargetMachine &TM);

FunctionPass *createFT64MergeBaseOffsetOptPass();
void initializeFT64MergeBaseOffsetOptPass(PassRegistry &);
}

#endif
