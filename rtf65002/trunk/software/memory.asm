
; ============================================================================
;        __
;   \\__/ o\    (C) 2013, 2014  Robert Finch, Stratford
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@opencores.org
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
;
MAX_VIRTUAL_PAGE	EQU		320
MAX_PHYSICAL_PAGE	EQU		2048

;------------------------------------------------------------------------------
; Allocate a memory page from the available memory pool.
; Returns a pointer to the page in memory. The address returned is the
; virtual memory address.
;
; Returns:
;	r1 = 0 if no more memory is available or max mapped capacity is reached.
;	r1 = virtual address of allocated memory page
;------------------------------------------------------------------------------
;
public AllocMemPage:
	phx
	phy
	; Search the page bitmap for a free memory page.
	lda		#0
	ldx		#MAX_PHYSICAL_PAGE
	spl		mem_sema + 1
amp2:
	bmt		PageMap
	beq		amp1		; found a free page ?
	ina
	dex
	bne		amp2
	; Here all memory pages are already in use. No more memmory is available.
	stz		mem_sema + 1
	ply
	plx
	lda		#0
	rts
	; Here we found an unallocated memory page. Next find a spot in the MMU
	; map to place the page.
amp1:
	; Find unallocated map slot in the MMU
	ldx		RunningTCB		; set access key for MMU
	ldx		TCB_mmu_map,x
	stx		MMU_AKEY
	ldx		#0
amp4:
	ldy		MMU,x
	cpy		#INV_PAGE
	beq		amp3
	inx
	cpx		#MAX_VIRTUAL_PAGE
	bne		amp4
	; Here we searched the entire MMU slots and none were available
	stz		mem_sema + 1
	ply
	plx
	lda		#0		; return NULL pointer
	rts
	; Here we have both an available page, and available map slot.
amp3:
	bms		PageMap		; mark page as allocated
	sta		MMU,x		; put the page# into the map slot
	asl		r1,r2,#14	; pages are 16kW in size (compute virtual address)
	dec		nPagesFree
	stz		mem_sema + 1
	ply
	plx
	rts

;------------------------------------------------------------------------------
; Parameters:
;	r1 = size of allocation in words
; Returns:
;	r1 = word pointer to memory
; No MMU
;------------------------------------------------------------------------------
;
public AllocMemPages:
	php
	phx
	phy
	push	r4
	sei
amp5:
	tay
	lsr		r3,r3,#14	; convert amount to #pages
	iny					; round up
	cpy		nPagesFree
	bhi		amp11
	tyx					; x = request size in pages
	; Search for enough free pages to satisfy the request
	lda		#0
amp7:
	bmt		PageMap		; test for a free page
	bne		amp6		; not a free page
	cpx		#1			; did we find enough free pages ?
	bls		amp8
	dex
amp6:					; keep checking for next free page
	ina
	cmp		#1855		; did we hit end of map ?
	bhi		amp11		; can't allocate enough memory
	bra		amp7		; go back and test for another free page

	; Insufficient memory, return NULL pointer
amp11:
	lda		#0
	pop		r4
	ply
	plx
	plp
	rts

	; Mark pages as allocated
amp8:
	tyx		; x= #pages to allocate
	cpx		#1
	bne		amp9
	txa							; flag indicates last page
	bra		amp10
amp9:
	lda		#0					; flag indicates middle page
amp10:
	jsr		AllocMemPage		; allocate first page
	ld		r4,r1				; save virtual address of first page allocated
	dex
	beq		amp14
amp13:
	cpx		#1
	bne		amp15
	txa
	bra		amp12
amp15:
	lda		#0
amp12:
	jsr		AllocMemPage
	dex
	bne		amp13
amp14:
	ld		r1,r4				; r1 = first virtual address
	pop		r4
	ply
	plx
	plp
	rts

;------------------------------------------------------------------------------
; FreeMemPage:
;
;	Free a single page of memory. This is an internal function called by
; FreeMemPages(). Normally FreeMemPages() will be called to free up the
; entire run of pages. This function both unmarks the memory page in the
; page bitmap and invalidates the page in the MMU.
;
; Parameters:
;	r1 = virtual memory address
;------------------------------------------------------------------------------
;
FreeMemPage:
	pha
	php
	phx
	sei
	; First mark the page as available in the virtual page map.
	pha
	lsr		r1,r1,#14
	and		#$1ff			; 512 virtual pages max
	ldx		RunningTCB
	ldx		TCB_mmu_map,x	; x = map #
	asl		r2,r2,#4		; 16 words per map
	bmc		VPM_bitmap_b0,x	; clear both bits
	bmc		VPM_bitmap_b1,x
	pla
	; Mark the page available in the physical page map
	pha
	jsr		VirtToPhys		; convert to a physical address
	lsr		r1,r1,#14
	and		#$7ff			; 2048 physical pages max
	bmc		PageMap
	pla
	; Now mark the MMU slot as empty
	lsr		r1,r1,#14		; / 16kW r1 = page # now
	and		#$1ff			; 512 pages max
	ldx		RunningTCB
	ldx		TCB_mmu_map,x
	stx		MMU_AKEY
	tax
	lda		#INV_PAGE
	sta		MMU,x
	inc		nPagesFree
	plx
	plp
	pla
	rts

;------------------------------------------------------------------------------
; FreeMemPages:
;
;	Free up multiple pages of memory. The pages freed are a consecutive
; run of pages. A double-bit bitmap is used to identify where the run of
; pages ends. Bit code 00 indicates a unallocated page, 01 indicates an
; allocated page somewhere in the run, and 11 indicates the end of a run
; of allocated pages.
;
; Parameters:
;	r1 = pointer to memory
;------------------------------------------------------------------------------
;
public FreeMemPages:
	cmp		#0x3fff				; test for a proper pointer
	bls		fmp5
	pha
	; Turn the memory pointer into a bit index
	lsr		r1,r1,#14			; / 16kW acc = virtual page #
	cmp		#MAX_VIRTUAL_PAGE	; make sure index is sensible
	bhs		fmp4
	phx
	spl		mem_sema + 1
	ldx		RunningTCB
	ldx		TCB_mmu_map,x
	asl		r2,r2,#4
fmp2:
	bmt		VPM_bitmap_b1,x		; Test to see if end of allocation
	bne		fmp3
	asl		r1,r1,#14			; acc = virtual address
	jsr		FreeMemPage			; 
	lsr		r1,r1,#14			; acc = virtual page # again
	ina
	cmp		#MAX_VIRTUAL_PAGE	; last 192 pages aren't freeable
	blo		fmp2
fmp3
	; Clear the last bit
	asl		r1,r1,#14			; acc = virtual address
	jsr		FreeMemPage			; 
	lsr		r1,r1,#14			; acc = virtual page # again
	bmc		VPM_bitmap_b1,x
	stz		mem_sema + 1
	plx
fmp4:
	pla
fmp5:
	rts

;------------------------------------------------------------------------------
; Convert a virtual address to a physical address.
; Parameters:
;	r1 = virtual address to translate
; Returns:
;	r1 = physical address
;------------------------------------------------------------------------------
;
public VirtToPhys:
	cmp		#$3FFF				; page #0 is physical page #0
	bls		vtp2
	cmp		#$01FFFFFF			; outside of managed address bounds (ROM / IO)
	bhi		vtp2
	phx
	ldx		CONFIGREC			; check if there is an MMU present
	bit		r2,#4096			; if not, then virtual and physical addresses
	beq		vtp3				; will match
	phy
	tay							; save original address
	and		r3,r3,#$FF803FFF	; mask off MMU managed address bits
	ldx		RunningTCB			; set the MMU access key
	ldx		TCB_mmu_map,x
	stx		MMU_AKEY
	lsr		r2,r1,#14			; convert to MMU index
	and		r2,r2,#511			; 512 mmu pages
	lda		MMU,x				; a = physical page#
	beq		vtp1				; zero = invalid address translation
	asl		r1,r1,#14			; *16kW
	or		r1,r1,r3			; put back unmanaged address bits
vtp1:
	ply
vtp3:
	plx
vtp2:
	rts

;------------------------------------------------------------------------------
; PhysToVirt
;
; Convert a physical address to a virtual address. A little more complex
; than converting virtual to physical addresses as the MMU map table must
; be searched for the physical page.
;
; Parameters:
;	r1 = physical address to translate
; Returns:
;	r1 = virtual address
;------------------------------------------------------------------------------
;
public PhysToVirt:
	cmp		#$3FFF				; first check for direct translations
	bls		ptv3				; outside of the MMU managed range
	cmp		#$01FFFFFF
	bhi		ptv3
	phx
	ldx		CONFIGREC			; check if there is an MMU present
	bit		r2,#4096			; if not, then virtual and physical addresses
	beq		ptv4				; will match
	phy
	ldx		RunningTCB
	ldx		TCB_mmu_map,x
	stx		MMU_AKEY
	tay
	and		r3,r3,#$FF803FFF	; mask off MMU managed address bits
	lsr		r1,r1,#14			; /16k to get index
	and		r1,r1,#$7ff			; 2048 pages max
	ldx		#0
ptv2:
	cmp		MMU,x
	beq		ptv1
	inx
	cpx		#512
	bne		ptv2
	; Return NULL pointer if address translation fails
	ply
	plx
	lda		#0
	rts
ptv1:
	asl		r1,r2,#14	; * 16k
	or		r1,r1,r3			; put back unmanaged address bits
	ply
ptv4:
	plx
ptv3:
	rts
