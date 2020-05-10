
/*============================================================================

This Chisel source file is part of a pre-release version of the HardPosit
Arithmetic Package and adpatation of the HardFloat package, by John R. Hauser
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

object rawPositFromFN
{
  def apply(expWidth: Int, posWidth: Int, in: Bits) =
  {
    val sign = in(posWidth - 1)
    val reglen = in(posWidth-2,0).countLeadingBits() + 1
    val regsign = in(posWidth-2)
    val regimeIn = Mux(regsign,reglen,reglen-1)
    val expIn = in(posWidth - reglen -1, posWidth - reglen - expWidth)
    val fractIn = in(posWidth - reglen - expWidth - 1, 0)

    val isZeroExpIn = (expIn === UInt(0))
    val isZeroFractIn = (fractIn === UInt(0))

    val normDist = 0
    val adjustedExp = expIn

    val isZero = in === UInt(0)
    val isSpecial = in(posWidth-1) === UInt(1) && in(posWidth-2,0) === UInt(0)

    val out = Wire(new RawPosit(expWidth, posWidth))
    out.isNaR  := isSpecial
    out.isInf  := isSpecial
    out.isZero := isZero
    out.sign   := sign
    out.regsign := regsign
    out.regime := regimeIn
    out.sExp   := adjustedExp(expWidth, 0).zext
    out.sig    := Cat(UInt(0,1),1,fractIn)
    out
  }
}

