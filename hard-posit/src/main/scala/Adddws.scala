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
// Add double width significands.
//----------------------------------------------------------------------------

class Adddws(expWidth: Int, posWidth: Int) extends Module
{
  val io = new Bundle {
    val op = Bits(INPUT, 1)
    val a = Bits(INPUT, RawPositDblSig(expWidth, posWidth).size)
    val b = Bits(INPUT, RawPositDblSig(expWidth, posWidth).size)
    val c = Bits(OUTPUT, posWidth)
  }
  val rs = log2Ceil(posWidth-1)-1
  val es = expWidth
  val pa = new rawPositFromBits(expWidth,RawPositDblSig(expWidth, posWidth).size,io.a)
  val pb = new rawPositFromBits(expWidth,RawPositDblSig(expWidth, posWidth).size,io.b)
  val aa = pa.sign ? -io.a : io.a
  val bb = pb.sign ? -io.b : io.b
  val aa_gt_bb = aa.asInt >= bb.asInt
  // Determine op really wanted
  val rop = pa.sign ^ pb.sign ^ io.op
  // Sort operand components
  val rgs1 = if (aa_gt_bb) pa.regsign else pb.regsign
  val rgs2 = if (aa_gt_bb) pb.regsign else pa.regsign
  val rgm1 = if (aa_gt_bb) pa.regime else pb.regime
  val rgm2 = if (aa_gt_bb) pb.regime else pa.regime
  val exp1 = if (aa_gt_bb) pa.exp else pb.exp
  val exp2 = if (aa_gt_bb) pb.exp else pa.exp
  val sig1 = if (aa_gt_bb) pa.sig else pb.sig 
  val sig2 = if (aa_gt_bb) pb.sig else pa.sig

  val argm1 = if (rgs1) rgm1 else -rgm1
  val argm2 = if (rgs2) rgm2 else -rgm2

  val diff = Cat(argm1,exp1) - Cat(argm2,exp2)
  val exp_diff = diff(es+rs,rs).orR ? Int(-1,rs) : diff(rs-1,0);
  val sig2s = Cat(sig2(pa.sigWidth-1),Cat(sig2,UInt(0,posWidth))) >> exp_diff;
  val sig1s = Cat(sig1(pa.sigWidth-1),Cat(sig1,UInt(0,posWidth)));
  val sig_sd = rop ? sig1s - sig2s : sig1s + sig2s;
  val sigov = sig_sd(pa.sigWidth+posWidth,pa.sigWidth+posWidth-1);
  val sig_sd1 = Cat(sigov.orR,sig_sd(pa.sigWidth+posWidth,pa-1.sigWidth+posWidth-2))
  // Re-align significand
  val lzcnt = countLeadingZeros(sig_sd1)
  val sigls = Cat(UInt(0,posWidth),sig_sd) << lzcnt

  val rxtmp = Int(0,es+rs+2);
  val arxtmp = Int(0,es+rs+2);
  val rxtmp1 = Int(0,es+rs+2);
  val srxtmp1 = Int(0,1)
  val expo = Int(0,es)
  val rgmo = Int(0,rs+1)
  if (es > 0) {
    rxtmp = Cat(argm1,exp1) - Cat(UInt(0,es+1),lzcnt-es)
    rxtmp1 = rxtmp + sigov(1) // add in overflow if any
    srxtmp1 = rxtmp1(es+rs+1)
    arxtmp = if (srxtmp1) -rxtmp1 else rxtmp1
    expo = if (srxtmp1 & arxtmp(es-1,0).orR) rxtmp1(es-1,0) else arxtmp(es-1,0)
    rgmo = (~srxtmp1 || (srxtmp1 & |arxtmp(es-1,0).orR)) ? arxtmp(es+rs:es) + 1 : arxtmp(es+rs,es)
  }
  else {
    rxtmp = argm1 - Cat(UInt(0,1),lzcnt)
    rxtmp1 = rxtmp + sigov(1) // add in overflow if any
    srxtmp1 = rxtmp1(rs+1)
    arxtmp = if (srxtmp1) -rxtmp1 else rxtmp1
    expo = UInt(0,1);
    rgmo = (~srxtmp1) ? arxtmp(rs,0) + 1 : arxtmp(rs,0);
  }

  val tmp = UInt(0,posWidth*2-1+4)
  val srxtmp2 = if (srxtmp1) Cat(Int(0,posWidth),srxtmp1) else Cat(Int(-1,posWidth),srxtmp1)

  if (es == 0) {
    tmp = Cat(Cat(srxtmp2,sigls(posWidth*2-2,posWidth-2)),sigls(posWidth-3,0).orR)
  }
  else if (es==1) {
    tmp = Cat(Cat(Cat(srxtmp2,expo),sigls(posWidth*2-2,posWidth-1)),sigls(posWidth-2,0).orR)
  }
  else if (es==2) {
    tmp = Cat(Cat(Cat(srxtmp2,expo),sigls(posWidth*2-2,posWidth)),sigls(posWidth-1,0).orR)
  }
  else {
    tmp = Cat(Cat(Cat(srxtmp2,expo),sigls(posWidth*2-2,posWidth+es-2)),sigls(posWidth-1+es-2,0).orR)
  }

  val tmp1 = Cat(tmp,UInt(0,posWidth)) >> rgmo

  // Rounding
  // LSB, Guard, Round, and Sticky
  val L = tmp1(posWidth+4)
  val G = tmp1(posWdith+3),
  val R = tmp1(posWidth+2),
  val St = |tmp1(posWidth+1,0).orR
  val ulp =  ((G & (R | St)) | (L & G & ~(R | St)))
  val rnd_ulp = Cat(UInt(0,posWidth-1),ulp)

  val tmp1_rnd_ulp = tmp1(2*posWidth-1+3:posWidth+3) + rnd_ulp
  val tmp1_rnd = if (rgmo < posWidth-es-2) tmp1_rnd_ulp(posWidth-1,0) else tmp1(posWidth*2-1+3,posWidth+3)

  // Compute output sign
  val so = Cat(Cat(Cat(zero,sa),op),sb) match {
    case 0: => 0          // + + + = +
    case 1: => !aa_gt_bb  // + + - = sign of larger
    case 2: => !aa_gt_bb  // + - + = sign of larger
    case 3: => 0          // + - - = +
    case 4: => aa_gt_bb   // - + + = sign of larger
    case 5: => 1          // - + - = -
    case 6: => 1          // - - + = -
    case 7: => aa_gt_bb   // - - - = sign of larger
    case _: => 0
  }

  val abs_tmp = so ? -tmp1_rnd : tmp1_rnd;

  io.c = Cat(Cat(zero,inf),sigls(posWidth)) match {
    case 0: => Cat(so,abs_tmp(posWidth-1,1))
    case 2: => Cat(UInt(1,1),UInt(0,posWidth-1))
    case 3: => Cat(UInt(1,1),UInt(0,posWidth-1))
    case _: => UInt(0,posWidth)
  }
}
