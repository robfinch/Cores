; 64GB card
; 36 address bits
; 9 bits for 512 byte block size
; 27 bits for block number
; 4kB cluster size = 3 bits
; 24 bit cluster number
; 2MB bitmap of allocated clusters ( contained in 512 clusters)
; 512 super bitmap bits
; 
NO_DEV		EQU		-1
READING		EQU		'R'
WRITING		EQU		'W'
DIRTY		EQU		'D'
CLEAN		EQU		'C'
NORMAL		EQU		0

;
; Note that structure offsets are word offsets
; The super block always occupies a whole block for simplicity even though
; it's mostly unused.
;
; STRUCT SUPER_BLOCK
;
s_inodes_count			EQU		0
s_blocks_count			EQU		1
s_r_blocks_count		EQU		2
s_free_blocks_count		EQU		3
s_free_inodes_count		EQU		4
s_first_data_block		EQU		5
s_log_block_size		EQU		6
s_log_frag_size			EQU		7
s_blocks_per_group		EQU		8
s_frags_per_group		EQU		9
s_inodes_per_group		EQU		10
s_pad					EQU		11
s_mtime					EQU		12
s_wtime					EQU		14
s_mnt_cnt				EQU		16
s_max_mnt_cnt			EQU		17
s_magic					EQU		18
s_state					EQU		19
s_errors				EQU		20
s_minor_rev_level		EQU		21
s_lastcheck				EQU		22
s_checkinterval			EQU		24
s_creator_os			EQU		26
s_rev_level				EQU		27
s_def_res_uid			EQU		28
s_def_res_gid			EQU		29
s_inode_size			EQU		31
s_volume_name			EQU		40
; In memory management fields
s_inodes_per_block		EQU		124
s_dev					EQU		125
s_dirty					EQU		126
SUPERBUF_SIZE			EQU		128

; STRUCT INODE
;
INODE_P0	EQU		17
INODE_P1	EQU		INODE_P0+1
INODE_P2	EQU		INODE_P1+1
INODE_P3	EQU		INODE_P2+1
INODE_P4	EQU		INODE_P3+1
INODE_P5	EQU		INODE_P4+1
INODE_P6	EQU		INODE_P5+1
INODE_P7	EQU		INODE_P6+1
INODE_P8	EQU		INODE_P7+1
INODE_P9	EQU		INODE_P8+1
INODE_P10	EQU		INODE_P9+1
INODE_P11	EQU		INODE_P10+1
INODE_IP	EQU		INODE_P11+1		; indirect pointer
INODE_IIP	EQU		INODE_IP+1		; double indirect pointer
INODE_IIIP	EQU		INODE_IIP+1		; triple indirect pointer
INODE_DEV	EQU		37
INODE_INUM	EQU		38
INODE_ICOUNT	EQU	39
INODE_DIRTY	EQU		40
INODE_SIZE	EQU		41				; 41 words

; STRUCT BGDESC
;
bg_block_bitmap			EQU		0
bg_inode_bitmap			EQU		1
bg_inode_table			EQU		2
bg_free_blocks_count	EQU		3
bg_free_inodes_count	EQU		4
bg_used_dirs_count		EQU		5
bg_reserved				EQU		6
BGDESC_SIZE				EQU		8
bg_dev					EQU		9
bg_group_num			EQU		10
bg_dirty				EQU		11
BGD_BUFSIZE				EQU		12

; STRUCT DIRENTRY
; Directory entries are 64 bytes
; 28 character file name
;  4 byte i-node number
;
DE_NAME			EQU		0
DE_TYPE			EQU		14
DE_INODE		EQU		15
DE_SIZE			EQU		16		; size in words

; Structure of a disk buffer
; STRUCT BUF
;
BUF_DEV			EQU		0		; device 
BUF_BLOCKNUM	EQU		1		; disk block number
BUF_COUNT		EQU		2		; reference count
BUF_DIRTY		EQU		3		; buffer has been altered
BUF_NEXT		EQU		4		; next buffer on LRU list
BUF_PREV		EQU		5
BUF_HASH		EQU		6		; pointer to hashed buffer
BUF_DATA		EQU		8		; beginning of data area
BUF_INODE		EQU		8
BUF_SIZE		EQU		BUF_DATA+256
NR_BUFS			EQU		2048	; number of disk buffers in the system

IAM_BUF_SIZE	EQU		1032	; 1024 + 8
CAM_SUPERMAP_SIZE	EQU		128

; $00000000 super block
; $00000001 iam super map (512 bits)
; $00000002 inode allocation map (128kB)
; $00000102 inode array (1M x 128 byte entries)
; $00040102 cam super bitmap bits (512 bits)
; $00040103 cluster allocation map (2MB)
; $00041103 start of data clusters

DOS_DATA		EQU		0x00300000					; start address of DOS data area
super_bufs		EQU		DOS_DATA
super_bufs_end	EQU		super_bufs + SUPERBUF_SIZE * 32
BGD_bufs		EQU		super_bufs_end
BGD_bufs_end	EQU		BGD_buf + 1024 * BGD_BUFSIZE	; 32 kB = 1024 descriptors
iam_bufs		EQU		BGDT_buf_end
inode_array		EQU		iam_bufs + IAM_BUF_SIZE * 32	; 129 kB worth (256 open files)
cam_supermaps	EQU		inode_array + INODE_SIZE * 256	; 64kB worth 
cam_bufs		EQU		cam_supermaps + CAM_SUPERMAP_SIZE * 32
data_bufs		EQU		0x00400000			; room for 2048 buffers
data_bufs_end	EQU		data_bufs + BUF_SIZE * NR_BUFS
superbuf_dump	EQU		data_bufs_end + 1
bufs_in_use		EQU		superbuf_dump + 1
blockbuf_dump	EQU		bufs_in_use + 1
disk_size		EQU		blockbuf_dump + 1
block_size		EQU		disk_size + 1
fs_start_block	EQU		block_size + 1
bgdt_valid		EQU		fs_start_block + 1

; number of buffers for the inode allocation map
; number of buffers for inode array
; Total caching to be 12MB
; 9MB reserved for data block caching
; 3MB reserved for file management caching

inode_bufs	EQU		DOS_DATA	; 128B x 256 bufs
iam_buf		EQU		0x01FBE800
super_buf	EQU		0x01FBEA00
sector_buf	EQU		0x01FBEC00

init_DOS:
	stz		bgdt_valid
	jsr		init_superbufs
	rts

;------------------------------------------------------------------------------
; The file system offset is the offset in disk sectors to the start
; of the file system. It may be desireable to reserve a number of
; disk sectors prior to the actual file system start.
;------------------------------------------------------------------------------
;
get_filesystem_offset:
	lda		#2
	rts

;------------------------------------------------------------------------------
; Initialize super block buffer array.
;------------------------------------------------------------------------------
;
init_superbufs:
	pha
	phx
	ldx		#super_bufs
isb1:
	lda		#NO_DEV
	sta		s_dev,x
	lda		#CLEAN
	sta		s_dirty,x
	add		r2,r2,#SUPERBUF_SIZE
	cpx		#super_bufs_end
	bltu	isb1
	plx
	pla
	rts

;------------------------------------------------------------------------------
; Parameters:
;	r1 = device
; Returns:
;	r1 = block size in bytes
;------------------------------------------------------------------------------
get_block_size:
	phx
	phy
	jsr		get_super
	tax
	ldy		s_log_block_size,x
	lda		#1024
	asl		r1,r1,r3
	ply
	plx
	rts

get_log_block_size:
	phx
	jsr		get_super
	tax
	lda		s_log_block_size,x
	plx
	rts

get_inode_size:
	phx
	jsr		get_super
	tax
	lda		s_inode_size,x
	plx
	rts

get_inodes_per_group:
	phx
	jsr		get_super
	tax
	lda		s_inodes_per_group,x
	plx
	rts

get_inodes_per_block:
	phx
	pha
	jsr		get_block_size
	tax
	pla
	jsr		get_inode_size
	divu	r1,r2,r1
	plx
	rts

get_bgd_per_block:
	jsr		get_block_size
	lsr		; BGD size is 32 bytes
	lsr
	lsr
	lsr
	lsr
	rts

;------------------------------------------------------------------------------
; get_super:
;	Get the super block.
; There is a super block for each device. This code should really call
; device driver code to read the disk. However for now it is hardcoded
; to read/write the SDCard.
;	We cheat here and read only a sector rather than a block because
; the superblock is only a sector in size.
;   Note that this routine calls the sector read/write routines rather
; than get_block. The superblocks have caching independent of the
; regular block cache.
;
; Parameters:
;	r1 = device number
; Returns:
;	r1 = pointer to superblock buffer
;------------------------------------------------------------------------------
;
get_super:
	phx
	; first search the superbuf array to see if the block is already
	; memory resident
	ldx		#super_bufs
gs2:
	cmp		s_dev,x					; device number match ?
	beq		gs1						; yes, found superblock buffer for device
	add		r2,r2,#SUPERBUF_SIZE
	cpx		#super_bufs_end
	bltu	gs2
	; Here we couldn't find the device superblock cached
	; So dump one from memory and load cache
	inc		superbuf_dump			; "randomizer" for dump select
	ldx		superbuf_dump
	and		r2,r2,#31				; 32 buffers
	mul		r2,r2,#SUPERBUF_SIZE
	add		r2,r2,#super_bufs
	; if the superblock is dirty, then write it out
	ldy		s_dirty,x
	asl		r2,r2,#2				; convert word to byte address
	cpy		#DIRTY
	bne		gs3
	jsr		get_filesystem_offset
	jsr		spi_write_sector		; put_block
gs3:
	jsr		get_filesystem_offset	; r1 = sector number of superblock
	jsr		spi_read_sector			; get_block
gs1:
	txa
	lsr								; convert byte address to word address
	lsr
	plx
	rts

;------------------------------------------------------------------------------
; Parameters:
;	r1 = device number
;	r2 = inode number
;------------------------------------------------------------------------------
;	
free_inode:
	pha
	phx
	phy
	push	r4
	push	r5
	push	r7
	push	r8
	push	r9
	ld		r7,r1		; r7 = device number
	jsr		get_inodes_per_group
	divu	r4,r2,r1	; r4 = group number of inode
	modu	r5,r2,r1	; r5 = group index
	ld		r1,r7
	ld		r2,r4
	jsr		get_bgdt_entry
	ld		r9,r1		; r9 = pointer to BGDesc
	ld		r1,r7
	ld		r2,bg_inode_bitmap,r9
	jsr		get_block	; get the bitmap block
	ld		r8,r1		; r8 = bitmap block
	ld		r1,r5
	bmt		BUF_DATA,r8	; is the inode already free ?
	beq		fi1
	bmc		BUF_DATA,r8
	inc		bg_free_inodes_count,r9
	jsr		get_super
	tax
	inc		s_free_inodes_count,x
	lda		#DIRTY
	sta		s_dirty,x
	sta		BUF_DIRTY,r8
fi1:
	pop		r9
	pop		r8
	pop		r7
	pop		r5
	pop		r4
	ply
	plx
	pla
	rts

;	r1 = inode number
;
mark_iam_bit:
	pha
	phx
	phy
	div		r2,r1,#4096	; r2 = iam block number
	mod		r1,r1,#4096	; r1 = bit number in block
	pha
	txa
	jsr		get_iam_block
	tay
	pla
	bms		0,y
	tya
	jsr		put_iam_block
	; check if all bits have been marked
	lda		#0
mib2:
	bmt		0,y
	beq		mib1
	ina
	cmp		#4096
	bltu	mib2
	txa
	bms		super_buf+112	; set the all allocated bit
	lda		#DIRTY
	sta		super_buf+s_dirty
mib1:
	ply
	plx
	pla
	rts

;------------------------------------------------------------------------------
; Allocate an inode
; This is called when a file or directory is created
;
; Parameters:
;	r1 = device number
;	r2 = mode bits
;------------------------------------------------------------------------------
;		
alloc_inode:

; search the super match for a block with available inode
	lda		#0				; start at bit zero
alin2:
	bmt		super_buf+112	; offset of super iam map
	beq		alin1			; 0=free inode in block
	ina
	cmp		#256
	bltu	alin2
	; Here there are no more free inodes - the file system is full
	lda		#0
	rts

	; We found an inode block with free inodes
alin1:
	ldx		#super_buf
	add		r2,r2,#s_imap_block
	tay						; save off block in y
	add		r1,r1,(r2)
	jsr		load_iam_map_block
	lda		#0
alin3:
	bmt		iam_buf
	beq		alin4
	ina
	cmp		#4096			; 4096 bits per block
	bltu	alin3
	; we should not get here as it was indicated there was a 
	; free inode
	lda		#0
	rts

	; we found the free inode
alin4:
	bms		iam_buf			; mark inode as allocated
	pha						; save off inode number

; now check if all inodes in the block have been allocated
;
	ldx		#0
alin6:
	lda		iam_buf,x
	cmp		#$FFFFFFFF
	bne		alin5
	inx
	cpx		#128
	bne		alin6
; Here, all inodes in block have been allocated, so mark it
; in the superblock
	tya
	bms		super_buf+112
alin5:
	mul		r3,r3,#4096
	pla						; restore inode number
	add		r1,r3
	jsr		get_inode		; get a buffer to correspond to the allocated inode
	cmp		#0
	bne		alin7
	
alin7:
	rts

;------------------------------------------------------------------------------
; Get an inode
;
; There are 256 inode buffers in the system which allows for 256 files
; to be open at once.
;
; Parameters:
;	r1 = device
;	r2 = inode number
; Returns:
;	r1 = pointer to inode buffer
;------------------------------------------------------------------------------
;
get_inode:
	; push working registers
	push	r4						; r4 = buffer number		
	push	r5						; r5 points to inode buffer
	push	r6
	push	r7
	ld		r7,#0					; tracks the last free buffer
	; Search the in use inode buffers for the one corresponding
	; to the given device and node number. If found then increment
	; the reference count and return a pointer to the buffer.
	ld		r4,#0
	ld		r5,#inode_bufs
gib4:
	ld		r6,INODE_ICOUNT,r5		; check the count field to see if in use
	beq		gib3					; branch if not in use
	cmp		INODE_DEV,r5			; now check for a matching device
	bne		gib5					; branch if no match					
	cpx		INODE_INUM,r5			; now check for matching node number
	bne		gib5
	inc		INODE_ICOUNT,r5			; increment count
	ld		r1,r5
	pop		r7
	pop		r6						; pop working registers
	pop		r5
	pop		r4
	cmp		#0
	rts

gib3:
	ld		r7,r5					; remember the free inode
gib5:
	add		r4,#1					; increment buffer number
	add		r5,r5,#INODE_SIZE		; size of an inode in words
	cmp		r4,#256					; have we searched all buffers ?
	bltu	gib4
	cmp		r7,#0					; test if free buffer found
	bne		gib6
	pop		r7
	pop		r6
	pop		r5
	pop		r4
	ld		r1,#0					; no more inode buffers available
	rts
gib6:
	sta		INODE_DEV,r7
	stx		INODE_INUM,r7
	inc		INODE_ICOUNT,r7			; count field =1, was 0
	cmp		#NO_DEV					; if there was a device number supplied
	beq		gib7					; read the inode from the device
	ld		r1,r7
	ldx		#READING
	jsr		rw_inode
gib7:
	ld		r1,r7
	pop		r7						; restore work registers
	pop		r6
	pop		r5
	pop		r4
	cmp		#0
	rts
		
;------------------------------------------------------------------------------
; Put inode
;
; Parameters:
;	r1 = pointer to inode buffer
;------------------------------------------------------------------------------
;
put_inode:
	cmp		#0					; check for NULL pointer
	bne		pi1
	rts
pi1:
	phx
	tax
	dec		INODE_ICOUNT,x
	bne		pi2
	; If the number of links to the inode is zero
	; then deallocate the storage for the inode
pi2:
	lda		INODE_DIRTY,x
	cmp		#DIRTY
	bne		pi3
	txa							; acc = inode buffer pointer
	ldx		#WRITING
	jsr		rw_inode
pi3:
	plx
	rts

;------------------------------------------------------------------------------
; Parameters:
;	r1 = inode
;	r2 = R/W indicator
;------------------------------------------------------------------------------
rw_inode:
	pha
	phx
	phy
	push	r4
	push	r5
	push	r6
	push	r7
	; get the super block for the device
	phx
	pha
	lda		INODE_DEV,r1
	jsr		get_inodes_per_group
	ld		r5,r1			; r4 = inodes per group
	pla
	ldx		INODE_INUM,r1
	divu	r6,r2,r5		; r6 = group number
	modu	r7,r2,r5		; r7 = index into group
	lda		INODE_DEV,r1
	pha
	ld		r2,r6
	jsr		get_bgdt_entry
	lda		bg_inode_table,r1	; get block address of inode table
	pha
	jsr		get_inodes_per_block
	divu	r6,r7,r1
	modu	r8,r7,r1
	pla
	add		r2,r1,r6
	pla
	ldy		#NORMAL
	jsr		get_block

	ld		r7,r1				; r7 = pointer to block buffer
	pop		r4					; r4 = inode
	add		r5,r1,#BUF_INODE	; r5 = address of inode data

	mulu	r6,r8,#INODE_SIZE
	add		r5,r6
	pop		r6					; r6 = R/W indicator
	cmp		r6,#READING
	bne		rwi1
	jsr		get_inode_size
	dea
	ld		r2,r5
	ld		r3,r4
	mvn
	bra		rw2
rwi1:			
	jsr		get_inode_size
	dea
	ld		r2,r4
	ld		r3,r5
	mvn
	lda		#DIRTY
	sta		BUF_DIRTY,r7
rwi2:	
	ld		r1,r7				; r1 = pointer to block buffer
	ld		r2,#INODE_BLOCK
	jsr		put_block
	lda		#CLEAN
	sta		INODE_DIRTY,r4
	pop		r7
	pop		r6
	pop		r5
	pop		r4
	ply
	plx
	pla
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
dup_inode:
	inc		INODE_ICOUNT,r1
	rts

;------------------------------------------------------------------------------
; load a block from the inode allocation map table
;	r1 = block to load
;
load_iam_map_block:
	ldx		#iam_buf
	jsr		spi_read_sector
	rts

;------------------------------------------------------------------------------
; get_bgdt_entry:
;	Get block group descriptor from the descriptor table.
;
; Parameters:
;	r1 = device number
;	r2 = group number
; Returns:
;	r1 = pointer to BGD buffer
;------------------------------------------------------------------------------
;
get_bgdt_entry:
	push	r5
	modu	r5,r2,#1024			; r5 = hashed group number
	mulu	r5,r5,#BGD_BUFSIZE
	add		r5,r5,#BGD_bufs		; r5 = pointer to BGD buffer
	cmp		bg_dev,r5
	bne		gbe1
	cpx		bg_group_num,r5
	beq		gbe2
gbe1:
	push	r4
	push	r6
	push	r7
	push	r8
	ld		r6,r1				; r6 = device number
	ld		r7,r2				; r7 = group number
	; does the buffer need to be written to disk ?
	ld		r4,bg_dirty,r5
	cmp		r4,#CLEAN
	beq		gbe3
	; Compute the block number containing the group
	jsr		get_bgd_per_block
	ld		r2,bg_group_num,r5
	divu	r8,r2,r1
	modu	r4,r2,r1
	lda		fs_start_block
	ina							; the next block after the file system start
	add		r2,r1,r8			; r2 = block number
	ld		r1,r6				; r1 = device number
	jsr		get_block
	pha
	add		r1,r1,#BUF_DATA		; move to data area
	mulu	r4,r4,#BGDESC_SIZE
	add		r1,r4				; r1 = pointer to desired BGD
	; copy BGD to the block
	tay
	ld		r2,r5
	lda		#BGDESC_SIZE-1
	mvn
	pla
	ld		r2,#DIRTY
	stx		BUF_DIRTY,r1
gbe3:
	; Compute the block number containing the group
	ld		r1,r6
	ld		r2,r7
	jsr		get_bgd_per_block
	divu	r8,r2,r1
	modu	r4,r2,r1
	lda		fs_start_block
	ina							; the next block after the file system start
	add		r2,r1,r8			; r2 = block number
	ld		r1,r6				; r1 = device number
	jsr		get_block
	add		r1,r1,#BUF_DATA		; move to data area
	mulu	r4,r4,#BGDESC_SIZE
	add		r1,r4				; r1 = pointer to desired BGD
	; copy BGD from the block to the buffer
	tax
	ld		r3,r5
	lda		#BGDESC_SIZE-1
	mvn
	st		r6,bg_dev,r5
	st		r7,bg_group_num,r5
	lda		#CLEAN
	sta		bg_dirty,r5
	pop		r8
	pop		r7
	pop		r6
	pop		r4
gbe2:
	ld		r1,r5
	pop		r5
	rts

;==============================================================================
;==============================================================================

;------------------------------------------------------------------------------
; get_block
;	Gets a block from the device. First the block cache is checked for the
; block; if found the cached buffer is returned.
;
; Parameters:
;	r1 = device
;	r2 = block number
; Returns:
;	r1 = pointer to buffer containing block
;------------------------------------------------------------------------------
;
get_block:
	phx
	phy
	push	r4
	push	r5
	push	r6
	push	r7
	push	r8
	ld		r4,r1				; r4 = device number
	ld		r5,r2				; r5 = block number
	ld		r8,#0				; r8 = NULL pointer to empty disk buffer
	ld		r6,#NR_BUFS			; number of disk buffers
	ldx		#data_bufs
gb3:
	cmp		r4,BUF_DEV,x		; check device number and
	bne		gb1
	cmp		r5,BUF_BLOCKNUM,x	; block number against current buffer values
	bne		gb1
	lda		BUF_COUNT,x			; if it's a match
	bne		gb2
	inc		bufs_in_use
gb2:
	ina
	sta		BUF_COUNT,x
	txa
gb_ret:
	pop		r8
	pop		r7
	pop		r6
	pop		r5
	pop		r4
	ply
	plx
	rts
	; Here, we iterate to the next buffer
gb1:
	ld		r7,BUF_DEV,x
	cmp		r7,#NO_DEV
	bne		gb4
	ld		r8,r2				; r8 = pointer to empty disk buffer
gb4:
	add		r2,r2,#BUF_SIZE
	sub		r6,#1
	bne		gb3
	; Here we searched the entire buffer cache and didn't find the
	; block cached. Did we find an empty buffer though ?
	cmp		r8,#0
	beq		gb5
gb8:
	; Here we have an available buffer in r8
	st		r4,BUF_DEV,r8
	st		r5,BUF_BLOCKNUM,r8
	inc		BUF_COUNT,r8

	cmp		r4,#NO_DEV
	beq		gb6
	cmp		r3,#NORMAL
	bne		gb6
	ld		r1,r8
	ldx		#READING
	jsr		rw_block
	bra		gb_ret
gb6:
	ld		r1,r8
	bra		gb_ret
	; Implement random replacement of disk block buffer
gb5:
	inc		blockbuf_dump
	lda		blockbuf_dump
	and		#$7ff
	ldx		#data_bufs
	mulu	r1,r1,#BUF_SIZE
	add		r2,r1
	lda		BUF_DEV,x
	cmp		#NO_DEV
	bne		gb7
gb9:
	ld		r8,r2
	stz		BUF_COUNT,x
	bra		gb8	
gb7:
	; If the buffer being dumped isn't dirty then we don't need to write it to disk
	lda		BUF_DIRTY,x
	cmp		#DIRTY
	bne		gb9
	txa
	ldx		#WRITING
	jsr		rw_block
	ld		r8,r1
	stz		BUF_COUNT,r1
	bra		gb8

;------------------------------------------------------------------------------
;
; Parameters:
;	r1 = pointer to buffer to put
;
;------------------------------------------------------------------------------
;
put_block:
	cmp		#0		; NULL pointer check
	bne		pb1
pb2:
	rts
pb1:
	dec		BUF_COUNT,r1	; if buf count > 0 then buffer is still in use
	bne		pb2
	dec		bufs_in_use
	rts
	
;------------------------------------------------------------------------------
; block_to_sector:
;	Convert a block number to a sector number.
;
; Parameters:
;	r1 = block number
; Returns:
;	r1 = sector number
;------------------------------------------------------------------------------
block_to_sector:
	phx
	pha
	jsr		get_log_block_size
	tax
	pla
	inx
	asl		r1,r1,r2
	plx
	rts
	
;------------------------------------------------------------------------------
; rw_block
;	This function should really go through a device driver interface, but for
; now just calls the spi read/write sector routines.
;	This routine currently assumes a block size of 1024 bytes (2 sectors).
; ToDo: add error handling
;
; Parameters:
;	r1 = pointer to buffer to operate on
;	r2 = R/W flag
;------------------------------------------------------------------------------
;
rw_block:
	phx
	phy
	pha
	ldy		BUF_DEV,r1
	cpy		#NO_DEV
	beq		rwb1
	cpx		#READING
	bne		rwb2
	tax
	add		r2,r2,#BUF_DATA
	lda		BUF_BLOCKNUM,r1
	jsr		block_to_sector
	pha
	asl		r2,r2,#2			; convert word address to byte address
	jsr		spi_read_sector
	pla
	ina
	add		r2,r2,#512
	jsr		spi_read_sector
	bra		rwb1
rwb2:
	tax
	add		r2,r2,#BUF_DATA
	lda		BUF_BLOCKNUM,r1
	jsr		block_to_sector
	pha
	asl		r2,r2,#2			; convert word address to byte address
	jsr		spi_write_sector
	pla
	ina
	add		r2,r2,#512
	jsr		spi_write_sector
rwb1:
	pla
	ldy		#CLEAN
	sty		BUF_DIRTY,r1
	ply
	plx
	rts

;------------------------------------------------------------------------------
; invalidate_dev
;	Cycle through all the block buffers and mark the buffers for the 
; matching device as free.
;
; Parameters:
;	r1 = device number
;------------------------------------------------------------------------------
;
invalidate_dev:
	phx
	phy
	push	r4
	ldy		#NR_BUFS
	ldx		#data_bufs
id2:
	ld		r4,BUF_DEV,x
	cmp		r4,r1
	bne		id1
	ld		r4,#NO_DEV
	st		r4,BUF_DEV,x
id1:
	add		r2,r2,#BUF_SIZE
	dey
	bne		id2

	ldy		#32
	ldx		#super_bufs
id3:
	ld		r4,s_dev,x
	cmp		r4,r1
	bne		id4
	ld		r4,#NO_DEV
	st		r4,s_dev,x
id4:
	add		r2,r2,#SUPERBUF_SIZE
	dey
	bne		id3

	pop		r4
	ply
	plx
	rts
	
;==============================================================================
;==============================================================================

; read the partition table to find out where the boot sector is.
; Returns
; r1 = 0 everything okay, 1=read error
; also Z=1=everything okay, Z=0=read error
;
spi_read_part2:
	phx
	stz		startSector						; default starting sector
	lda		#0								; r1 = sector number (#0)
	ldx		#BYTE_SECTOR_BUF				; r2 = target address (word to byte address)
	jsr		spi_read_sector
	cmp		#0
	bne		spi_rp1
	lb		r1,BYTE_SECTOR_BUF+$1C9
	asl		r1,r1,#8
	orb		r1,r1,BYTE_SECTOR_BUF+$1C8
	asl		r1,r1,#8
	orb		r1,r1,BYTE_SECTOR_BUF+$1C7
	asl		r1,r1,#8
	orb		r1,r1,BYTE_SECTOR_BUF+$1C6
	sta		startSector						; r1 = 0, for okay status
	lb		r1,BYTE_SECTOR_BUF+$1CD
	asl		r1,r1,#8
	orb		r1,r1,BYTE_SECTOR_BUF+$1CC
	asl		r1,r1,#8
	orb		r1,r1,BYTE_SECTOR_BUF+$1CB
	asl		r1,r1,#8
	orb		r1,r1,BYTE_SECTOR_BUF+$1CA
	sta		disk_size						; r1 = 0, for okay status
	plx
	lda		#0
	rts
spi_rp1:
	plx
	lda		#1
	rts



;==============================================================================
; DOS commands
;==============================================================================

;------------------------------------------------------------------------------
; MKFS - make file system
;------------------------------------------------------------------------------
;
;numb_block_group_sectors:
	; nbg = ((disk size in bytes / 
	;	(blocks  per block group * block size)) * block group descriptor size ) / block size + 1
	
	jsr		spi_init
	lda		#1024
	sta		block_size
	jsr		spi_read_part2
	jsr		get_super
	tax
	;	blocks_count = disk size * 512 / block size
	jsr		get_log_block_size
	tax
	inx
	lda		disk_size		; disk size in sectors
	lsr		r1,r1,r2		; r1 = disk size in blocks
	sta		s_block_count,x
	sta		s_free_blocks_count,x
	; # files = block count * block size / 2048 (average file size)
	lda		disk_size
	lsr
	lsr
	sta		s_inodes_count,x
	sta		s_free_inodes_count,x
	stz		s_log_block_size,x	; 0=1kB
	lda		#8192
	sta		s_blocks_per_group,x
	sta		s_inodes_per_group,x
	lda		#$EF54EF54
	sta		s_magic,x
	stz		s_errors,x
	jsr		get_filesystem_offset
	jsr		spi_write_sector		; put_block

	lda		disk_size
	div		r1,r1,#16384			; 8388608/512
	div		r1,r1,#32				; divide by size of block group descriptot
	add		r1,#1					; round up
	add		r4,r1,#2				; boot block + superblock
	; acc = number of blocks for descriptor table
	tay
	st		r4,bg_block_bitmap,
	rts	


