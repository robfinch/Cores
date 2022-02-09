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

; The max page that will be used for an app. Pages above this are for the
; OS ROMs. 

MEMSZ			EQU		65536		; memory size in 8kB pages
MAXVPG		EQU		$7EF

;------------------------------------------------------------------------------
; Page Mapping Ram centric MMU
;------------------------------------------------------------------------------

MMUInit:
	ldd		#MEMSZ-OSPAGES-4  ; set number of available pages (20 pages already allocated)
	std		NPAGES
	; Free all memory for all tasks
	; Sets all pages to map to page zero for all tasks, except for the system
	; task (task #0) which pre-allocates the first 16kB of memory.
	clrd
	tfr		d,y	
MMUInit2:
	stb		MMU_AKEY				; set access key
	ldx		#0
MMUInit1:
	sty		MMU,x
	leax	2,x
	cmpx	#$1000
	blo		MMUInit1
	incb
	cmpb	#64
	blo		MMUInit2

	; Now ensure all pages in PAM are marked as free or OS allocated
	bsr  	PAMInit

	; allocate last page for system stacks
	clr		MMU_AKEY				; select Mid #0 (system)
	ldd		#$FFFE0F				; read/write/cacheable page $FFFF (last page of RAM)
	ldx		#$DFE
	std		MMU,x

	rts

;------------------------------------------------------------------------------
; Find a run of buckets available for mapping virtual to physical addresses.
;
; Parameters:
;		D = mid
;		X = number of pages required.
; Modifies:
;		
; Returns:
;		D = starting bucket number, -1 if no run found
;   N flag set if no run found
;------------------------------------------------------------------------------

FindRun:
	pshs		u,w
	cmpx		#0								; make sure a reasonable request is made
	beq			FindRun0002
	cmpx		#MAXVPG
	bhs			FindRun0002
	stb			MMU_AKEY					; set MMU access key
	tfr			x,y								; Y = number of consecutive empty buckets needed
	ldd			#OSPAGES					; start looking at page D=8 (others are for OS)
	asld
	tfr			d,u
	; First find an empty bucket
FindRun0001:
	ldd			MMU,u							; get map entry into U
	beq			FindRunEmpty0     ; is it empty?
	leau		2,u
	cmpu		#MAXVPG*2
	blo			FindRun0001
FindRun0002:
	ldd			#-1								; got here so no run was found
	puls		u,w,pc
	; Check subsequent buckets for emptiness
FindRunEmpty0:
	tfr			u,w								; w = start of run bucket
FindRunEmpty1:
	ldd			MMU,u							; get bucket value
	bne			FindRun0003
	dey
	beq		  FindRunFoundEnough
	leau		2,u								; advance to next bucket
	bra			FindRunEmpty1
FindRun0003:
	leau		2,u								; increment to next bucket
	tfr			x,y								; reset required count
	bra			FindRun0001				; continue search
FindRunFoundEnough:
	tfr			w,d
	puls		u,w,pc

;------------------------------------------------------------------------------
; Parameters:
;		D = mid
;		X = amount of memory to allocate
; Modifies:
;		t0
; Returns:
;		X = pointer to allocated memory in virtual address space.
;		D = E_Ok for success, E_NotAlloc otherwise
;   Z flag set if successful
;------------------------------------------------------------------------------
;
Alloc:
	stb			MMU_AKEY
	tfr			x,d
	tfr			x,w								; w = number of pages
	beq     allocZero
	; First check if there are enough pages available in the system.
	addd		#PAGESZ-1					; D = round memory request
	tfr			a,b								; convert to pages required (/8192)
	clra
	lsrb
	cmpb		NPAGES						; check number of pages available
	bls		  allocEnough
allocNoRun2:
	ldx			#0								; not enough, return null
	bra			allocNoRun
allocEnough:
	mov			$s1,$a0
	; There are enough pages, but is there a run long enough in map space?
	pshs		d									; save required # pages
	bsr 		FindRun						; find a run of available slots
	tsta
	puls		x
	bmi			allocNoRun2
	; Now there are enough pages, and a run available, so allocate
	mov			$s1,$a0						; s1 = start of run
	pshs		d									; save start of run
	ldd			NPAGES						; decrease number of pages available in system
	subr		w,d
	std			NPAGES
	puls		d									; D = start of run
.0001:
  bsr     PAMMarkPage       ; allocates a page
	beq		  allocNoRun    		; shouldn't get an error here
	aslb
	rola
	
	mvmap		$x0,$a0,$s3				; map the page
	add			$s3,$s3,#1				; next bucket
	sub			$s2,$s2,#1
	bne		  $s2,$x0,.0001
	and     $a1,$s1,#$FFFF    ; strip out ASID
	sll			$a1,$a1,#LOG_PGSZ	; $a1 = virtual address of allocated mem.
	ldo     $s1,48[$sp]
	; Clear the allocated memory
  mov     $s4,$a1
.zm:
  sto     $x0,[$s4]
  add     $s4,$s4,#16
  sub    	$s1,$s1,#16
  bge     $s1,$x0,.zm	
	ldi			$a0,#E_Ok
	bra			.xit
allocNoRun:
	ldd			#E_NotAlloc
.xit:
	ldo			$ra,[$sp]
	ldo			$s1,16[$sp]			; restore regs
	ldo			$s2,32[$sp]
	ldo			$s3,48[$sp]
	ldo     $s4,64[$sp]
	add     $sp,$sp,#80
	ret
allocZero:
	ldd			#E_Ok
  rts

;------------------------------------------------------------------------------
; Allocate the stack page for a task. The stack is located at $FDFFFF and
; downwards. The virtual address of the stack is fixed at $FDE000. The physical
; page varies.
;
; Parameters:
;		b = mid to allocate for
;	Returns:
;		d = physical address, 0 if unsuccessful
;		x = virtual address, not valid unless successful
;------------------------------------------------------------------------------

AllocStack:
	pshs		ccr
	stb			MMU_AKEY				; set access key for table
	ldx			#MAXVPG*2				; last page of memory is for stack
	orcc		#$290						; mask off interrupts
	ldd			MMU,x						; check if stack already allocated
	bne		  asAlreadyAlloc
	lbsr    PAMMarkPage 		; allocate a page, will set / clear Z
	beq		  astkXit    			; success?
	exg			a,b
	orb			#$E00						; set page for cacheable read / write access
	ldx			#MAXVPG*2				; last page of memory is for stack
	std			MMU,x
asAlreadyAlloc:
	clra										; convert pages to addresses (*8192)
	aslb										; B already has high-order byte, so is *4096
	ldx			#MAXVPG*8192
astkXit:
	puls		ccr,pc

;------------------------------------------------------------------------------
; This routine will de-allocate all the pages associated with a task including
; the stack.
;
; Parameters:
;		D = mid to free memory for
;	Modifies:
;		
; Returns:
;		none
;------------------------------------------------------------------------------

FreeAll:
	pshs		u,x,ccr
	stb			MMU_AKEY				; set access key to MMU
	ldu			#-1							; start at first entry
FreeAllNxt:
	andcc		#$D6F						; enable interrupts
	leau		1,u							; increment page number
	cmpu		#MAXVPG+1				; number of buckets to check, dont free OS memory
	bhs			FreeAllXit
	tfr			u,d							; D = page number
	aslb										; convert page number to MMU table index
	tfr			d,x
	orcc		#$290						; mask off interrupts
	ldd			MMU,x						; get current mapping
	andb		#$0FF						; mask off ACR
	exg			a,b							; D = page number
	tfr			d,x
	tst			PAMShareCount,x	; check the share count for the page
	beq			FreeAll1				
	dec			PAMShareCount,x	; decrement share count if non-zero
	bne			FreeAllNxt			; we're done with this page if share count non-zero
FreeAll1:
	lbsr		PAMUnmarkPage
	aslb										; D = index into MMU tables
	tfr			d,x							; X = index into MMU tables
	clr			MMU,x						; clear the entry in the MMU (marks as free)
	clr			MMU+1,x
	inc			NPAGES					; update the number of available pages
	bra			FreeAllNxt
FreeAllXit:
	puls		u,x,ccr,pc

;------------------------------------------------------------------------------
; Convert a virtual address to a physical one. The physical address may contain
; more than 24 bits so it is returned in the Q register.
;
; Stack Space:
;		1 word
; Parameters:
;		D = virtual address to convert
; Returns:
;		Q = physical address
;------------------------------------------------------------------------------

VirtToPhys:
	pshs	x
	tfr		a,b									; convert virtual address to page number (/8192)
	clra											; (divide by 8192 then multiply by 2 = /4096)
	andb	#$FFE								; mask for table index
	pshs	d										; save off table index
	mGetCurrentMid
	stb		MMU_AKEY						; set access key for table
	puls	x										; get back table index
	ldd		MMU,x								; get the translation
	andb	#$0FF								; mask off ACR bits
	tfr		b,e									; multiply page number by 4096
	clrb
	asla											; multiply by 2 more
	clrf
	adcr	e,e									; shift carry bit into e
	adcr	f,f
	exg		w,d
	puls	x,pc
