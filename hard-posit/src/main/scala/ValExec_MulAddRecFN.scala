
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

class ValExec_MulAddRecFN(expWidth: Int, posWidth: Int) extends Module
{
    val io = new Bundle {
        val a = Bits(INPUT, posWidth - 1)
        val b = Bits(INPUT, posWidth - 1)
        val c = Bits(INPUT, posWidth - 1)
        val roundingMode   = UInt(INPUT, 3)
        val detectTininess = UInt(INPUT, 1)

        val expected = new Bundle {
            val out = Bits(INPUT, posWidth - 1)
            val exceptionFlags = Bits(INPUT, 5)
            val recOut = Bits(OUTPUT, posWidth)
        }

        val actual = new Bundle {
            val out = Bits(OUTPUT, posWidth)
            val exceptionFlags = Bits(OUTPUT, 5)
        }

        val check = Bool(OUTPUT)
        val pass = Bool(OUTPUT)
    }

    val mulAddRecFN = Module(new MulAddRecFN(expWidth, posWidth))
    mulAddRecFN.io.op := UInt(0)
    mulAddRecFN.io.a := recFNFromFN(expWidth, posWidth, io.a)
    mulAddRecFN.io.b := recFNFromFN(expWidth, posWidth, io.b)
    mulAddRecFN.io.c := recFNFromFN(expWidth, posWidth, io.c)
    mulAddRecFN.io.roundingMode   := io.roundingMode
    mulAddRecFN.io.detectTininess := io.detectTininess

    io.expected.recOut := recFNFromFN(expWidth, posWidth, io.expected.out)

    io.actual.out := mulAddRecFN.io.out
    io.actual.exceptionFlags := mulAddRecFN.io.exceptionFlags

    io.check := Bool(true)
    io.pass :=
        equivRecFN(expWidth, sigWidth, io.actual.out, io.expected.recOut) &&
        (io.actual.exceptionFlags === io.expected.exceptionFlags)
}

class ValExec_MulAddRecF16 extends ValExec_MulAddRecFN(2, 16)
class ValExec_MulAddRecF32 extends ValExec_MulAddRecFN(3, 32)
class ValExec_MulAddRecF64 extends ValExec_MulAddRecFN(4, 64)

class ValExec_MulAddRecFN_add(expWidth: Int, posWidth: Int) extends Module
{
    val io = new Bundle {
        val a = Bits(INPUT, posWidth - 1)
        val b = Bits(INPUT, posWidth - 1)
        val roundingMode   = UInt(INPUT, 3)
        val detectTininess = UInt(INPUT, 1)

        val expected = new Bundle {
            val out = Bits(INPUT, posWidth - 1)
            val exceptionFlags = Bits(INPUT, 5)
            val recOut = Bits(OUTPUT, posWidth)
        }

        val actual = new Bundle {
            val out = Bits(OUTPUT, posWidth)
            val exceptionFlags = Bits(OUTPUT, 5)
        }

        val check = Bool(OUTPUT)
        val pass = Bool(OUTPUT)
    }

    val mulAddRecFN = Module(new MulAddRecFN(expWidth, posWidth))
    mulAddRecFN.io.op := UInt(0)
    mulAddRecFN.io.a := recFNFromFN(expWidth, posWidth, io.a)
    mulAddRecFN.io.b := UInt(BigInt(1)<<(expWidth + sigWidth - 1))  // Fix this
    mulAddRecFN.io.c := recFNFromFN(expWidth, posWidth, io.b)
    mulAddRecFN.io.roundingMode   := io.roundingMode
    mulAddRecFN.io.detectTininess := io.detectTininess

    io.expected.recOut := recFNFromFN(expWidth, posWidth, io.expected.out)

    io.actual.out := mulAddRecFN.io.out
    io.actual.exceptionFlags := mulAddRecFN.io.exceptionFlags

    io.check := Bool(true)
    io.pass :=
        equivRecFN(expWidth, sigWidth, io.actual.out, io.expected.recOut) &&
        (io.actual.exceptionFlags === io.expected.exceptionFlags)
}

class ValExec_MulAddRecF16_add extends ValExec_MulAddRecFN_add(2, 16)
class ValExec_MulAddRecF32_add extends ValExec_MulAddRecFN_add(3, 32)
class ValExec_MulAddRecF64_add extends ValExec_MulAddRecFN_add(4, 64)

class ValExec_MulAddRecFN_mul(expWidth: Int, posWidth: Int) extends Module
{
    val io = new Bundle {
        val a = Bits(INPUT, posWidth - 1)
        val b = Bits(INPUT, posWidth - 1)
        val roundingMode   = UInt(INPUT, 3)
        val detectTininess = UInt(INPUT, 1)

        val expected = new Bundle {
            val out = Bits(INPUT, posWidth - 1)
            val exceptionFlags = Bits(INPUT, 5)
            val recOut = Bits(OUTPUT, posWidth)
        }

        val actual = new Bundle {
            val out = Bits(OUTPUT, posWidth)
            val exceptionFlags = Bits(OUTPUT, 5)
        }

        val check = Bool(OUTPUT)
        val pass = Bool(OUTPUT)
    }

    val mulAddRecFN = Module(new MulAddRecFN(expWidth, posWidth))
    mulAddRecFN.io.op := UInt(0)
    mulAddRecFN.io.a := recFNFromFN(expWidth, posWidth, io.a)
    mulAddRecFN.io.b := recFNFromFN(expWidth, posWidth, io.b)
    mulAddRecFN.io.c :=
        ((io.a ^ io.b) & UInt(BigInt(1)<<(expWidth + sigWidth - 1)))<<1 // Fix this line
    mulAddRecFN.io.roundingMode   := io.roundingMode
    mulAddRecFN.io.detectTininess := io.detectTininess

    io.expected.recOut := recFNFromFN(expWidth, posWidth, io.expected.out)

    io.actual.out := mulAddRecFN.io.out
    io.actual.exceptionFlags := mulAddRecFN.io.exceptionFlags

    io.check := Bool(true)
    io.pass :=
        equivRecFN(expWidth, sigWidth, io.actual.out, io.expected.recOut) &&
        (io.actual.exceptionFlags === io.expected.exceptionFlags)
}

class ValExec_MulAddRecF16_mul extends ValExec_MulAddRecFN_mul(2, 16)
class ValExec_MulAddRecF32_mul extends ValExec_MulAddRecFN_mul(3, 32)
class ValExec_MulAddRecF64_mul extends ValExec_MulAddRecFN_mul(4, 64)

