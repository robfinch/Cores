; ============================================================================
;        __
;   \\__/ o\    (C) 2013-2022  Robert Finch, Waterloo
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
;
; ASCII control characters.
SOH		equ 1
EOT		equ 4
ACK		equ 6
BS		equ 8
NAK		equ 21
ETB		equ	$17
CAN		equ 24
DEL		equ 127

CR	EQU	$0D		;ASCII equates
LF	EQU	$0A
TAB	EQU	$09
CTRLC	EQU	$03
CTRLH	EQU	$08
CTRLI	EQU	$09
CTRLJ	EQU	$0A
CTRLK	EQU	$0B
CTRLM   EQU $0D
CTRLS	EQU	$13
CTRLT EQU $14
CTRLX	EQU	$18
CTRLZ	EQU	$1A
XON		EQU	$11
XOFF	EQU	$13

FIRST_CORE	EQU	1
MAX_TASKNO	EQU 63
DRAM_BASE	EQU $10000000

; ROM monitor functions
;
MF_Monitor	EQU		0
MF_INCH			EQU		1
MF_OUTCH		EQU 	2
MF_CRLF			EQU		3
MF_DisplayString	EQU		4
MF_DisplayByteAsHex		EQU	5
MF_DisplayWordAsHex		EQU	6
MF_ShowSprites	EQU		7
MF_Srand		EQU		8
MF_Random		EQU		9
MF_OSCALL		EQU		10
MF_GetRange	EQU		11	; gets a pair of numbers last>first
MF_GetNumber	EQU	12
MF_SerialPutchar	EQU	13

mon_numwka	EQU		$910
mon_r1		EQU		$920
mon_r2		EQU		$924
