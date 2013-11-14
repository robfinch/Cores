		code
		org		0xFFFFF800
start
		; Initialize segment registers for "flat" addressing
		mtspr	seg0,r0
		mtspr	seg1,r0
		mtspr	seg2,r0
		mtspr	seg3,r0
		mtspr	seg4,r0
		mtspr	seg5,r0
		mtspr	seg6,r0
		mtspr	seg7,r0
		mtspr	seg8,r0
		mtspr	seg9,r0
		mtspr	seg10,r0
		mtspr	seg11,r0
		mtspr	seg12,r0
		mtspr	seg13,r0
		mtspr	seg14,r0
		mtspr	seg15,r0
		tlbwrreg DMA,r0				; clear TLB miss registers
		tlbwrreg IMA,r0
		ldi			r1,#2			; 2 wired registers
		tlbwrreg	Wired,r1
		ldi			r1,#$2			; 64kiB page size
		tlbwrreg	PageSize,r1

		; setup the first translation
		; virtual page $FFFF0000 maps to physical page $FFFF0000
		; This places the BIOS ROM at $FFFFxxxx in the memory map
		ldi			r1,#$80000101	; ASID=zero, G=1,valid=1
		tlbwrreg	ASID,r1
		ldi			r1,#$0FFFF
		tlbwrreg	VirtPage,r1
		tlbwrreg	PhysPage,r1
		tlbwrreg	Index,r0		; select way #0
		tlbwi						; write to TLB entry group #0 with hold registers

		; setup second translation
		; virtual page 0 maps to physical page 0
		ldi			r1,#$80000101	; ASID=zero, G=1,valid=1
		tlbwrreg	ASID,r1
		tlbwrreg	VirtPage,r0
		tlbwrreg	PhysPage,r0
		ldi			r1,#8			; select way#1
		tlbwrreg	Index,r1		
		tlbwi						; write to TLB entry group #0 with hold registers

		; turn on the TLB
		tlben

		mtspr	br12,r0			; set vector table address
		lh		r1,jirq			; setup jump to irqrout
		lh		r2,jirq+4
		lh		r3,jirq+8
		lh		r4,jirq+12
		sh		r1,$fe0
		sh		r2,$fe4
		sh		r3,$fe8
		sh		r4,$fec
		ldi		r3,#st1			; set return address for an RTI
		mtspr	br14,r3
		rti						; RTI to enable interrupts
st1:
		ldi		r1,#1234
		ldi		r2,#5678
		ldi		r3,#7777
		ldi		r4,#4444
		ldi		r5,#8888
		ldi		r6,#9999
		add		r1,r2,r3
		nand	r3,r4,r5
		nand	r4,r5,r6
		add		r1,r3,r4
		tst		p1,r1
p1.eq	br		foobar
		add		r1,r4,r5
		nop
		nop
		align	8
jirq:
		jmp		irqrout

foobar
		addi	r1,r57,#1234
		cmpi	p1,r1,#1233

irqrout:
		rti

p1.eq	subi	r1,r1,#10
		org		0xFFFFFFF0
		jmp		start
		nop
		nop
		nop

