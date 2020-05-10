
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

/*----------------------------------------------------------------------------
| In the result, no more than one of 'isNaN', 'isInf', and 'isZero' will be
| set.
*----------------------------------------------------------------------------*/
object rawPositFromBits
{
  def apply(expWidth: Int, posWidth: Int, in: Bits): RawPosit =
  {
    val n = Mux(in(posWidth-1),-in,in)
    val rgmlen = countLeadingBits(n(posWidth-2,0)) + 1
    val exp = n(posWidth - rgmlen - 1, posWidth - rgmlen - expWidth)

    val out = Wire(new RawPosit(expWidth, posWidth))
    out.isNaR  := in(posWidth-1) === UInt(1) && in(posWidth-2,0)===UInt(0)
    out.isInf  := in(posWidth-1) === UInt(1) && in(posWidth-2,0)===UInt(0)
    out.isZero := in(posWidth-1,0) === UInt(0))
    out.sign   := in(posWidth-1)
    out.exp    := exp.zext
    out.regsign := n(posWidth-2)
    out.regime := Mux(n(posWidth-2),rgmlen,rgmlen-1)
    out.regexp := Cat(Mux(n(posWidth-2),-rgmlen,rgmlen-1),exp.zext)
    out.sigWidth := Max(0,posWidth - rgmlen - expWidth)
    if (posWidth - rgmlen - expWidth - 1 >= 0)
      out.sig  := n(posWidth - rgmlen - expWidth - 1,0)
    else
      out.sig  := 1
    out
  }
}

