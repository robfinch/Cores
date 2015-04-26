	code
	align	16
public code SetNormAttr_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         push  r6
         lw    r1,24[bp]
         ldi   r6,#$22
         sys   #410
         pop   r6
     
disassem_416:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code GetNormAttr_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         push  r6
         ldi   r6,#$23
         sys   #410
         pop   r6
     
disassem_419:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code reverse_video_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_420
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	bsr  	GetNormAttr_
	      	mov  	r3,r1
	      	andi 	r3,r3,#4294967295
	      	andi 	r3,r3,#4294967295
	      	sh   	r3,-4[bp]
	      	lh   	r6,-4[bp]
	      	andi 	r6,r6,#4294967295
	      	asri 	r5,r6,#10
	      	asli 	r4,r5,#19
	      	lh   	r7,-4[bp]
	      	andi 	r7,r7,#4294967295
	      	asri 	r6,r7,#19
	      	asli 	r5,r6,#10
	      	or   	r3,r4,r5
	      	andi 	r3,r3,#4294967295
	      	sh   	r3,-4[bp]
	      	lh   	r3,-4[bp]
	      	push 	r3
	      	bsr  	SetNormAttr_
	      	addui	sp,sp,#8
disassem_422:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_420:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_422
endpublic

public code DumpInsnBytes_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_424
	      	mov  	bp,sp
	      	lw   	r5,32[bp]
	      	asri 	r4,r5,#24
	      	and  	r3,r4,#255
	      	push 	r3
	      	lw   	r5,32[bp]
	      	asri 	r4,r5,#16
	      	and  	r3,r4,#255
	      	push 	r3
	      	lw   	r5,32[bp]
	      	asri 	r4,r5,#8
	      	and  	r3,r4,#255
	      	push 	r3
	      	lw   	r4,32[bp]
	      	and  	r3,r4,#255
	      	push 	r3
	      	push 	24[bp]
	      	pea  	disassem_423[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#48
disassem_426:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_424:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_426
endpublic

DispRst_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_429
	      	mov  	bp,sp
	      	lw   	r5,24[bp]
	      	asri 	r4,r5,#12
	      	and  	r3,r4,#31
	      	push 	r3
	      	pea  	disassem_428[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_431:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_429:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_431
DispRstc_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_434
	      	mov  	bp,sp
	      	lw   	r5,24[bp]
	      	asri 	r4,r5,#12
	      	and  	r3,r4,#31
	      	push 	r3
	      	pea  	disassem_433[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_436:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_434:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_436
DispRac_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_439
	      	mov  	bp,sp
	      	lw   	r5,24[bp]
	      	asri 	r4,r5,#7
	      	and  	r3,r4,#31
	      	push 	r3
	      	pea  	disassem_438[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_441:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_439:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_441
DispRa_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_444
	      	mov  	bp,sp
	      	lw   	r5,24[bp]
	      	asri 	r4,r5,#7
	      	and  	r3,r4,#31
	      	push 	r3
	      	pea  	disassem_443[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_446:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_444:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_446
DispRb_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_449
	      	mov  	bp,sp
	      	lw   	r5,24[bp]
	      	asri 	r4,r5,#17
	      	and  	r3,r4,#31
	      	push 	r3
	      	pea  	disassem_448[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_451:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_449:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_451
DispSpr_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_468
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r5,24[bp]
	      	asri 	r4,r5,#17
	      	and  	r3,r4,#255
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_471
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_472
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_473
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_474
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_475
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_476
	      	cmp  	r4,r3,#9
	      	beq  	r4,disassem_477
	      	cmp  	r4,r3,#10
	      	beq  	r4,disassem_478
	      	cmp  	r4,r3,#50
	      	beq  	r4,disassem_479
	      	cmp  	r4,r3,#51
	      	beq  	r4,disassem_480
	      	cmp  	r4,r3,#52
	      	beq  	r4,disassem_481
	      	cmp  	r4,r3,#53
	      	beq  	r4,disassem_482
	      	cmp  	r4,r3,#54
	      	beq  	r4,disassem_483
	      	cmp  	r4,r3,#55
	      	beq  	r4,disassem_484
	      	bra  	disassem_485
disassem_471:
	      	pea  	disassem_453[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_470
disassem_472:
	      	pea  	disassem_454[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_470
disassem_473:
	      	pea  	disassem_455[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_470
disassem_474:
	      	pea  	disassem_456[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_470
disassem_475:
	      	pea  	disassem_457[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_470
disassem_476:
	      	pea  	disassem_458[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_470
disassem_477:
	      	pea  	disassem_459[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_470
disassem_478:
	      	pea  	disassem_460[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_470
disassem_479:
	      	pea  	disassem_461[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_470
disassem_480:
	      	pea  	disassem_462[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_470
disassem_481:
	      	pea  	disassem_463[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_470
disassem_482:
	      	pea  	disassem_464[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_470
disassem_483:
	      	pea  	disassem_465[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_470
disassem_484:
	      	pea  	disassem_466[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_470
disassem_485:
	      	push 	-8[bp]
	      	pea  	disassem_467[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_470:
disassem_486:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_468:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_486
DispMemAddress_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_492
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,40[bp]
	      	sh   	r3,-4[bp]
	      	lw   	r3,24[bp]
	      	beq  	r3,disassem_494
	      	lw   	r5,32[bp]
	      	asli 	r4,r5,#15
	      	lw   	r6,40[bp]
	      	asri 	r5,r6,#17
	      	or   	r3,r4,r5
	      	push 	r3
	      	pea  	disassem_488[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	disassem_495
disassem_494:
	      	lh   	r4,-4[bp]
	      	sxh  	r4,r4
	      	asri 	r3,r4,#17
	      	push 	r3
	      	pea  	disassem_489[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_495:
	      	lw   	r5,40[bp]
	      	asri 	r4,r5,#7
	      	and  	r3,r4,#31
	      	beq  	r3,disassem_496
	      	lw   	r5,40[bp]
	      	asri 	r4,r5,#7
	      	and  	r3,r4,#31
	      	push 	r3
	      	pea  	disassem_490[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	disassem_497
disassem_496:
	      	pea  	disassem_491[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
disassem_497:
disassem_498:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_492:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_498
	data
	align	8
	code
	align	16
DispInc_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_507
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	lw   	r3,40[bp]
	      	sh   	r3,-4[bp]
	      	lw   	r5,40[bp]
	      	asri 	r4,r5,#7
	      	and  	r3,r4,#31
	      	sw   	r3,-16[bp]
	      	lw   	r5,40[bp]
	      	asri 	r4,r5,#12
	      	and  	r3,r4,#31
	      	sw   	r3,-24[bp]
	      	lw   	r4,-24[bp]
	      	and  	r3,r4,#16
	      	cmp  	r4,r3,#16
	      	bne  	r4,disassem_509
	      	lw   	r3,-24[bp]
	      	ori  	r3,r3,#-16
	      	sw   	r3,-24[bp]
	      	lw   	r4,-24[bp]
	      	neg  	r3,r4
	      	sw   	r3,-24[bp]
	      	pea  	disassem_500[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_510
disassem_509:
	      	pea  	disassem_501[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
disassem_510:
	      	lw   	r3,24[bp]
	      	beq  	r3,disassem_511
	      	lw   	r5,32[bp]
	      	asli 	r4,r5,#15
	      	lw   	r6,40[bp]
	      	asri 	r5,r6,#17
	      	or   	r3,r4,r5
	      	push 	r3
	      	pea  	disassem_502[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	disassem_512
disassem_511:
	      	lh   	r4,-4[bp]
	      	sxh  	r4,r4
	      	asri 	r3,r4,#17
	      	push 	r3
	      	pea  	disassem_503[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_512:
	      	lw   	r3,-16[bp]
	      	bne  	r3,disassem_513
	      	pea  	disassem_504[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_514
disassem_513:
	      	push 	-16[bp]
	      	pea  	disassem_505[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_514:
	      	push 	-24[bp]
	      	pea  	disassem_506[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_515:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_507:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_515
PrintSc_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_519
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	cmp  	r4,r3,#1
	      	ble  	r4,disassem_521
	      	push 	24[bp]
	      	pea  	disassem_517[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	disassem_522
disassem_521:
	      	pea  	disassem_518[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
disassem_522:
disassem_523:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_519:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_523
DispBrk_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_529
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	lh   	r5,24[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#30
	      	and  	r3,r4,#3
	      	sw   	r3,-8[bp]
	      	lh   	r5,24[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#17
	      	and  	r3,r4,#511
	      	sw   	r3,-16[bp]
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_532
	      	cmp  	r4,r3,#1
	      	beq  	r4,disassem_533
	      	cmp  	r4,r3,#2
	      	beq  	r4,disassem_534
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_535
	      	bra  	disassem_531
disassem_532:
	      	push 	-16[bp]
	      	pea  	disassem_525[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_533:
	      	push 	-16[bp]
	      	pea  	disassem_526[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_534:
	      	push 	-16[bp]
	      	pea  	disassem_527[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_535:
	      	push 	-16[bp]
	      	pea  	disassem_528[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_531:
disassem_536:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_529:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_536
DispIndexedAddr_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_543
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	lh   	r4,40[bp]
	      	andi 	r4,r4,#4294967295
	      	asri 	r3,r4,#24
	      	sw   	r3,-8[bp]
	      	lh   	r5,40[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#7
	      	and  	r3,r4,#31
	      	sw   	r3,-16[bp]
	      	lh   	r5,40[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#12
	      	and  	r3,r4,#31
	      	sw   	r3,-32[bp]
	      	lh   	r5,40[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#17
	      	and  	r3,r4,#31
	      	sw   	r3,-24[bp]
	      	lh   	r5,40[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#22
	      	and  	r3,r4,#3
	      	sw   	r3,-40[bp]
	      	ldi  	r4,#1
	      	lw   	r5,-40[bp]
	      	asl  	r3,r4,r5
	      	sw   	r3,-40[bp]
	      	lh   	r3,40[bp]
	      	push 	r3
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	-32[bp]
	      	push 	32[bp]
	      	pea  	disassem_538[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#24
	      	lw   	r3,-8[bp]
	      	beq  	r3,disassem_545
	      	push 	-8[bp]
	      	pea  	disassem_539[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_545:
	      	lw   	r3,-16[bp]
	      	beq  	r3,disassem_547
	      	lw   	r3,-24[bp]
	      	beq  	r3,disassem_547
	      	pea  	disassem_540[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	push 	-40[bp]
	      	bsr  	PrintSc_
	      	addui	sp,sp,#8
	      	bra  	disassem_548
disassem_547:
	      	lw   	r3,-16[bp]
	      	bne  	r3,disassem_549
	      	push 	-24[bp]
	      	pea  	disassem_541[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	push 	-40[bp]
	      	bsr  	PrintSc_
	      	addui	sp,sp,#8
	      	bra  	disassem_550
disassem_549:
	      	lw   	r3,-24[bp]
	      	bne  	r3,disassem_551
	      	pea  	disassem_542[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
disassem_551:
disassem_550:
disassem_548:
disassem_553:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_543:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_553
DispLS_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_556
	      	mov  	bp,sp
	      	push 	56[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	pea  	disassem_555[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	push 	56[bp]
	      	bsr  	DispRstc_
	      	addui	sp,sp,#8
	      	push 	56[bp]
	      	push 	48[bp]
	      	push 	40[bp]
	      	bsr  	DispMemAddress_
	      	addui	sp,sp,#24
disassem_558:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_556:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_558
DispRI_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_563
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,56[bp]
	      	sh   	r3,-4[bp]
	      	push 	56[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	pea  	disassem_560[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	push 	56[bp]
	      	bsr  	DispRstc_
	      	addui	sp,sp,#8
	      	push 	56[bp]
	      	bsr  	DispRac_
	      	addui	sp,sp,#8
	      	lw   	r3,40[bp]
	      	beq  	r3,disassem_565
	      	lw   	r5,48[bp]
	      	asli 	r4,r5,#15
	      	lw   	r6,56[bp]
	      	asri 	r5,r6,#17
	      	or   	r3,r4,r5
	      	push 	r3
	      	pea  	disassem_561[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	disassem_566
disassem_565:
	      	lh   	r4,-4[bp]
	      	sxh  	r4,r4
	      	asri 	r3,r4,#17
	      	push 	r3
	      	pea  	disassem_562[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_566:
disassem_567:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_563:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_567
public code DispBcc_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_570
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	lw   	r6,40[bp]
	      	asri 	r5,r6,#17
	      	and  	r4,r5,#32767
	      	asli 	r3,r4,#2
	      	sw   	r3,-16[bp]
	      	lw   	r4,40[bp]
	      	and  	r3,r4,#2147483648
	      	beq  	r3,disassem_572
	      	lw   	r3,-16[bp]
	      	ori  	r3,r3,#-65536
	      	sw   	r3,-16[bp]
disassem_572:
	      	push 	40[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	pea  	disassem_568[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	push 	40[bp]
	      	bsr  	DispRac_
	      	addui	sp,sp,#8
	      	lw   	r4,24[bp]
	      	lw   	r5,-16[bp]
	      	addu 	r3,r4,r5
	      	push 	r3
	      	pea  	disassem_569[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_574:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_570:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_574
endpublic

public code DispRR_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_579
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	lh   	r4,40[bp]
	      	andi 	r4,r4,#4294967295
	      	asri 	r3,r4,#25
	      	sw   	r3,-8[bp]
	      	lh   	r5,40[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#17
	      	and  	r3,r4,#31
	      	sw   	r3,-16[bp]
	      	lh   	r3,40[bp]
	      	push 	r3
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#13
	      	bne  	r4,disassem_581
	      	lw   	r3,-16[bp]
	      	bne  	r3,disassem_581
	      	pea  	disassem_575[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	lh   	r3,40[bp]
	      	push 	r3
	      	bsr  	DispRstc_
	      	addui	sp,sp,#8
	      	lh   	r3,40[bp]
	      	push 	r3
	      	bsr  	DispRa_
	      	addui	sp,sp,#8
	      	pea  	disassem_576[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
disassem_583:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_581:
	      	push 	32[bp]
	      	pea  	disassem_577[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	lh   	r3,40[bp]
	      	push 	r3
	      	bsr  	DispRstc_
	      	addui	sp,sp,#8
	      	lh   	r3,40[bp]
	      	push 	r3
	      	bsr  	DispRac_
	      	addui	sp,sp,#8
	      	lh   	r3,40[bp]
	      	push 	r3
	      	bsr  	DispRb_
	      	addui	sp,sp,#8
	      	pea  	disassem_578[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_583
disassem_579:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_583
endpublic

public code DispJALI_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_592
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	lh   	r3,32[bp]
	      	sh   	r3,-20[bp]
	      	lh   	r5,32[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#12
	      	and  	r3,r4,#31
	      	sw   	r3,-8[bp]
	      	lh   	r5,32[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#7
	      	and  	r3,r4,#31
	      	sw   	r3,-16[bp]
	      	lh   	r3,32[bp]
	      	push 	r3
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	lw   	r3,-8[bp]
	      	beq  	r3,disassem_594
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#31
	      	beq  	r4,disassem_596
	      	pea  	disassem_584[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	lh   	r3,32[bp]
	      	push 	r3
	      	bsr  	DispRstc_
	      	addui	sp,sp,#8
	      	pea  	disassem_585[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_597
disassem_596:
	      	pea  	disassem_586[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
disassem_597:
	      	bra  	disassem_595
disassem_594:
	      	pea  	disassem_587[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
disassem_595:
	      	lw   	r3,40[bp]
	      	beq  	r3,disassem_598
	      	lw   	r5,48[bp]
	      	asli 	r4,r5,#15
	      	lh   	r6,32[bp]
	      	andi 	r6,r6,#4294967295
	      	asri 	r5,r6,#17
	      	or   	r3,r4,r5
	      	push 	r3
	      	pea  	disassem_588[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	disassem_599
disassem_598:
	      	lh   	r4,-20[bp]
	      	sxh  	r4,r4
	      	asri 	r3,r4,#17
	      	beq  	r3,disassem_600
	      	lh   	r4,-20[bp]
	      	sxh  	r4,r4
	      	asri 	r3,r4,#17
	      	push 	r3
	      	pea  	disassem_589[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_600:
disassem_599:
	      	lw   	r3,-16[bp]
	      	beq  	r3,disassem_602
	      	push 	-16[bp]
	      	pea  	disassem_590[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_602:
	      	pea  	disassem_591[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
disassem_604:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_592:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_604
endpublic

	data
	align	8
	align	8
	code
	align	16
public code disassem_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_690
	      	mov  	bp,sp
	      	subui	sp,sp,#96
	      	push 	r11
	      	push 	r12
	      	lw   	r11,24[bp]
	      	ldi  	r3,#0
	      	mov  	r12,r3
	      	sw   	r0,-40[bp]
	      	sw   	r0,-48[bp]
	      	ldi  	r3,#1
	      	sw   	r3,-88[bp]
	      	sw   	r0,-96[bp]
disassem_692:
	      	lw   	r3,[r11]
	      	lw   	r4,32[bp]
	      	cmp  	r5,r3,r4
	      	bne  	r5,disassem_694
	      	bsr  	reverse_video_
	      	ldi  	r3,#1
	      	sw   	r3,-96[bp]
disassem_694:
	      	lw   	r4,[r11]
	      	asri 	r3,r4,#2
	      	sw   	r3,-72[bp]
	      	lw   	r4,-72[bp]
	      	asli 	r3,r4,#2
	      	lhu  	r4,0[r12+r3]
	      	sh   	r4,-12[bp]
	      	lh   	r3,-12[bp]
	      	sh   	r3,-76[bp]
	      	lh   	r4,-12[bp]
	      	and  	r3,r4,#127
	      	sw   	r3,-24[bp]
	      	lh   	r5,-12[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#25
	      	and  	r3,r4,#127
	      	sw   	r3,-32[bp]
	      	lw   	r3,-24[bp]
	      	cmp  	r4,r3,#124
	      	beq  	r4,disassem_697
	      	cmp  	r4,r3,#2
	      	beq  	r4,disassem_698
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_699
	      	cmp  	r4,r3,#20
	      	beq  	r4,disassem_700
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_701
	      	cmp  	r4,r3,#21
	      	beq  	r4,disassem_702
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_703
	      	cmp  	r4,r3,#22
	      	beq  	r4,disassem_704
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_705
	      	cmp  	r4,r3,#23
	      	beq  	r4,disassem_706
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_707
	      	cmp  	r4,r3,#24
	      	beq  	r4,disassem_708
	      	cmp  	r4,r3,#12
	      	beq  	r4,disassem_709
	      	cmp  	r4,r3,#13
	      	beq  	r4,disassem_710
	      	cmp  	r4,r3,#14
	      	beq  	r4,disassem_711
	      	cmp  	r4,r3,#61
	      	beq  	r4,disassem_712
	      	cmp  	r4,r3,#62
	      	beq  	r4,disassem_713
	      	cmp  	r4,r3,#56
	      	beq  	r4,disassem_714
	      	cmp  	r4,r3,#57
	      	beq  	r4,disassem_715
	      	cmp  	r4,r3,#58
	      	beq  	r4,disassem_716
	      	cmp  	r4,r3,#55
	      	beq  	r4,disassem_717
	      	cmp  	r4,r3,#59
	      	beq  	r4,disassem_718
	      	cmp  	r4,r3,#64
	      	beq  	r4,disassem_719
	      	cmp  	r4,r3,#65
	      	beq  	r4,disassem_720
	      	cmp  	r4,r3,#66
	      	beq  	r4,disassem_721
	      	cmp  	r4,r3,#67
	      	beq  	r4,disassem_722
	      	cmp  	r4,r3,#68
	      	beq  	r4,disassem_723
	      	cmp  	r4,r3,#69
	      	beq  	r4,disassem_724
	      	cmp  	r4,r3,#70
	      	beq  	r4,disassem_725
	      	cmp  	r4,r3,#71
	      	beq  	r4,disassem_726
	      	cmp  	r4,r3,#72
	      	beq  	r4,disassem_727
	      	cmp  	r4,r3,#73
	      	beq  	r4,disassem_728
	      	cmp  	r4,r3,#74
	      	beq  	r4,disassem_729
	      	cmp  	r4,r3,#75
	      	beq  	r4,disassem_730
	      	cmp  	r4,r3,#76
	      	beq  	r4,disassem_731
	      	cmp  	r4,r3,#77
	      	beq  	r4,disassem_732
	      	cmp  	r4,r3,#78
	      	beq  	r4,disassem_733
	      	cmp  	r4,r3,#79
	      	beq  	r4,disassem_734
	      	cmp  	r4,r3,#100
	      	beq  	r4,disassem_735
	      	cmp  	r4,r3,#96
	      	beq  	r4,disassem_736
	      	cmp  	r4,r3,#97
	      	beq  	r4,disassem_737
	      	cmp  	r4,r3,#98
	      	beq  	r4,disassem_738
	      	cmp  	r4,r3,#99
	      	beq  	r4,disassem_739
	      	cmp  	r4,r3,#104
	      	beq  	r4,disassem_740
	      	cmp  	r4,r3,#105
	      	beq  	r4,disassem_741
	      	cmp  	r4,r3,#106
	      	beq  	r4,disassem_742
	      	cmp  	r4,r3,#107
	      	beq  	r4,disassem_743
	      	cmp  	r4,r3,#92
	      	beq  	r4,disassem_744
	      	cmp  	r4,r3,#110
	      	beq  	r4,disassem_745
	      	cmp  	r4,r3,#103
	      	beq  	r4,disassem_746
	      	cmp  	r4,r3,#87
	      	beq  	r4,disassem_747
	      	cmp  	r4,r3,#63
	      	beq  	r4,disassem_748
	      	cmp  	r4,r3,#10
	      	beq  	r4,disassem_749
	      	bra  	disassem_750
disassem_697:
	      	ldi  	r3,#1
	      	sw   	r3,-40[bp]
	      	lw   	r3,-88[bp]
	      	beq  	r3,disassem_751
	      	lh   	r4,-76[bp]
	      	sxh  	r4,r4
	      	asri 	r3,r4,#7
	      	sw   	r3,-48[bp]
	      	lw   	r4,-48[bp]
	      	and  	r3,r4,#16777216
	      	beq  	r3,disassem_753
	      	lw   	r3,-48[bp]
	      	ori  	r3,r3,#-16777216
	      	sw   	r3,-48[bp]
disassem_753:
	      	bra  	disassem_752
disassem_751:
	      	lw   	r5,-48[bp]
	      	asli 	r4,r5,#25
	      	lh   	r6,-12[bp]
	      	andi 	r6,r6,#4294967295
	      	asri 	r5,r6,#7
	      	or   	r3,r4,r5
	      	sw   	r3,-48[bp]
disassem_752:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	pea  	disassem_605[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	sw   	r0,-88[bp]
	      	bra  	disassem_696
disassem_698:
	      	lw   	r3,-32[bp]
	      	cmp  	r4,r3,#55
	      	beq  	r4,disassem_756
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_757
	      	cmp  	r4,r3,#20
	      	beq  	r4,disassem_758
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_759
	      	cmp  	r4,r3,#21
	      	beq  	r4,disassem_760
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_761
	      	cmp  	r4,r3,#22
	      	beq  	r4,disassem_762
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_763
	      	cmp  	r4,r3,#23
	      	beq  	r4,disassem_764
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_765
	      	cmp  	r4,r3,#24
	      	beq  	r4,disassem_766
	      	cmp  	r4,r3,#12
	      	beq  	r4,disassem_767
	      	cmp  	r4,r3,#13
	      	beq  	r4,disassem_768
	      	cmp  	r4,r3,#14
	      	beq  	r4,disassem_769
	      	cmp  	r4,r3,#31
	      	beq  	r4,disassem_770
	      	cmp  	r4,r3,#30
	      	beq  	r4,disassem_771
	      	bra  	disassem_755
disassem_756:
	      	lh   	r5,-12[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#17
	      	and  	r3,r4,#31
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_773
	      	cmp  	r4,r3,#1
	      	beq  	r4,disassem_774
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_775
	      	cmp  	r4,r3,#29
	      	beq  	r4,disassem_776
	      	cmp  	r4,r3,#30
	      	beq  	r4,disassem_777
	      	cmp  	r4,r3,#31
	      	beq  	r4,disassem_778
	      	bra  	disassem_779
disassem_773:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	pea  	disassem_606[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_772
disassem_774:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	pea  	disassem_607[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_772
disassem_775:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	pea  	disassem_608[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_772
disassem_776:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	pea  	disassem_609[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_772
disassem_777:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	pea  	disassem_610[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_772
disassem_778:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	pea  	disassem_611[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_772
disassem_779:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	pea  	disassem_612[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_772
disassem_772:
	      	bra  	disassem_755
disassem_757:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_613[gp]
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_755
disassem_758:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_614[gp]
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_755
disassem_759:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_615[gp]
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_755
disassem_760:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_616[gp]
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_755
disassem_761:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_617[gp]
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_755
disassem_762:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_618[gp]
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_755
disassem_763:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_619[gp]
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_755
disassem_764:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_620[gp]
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_755
disassem_765:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_621[gp]
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_755
disassem_766:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_622[gp]
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_755
disassem_767:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_623[gp]
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_755
disassem_768:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_624[gp]
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_755
disassem_769:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_625[gp]
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_755
disassem_770:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	pea  	disassem_626[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRstc_
	      	addui	sp,sp,#8
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispSpr_
	      	addui	sp,sp,#8
	      	pea  	disassem_627[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_755
disassem_771:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	pea  	disassem_628[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispSpr_
	      	addui	sp,sp,#8
	      	pea  	disassem_629[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRa_
	      	addui	sp,sp,#8
	      	pea  	disassem_630[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_755
disassem_755:
	      	bra  	disassem_696
disassem_699:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_631[gp]
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_700:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_632[gp]
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_701:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_633[gp]
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_702:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_634[gp]
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_703:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_635[gp]
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_704:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_636[gp]
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_705:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_637[gp]
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_706:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_638[gp]
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_707:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_639[gp]
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_708:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_640[gp]
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_709:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_641[gp]
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_710:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_642[gp]
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_711:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_643[gp]
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_712:
	      	lh   	r5,-12[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#12
	      	and  	r3,r4,#7
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_781
	      	cmp  	r4,r3,#1
	      	beq  	r4,disassem_782
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_783
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_784
	      	cmp  	r4,r3,#2
	      	beq  	r4,disassem_785
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_786
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_787
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_787
	      	bra  	disassem_780
disassem_781:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_644[gp]
	      	push 	[r11]
	      	bsr  	DispBcc_
	      	addui	sp,sp,#24
	      	bra  	disassem_780
disassem_782:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_645[gp]
	      	push 	[r11]
	      	bsr  	DispBcc_
	      	addui	sp,sp,#24
	      	bra  	disassem_780
disassem_783:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_646[gp]
	      	push 	[r11]
	      	bsr  	DispBcc_
	      	addui	sp,sp,#24
	      	bra  	disassem_780
disassem_784:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_647[gp]
	      	push 	[r11]
	      	bsr  	DispBcc_
	      	addui	sp,sp,#24
	      	bra  	disassem_780
disassem_785:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_648[gp]
	      	push 	[r11]
	      	bsr  	DispBcc_
	      	addui	sp,sp,#24
	      	bra  	disassem_780
disassem_786:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_649[gp]
	      	push 	[r11]
	      	bsr  	DispBcc_
	      	addui	sp,sp,#24
	      	bra  	disassem_780
disassem_787:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_650[gp]
	      	push 	[r11]
	      	bsr  	DispBcc_
	      	addui	sp,sp,#24
	      	bra  	disassem_780
disassem_780:
	      	bra  	disassem_696
disassem_713:
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DispJALI_
	      	addui	sp,sp,#32
	      	bra  	disassem_696
disassem_714:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispBrk_
	      	addui	sp,sp,#8
	      	bra  	disassem_696
disassem_715:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	lh   	r4,-12[bp]
	      	andi 	r4,r4,#4294967295
	      	asri 	r3,r4,#7
	      	sw   	r3,-64[bp]
	      	lh   	r4,-12[bp]
	      	and  	r3,r4,#2147483648
	      	beq  	r3,disassem_788
	      	lw   	r3,-64[bp]
	      	ori  	r3,r3,#-16777216
	      	sw   	r3,-64[bp]
disassem_788:
	      	lw   	r4,[r11]
	      	lw   	r6,-64[bp]
	      	asli 	r5,r6,#2
	      	addu 	r3,r4,r5
	      	sw   	r3,-56[bp]
	      	push 	-56[bp]
	      	pea  	disassem_651[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	disassem_696
disassem_716:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	lh   	r4,-12[bp]
	      	andi 	r4,r4,#4294967295
	      	asri 	r3,r4,#7
	      	sw   	r3,-64[bp]
	      	lh   	r4,-12[bp]
	      	and  	r3,r4,#2147483648
	      	beq  	r3,disassem_790
	      	lw   	r3,-64[bp]
	      	ori  	r3,r3,#-16777216
	      	sw   	r3,-64[bp]
disassem_790:
	      	lw   	r4,[r11]
	      	lw   	r6,-64[bp]
	      	asli 	r5,r6,#2
	      	addu 	r3,r4,r5
	      	sw   	r3,-56[bp]
	      	push 	-56[bp]
	      	pea  	disassem_652[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	disassem_696
disassem_717:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	lh   	r4,-12[bp]
	      	andi 	r4,r4,#4294967295
	      	asri 	r3,r4,#17
	      	sw   	r3,-56[bp]
	      	push 	-56[bp]
	      	pea  	disassem_653[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	disassem_696
disassem_718:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	lh   	r4,-12[bp]
	      	andi 	r4,r4,#4294967295
	      	asri 	r3,r4,#17
	      	sw   	r3,-56[bp]
	      	push 	-56[bp]
	      	pea  	disassem_654[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	disassem_696
disassem_719:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_655[gp]
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_720:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_656[gp]
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_721:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_657[gp]
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_722:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_658[gp]
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_723:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_659[gp]
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_724:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_660[gp]
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_725:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_661[gp]
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_726:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_662[gp]
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_727:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_663[gp]
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_696
disassem_728:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_664[gp]
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_696
disassem_729:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_665[gp]
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_696
disassem_730:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_666[gp]
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_696
disassem_731:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_667[gp]
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_696
disassem_732:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_668[gp]
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_696
disassem_733:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_669[gp]
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_696
disassem_734:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_670[gp]
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_696
disassem_735:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	bsr  	DispInc_
	      	addui	sp,sp,#24
	      	bra  	disassem_696
disassem_736:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_671[gp]
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_737:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_672[gp]
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_738:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_673[gp]
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_739:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_674[gp]
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_740:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_675[gp]
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_696
disassem_741:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_676[gp]
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_696
disassem_742:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_677[gp]
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_696
disassem_743:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	pea  	disassem_678[gp]
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_696
disassem_744:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_679[gp]
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_745:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	pea  	disassem_680[gp]
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_696
disassem_746:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	pea  	disassem_681[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRa_
	      	addui	sp,sp,#8
	      	pea  	disassem_682[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_696
disassem_747:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	pea  	disassem_683[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRst_
	      	addui	sp,sp,#8
	      	pea  	disassem_684[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_696
disassem_748:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	pea  	disassem_685[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_696
disassem_749:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	pea  	disassem_686[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRstc_
	      	addui	sp,sp,#8
	      	lw   	r3,-40[bp]
	      	beq  	r3,disassem_792
	      	lw   	r5,-48[bp]
	      	asli 	r4,r5,#15
	      	lh   	r6,-12[bp]
	      	andi 	r6,r6,#4294967295
	      	asri 	r5,r6,#17
	      	or   	r3,r4,r5
	      	push 	r3
	      	pea  	disassem_687[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	disassem_793
disassem_792:
	      	lh   	r4,-76[bp]
	      	sxh  	r4,r4
	      	asri 	r3,r4,#17
	      	push 	r3
	      	pea  	disassem_688[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_793:
	      	bra  	disassem_696
disassem_750:
	      	lh   	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	pea  	disassem_689[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_696
disassem_696:
	      	lw   	r4,[r11]
	      	addu 	r3,r4,#4
	      	sw   	r3,[r11]
	      	lw   	r3,-96[bp]
	      	beq  	r3,disassem_794
	      	bsr  	reverse_video_
	      	sw   	r0,-96[bp]
disassem_794:
	      	lw   	r3,-24[bp]
	      	cmp  	r4,r3,#124
	      	beq  	r4,disassem_692
disassem_693:
disassem_796:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_690:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_796
endpublic

public code disassem20_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_798
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	pea  	disassem_797[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	sw   	r0,-8[bp]
disassem_800:
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#16
	      	bge  	r4,disassem_801
	      	push 	32[bp]
	      	pea  	24[bp]
	      	bsr  	disassem_
	      	addui	sp,sp,#16
disassem_802:
	      	inc  	-8[bp],#1
	      	bra  	disassem_800
disassem_801:
disassem_803:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_798:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_803
endpublic

	rodata
	align	16
	align	8
disassem_797:
	dc	68,105,115,97,115,115,101,109
	dc	58,13,10,0
disassem_689:
	dc	63,63,63,63,63,13,10,0
disassem_688:
	dc	35,36,37,88,13,10,0
disassem_687:
	dc	35,36,37,88,13,10,0
disassem_686:
	dc	76,68,73,32,32,32,0
disassem_685:
	dc	78,79,80,13,10,0
disassem_684:
	dc	13,10,0
disassem_683:
	dc	80,79,80,32,32,32,0
disassem_682:
	dc	13,10,0
disassem_681:
	dc	80,85,83,72,32,32,0
disassem_680:
	dc	83,87,67,82,32,0
disassem_679:
	dc	76,87,65,82,32,0
disassem_678:
	dc	83,87,32,32,32,0
disassem_677:
	dc	83,72,32,32,32,0
disassem_676:
	dc	83,67,32,32,32,0
disassem_675:
	dc	83,66,32,32,32,0
disassem_674:
	dc	83,87,32,32,32,0
disassem_673:
	dc	83,72,32,32,32,0
disassem_672:
	dc	83,67,32,32,32,0
disassem_671:
	dc	83,66,32,32,32,0
disassem_670:
	dc	76,69,65,32,32,0
disassem_669:
	dc	76,87,32,32,32,0
disassem_668:
	dc	76,72,85,32,32,0
disassem_667:
	dc	76,72,32,32,32,0
disassem_666:
	dc	76,67,85,32,32,0
disassem_665:
	dc	76,67,32,32,32,0
disassem_664:
	dc	76,66,85,32,32,0
disassem_663:
	dc	76,66,32,32,32,0
disassem_662:
	dc	76,69,65,32,32,0
disassem_661:
	dc	76,87,32,32,32,0
disassem_660:
	dc	76,72,85,32,32,0
disassem_659:
	dc	76,72,32,32,32,0
disassem_658:
	dc	76,67,85,32,32,0
disassem_657:
	dc	76,67,32,32,32,0
disassem_656:
	dc	76,66,85,32,32,0
disassem_655:
	dc	76,66,32,32,32,0
disassem_654:
	dc	82,84,83,32,32,32,35,37
	dc	88,13,10,0
disassem_653:
	dc	82,84,76,32,32,32,35,37
	dc	88,13,10,0
disassem_652:
	dc	66,82,65,32,32,32,36,37
	dc	88,13,10,0
disassem_651:
	dc	66,83,82,32,32,32,36,37
	dc	88,13,10,0
disassem_650:
	dc	63,63,63,32,32,0
disassem_649:
	dc	66,71,69,32,32,0
disassem_648:
	dc	66,71,84,32,32,0
disassem_647:
	dc	66,76,69,32,32,0
disassem_646:
	dc	66,76,84,32,32,0
disassem_645:
	dc	66,78,69,32,32,0
disassem_644:
	dc	66,69,81,32,32,0
disassem_643:
	dc	69,79,82,32,32,0
disassem_642:
	dc	79,82,32,32,32,0
disassem_641:
	dc	65,78,68,32,32,0
disassem_640:
	dc	68,73,86,85,32,0
disassem_639:
	dc	68,73,86,32,32,0
disassem_638:
	dc	77,85,76,85,32,0
disassem_637:
	dc	77,85,76,32,32,0
disassem_636:
	dc	67,77,80,85,32,0
disassem_635:
	dc	67,77,80,32,32,0
disassem_634:
	dc	83,85,66,85,32,0
disassem_633:
	dc	83,85,66,32,32,0
disassem_632:
	dc	65,68,68,85,32,0
disassem_631:
	dc	65,68,68,32,32,0
disassem_630:
	dc	13,10,0
disassem_629:
	dc	44,0
disassem_628:
	dc	77,84,83,80,82,32,0
disassem_627:
	dc	13,10,0
disassem_626:
	dc	77,70,83,80,82,32,0
disassem_625:
	dc	69,79,82,32,32,0
disassem_624:
	dc	79,82,32,32,32,0
disassem_623:
	dc	65,78,68,32,32,0
disassem_622:
	dc	68,73,86,85,32,0
disassem_621:
	dc	68,73,86,32,32,0
disassem_620:
	dc	77,85,76,85,32,0
disassem_619:
	dc	77,85,76,32,32,0
disassem_618:
	dc	67,77,80,85,32,0
disassem_617:
	dc	67,77,80,32,32,0
disassem_616:
	dc	83,85,66,85,32,0
disassem_615:
	dc	83,85,66,32,32,0
disassem_614:
	dc	65,68,68,85,32,0
disassem_613:
	dc	65,68,68,32,32,0
disassem_612:
	dc	63,63,63,13,10,0
disassem_611:
	dc	82,84,73,13,10,0
disassem_610:
	dc	82,84,69,13,10,0
disassem_609:
	dc	82,84,68,13,10,0
disassem_608:
	dc	87,65,73,13,10,0
disassem_607:
	dc	83,69,73,13,10,0
disassem_606:
	dc	67,76,73,13,10,0
disassem_605:
	dc	73,77,77,13,10,0
disassem_591:
	dc	41,13,10,0
disassem_590:
	dc	91,82,37,100,93,0
disassem_589:
	dc	36,37,88,0
disassem_588:
	dc	36,37,88,0
disassem_587:
	dc	74,77,80,32,32,32,40,0
disassem_586:
	dc	74,83,82,32,32,32,40,0
disassem_585:
	dc	40,0
disassem_584:
	dc	74,65,76,32,32,32,0
disassem_578:
	dc	13,10,0
disassem_577:
	dc	37,115,32,0
disassem_576:
	dc	13,10,0
disassem_575:
	dc	77,79,86,32,32,32,0
disassem_569:
	dc	37,48,54,88,13,10,0
disassem_568:
	dc	37,115,32,0
disassem_562:
	dc	35,36,37,88,13,10,0
disassem_561:
	dc	35,36,37,88,13,10,0
disassem_560:
	dc	37,115,32,0
disassem_555:
	dc	37,115,32,0
disassem_542:
	dc	91,82,37,100,93,13,10,0
disassem_541:
	dc	91,82,37,100,0
disassem_540:
	dc	91,82,37,100,43,82,37,100
	dc	0
disassem_539:
	dc	36,37,88,0
disassem_538:
	dc	37,115,32,82,37,100,44,0
disassem_528:
	dc	66,82,75,63,32,32,35,37
	dc	88,13,10,0
disassem_527:
	dc	73,78,84,32,32,32,35,37
	dc	88,13,10,0
disassem_526:
	dc	68,66,71,32,32,32,35,37
	dc	88,13,10,0
disassem_525:
	dc	83,89,83,32,32,32,35,37
	dc	88,13,10,0
disassem_518:
	dc	93,13,10,0
disassem_517:
	dc	42,37,100,93,13,10,0
disassem_506:
	dc	35,37,100,13,10,0
disassem_505:
	dc	91,82,37,100,93,44,0
disassem_504:
	dc	44,0
disassem_503:
	dc	36,37,88,0
disassem_502:
	dc	36,37,88,0
disassem_501:
	dc	73,78,67,32,32,32,0
disassem_500:
	dc	68,69,67,32,32,32,0
disassem_491:
	dc	13,10,0
disassem_490:
	dc	91,82,37,100,93,13,10,0
disassem_489:
	dc	36,37,88,0
disassem_488:
	dc	36,37,88,0
disassem_467:
	dc	83,80,82,37,100,0
disassem_466:
	dc	68,66,83,84,65,84,0
disassem_465:
	dc	68,66,67,84,82,76,0
disassem_464:
	dc	68,66,65,68,51,0
disassem_463:
	dc	68,66,65,68,50,0
disassem_462:
	dc	68,66,65,68,49,0
disassem_461:
	dc	68,66,65,68,48,0
disassem_460:
	dc	86,66,82,0
disassem_459:
	dc	69,80,67,0
disassem_458:
	dc	73,80,67,0
disassem_457:
	dc	68,80,67,0
disassem_456:
	dc	67,76,75,0
disassem_455:
	dc	84,73,67,75,0
disassem_454:
	dc	67,82,51,0
disassem_453:
	dc	67,82,48,0
disassem_448:
	dc	82,37,100,0
disassem_443:
	dc	82,37,100,0
disassem_438:
	dc	82,37,100,44,0
disassem_433:
	dc	82,37,100,44,0
disassem_428:
	dc	114,37,100,0
disassem_423:
	dc	37,48,54,88,32,37,48,50
	dc	88,32,37,48,50,88,32,37
	dc	48,50,88,32,37,48,50,88
	dc	9,0
;	global	DispJALI_
;	global	disassem20_
	extern	putstr2_
;	global	DispRR_
;	global	DumpInsnBytes_
;	global	GetNormAttr_
;	global	disassem_
;	global	SetNormAttr_
;	global	reverse_video_
	extern	printf_
;	global	DispBcc_
