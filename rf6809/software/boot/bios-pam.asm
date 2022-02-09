; ============================================================================
;        __
;   \\__/ o\    (C) 2020-2021  Robert Finch, Stratford
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@finitron.ca
;       ||
;  
;
; This source file is free software: you can redistribute it and/or modify 
; it under the terms of the GNU Lesser General Public License as published 
; by the Free Software Foundation, either version 3 of the License, or     
; (at your option) any later version.                                      
;                                                                          
; This source file is distributed in the hope that it will be useful,      
; but WITHOUT ANY WARRANTY; without even the implied warranty of           
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
; GNU General Public License for more details.                             
;                                                                          
; You should have received a copy of the GNU General Public License        
; along with this program.  If not, see <http://www.gnu.org/licenses/>.    
;
; ============================================================================

;------------------------------------------------------------------------------
; PAM
; 0 = unallocated
; 1 = reserved
; 2 = end of run of pages
; 3 = allocated
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; PAMFindRun
;    Find a run of unallocated pages.
;
; Parameters:
;   d = number of consecutive pages required
; Returns:
;   d = page starting run, -1 if not enough memory
;   N set if not enough memory
;------------------------------------------------------------------------------

PAMFindRun:
	pshs	y,u									
	ldx   #OSPAGES						; X = starting position
	pshs	d
pfrNextPage:
	tfr		x,d
  bsr   PAMGetbitPair
  tstb
  bne   pfrNotAvailable
  tfr		x,u             		; remember start of run in U
  ldy		,s             			; Y = required run length
pfrRunInc:
  dey												; decrement run length
  beq   pfrFoundRun
  inx          							; increment run start
  cmpx	#MEMSZ
  bhs   pfrOutOfMem
  tfr		x,d									; D = bit pair number
  bsr		PAMGetbitPair
  tstb
  beq   pfrRunInc						; unallocated page?
  inx        								; increment run start pos
  bra   pfrNextPage
pfrNotAvailable:
  inx
  cmpx	#MEMSZ
  blo		pfrNextPage
pfrOutOfMem:
	leas	2,s									; get rid of length
  ldd	  #-1									; D = -1, set N
	puls	y,u,pc
pfrFoundRun:
	leas	2,s									; get rid of length
	tfr		u,d									; D = start of run
	tstd											; clear N
	puls	y,u,pc
	
;------------------------------------------------------------------------------
; Find a run of pages and mark them all allocated.
;
; Parameters:
;   d = amount of memory to allocate
; Returns:
;   d = pointer to memory, -1 if insufficient memory
;   $cr0 = N flag set if insufficient memory
;------------------------------------------------------------------------------
  align 16
_PAMAlloc:
	enter	#64
  sto   $s1,[$sp]
  sto   $s4,8[$sp]
  sto   $s5,16[$sp]
  beq   $a0,$x0,.outOfMem           ; request sensible?
  add   $t0,$a0,#PAGESZ-1   ; round allocation up
  srl   $a0,$t0,#LOG_PGSZ   ; convert size to pages
  mov   $s4,$a0             ; $s4 = length of run in pages
  ldt   $t0,NPAGES          ; check number of pages of memory available
  sub  	$t0,$t0,$a0
  blt		$t0,$x0,.outOfMem
  stt   $t0,NPAGES          ; update the number of available pages
  bal   $x1,_PAMFindRun
  blt		$a0,$x0,.xit
  mov   $s1,$a0
  mov   $a3,$a0
  mov   $s5,$a0             ; $s5 = start of run
.markNext:
  mov   $a0,$a3
  slt   $a1,$s4,#2          ; if $s4 <= 1
  xor   $a1,$a1,#3          ; $a1 = 3, 2 if end of run
  bal  	$x1,_PAMSetbitPair
  add   $a3,$a3,#1          ; increment page number
  sub   $s4,$s4,#1          ; decrement length
  bgt		$s4,$x0,.markNext
  mov   $a0,$s5             ; $a0 = start of run
  sll  	$a0,$a0,#LOG_PGSZ   ; $a0 = physical address of page
.xit:
  ldo   $s1,[$sp]
  ldo   $s4,8[$sp]
  ldo   $s5,16[$sp]
  leave	#32
.outOfMem:
  ldi  	$a0,#-1
  jmp   .xit

;------------------------------------------------------------------------------
; Free memory previously allocated with PAMAlloc.
;
; Parameters:
;   $a0 = pointer to start of memory
; Modifies:
;   $a0,$t0,$t1,$t2,$t3,$t4
; Returns:
;   none
;------------------------------------------------------------------------------
  align 16
_PAMFree:
	enter		#40
  sto     $s1,[$sp]
  mov     $s1,$a0
  and    	$a0,$a0,#$F8007FFE  ; check page 16kB aligned
  bne			$a0,$x0,.xit
  srl     $a0,$s1,#LOG_PGSZ   ; convert to page number
  ldi     $t4,#1
.nextPage:
  mov     $s1,$a0
  bal    	$x1,_PAMGetbitPair
  beq			$a0,$x0,.endOfRun
  slt     $t0,$a0,#3
  bne			$t0,$x0,.lastPage
  mov     $a0,$s1
  ldi     $a1,#0
  bal    	$x1,_PAMSetbitPair
  add     $s1,$a0,#1
  add     $t4,$t4,#1
  bra     .nextPage  
.lastPage:
  mov     $a0,$s1
  ldi     $a1,#0
  bal     $x1,_PAMSetbitPair
  add     $t4,$t4,#1
.endOfRun:
  ldt     $a1,NPAGES
  add     $a1,$a1,$t4
  stt     $a1,NPAGES
.xit:
  ldo     $s1,[$sp]
  leave		#32

;------------------------------------------------------------------------------
; Allocate a single page of memory. Available memory is indicated by a bitmmap
; called the PAM for page allocation map.
;
; Stack Space:
;		1 word
; Modifies:
;		d
; Returns:
;		d = page allocated
;   Z flag if can not allocate
;------------------------------------------------------------------------------

PAMMarkPage:
	ldd   #OSPAGES
pmp1:
	bsr		PAMGetbitPair
	tstb
	beq   pmpGotFree
	addd  #1
	cmpd	#MEMSZ
	blo		pmp1
	clrd
	rts
pmpGotFree:
	pshs	e
  lde		#2							; end of run bits
  bsr  	PAMSetbitPair
  puls	e
  tstd
  rts

;------------------------------------------------------------------------------
; Parameters:
;		d = page number to free
; Modifies:
;		none
;------------------------------------------------------------------------------

PAMUnmarkPage:
	cmpd		#MEMSZ-1					; last page is permanently allocated to system stack
	bhi			pump1
	cmpd		#OSPAGES					; first 8 pages (64kB) allocated permanently to system
	blo			pump1
	pshs		e
	lde			#0
	bsr			PAMSetbitPair
	puls		e
pump1:
	rts

;------------------------------------------------------------------------------
;	Stack Space:
;		3 words
; Parameters:
;		d = bit number to set
;   e = value to set 0,1,2 or 3
; Does not modify:
;   
; Modifies:
;		
;------------------------------------------------------------------------------

PAMSetbitPair:
	pshs	x,d,w
	divd	#6									; 6 bit pairs per byte
	ldx		#PAM								; x = address of PAM
	abx
	ldb		,x									; b = current byte value
	pshs	a										; save off count, it'll be needed again
psbp2:
	tsta											; rotate value by insert position
	beq		psbp1								; done rotate?
	rorb											; rotate by 2 bits
	rorb
	deca
	bra		psbp2
psbp1:
	andb	#$FFC								; clear the bits
	orr		e,b									; insert bit pair
	puls	a										; get back count so we know where to rotate to
psbp4:
	tsta
	beq		psbp3								; done rotate?
	rolb											; rotate by two bits
	rolb
	deca
	bra		psbp4
psbp3:
	stb		,x									; store updated value back to memory
	puls	x,d,w,pc

;------------------------------------------------------------------------------
;	Stack Space:
;		2 words
; Parameters:
;		d = bit pair number to get
; Modifies:
;		none		
; Returns:
;   d = value of bit (0, 1, 2, or 3)
;   Z flag set if bit = 0
;------------------------------------------------------------------------------

PAMGetbitPair:
	pshs	x
	divd	#6									; 6 bit pairs per byte, a = bit pair, b = byte num
	ldx		#PAM								; x = PAM base address
	abx
	ldb		,x									; get a byte of data
pgbp1:
	tsta			
	beq		pgbp2								; finshed shift?
	lsrb											; right shift by pair
	lsrb
	deca
	bra		pgbp1
pgbp2:	
	andb	#3
	puls	x,pc
	
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
  align 16
PAMInit:
	enter	#32
  ; First zero out the entire PAM using word stores
  ldi   $a0,#0
.0002:
  sto   $x0,PAM[$a0]
  add   $a0,$a0,#16
  slt   $t0,$a0,#65536      ; 131072 bit pair = 32,768 bytes
  bne  	$t0,$x0,.0002

  ; Now set bits for preallocated memory pages
  ldi   $a0,#OSPAGES-1  ; OS pages
  ldi   $a1,#3
.0001:
  bal  	$x1,_PAMSetbitPair
  sub   $a0,$a0,#1
  bge		$a0,$x0,.0001
  ldi   $a0,#OSPAGES-1  ; Last OS page
  ldi   $a1,#2          ; set mark end of run
  bal  	$x1,_PAMSetbitPair
  ldi   $a1,#2          ; end of run
  ldi   $a0,#MEMSZ-1    ; OS stack page
  bal  	$x1,_PAMSetbitPair
  ldi   $a0,#MEMSZ-2    ; OS stack page
  ldi   $a1,#3          ; mid run
  bal  	$x1,_PAMSetbitPair
  ldi   $a0,#MEMSZ-3    ; OS stack page
  bal  	$x1,_PAMSetbitPair
  ldi   $a0,#MEMSZ-4    ; OS stack page
  bal  	$x1,_PAMSetbitPair
  leave	#32

GetPamBit:
	sub		$sp,$sp,#16
	sto		$ra,[$sp]
  mov   $a0,$a1
  bal  	$x1,_PAMGetbitPair
  mov   $a1,$a0
  ldi   $a0,#E_Ok
  ldo		$ra,[$sp]
  add		$sp,$sp,#16
  bra   OSExit
