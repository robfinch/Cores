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

//----------------------------------------------------------------------------
// Multiply and produce a double width significand.
//----------------------------------------------------------------------------

class Muldws(expWidth: Int, posWidth: Int) extends Module
{
  val io = new Bundle {
    val a = Bits(INPUT, posWidth)
    val b = Bits(INPUT, posWidth)
    val p = Bits(OUTPUT, RawPositDblSig(expWidth, posWidth).size)
  }
  val rawA = new rawPositFromBits(expWidth, posWidth, io.a)
  val rawB = new rawPositFromBits(expWidth, posWidth, io.a)
  val rawP = new RawPositDblSig(expWidth, posWidth)
 
  rawP.isNaR  = rawA.isNaR || rawB.isNaR
  rawP.isInf  = rawA.isInf || rawB.isInf
  rawP.isZero = rawA.isZero || rawB.isZero
  rawP.sign   = rawA.sign ^ rawB.sign
  rawP.regexp = rawA.regexp + rawB.regexp
  // Product will be between 1 and 4, may have a leading zero
  if (rawP.isZero) {
    rawP.sig  = 0
    rawP.regexp = 0
    rawP.sign = 0
  }
  else if (rawP.isInf) {
    rawP.sig  = 0
    rawP.regexp = 0
    rawP.sign = 1
  }
  else
    rawP.sig  = rawA.sig * rawB.sig
  if (rawP.sig(rawP.sig.width-1)==UInt(0)) {
    rawP.sig  = rawP.sig << 1
    rawP.regexp = rawP.regexp - 1
  }
  rawP.regime = rawP.regexp(rawP.regime.width+expwidth-1,expwidth)
  rawP.regsign = rawP.regime(rawP.regime.width)
  rawP.exp    = rawP.regexp(expwidth-1,0)
  override def cloneType =
      new Muldws(expWidth, posWidth).asInstanceOf[this.type]
}
