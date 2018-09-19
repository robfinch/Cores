//===-- FT64MCTargetDesc.cpp - FT64 Target Descriptions -----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
///
/// This file provides FT64-specific target descriptions.
///
//===----------------------------------------------------------------------===//

#include "FT64MCTargetDesc.h"
#include "InstPrinter/FT64InstPrinter.h"
#include "FT64ELFStreamer.h"
#include "FT64MCAsmInfo.h"
#include "FT64TargetStreamer.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/TargetRegistry.h"

#define GET_INSTRINFO_MC_DESC
#include "FT64GenInstrInfo.inc"

#define GET_REGINFO_MC_DESC
#include "FT64GenRegisterInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "FT64GenSubtargetInfo.inc"

using namespace llvm;

static MCInstrInfo *createFT64MCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitFT64MCInstrInfo(X);
  return (X);
}

static MCRegisterInfo *createFT64MCRegisterInfo(const Triple &TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  InitFT64MCRegisterInfo(X, FT64::X1);
  return (X);
}

static MCAsmInfo *createFT64MCAsmInfo(const MCRegisterInfo &MRI,
                                       const Triple &TT) {
  return (new FT64MCAsmInfo(TT));
}

static MCSubtargetInfo *createFT64MCSubtargetInfo(const Triple &TT,
                                                   StringRef CPU, StringRef FS) {
  std::string CPUName = CPU;
  if (CPUName.empty())
    CPUName = TT.isArch64Bit() ? "generic-rv64" : "generic-rv32";
  return (createFT64MCSubtargetInfoImpl(TT, CPUName, FS));
}

static MCInstPrinter *createFT64MCInstPrinter(const Triple &T,
                                               unsigned SyntaxVariant,
                                               const MCAsmInfo &MAI,
                                               const MCInstrInfo &MII,
                                               const MCRegisterInfo &MRI) {
  return (new FT64InstPrinter(MAI, MII, MRI));
}

static MCTargetStreamer *
createFT64ObjectTargetStreamer(MCStreamer &S, const MCSubtargetInfo &STI) {
  const Triple &TT = STI.getTargetTriple();
  if (TT.isOSBinFormatELF())
    return new FT64TargetELFStreamer(S, STI);
  return (nullptr);
}

static MCTargetStreamer *createFT64AsmTargetStreamer(MCStreamer &S,
                                                      formatted_raw_ostream &OS,
                                                      MCInstPrinter *InstPrint,
                                                      bool isVerboseAsm) {
  return (new FT64TargetAsmStreamer(S, OS));
}

extern "C" void LLVMInitializeFT64TargetMC() {
  for (Target *T : {&getTheFT6432Target(), &getTheFT6464Target()}) {
    TargetRegistry::RegisterMCAsmInfo(*T, createFT64MCAsmInfo);
    TargetRegistry::RegisterMCInstrInfo(*T, createFT64MCInstrInfo);
    TargetRegistry::RegisterMCRegInfo(*T, createFT64MCRegisterInfo);
    TargetRegistry::RegisterMCAsmBackend(*T, createFT64AsmBackend);
    TargetRegistry::RegisterMCCodeEmitter(*T, createFT64MCCodeEmitter);
    TargetRegistry::RegisterMCInstPrinter(*T, createFT64MCInstPrinter);
    TargetRegistry::RegisterMCSubtargetInfo(*T, createFT64MCSubtargetInfo);
    TargetRegistry::RegisterObjectTargetStreamer(
        *T, createFT64ObjectTargetStreamer);

    // Register the asm target streamer.
    TargetRegistry::RegisterAsmTargetStreamer(*T, createFT64AsmTargetStreamer);
  }
}
