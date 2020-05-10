
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

object rawPositFromIN
{
  def apply(signedIn: Bool, in: Bits): RawPosit =
  {
    val sign := signedIn && in(in.getWidth - 1)
    val absIn := Mux(sign, -in.asUInt, in.asUInt)

    val extIntWidth
    val posWidth
    val regsign
    val regime
    val expWidth
    val exp
    val sigWidth

    if (in.getWidth < 9) {
      extIntWidth := 8
      sigWidth := UInt(8)
    }
    else if (in.getWidth < 17) {
      extIntWidth := 16
      sigWidth := UInt(16)
    }
    else if (in.getWidth < 33) {
      extIntWidth := 32
      sigWidth := UInt(32)
    }
    else if (in.getWidth < 65) {
      extIntWidth := 64
      sigWidth := UInt(64)
    }
    else {
      extIntWidth = in.getWidth
      sigWidth = in.getWidth
    }

    val extAbsIn := Cat(UInt(0,extIntWidth),absIn)(extIntWidth-1, 0)
    val adjustedNormDist := countLeadingZeros(extAbsIn)
    val sig := (extAbsIn<<adjustedNormDist)(extIntWidth-1, extIntWidth - in.getWidth)
    val tz := PriorityEncoder(sig)  // count trailing zeros

    // Attempt to fit into a standard size posit
    sigWidth := sig.width - tz
    regime := -adjustedNormDist
    val canFitIn8 = (sigWidth + regime + 2 + 1) <= 8
    regime := -(adjustedNormDist >> 1)
    val canFitIn16 = (sigWidth + regime + 2 + 1 + 1) <= 16
    regime := -(adjustedNormDist >> 2)
    val canFitIn32 = (sigWidth + regime + 2 + 1 + 2) <= 32
    regime := -(adjustedNormDist >> 3)
    val canFitIn64 = (sigWidth + regime + 2 + 1 + 3) <= 64

    if (canFitIn8) {
      exp := UInt(0)
      expWidth := UInt(0)
      regsign := if (adjustedNormDist > 0) UInt(0,1) else UInt(1,1)
      regime := -adjustedNormDist
      posWidth := UInt(8)
    }
    else if (canFitIn16) {
      exp := UInt(adjustedNormDist & 1,1)
      expWidth := UInt(1)
      regsign := if ((adjustedNormDist >> 1) > 0) UInt(0,1) else UInt(1,1)
      regime = -(adjustedNormDist >> 1)
      posWidth := UInt(16)
    }
    else if (canFitIn32) {
      exp := UInt(adjustedNormDist & 3,2)
      expWidth := UInt(2)
      regsign := if ((adjustedNormDist >> 2) > 0) UInt(0,1) else UInt(1,1)
      regime = -(adjustedNormDist >> 2)
      posWidth := UInt(32)
    }
    else if (canFitIn64) {
      exp := UInt(adjustedNormDist & 7,3)
      expWidth := UInt(3)
      regsign := if ((adjustedNormDist >> 3) > 0) UInt(0,1) else UInt(1,1)
      regime = -(adjustedNormDist >> 3)
      posWidth := UInt(64)
    }
    else {
      exp := UInt(adjustedNormDist & 15,4)
      expWidth := UInt(4)
      regsign := if ((adjustedNormDist >> 4) > 0) UInt(0,1) else UInt(1,1)
      regime = -(adjustedNormDist >> 4)
      posWidth := sigWidth + adjustedNormDist + 1 + 1 + expWidth
    }
    sig := sig(sig.width-1,tz)

    val out = Wire(new RawPosit(expWidth, posWidth))
    out.isNaR := Bool(false)
    out.isInf := Bool(false)
    out.isZero := in.asUInt === UInt(0)
    out.sign := sign
    out.regsign := regsign
    out.regime := regime
    out.exp   := exp
    out.sigWidth := sigWidth
    out.sig    := sig
    out
  }
}
