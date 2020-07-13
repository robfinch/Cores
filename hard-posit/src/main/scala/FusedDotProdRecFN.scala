
/*============================================================================

This Chisel source file is part of a pre-release version of the HardPosit
Arithmetic Package an adpatation of the HardFloat package, by John R. Hauser
(with some contributions
from Yunsup Lee and Andrew Waterman, mainly concerning testing).

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 The Regents of the
University of California.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice,
    this list of conditions, and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions, and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

 3. Neither the name of the University nor the names of its contributors may
    be used to endorse or promote products derived from this software without
    specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS "AS IS", AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, ARE
DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=============================================================================*/

package hardposit

import Chisel._
import consts._

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------

class FusedDotProdRecFN_interIo(expWidth: Int, posWidth: Int) extends Bundle
{
    val isNaRAOrB       = Bool()
    val isNaRCOrD       = Bool()
    val isInfA          = Bool()
    val isZeroA         = Bool()
    val isInfB          = Bool()
    val isZeroB         = Bool()
    val isInfC          = Bool()
    val isZeroC         = Bool()
    val isInfD          = Bool()
    val isZeroD         = Bool()
    val signProdAB      = Bool()
    val signProdCD      = Bool()
    val sExpSum         = SInt(width = expWidth + 2)
    val doSubMags       = Bool()
    val CDIsDominant     = Bool()
    val CDDom_CDAlignDist = UInt(width = log2Up((posWidth - expWidth - 2) + 1))
    val highAlignedSigCD = UInt(width = (posWidth - expWidth - 2) + 2)
    val bit0AlignedSigCD = UInt(width = 1)

    override def cloneType =
        new FusedDotProdRecFN_interIo(
                expWidth, posWidth).asInstanceOf[this.type]
}

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
class FusedDotProd_preMul(expWidth: Int, posWidth: Int) extends Module
{
  val sigWidth = posWidth - expWidth - 2;
  val io = new Bundle {
    val op = Bits(INPUT, 2)
    val a = Bits(INPUT, posWidth)
    val b = Bits(INPUT, posWidth)
    val c = Bits(INPUT, posWidth)
    val d = Bits(INPUT, posWidth)
    val mulAddA = UInt(OUTPUT, sigWidth)
    val mulAddB = UInt(OUTPUT, sigWidth)
    val mulAddC = UInt(OUTPUT, sigWidth)
    val mulAddD = UInt(OUTPUT, sigWidth)
    val toPostFDP = new FusedDotProdRecFN_interIo(expWidth, posWidth).asOutput
  }

  //------------------------------------------------------------------------
  //------------------------------------------------------------------------
//*** POSSIBLE TO REDUCE THIS BY 1 OR 2 BITS?  (CURRENTLY 2 BITS BETWEEN
//***  UNSHIFTED C AND PRODUCT):
  val sigSumWidth = sigWidth * 3 + 3

  //------------------------------------------------------------------------
  //------------------------------------------------------------------------
  val rawA = rawPositFromBits(expWidth, posWidth, io.a)
  val rawB = rawPositFromBits(expWidth, posWidth, io.b)
  val rawC = rawPositFromBits(expWidth, posWidth, io.c)
  val rawD = rawPositFromBits(expWidth, posWidth, io.d)

  val signProdAB = rawA.sign ^ rawB.sign ^ io.op(1)
  val signProdCD = rawC.sign ^ rawD.sign
//*** REVIEW THE BIAS FOR 'sExpAlignedProd':
  val rgma = Mux(rawA.regsign,rawA.regime,-rawA.regime)
  val rgmb = Mux(rawB.regsign,rawB.regime,-rawB.regime)
  val rgmc = Mux(rawC.regsign,rawC.regime,-rawC.regime)
  val rgmd = Mux(rawD.regsign,rawD.regime,-rawD.regime)
  val expa = Cat(rgma,rawA.sExp)
  val expb = Cat(rgmb,rawB.sExp)
  val expc = Cat(rgmc,rawC.sExp)
  val expd = Cat(rgmd,rawD.sExp)

  val expProdAB = expa +& expb
  val expProdCD = expc +& expd

  val doSubMags = signProdAB ^ signProdCD ^ io.op(0)

  //------------------------------------------------------------------------
  //------------------------------------------------------------------------
  
  val sNatCAlignDist = expProdAB - expProdCD
  val posNatCAlignDist = sNatCAlignDist(expWidth + 1, 0)
  val isMinCAlign = rawA.isZero || rawB.isZero || (sNatCAlignDist < SInt(0))
  val CIsDominant =
      ! rawC.isZero && (isMinCAlign || (posNatCAlignDist <= UInt(sigWidth)))
  val CAlignDist =
      Mux(isMinCAlign,
          UInt(0),
          Mux(posNatCAlignDist < UInt(sigSumWidth - 1),
              posNatCAlignDist(log2Up(sigSumWidth) - 1, 0),
              UInt(sigSumWidth - 1)
          )
      )
  val mainAlignedSigC =
      Cat(Mux(doSubMags, ~rawC.sig, rawC.sig),
          Fill(sigSumWidth - sigWidth + 2, doSubMags)
      ).asSInt>>CAlignDist
  val reduced4CExtra =
      (orReduceBy4(rawC.sig<<((sigSumWidth - sigWidth - 1) & 3)) &
           lowMask(
               CAlignDist>>2,
//*** NOT NEEDED?:
//                 (sigSumWidth + 2)>>2,
               (sigSumWidth - 1)>>2,
               (sigSumWidth - sigWidth - 1)>>2
           )
      ).orR
  val alignedSigC =
      Cat(mainAlignedSigC>>3,
          Mux(doSubMags,
              mainAlignedSigC(2, 0).andR && ! reduced4CExtra,
              mainAlignedSigC(2, 0).orR  ||   reduced4CExtra
          )
      )

    //------------------------------------------------------------------------
    //------------------------------------------------------------------------
    io.FDPA := rawA.sig
    io.FDPB := rawB.sig
    io.FDPC := rawC.sig
    io.FDPD := rawD.sig
    io.FDPE := alignedSigC(sigWidth * 2, 1)

    io.toPostMul.isSigNaNAny :=
        isSigNaNRawFloat(rawA) || isSigNaNRawFloat(rawB) ||
            isSigNaNRawFloat(rawC)
    io.toPostMul.isNaRAOrB := rawA.isNaR || rawB.isNaR
    io.toPostMul.isNaRCOrD := rawC.isNaR || rawD.isNaR
    io.toPostMul.isInfA    := rawA.isInf
    io.toPostMul.isZeroA   := rawA.isZero
    io.toPostMul.isInfB    := rawB.isInf
    io.toPostMul.isZeroB   := rawB.isZero
    io.toPostMul.isInfC    := rawC.isInf
    io.toPostMul.isZeroC   := rawC.isZero
    io.toPostMul.isInfD    := rawD.isInf
    io.toPostMul.isZeroD   := rawD.isZero
    io.toPostMul.signProdAB  := signProdAB
    io.toPostMul.signProdCD  := signProdCD
    io.toPostMul.isNaNR    := rawE.isNaR
    io.toPostMul.isInfE    := rawE.isInf
    io.toPostMul.isZeroE   := rawE.isZero
    io.toPostMul.sExpSum   :=
        Mux(CIsDominant, rawC.sExp, sExpAlignedProd - SInt(sigWidth))
    io.toPostMul.doSubMags := doSubMags
    io.toPostMul.CIsDominant := CIsDominant
    io.toPostMul.CDom_CAlignDist := CAlignDist(log2Up(sigWidth + 1) - 1, 0)
    io.toPostMul.highAlignedSigC :=
        alignedSigC(sigSumWidth - 1, sigWidth * 2 + 1)
    io.toPostMul.bit0AlignedSigC := alignedSigC(0)
}

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
class FusedDotProdRecFNToRaw_postMul(expWidth: Int, posWidth: Int) extends Module
{
  val sigWidth = posWidth - expWidth - 2
  val io = new Bundle {
    val fromPreMul = new FusedDotProdRecFN_interIo(expWidth, posWidth).asInput
    val FusedDotProdResult = UInt(INPUT, sigWidth * 2 + 1)
    val roundingMode = UInt(INPUT, 3)
    val invalidExc  = Bool(OUTPUT)
    val rawOut = new RawPosit(expWidth, sigWidth + 2).asOutput
  }

  //------------------------------------------------------------------------
  //------------------------------------------------------------------------
  val sigSumWidth = sigWidth * 3 + 3

  //------------------------------------------------------------------------
  //------------------------------------------------------------------------
  val roundingMode_min = (io.roundingMode === round_min)

  //------------------------------------------------------------------------
  //------------------------------------------------------------------------
  val opSignC = io.fromPreMul.signProdCD ^ io.fromPreMul.doSubMags
  val sigSum =
      Cat(Mux(io.FusedDotProdResult(sigWidth * 2),
              io.fromPreMul.highAlignedSigC + UInt(1),
              io.fromPreMul.highAlignedSigC
             ),
          io.FusedDotProdResult(sigWidth * 2 - 1, 0),
          io.fromPreMul.bit0AlignedSigC
      )

  //------------------------------------------------------------------------
  //------------------------------------------------------------------------
  val CDom_sign = opSignC
  val CDom_sExp = io.fromPreMul.sExpSum - io.fromPreMul.doSubMags.zext
  val CDom_absSigSum =
      Mux(io.fromPreMul.doSubMags,
          ~sigSum(sigSumWidth - 1, sigWidth + 1),
          Cat(UInt(0, 1),
//*** IF GAP IS REDUCED TO 1 BIT, MUST REDUCE THIS COMPONENT TO 1 BIT TOO:
              io.fromPreMul.highAlignedSigC(sigWidth + 1, sigWidth),
              sigSum(sigSumWidth - 3, sigWidth + 2)
          )
      )
  val CDom_absSigSumExtra =
      Mux(io.fromPreMul.doSubMags,
          (~sigSum(sigWidth, 1)).orR,
          sigSum(sigWidth + 1, 1).orR
      )
  val CDom_mainSig =
      (CDom_absSigSum<<io.fromPreMul.CDom_CAlignDist)(
          sigWidth * 2 + 1, sigWidth - 3)
  val CDom_reduced4SigExtra =
      (orReduceBy4(CDom_absSigSum(sigWidth - 1, 0)<<(~sigWidth & 3)) &
           lowMask(io.fromPreMul.CDom_CAlignDist>>2, 0, sigWidth>>2)).orR
  val CDom_sig =
      Cat(CDom_mainSig>>3,
          CDom_mainSig(2, 0).orR || CDom_reduced4SigExtra ||
              CDom_absSigSumExtra
      )

  //------------------------------------------------------------------------
  //------------------------------------------------------------------------
  val notCDom_signSigSum = sigSum(sigWidth * 2 + 3)
  val notCDom_absSigSum =
      Mux(notCDom_signSigSum,
          ~sigSum(sigWidth * 2 + 2, 0),
          sigSum(sigWidth * 2 + 2, 0) + io.fromPreMul.doSubMags
      )
  val notCDom_reduced2AbsSigSum = orReduceBy2(notCDom_absSigSum)
  val notCDom_normDistReduced2 = countLeadingZeros(notCDom_reduced2AbsSigSum)
  val notCDom_nearNormDist = notCDom_normDistReduced2<<1
  val notCDom_sExp = io.fromPreMul.sExpSum - notCDom_nearNormDist.zext
  val notCDom_mainSig =
      (notCDom_absSigSum<<notCDom_nearNormDist)(
          sigWidth * 2 + 3, sigWidth - 1)
  val notCDom_reduced4SigExtra =
      (orReduceBy2(
           notCDom_reduced2AbsSigSum(sigWidth>>1, 0)<<((sigWidth>>1) & 1)) &
           lowMask(notCDom_normDistReduced2>>1, 0, (sigWidth + 2)>>2)
      ).orR
  val notCDom_sig =
      Cat(notCDom_mainSig>>3,
          notCDom_mainSig(2, 0).orR || notCDom_reduced4SigExtra
      )
  val notCDom_completeCancellation =
      (notCDom_sig(sigWidth + 2, sigWidth + 1) === UInt(0))
  val notCDom_sign =
      Mux(notCDom_completeCancellation,
          roundingMode_min,
          io.fromPreMul.signProd ^ notCDom_signSigSum
      )

  //------------------------------------------------------------------------
  //------------------------------------------------------------------------
  val notNaN_isInfProd = io.fromPreMul.isInfA || io.fromPreMul.isInfB
  val notNaN_isInfOut = notNaN_isInfProd || io.fromPreMul.isInfC
  val notNaN_addZeros =
      (io.fromPreMul.isZeroA || io.fromPreMul.isZeroB) &&
          io.fromPreMul.isZeroC

  io.invalidExc :=
      io.fromPreMul.isSigNaNAny ||
      (io.fromPreMul.isInfA && io.fromPreMul.isZeroB) ||
      (io.fromPreMul.isZeroA && io.fromPreMul.isInfB) ||
      (! io.fromPreMul.isNaNAOrB &&
           (io.fromPreMul.isInfA || io.fromPreMul.isInfB) &&
           io.fromPreMul.isInfC &&
           io.fromPreMul.doSubMags)
  io.rawOut.isNaR := io.fromPreMul.isNaRAOrB || io.fromPreMul.isNaRCOrD
  io.rawOut.isInf := notNaN_isInfOut
//*** IMPROVE?:
  io.rawOut.isZero :=
      notNaN_addZeros ||
          (! io.fromPreMul.CIsDominant && notCDom_completeCancellation)
  io.rawOut.sign :=
      (notNaN_isInfProd && io.fromPreMul.signProd) ||
      (io.fromPreMul.isInfC && opSignC) ||
      (notNaN_addZeros && ! roundingMode_min &&
          io.fromPreMul.signProd && opSignC) ||
      (notNaN_addZeros && roundingMode_min &&
          (io.fromPreMul.signProd || opSignC)) ||
      (! notNaN_isInfOut && ! notNaN_addZeros &&
           Mux(io.fromPreMul.CIsDominant, CDom_sign, notCDom_sign))
  io.rawOut.sExp := Mux(io.fromPreMul.CIsDominant, CDom_sExp, notCDom_sExp)
  io.rawOut.sig := Mux(io.fromPreMul.CIsDominant, CDom_sig, notCDom_sig)
}

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------

class FusedDotProd(expWidth: Int, posWidth: Int) extends Module
{
  val io = new Bundle {
    val op = Bits(INPUT, 2)
    val a = Bits(INPUT, posWidth)
    val b = Bits(INPUT, posWidth)
    val c = Bits(INPUT, posWidth)
    val d = Bits(INPUT, posWidth)
    val roundingMode   = UInt(INPUT, 3)
    val detectTininess = UInt(INPUT, 1)
    val out = Bits(OUTPUT, posWidth)
    val exceptionFlags = Bits(OUTPUT, 5)
  }

  //------------------------------------------------------------------------
  //------------------------------------------------------------------------
  val FusedDotProd_preMul =
      Module(new FusedDotProd_preMul(expWidth, posWidth))
  val FusedDotProd_postMul =
      Module(new FusedDotProd_postMul(expWidth, posWidth))

  FusedDotProdRecFNToRaw_preMul.io.op := io.op
  FusedDotProdRecFNToRaw_preMul.io.a  := io.a
  FusedDotProdRecFNToRaw_preMul.io.b  := io.b
  FusedDotProdRecFNToRaw_preMul.io.c  := io.c
  FusedDotProdRecFNToRaw_preMul.io.d  := io.d

  val FusedDotProdResult =
    (FusedDotProd_preMul.io.mulAddA *
       FusedDotProd_preMul.io.mulAddB) +&
    (FusedDotProdRec_preMul.io.mulAddC *
       FusedDotProd_preMul.io.mulAddD)

  FusedDotProdRecFNToRaw_postMul.io.fromPreMul :=
      FusedDotProdRecFNToRaw_preMul.io.toPostMul
  FusedDotProdRecFNToRaw_postMul.io.FusedDotProdResult := FusedDotProdResult
  FusedDotProdRecFNToRaw_postMul.io.roundingMode := io.roundingMode

  //------------------------------------------------------------------------
  //------------------------------------------------------------------------
  val roundRawFNToRecFN =
      Module(new RoundRawFNToRecFN(expWidth, posWidth, 0))
  roundRawFNToRecFN.io.invalidExc   := FusedDotProdRecFNToRaw_postMul.io.invalidExc
  roundRawFNToRecFN.io.infiniteExc  := Bool(false)
  roundRawFNToRecFN.io.in           := FusedDotProdRecFNToRaw_postMul.io.rawOut
  roundRawFNToRecFN.io.roundingMode := io.roundingMode
  roundRawFNToRecFN.io.detectTininess := io.detectTininess
  io.out            := roundRawFNToRecFN.io.out
  io.exceptionFlags := roundRawFNToRecFN.io.exceptionFlags
}

