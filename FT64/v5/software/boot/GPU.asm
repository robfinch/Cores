; GPU Grid

SCREEN	equ	$00100000
REGS		equ	$FFD00000
CONTROL	equ	$00
STATUS	equ	$04
DEST_X	equ	$38
DEST_Y	equ	$3C
DEST_Z	equ	$40
TARGET_X0		equ	$AC
TARGET_Y0		equ	$B0
TARGET_X1		equ	$B4
TARGET_Y1		equ	$B8
CLIP_P0_X		equ	$74
CLIP_P0_Y		equ	$78
CLIP_P1_X		equ	$7C
CLIP_P1_Y		equ	$80
VAR_AREA	equ	$00105000
dest_p0_x	equ	VAR_AREA
dest_p0_y	equ	dest_p0_x + 4
dest_p0_z	equ	dest_p0_y + 4
dest_p1_x equ	dest_p0_z + 4
dest_p1_y equ dest_p1_x + 4
dest_p1_z equ dest_p1_y + 4
dest_p2_x equ	dest_p1_z + 4
dest_p2_y equ dest_p2_x + 4
dest_p2_z equ dest_p2_y + 4

		code
		org	$FFFC0000
		jmp	start

		code
		org		$FFFC0100
start:
		ldi		r1,#$0F00		; red in ZRGB4444
		ldi		r2,#20480		; number of pixels
		ldi		r3,#SCREEN
.0001:
		sc		r1,[r3]
		add		r3,r3,#2
		sub		r2,r2,#1
		bne		r2,r0,.0001
		jmp		start

;
table1:
		dh		$100
		dh		$200
		dh		$400
		dh		$800
		dh		$40000
		dh		$80000
table2:
		dh		writeRect
		dh		writeLine
		dh		writeTriangle
		dh		writeCurve
		dh		fwdPoint
		dh		transformPoint

nextCmd:
		ldi		r20,#REGS
		lh		r1,CONTROL[r20]
		and		r2,r1,#$100|$200|$400|$800|$40000|$80000
		beq		r2,r0,.0003	; no command to execute
		ldi		r2,#20
.0002:
		lh		r3,table1[r2]
		and		r4,r1,r3
		beq		r4,r0,.0001
		lh		r3,table2[r2]
		jmp		[r3]
.0001:
		sub		r2,r2,#4
		bge		r2,r0,.0002
		; no graphics commands left to perform
.0003:
		sc		r0,STATUS[r20]
		jmp		nextCmd

fwdPoint:
		lh		r2,DEST_X[r20]
		lh		r3,DEST_Y[r20]
		lh		r4,DEST_X[r20]
storePoint:
		shr		r5,r1,#16
		and		r5,r5,#3
		beq		r5,r0,.pt0
		beqi	r5,#1,.pt1
		beqi	r5,#2,.pt2
		sc		r0,STATUS[r20]
		jmp		nextCmd
.pt0:
		sh		r2,dest_p0_x
		sh		r3,dest_p0_y
		sh		r4,dest_p0_z
		sc		r0,STATUS[r20]
		jmp		nextCmd
.pt1:
		sh		r2,dest_p1_x
		sh		r3,dest_p1_y
		sh		r4,dest_p1_z
		sc		r0,STATUS[r20]
		jmp		nextCmd
.pt2:
		sh		r2,dest_p2_x
		sh		r3,dest_p2_y
		sh		r4,dest_p2_z
		sc		r0,STATUS[r20]
		jmp		nextCmd

transformPoint:
		lh		r2,DEST_X[r20]
		lh		r3,DEST_Y[r20]
		lh		r4,DEST_X[r20]
		transform		r2,r3,r4
		transform.w	r2,r3,r4
		jmp		storePoint

writeLine:
		lh		r2,dest_p0_x
		lh		r3,dest_p0_y
		lh		r4,dest_p1_x
		lh		r5,dest_p1_y
		; swap points so that we are drawing left to right
		blt		r2,r4,.0001
		or		r6,r2,r0
		or		r2,r4,r0
		or		r4,r6,r0
		or		r6,r3,r0		
		or		r3,r5,r0
		or		r5,r6,r0
.0001:
		; compute slope
		sub		r7,r4,r2		; x1-x0
		sub		r8,r5,r3		; y1-y0
		bne		r7,r0,.0006
		bne		r8,r0,.0006
		sc		r0,STATUS[r20]
		jmp		nextCmd			; dx and dy = 0, zero length line
.0006:
		fxdiv	r9,r8,r7		; dy/dx
		fxdiv	r12,r7,r8		; dx/dy
		lh		r16,TARGET_X0[r20]
		lh		r17,TARGET_Y0[r20]
		lh		r18,TARGET_X1[r20]
		lh		r19,TARGET_Y1[r20]
		fxdiv.w	r9,r9,r0
		fxdiv.w	r12,r12,r0
		call	CheckLineInArea
		bne		r1,r0,.0002
		sc		r0,STATUS[r20]
		jmp		nextCmd
.0002:
		lh		r1,CONTROL[r20]
		and		r2,r1,#$20				; is clipping enabled ?
		beq		r2,r0,.0003
		lh		r16,CLIP_P0_X[r20]
		lh		r17,CLIP_P0_Y[r20]
		lh		r18,CLIP_P1_X[r20]
		lh		r19,CLIP_P1_Y[r20]
		call	CheckLineInArea
		bne		r1,r0,.0003
		sc		r0,STATUS[r20]
		jmp		nextCmd
.0003:
		; Draw line according to slope
		abs		r7,r7
		abs		r8,r8
		blt		r7,r8,.0004		; dx < dy ?
.0007:
		or		r14,r2,r0			;
		or		r15,r3,r0
		call	plotPoint
		add		r2,r2,#$10000	; fixed point 1.0
		add		r3,r3,r9
		blt		r2,r4,.0007
		sc		r0,STATUS[r20]
		jmp		nextCmd
.0004:
		blt		r3,r5,.0008		; y0 < y1 ?
.0009:
		or		r14,r2,r0			;
		or		r15,r3,r0
		call	plotPoint
		sub		r3,r3,#10000			; fixed point 1.0
		add		r2,r2,r12
		blt		r5,r3,.0009
		sc		r0,STATUS[r20]
		jmp		nextCmd
.0008:
		or		r14,r2,r0			;
		or		r15,r3,r0
		call	plotPoint
		add		r3,r3,#$10000			; fixed point 1.0
		add		r2,r2,r12
		blt		r3,r5,.0008
		sc		r0,STATUS[r20]
		jmp		nextCmd

CheckLineInArea:
		; if right point is before target area, nothing to do
		blt		r4,r16,.0002
.0003:
		ldi		r1,#0
		ret
.0002:
		; if left point is after target area, nothing to do
		blt		r18,r2,.0003
		blt		r2,r16,.xBeforeTarget
.0004:
		blt		r18,r4,.xAfterTarget
.0005:
		; if y0 is less than target y0 and slope is positive (downwards)
		; line is outside of target area
		blt		r17,r3,.0006
		blt		r0,r9,.0003		; line outside area, nothing to do
.0006:
		; if y0 is greater than target y1 and slope is negative (upwards)
		blt		r3,r19,.0007
		blt		r9,r0,.0003		; line outside area
.0007:
		; The line is probably somewhere in the target area
		ldi		r1,#1
		ret		

.xBeforeTarget:
		sub			r11,r16,r2	; compute distance before target
		fxmul		r11,r11,r9	; y0 = y0 + dy/dx * xdiff
		add			r3,r11,r3		; add y0 to get new y0
		bra			.0004
		
.xAfterTarget:
		sub			r11,r4,r18	; compute distance after target
		fxmul		r11,r11,r9
		sub			r5,r11,r5		; y1 = y1 - dy/dx * xdiff
		bra			.0005		
				
plotPoint:
		ret

writeRect:
		lh		r2,dest_p0_x
		lh		r3,dest_p0_y
		lh		r4,dest_p1_x
		lh		r5,dest_p1_y
		; swap points so that we are drawing left to right
		blt		r2,r4,.0001
		or		r6,r2,r0
		or		r2,r4,r0
		or		r4,r6,r0
.0001:
		; swap y so we are drawing top to bottom
		blt		r3,r5,.0002
		or		r6,r3,r0
		or		r3,r5,r0
		or		r5,r6,r0
.0002:
		lh		r16,TARGET_X0[r20]
		lh		r17,TARGET_Y0[r20]
		lh		r18,TARGET_X1[r20]
		lh		r19,TARGET_Y1[r20]
		; Clip x0
		blt		r2,r18,.0003
.0004:
		sc		r0,STATUS[r20]		; rect is after target area
		jmp		nextCmd						; nothing to draw
.0003:
		blt		r4,r16,.0004			; rect is before target area
		blt		r5,r17,.0004			; rect is above target area
		bgt		r3,r19,.0004			; rect is below target area
		; The rect at least partially overlaps the target area
		; Ensure the rect coords limited by target
		max		r2,r2,r16
		max		r3,r3,r17
		min		r4,r4,r18
		min		r5,r5,r19
		; Check for clipping area
		and		r6,r1,#$20				; is clipping enabled ?
		beq		r6,r0,.0005
		lh		r16,CLIP_P0_X[r20]
		lh		r17,CLIP_P0_Y[r20]
		lh		r18,CLIP_P1_X[r20]
		lh		r19,CLIP_P1_Y[r20]
		max		r2,r2,r16
		max		r3,r3,r17
		min		r4,r4,r18
		min		r5,r5,r19
.0005:
		or		r14,r2,r0
		or		r15,r3,r0
.nextPoint:
		call	plotPoint
		add		r14,r14,#1
		blt		r14,r4,.nextPoint
		or		r14,r2,r0
		add		r15,r15,#1
		blt		r15,r5,.nextPoint
		sc		r0,STATUS[r20]
		jmp		nextCmd

			
		