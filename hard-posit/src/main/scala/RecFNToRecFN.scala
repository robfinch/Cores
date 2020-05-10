
/*============================================================================

This Chisel source file is part of a pre-release version of the HardPosit
Arithmetic Package an adpatation of the HardFloat package, by John R. Hauser
(with some contributions
from Yunsup Lee and Andrew Waterman, mainly concerning testing).

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016 The Regents of the
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

class
    RecFNToRecFN(
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
    if (inPosWidth == outPosWidth) {
      io.out := io.in
    }
    else if ((inExpWidth == outExpWidth) && (inSigWidth <= outSigWidth)) {

        //--------------------------------------------------------------------
        //--------------------------------------------------------------------
        io.out            := io.in<<(outSigWidth - inSigWidth)
    } else {

        //--------------------------------------------------------------------
        //--------------------------------------------------------------------
        val roundAnyRawFNToRecFN =
            Module(
                new RoundAnyRawFNToRecFN(
                        inExpWidth,
                        inSigWidth,
                        outExpWidth,
                        outSigWidth,
                        flRoundOpt_sigMSBitAlwaysZero
                    ))
        roundAnyRawFNToRecFN.io.invalidExc     := isSigNaNRawFloat(rawIn)
        roundAnyRawFNToRecFN.io.infiniteExc    := Bool(false)
        roundAnyRawFNToRecFN.io.in             := rawIn
        roundAnyRawFNToRecFN.io.roundingMode   := io.roundingMode
        roundAnyRawFNToRecFN.io.detectTininess := io.detectTininess
        io.out            := roundAnyRawFNToRecFN.io.out
        io.exceptionFlags := roundAnyRawFNToRecFN.io.exceptionFlags
    }
}

