; ============================================================================
;        __
;   \\__/ o\    (C) 2020-2022  Robert Finch, Waterloo
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@finitron.ca
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

TS_NONE			EQU		0
TS_READY		EQU		1
TS_DEAD			EQU		2
TS_MSGRDY		EQU		4
TS_WAITMSG	EQU		8
TS_TIMEOUT	EQU		16
TS_PREEMPT	EQU		32
TS_RUNNING	EQU		128

; error codes
E_Ok		EQU		$00
E_Arg		EQU		$01
E_Func  EQU    $02
E_BadMbx	EQU		$04
E_QueFull	EQU		$05
E_NoThread	EQU		$06
E_NotAlloc	EQU		$09
E_NoMsg		EQU		$0b
E_Timeout	EQU		$10
E_BadAlarm	EQU		$11
E_NotOwner	EQU		$12
E_QueStrategy EQU		$13
E_DCBInUse	EQU		$19
; Device driver errors
E_BadDevNum	EQU		$20
E_NoDev		EQU		$21
E_BadDevOp	EQU		$22
E_ReadError	EQU		$23
E_WriteError EQU		$24
E_BadBlockNum	EQU	$25
E_TooManyBlocks	EQU	$26

; resource errors
E_NoMoreMbx	EQU		$40
E_NoMoreMsgBlks	EQU	$41
E_NoMoreAlarmBlks	EQU $44
E_NoMoreTCBs	EQU	$45
E_NoMem		EQU 12

