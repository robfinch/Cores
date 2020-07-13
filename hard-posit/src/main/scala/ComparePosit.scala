
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

class ComparePosit(expWidth: Int, posWidth: Int) extends Module
{
  val io = new Bundle {
    val a = Bits(INPUT, posWidth)
    val b = Bits(INPUT, posWidth)
    val lt = Bool(OUTPUT)
    val eq = Bool(OUTPUT)
    val gt = Bool(OUTPUT)
  }

  val rawA = decomposePosit(expWidth, posWidth, io.a)  // for NaR
  val rawB = decomposePosit(expWidth, posWidth, io.b)

  val ordered = ! rawA.isNaR && ! rawB.isNaR

  // The beauty of posits
  val ordered_lt = a.asInt < b.asInt
  val ordered_eq = a === b

  io.lt := ordered && ordered_lt
  io.eq := ordered && ordered_eq
  io.gt := ordered && ! ordered_lt && ! ordered_eq
}
