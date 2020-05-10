
/*============================================================================

This Chisel source file is part of a pre-release version of the HardPosit
Arithmetic Package by Robert Finch an adpatation of the HardFloat package,
by John R. Hauser

Copyright (c) 2020 Robert Finch
All rights reserved.

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

class
  PositToPosit(
    inExpWidth: Int, inPosWidth: Int, outExpWidth: Int, outPosWidth: Int)
  extends Module
{
  val io = new Bundle {
    val in = Bits(INPUT, inPosWidth)
    val roundingMode   = UInt(INPUT, 3)
    val detectTininess = UInt(INPUT, 1)
    val out = Bits(OUTPUT, outPosWidth)
    val exceptionFlags = Bits(OUTPUT, 5)
  }

  //------------------------------------------------------------------------
  //------------------------------------------------------------------------
  val rawIn = rawPositFromBits(inExpWidth, inPosWidth, io.in);
  // Input and output the same?
  if (inPosWidth == outPosWidth && inExpWidth==outExpWidth) {
    io.out := io.in
  }
  // Since we are basically copying input to output, if the exponents are
  // the same size the regimes will be too. If output is larger than input
  // the only difference is in the significand size which is padded with
  // zeros.
  else if ((inExpWidth == outExpWidth) && (inSigWidth <= outSigWidth)) {
    io.out := io.in<<(outSigWidth - inSigWidth)
  }
  // The complex case.
  else {
    val o2
    val out = Wire(new RawPosit(outExpWidth, outPosWidth))
    val rx = Cat(rawIn.regime,rawIn.exp)
    val sig = rawIn.sig
    out.exp = rx(outExpWidth-1,0)
    out.regsign = rawIn.regsign
    out.regime = rx(rawIn.regime.width + rawIn.exp.width - 1,rawIn.exp.width)
    out.sigWidth = Max(0,outPosWidth - outExpWidth - Mux(out.regsign,out.regime+2,out.regime+1))
    // If output significand is larger or same size as input, no need to round. just copy.
    if (out.sigWidth >= in.sigWidth) {
      out.sig = in.sig << (out.sigWidth - in.sigWidth)
      o2 = Cat(setLeadingBits(out.regsign,out.regime),out.exp,out.sig)
    }
    else {
      val L = Cat(in.sig,UInt(0,3))(in.sigWidth - out.sigWidth+3)
      val G = Cat(in.sig,UInt(0,3))(in.sigWidth - out.sigWidth+2)
      val R = Cat(in.sig,UInt(0,3))(in.sigWidth - out.sigWidth+1)
      val S = Cat(in.sig,UInt(0,3))(in.sigWidth - out.sigWidth,0).orR
      val ulp = ((G & (R | S)) | (L & G & ~(R | S)));
      val rnd_ulp = Cat(UInt(0,outPosWidth-1),ulp(0,0))
      out.sig = in.sig(in.sigWidth - 1,in.sigWidth - out.sigWidth)
      o2 = Cat(setLeadingBits(out.regsign,out.regime),out.exp,out.sig) + rnd_ulp
    }
    io.out := Cat(in.sign,in.sign ? -o2(outPosWidth-2,0) : o2(outPosWidth-2,0))
  }
  io.out
}
