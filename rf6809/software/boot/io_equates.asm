; ============================================================================
;        __
;   \\__/ o\    (C) S2022  Robert Finch, Waterloo
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@opencores.org
;       ||
;  
;
; BSD 3-Clause License
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;
; 1. Redistributions of source code must retain the above copyright notice, this
;    list of conditions and the following disclaimer.
;
; 2. Redistributions in binary form must reproduce the above copyright notice,
;    this list of conditions and the following disclaimer in the documentation
;    and/or other materials provided with the distribution.
;
; 3. Neither the name of the copyright holder nor the names of its
;    contributors may be used to endorse or promote products derived from
;    this software without specific prior written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;                                                                          
; ============================================================================

COREID	EQU		$FFFFFFFE0
MSCOUNT	EQU		$FFFFFFFE4
LEDS		EQU		$FFFE60001
VIA			EQU		$FFFE60000
VIA_PA		EQU		1
VIA_DDRA	EQU		3
VIA_ACR			EQU		11
VIA_IFR			EQU		13
VIA_IER			EQU		14
VIA_T3LL		EQU		18
VIA_T3LH		EQU		19
VIA_T3CMPL	EQU		20
VIA_T3CMPH	EQU		21
TEXTSCR		EQU		$FFFE00000
TEXTREG		EQU		$FFFE07F00
TEXT_COLS	EQU		0
TEXT_ROWS	EQU		1
TEXT_CURPOS	EQU		34
COLS		EQU		64
ROWS		EQU		32
ACIA		EQU		$FFFE30100
ACIA_TX		EQU		0
ACIA_RX		EQU		0
ACIA_STAT	EQU		1
ACIA_CMD	EQU		2
ACIA_CTRL	EQU		3
ACIA_IRQS	EQU		4
ACIA_CTRL2	EQU		11
RTC				EQU		$FFFE30500	; I2C
RTCBuf		EQU		$7FC0
PRNG		EQU		$FFFE30600
KEYBD		EQU		$FFFE30400
KEYBDCLR	EQU		$FFFE30402
PIC			EQU		$FFFE3F000
SPRITE_CTRL		EQU		$FFFE10000
SPRITE_EN			EQU		$3C0

OUTSEMA	EQU	$EF0000
SEMAABS	EQU	$1000
OSSEMA	EQU	$EF0010
