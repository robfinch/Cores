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
     
disassem_386:
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
     
disassem_388:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code reverse_video_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_389
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	bsr  	GetNormAttr_
	      	mov  	r3,r1
	      	andi 	r3,r3,#4294967295
	      	sh   	r3,-4[bp]
	      	lhu  	r6,-4[bp]
	      	andi 	r6,r6,#4294967295
	      	asri 	r5,r6,#10
	      	asli 	r4,r5,#19
	      	lhu  	r7,-4[bp]
	      	andi 	r7,r7,#4294967295
	      	asri 	r6,r7,#19
	      	asli 	r5,r6,#10
	      	or   	r3,r4,r5
	      	sh   	r3,-4[bp]
	      	lhu  	r3,-4[bp]
	      	push 	r3
	      	bsr  	SetNormAttr_
	      	addui	sp,sp,#8
disassem_390:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_389:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_390
endpublic

public code DumpInsnBytes_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_392
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
	      	push 	#disassem_391
	      	bsr  	printf_
	      	addui	sp,sp,#48
disassem_393:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_392:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_393
endpublic

DispRst_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_396
	      	mov  	bp,sp
	      	lw   	r5,24[bp]
	      	asri 	r4,r5,#12
	      	and  	r3,r4,#31
	      	push 	r3
	      	push 	#disassem_395
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_397:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_396:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_397
DispRstc_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_400
	      	mov  	bp,sp
	      	lw   	r5,24[bp]
	      	asri 	r4,r5,#12
	      	and  	r3,r4,#31
	      	push 	r3
	      	push 	#disassem_399
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_401:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_400:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_401
DispRac_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_404
	      	mov  	bp,sp
	      	lw   	r5,24[bp]
	      	asri 	r4,r5,#7
	      	and  	r3,r4,#31
	      	push 	r3
	      	push 	#disassem_403
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_405:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_404:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_405
DispRa_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_408
	      	mov  	bp,sp
	      	lw   	r5,24[bp]
	      	asri 	r4,r5,#7
	      	and  	r3,r4,#31
	      	push 	r3
	      	push 	#disassem_407
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_409:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_408:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_409
DispRb_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_412
	      	mov  	bp,sp
	      	lw   	r5,24[bp]
	      	asri 	r4,r5,#17
	      	and  	r3,r4,#31
	      	push 	r3
	      	push 	#disassem_411
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_413:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_412:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_413
DispSpr_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_430
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r5,24[bp]
	      	asri 	r4,r5,#17
	      	and  	r3,r4,#255
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_432
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_433
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_434
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_435
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_436
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_437
	      	cmp  	r4,r3,#9
	      	beq  	r4,disassem_438
	      	cmp  	r4,r3,#10
	      	beq  	r4,disassem_439
	      	cmp  	r4,r3,#50
	      	beq  	r4,disassem_440
	      	cmp  	r4,r3,#51
	      	beq  	r4,disassem_441
	      	cmp  	r4,r3,#52
	      	beq  	r4,disassem_442
	      	cmp  	r4,r3,#53
	      	beq  	r4,disassem_443
	      	cmp  	r4,r3,#54
	      	beq  	r4,disassem_444
	      	cmp  	r4,r3,#55
	      	beq  	r4,disassem_445
	      	bra  	disassem_446
disassem_432:
	      	push 	#disassem_415
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_431
disassem_433:
	      	push 	#disassem_416
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_431
disassem_434:
	      	push 	#disassem_417
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_431
disassem_435:
	      	push 	#disassem_418
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_431
disassem_436:
	      	push 	#disassem_419
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_431
disassem_437:
	      	push 	#disassem_420
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_431
disassem_438:
	      	push 	#disassem_421
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_431
disassem_439:
	      	push 	#disassem_422
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_431
disassem_440:
	      	push 	#disassem_423
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_431
disassem_441:
	      	push 	#disassem_424
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_431
disassem_442:
	      	push 	#disassem_425
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_431
disassem_443:
	      	push 	#disassem_426
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_431
disassem_444:
	      	push 	#disassem_427
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_431
disassem_445:
	      	push 	#disassem_428
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_431
disassem_446:
	      	push 	-8[bp]
	      	push 	#disassem_429
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_431:
disassem_447:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_430:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_447
DispMemAddress_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_453
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,40[bp]
	      	sh   	r3,-4[bp]
	      	lw   	r3,24[bp]
	      	beq  	r3,disassem_454
	      	lw   	r5,32[bp]
	      	asli 	r4,r5,#15
	      	lw   	r6,40[bp]
	      	asri 	r5,r6,#17
	      	or   	r3,r4,r5
	      	push 	r3
	      	push 	#disassem_449
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	disassem_455
disassem_454:
	      	lh   	r4,-4[bp]
	      	sxh  	r4,r4
	      	asri 	r3,r4,#17
	      	push 	r3
	      	push 	#disassem_450
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_455:
	      	lw   	r5,40[bp]
	      	asri 	r4,r5,#7
	      	and  	r3,r4,#31
	      	beq  	r3,disassem_456
	      	lw   	r5,40[bp]
	      	asri 	r4,r5,#7
	      	and  	r3,r4,#31
	      	push 	r3
	      	push 	#disassem_451
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	disassem_457
disassem_456:
	      	push 	#disassem_452
	      	bsr  	printf_
	      	addui	sp,sp,#8
disassem_457:
disassem_458:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_453:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_458
	data
	align	8
	code
	align	16
DispInc_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_467
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
	      	bne  	r4,disassem_468
	      	lw   	r3,-24[bp]
	      	ori  	r3,r3,#-16
	      	sw   	r3,-24[bp]
	      	lw   	r3,-24[bp]
	      	neg  	r3,r3
	      	sw   	r3,-24[bp]
	      	push 	#disassem_460
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_469
disassem_468:
	      	push 	#disassem_461
	      	bsr  	printf_
	      	addui	sp,sp,#8
disassem_469:
	      	lw   	r3,24[bp]
	      	beq  	r3,disassem_470
	      	lw   	r5,32[bp]
	      	asli 	r4,r5,#15
	      	lw   	r6,40[bp]
	      	asri 	r5,r6,#17
	      	or   	r3,r4,r5
	      	push 	r3
	      	push 	#disassem_462
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	disassem_471
disassem_470:
	      	lh   	r4,-4[bp]
	      	sxh  	r4,r4
	      	asri 	r3,r4,#17
	      	push 	r3
	      	push 	#disassem_463
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_471:
	      	lw   	r3,-16[bp]
	      	bne  	r3,disassem_472
	      	push 	#disassem_464
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_473
disassem_472:
	      	push 	-16[bp]
	      	push 	#disassem_465
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_473:
	      	push 	-24[bp]
	      	push 	#disassem_466
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_474:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_467:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_474
PrintSc_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_478
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	cmp  	r4,r3,#1
	      	ble  	r4,disassem_479
	      	push 	24[bp]
	      	push 	#disassem_476
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	disassem_480
disassem_479:
	      	push 	#disassem_477
	      	bsr  	printf_
	      	addui	sp,sp,#8
disassem_480:
disassem_481:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_478:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_481
DispBrk_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_487
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	lhu  	r5,24[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#30
	      	and  	r3,r4,#3
	      	sw   	r3,-8[bp]
	      	lhu  	r5,24[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#17
	      	and  	r3,r4,#511
	      	sw   	r3,-16[bp]
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_489
	      	cmp  	r4,r3,#1
	      	beq  	r4,disassem_490
	      	cmp  	r4,r3,#2
	      	beq  	r4,disassem_491
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_492
	      	bra  	disassem_488
disassem_489:
	      	push 	-16[bp]
	      	push 	#disassem_483
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_490:
	      	push 	-16[bp]
	      	push 	#disassem_484
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_491:
	      	push 	-16[bp]
	      	push 	#disassem_485
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_492:
	      	push 	-16[bp]
	      	push 	#disassem_486
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_488:
disassem_493:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_487:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_493
DispIndexedAddr_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_500
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	lhu  	r4,40[bp]
	      	andi 	r4,r4,#4294967295
	      	asri 	r3,r4,#24
	      	sw   	r3,-8[bp]
	      	lhu  	r5,40[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#7
	      	and  	r3,r4,#31
	      	sw   	r3,-16[bp]
	      	lhu  	r5,40[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#12
	      	and  	r3,r4,#31
	      	sw   	r3,-32[bp]
	      	lhu  	r5,40[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#17
	      	and  	r3,r4,#31
	      	sw   	r3,-24[bp]
	      	lhu  	r5,40[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#22
	      	and  	r3,r4,#3
	      	sw   	r3,-40[bp]
	      	ldi  	r4,#1
	      	lw   	r5,-40[bp]
	      	asl  	r3,r4,r5
	      	sw   	r3,-40[bp]
	      	lhu  	r3,40[bp]
	      	push 	r3
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	-32[bp]
	      	push 	32[bp]
	      	push 	#disassem_495
	      	bsr  	printf_
	      	addui	sp,sp,#24
	      	lw   	r3,-8[bp]
	      	beq  	r3,disassem_501
	      	push 	-8[bp]
	      	push 	#disassem_496
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_501:
	      	lw   	r3,-16[bp]
	      	beq  	r3,disassem_503
	      	lw   	r3,-24[bp]
	      	beq  	r3,disassem_503
	      	push 	#disassem_497
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	push 	-40[bp]
	      	bsr  	PrintSc_
	      	addui	sp,sp,#8
	      	bra  	disassem_504
disassem_503:
	      	lw   	r3,-16[bp]
	      	bne  	r3,disassem_505
	      	push 	-24[bp]
	      	push 	#disassem_498
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	push 	-40[bp]
	      	bsr  	PrintSc_
	      	addui	sp,sp,#8
	      	bra  	disassem_506
disassem_505:
	      	lw   	r3,-24[bp]
	      	bne  	r3,disassem_507
	      	push 	#disassem_499
	      	bsr  	printf_
	      	addui	sp,sp,#8
disassem_507:
disassem_506:
disassem_504:
disassem_509:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_500:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_509
DispLS_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_512
	      	mov  	bp,sp
	      	push 	56[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_511
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
disassem_513:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_512:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_513
DispRI_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_518
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,56[bp]
	      	sh   	r3,-4[bp]
	      	push 	56[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_515
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	push 	56[bp]
	      	bsr  	DispRstc_
	      	addui	sp,sp,#8
	      	push 	56[bp]
	      	bsr  	DispRac_
	      	addui	sp,sp,#8
	      	lw   	r3,40[bp]
	      	beq  	r3,disassem_519
	      	lw   	r5,48[bp]
	      	asli 	r4,r5,#15
	      	lw   	r6,56[bp]
	      	asri 	r5,r6,#17
	      	or   	r3,r4,r5
	      	push 	r3
	      	push 	#disassem_516
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	disassem_520
disassem_519:
	      	lh   	r4,-4[bp]
	      	sxh  	r4,r4
	      	asri 	r3,r4,#17
	      	push 	r3
	      	push 	#disassem_517
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_520:
disassem_521:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_518:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_521
public code DispBcc_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_524
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	lw   	r6,40[bp]
	      	asri 	r5,r6,#17
	      	and  	r4,r5,#32767
	      	asli 	r3,r4,#2
	      	sw   	r3,-16[bp]
	      	lw   	r4,40[bp]
	      	and  	r3,r4,#2147483648
	      	beq  	r3,disassem_525
	      	lw   	r3,-16[bp]
	      	ori  	r3,r3,#-65536
	      	sw   	r3,-16[bp]
disassem_525:
	      	push 	40[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_522
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	push 	40[bp]
	      	bsr  	DispRac_
	      	addui	sp,sp,#8
	      	lw   	r4,24[bp]
	      	lw   	r5,-16[bp]
	      	addu 	r3,r4,r5
	      	push 	r3
	      	push 	#disassem_523
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_527:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_524:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_527
endpublic

public code DispRR_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_532
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	lhu  	r4,40[bp]
	      	andi 	r4,r4,#4294967295
	      	asri 	r3,r4,#25
	      	sw   	r3,-8[bp]
	      	lhu  	r5,40[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#17
	      	and  	r3,r4,#31
	      	sw   	r3,-16[bp]
	      	lhu  	r3,40[bp]
	      	push 	r3
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#13
	      	bne  	r4,disassem_533
	      	lw   	r3,-16[bp]
	      	bne  	r3,disassem_533
	      	push 	#disassem_528
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	lhu  	r3,40[bp]
	      	push 	r3
	      	bsr  	DispRstc_
	      	addui	sp,sp,#8
	      	lhu  	r3,40[bp]
	      	push 	r3
	      	bsr  	DispRa_
	      	addui	sp,sp,#8
	      	push 	#disassem_529
	      	bsr  	printf_
	      	addui	sp,sp,#8
disassem_535:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_533:
	      	push 	32[bp]
	      	push 	#disassem_530
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	lhu  	r3,40[bp]
	      	push 	r3
	      	bsr  	DispRstc_
	      	addui	sp,sp,#8
	      	lhu  	r3,40[bp]
	      	push 	r3
	      	bsr  	DispRac_
	      	addui	sp,sp,#8
	      	lhu  	r3,40[bp]
	      	push 	r3
	      	bsr  	DispRb_
	      	addui	sp,sp,#8
	      	push 	#disassem_531
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_535
disassem_532:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_535
endpublic

public code DispJALI_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_544
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	lh   	r3,32[bp]
	      	sh   	r3,-20[bp]
	      	lhu  	r5,32[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#12
	      	and  	r3,r4,#31
	      	sw   	r3,-8[bp]
	      	lhu  	r5,32[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#7
	      	and  	r3,r4,#31
	      	sw   	r3,-16[bp]
	      	lhu  	r3,32[bp]
	      	push 	r3
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	lw   	r3,-8[bp]
	      	beq  	r3,disassem_545
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#31
	      	beq  	r4,disassem_547
	      	push 	#disassem_536
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	lhu  	r3,32[bp]
	      	push 	r3
	      	bsr  	DispRstc_
	      	addui	sp,sp,#8
	      	push 	#disassem_537
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_548
disassem_547:
	      	push 	#disassem_538
	      	bsr  	printf_
	      	addui	sp,sp,#8
disassem_548:
	      	bra  	disassem_546
disassem_545:
	      	push 	#disassem_539
	      	bsr  	printf_
	      	addui	sp,sp,#8
disassem_546:
	      	lw   	r3,40[bp]
	      	beq  	r3,disassem_549
	      	lw   	r5,48[bp]
	      	asli 	r4,r5,#15
	      	lhu  	r6,32[bp]
	      	andi 	r6,r6,#4294967295
	      	asri 	r5,r6,#17
	      	or   	r3,r4,r5
	      	push 	r3
	      	push 	#disassem_540
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	disassem_550
disassem_549:
	      	lh   	r4,-20[bp]
	      	sxh  	r4,r4
	      	asri 	r3,r4,#17
	      	beq  	r3,disassem_551
	      	lh   	r4,-20[bp]
	      	sxh  	r4,r4
	      	asri 	r3,r4,#17
	      	push 	r3
	      	push 	#disassem_541
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_551:
disassem_550:
	      	lw   	r3,-16[bp]
	      	beq  	r3,disassem_553
	      	push 	-16[bp]
	      	push 	#disassem_542
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_553:
	      	push 	#disassem_543
	      	bsr  	printf_
	      	addui	sp,sp,#8
disassem_555:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_544:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_555
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
	      	ldi  	xlr,#disassem_641
	      	mov  	bp,sp
	      	subui	sp,sp,#96
	      	push 	r11
	      	push 	r12
	      	lw   	r11,24[bp]
	      	ldi  	r12,#0
	      	sw   	r0,-40[bp]
	      	sw   	r0,-48[bp]
	      	ldi  	r3,#1
	      	sw   	r3,-88[bp]
	      	sw   	r0,-96[bp]
disassem_642:
	      	lw   	r3,[r11]
	      	lw   	r4,32[bp]
	      	cmp  	r5,r3,r4
	      	bne  	r5,disassem_644
	      	bsr  	reverse_video_
	      	ldi  	r3,#1
	      	sw   	r3,-96[bp]
disassem_644:
	      	lw   	r4,[r11]
	      	asri 	r3,r4,#2
	      	sw   	r3,-72[bp]
	      	lw   	r4,-72[bp]
	      	asli 	r3,r4,#2
	      	lhu  	r4,0[r12+r3]
	      	sh   	r4,-12[bp]
	      	lh   	r3,-12[bp]
	      	sh   	r3,-76[bp]
	      	lhu  	r4,-12[bp]
	      	and  	r3,r4,#127
	      	sw   	r3,-24[bp]
	      	lhu  	r5,-12[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#25
	      	and  	r3,r4,#127
	      	sw   	r3,-32[bp]
	      	lw   	r3,-24[bp]
	      	cmp  	r4,r3,#124
	      	beq  	r4,disassem_647
	      	cmp  	r4,r3,#2
	      	beq  	r4,disassem_648
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_649
	      	cmp  	r4,r3,#20
	      	beq  	r4,disassem_650
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_651
	      	cmp  	r4,r3,#21
	      	beq  	r4,disassem_652
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_653
	      	cmp  	r4,r3,#22
	      	beq  	r4,disassem_654
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_655
	      	cmp  	r4,r3,#23
	      	beq  	r4,disassem_656
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_657
	      	cmp  	r4,r3,#24
	      	beq  	r4,disassem_658
	      	cmp  	r4,r3,#12
	      	beq  	r4,disassem_659
	      	cmp  	r4,r3,#13
	      	beq  	r4,disassem_660
	      	cmp  	r4,r3,#14
	      	beq  	r4,disassem_661
	      	cmp  	r4,r3,#61
	      	beq  	r4,disassem_662
	      	cmp  	r4,r3,#62
	      	beq  	r4,disassem_663
	      	cmp  	r4,r3,#56
	      	beq  	r4,disassem_664
	      	cmp  	r4,r3,#57
	      	beq  	r4,disassem_665
	      	cmp  	r4,r3,#58
	      	beq  	r4,disassem_666
	      	cmp  	r4,r3,#55
	      	beq  	r4,disassem_667
	      	cmp  	r4,r3,#59
	      	beq  	r4,disassem_668
	      	cmp  	r4,r3,#64
	      	beq  	r4,disassem_669
	      	cmp  	r4,r3,#65
	      	beq  	r4,disassem_670
	      	cmp  	r4,r3,#66
	      	beq  	r4,disassem_671
	      	cmp  	r4,r3,#67
	      	beq  	r4,disassem_672
	      	cmp  	r4,r3,#68
	      	beq  	r4,disassem_673
	      	cmp  	r4,r3,#69
	      	beq  	r4,disassem_674
	      	cmp  	r4,r3,#70
	      	beq  	r4,disassem_675
	      	cmp  	r4,r3,#71
	      	beq  	r4,disassem_676
	      	cmp  	r4,r3,#72
	      	beq  	r4,disassem_677
	      	cmp  	r4,r3,#73
	      	beq  	r4,disassem_678
	      	cmp  	r4,r3,#74
	      	beq  	r4,disassem_679
	      	cmp  	r4,r3,#75
	      	beq  	r4,disassem_680
	      	cmp  	r4,r3,#76
	      	beq  	r4,disassem_681
	      	cmp  	r4,r3,#77
	      	beq  	r4,disassem_682
	      	cmp  	r4,r3,#78
	      	beq  	r4,disassem_683
	      	cmp  	r4,r3,#79
	      	beq  	r4,disassem_684
	      	cmp  	r4,r3,#100
	      	beq  	r4,disassem_685
	      	cmp  	r4,r3,#96
	      	beq  	r4,disassem_686
	      	cmp  	r4,r3,#97
	      	beq  	r4,disassem_687
	      	cmp  	r4,r3,#98
	      	beq  	r4,disassem_688
	      	cmp  	r4,r3,#99
	      	beq  	r4,disassem_689
	      	cmp  	r4,r3,#104
	      	beq  	r4,disassem_690
	      	cmp  	r4,r3,#105
	      	beq  	r4,disassem_691
	      	cmp  	r4,r3,#106
	      	beq  	r4,disassem_692
	      	cmp  	r4,r3,#107
	      	beq  	r4,disassem_693
	      	cmp  	r4,r3,#92
	      	beq  	r4,disassem_694
	      	cmp  	r4,r3,#110
	      	beq  	r4,disassem_695
	      	cmp  	r4,r3,#103
	      	beq  	r4,disassem_696
	      	cmp  	r4,r3,#87
	      	beq  	r4,disassem_697
	      	cmp  	r4,r3,#63
	      	beq  	r4,disassem_698
	      	cmp  	r4,r3,#10
	      	beq  	r4,disassem_699
	      	bra  	disassem_700
disassem_647:
	      	ldi  	r3,#1
	      	sw   	r3,-40[bp]
	      	lw   	r3,-88[bp]
	      	beq  	r3,disassem_701
	      	lh   	r4,-76[bp]
	      	sxh  	r4,r4
	      	asri 	r3,r4,#7
	      	sw   	r3,-48[bp]
	      	lw   	r4,-48[bp]
	      	and  	r3,r4,#16777216
	      	beq  	r3,disassem_703
	      	lw   	r3,-48[bp]
	      	ori  	r3,r3,#-16777216
	      	sw   	r3,-48[bp]
disassem_703:
	      	bra  	disassem_702
disassem_701:
	      	lw   	r5,-48[bp]
	      	asli 	r4,r5,#25
	      	lhu  	r6,-12[bp]
	      	andi 	r6,r6,#4294967295
	      	asri 	r5,r6,#7
	      	or   	r3,r4,r5
	      	sw   	r3,-48[bp]
disassem_702:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	#disassem_556
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	sw   	r0,-88[bp]
	      	bra  	disassem_646
disassem_648:
	      	lw   	r3,-32[bp]
	      	cmp  	r4,r3,#55
	      	beq  	r4,disassem_706
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_707
	      	cmp  	r4,r3,#20
	      	beq  	r4,disassem_708
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_709
	      	cmp  	r4,r3,#21
	      	beq  	r4,disassem_710
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_711
	      	cmp  	r4,r3,#22
	      	beq  	r4,disassem_712
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_713
	      	cmp  	r4,r3,#23
	      	beq  	r4,disassem_714
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_715
	      	cmp  	r4,r3,#24
	      	beq  	r4,disassem_716
	      	cmp  	r4,r3,#12
	      	beq  	r4,disassem_717
	      	cmp  	r4,r3,#13
	      	beq  	r4,disassem_718
	      	cmp  	r4,r3,#14
	      	beq  	r4,disassem_719
	      	cmp  	r4,r3,#31
	      	beq  	r4,disassem_720
	      	cmp  	r4,r3,#30
	      	beq  	r4,disassem_721
	      	bra  	disassem_705
disassem_706:
	      	lhu  	r5,-12[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#17
	      	and  	r3,r4,#31
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_723
	      	cmp  	r4,r3,#1
	      	beq  	r4,disassem_724
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_725
	      	cmp  	r4,r3,#29
	      	beq  	r4,disassem_726
	      	cmp  	r4,r3,#30
	      	beq  	r4,disassem_727
	      	cmp  	r4,r3,#31
	      	beq  	r4,disassem_728
	      	bra  	disassem_729
disassem_723:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	#disassem_557
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_722
disassem_724:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	#disassem_558
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_722
disassem_725:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	#disassem_559
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_722
disassem_726:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	#disassem_560
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_722
disassem_727:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	#disassem_561
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_722
disassem_728:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	#disassem_562
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_722
disassem_729:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	#disassem_563
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_722
disassem_722:
	      	bra  	disassem_705
disassem_707:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_564
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_705
disassem_708:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_565
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_705
disassem_709:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_566
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_705
disassem_710:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_567
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_705
disassem_711:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_568
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_705
disassem_712:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_569
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_705
disassem_713:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_570
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_705
disassem_714:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_571
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_705
disassem_715:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_572
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_705
disassem_716:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_573
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_705
disassem_717:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_574
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_705
disassem_718:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_575
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_705
disassem_719:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_576
	      	push 	[r11]
	      	bsr  	DispRR_
	      	addui	sp,sp,#24
	      	bra  	disassem_705
disassem_720:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	#disassem_577
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRstc_
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispSpr_
	      	addui	sp,sp,#8
	      	push 	#disassem_578
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_705
disassem_721:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	#disassem_579
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispSpr_
	      	addui	sp,sp,#8
	      	push 	#disassem_580
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRa_
	      	addui	sp,sp,#8
	      	push 	#disassem_581
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_705
disassem_705:
	      	bra  	disassem_646
disassem_649:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_582
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_650:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_583
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_651:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_584
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_652:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_585
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_653:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_586
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_654:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_587
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_655:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_588
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_656:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_589
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_657:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_590
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_658:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_591
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_659:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_592
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_660:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_593
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_661:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_594
	      	push 	[r11]
	      	bsr  	DispRI_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_662:
	      	lhu  	r5,-12[bp]
	      	andi 	r5,r5,#4294967295
	      	asri 	r4,r5,#12
	      	and  	r3,r4,#7
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_731
	      	cmp  	r4,r3,#1
	      	beq  	r4,disassem_732
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_733
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_734
	      	cmp  	r4,r3,#2
	      	beq  	r4,disassem_735
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_736
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_737
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_737
	      	bra  	disassem_730
disassem_731:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_595
	      	push 	[r11]
	      	bsr  	DispBcc_
	      	addui	sp,sp,#24
	      	bra  	disassem_730
disassem_732:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_596
	      	push 	[r11]
	      	bsr  	DispBcc_
	      	addui	sp,sp,#24
	      	bra  	disassem_730
disassem_733:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_597
	      	push 	[r11]
	      	bsr  	DispBcc_
	      	addui	sp,sp,#24
	      	bra  	disassem_730
disassem_734:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_598
	      	push 	[r11]
	      	bsr  	DispBcc_
	      	addui	sp,sp,#24
	      	bra  	disassem_730
disassem_735:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_599
	      	push 	[r11]
	      	bsr  	DispBcc_
	      	addui	sp,sp,#24
	      	bra  	disassem_730
disassem_736:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_600
	      	push 	[r11]
	      	bsr  	DispBcc_
	      	addui	sp,sp,#24
	      	bra  	disassem_730
disassem_737:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_601
	      	push 	[r11]
	      	bsr  	DispBcc_
	      	addui	sp,sp,#24
	      	bra  	disassem_730
disassem_730:
	      	bra  	disassem_646
disassem_663:
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DispJALI_
	      	addui	sp,sp,#32
	      	bra  	disassem_646
disassem_664:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispBrk_
	      	addui	sp,sp,#8
	      	bra  	disassem_646
disassem_665:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	lhu  	r4,-12[bp]
	      	andi 	r4,r4,#4294967295
	      	asri 	r3,r4,#7
	      	sw   	r3,-64[bp]
	      	lhu  	r4,-12[bp]
	      	and  	r3,r4,#2147483648
	      	beq  	r3,disassem_738
	      	lw   	r3,-64[bp]
	      	ori  	r3,r3,#-16777216
	      	sw   	r3,-64[bp]
disassem_738:
	      	lw   	r4,[r11]
	      	lw   	r6,-64[bp]
	      	asli 	r5,r6,#2
	      	addu 	r3,r4,r5
	      	sw   	r3,-56[bp]
	      	push 	-56[bp]
	      	push 	#disassem_602
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	disassem_646
disassem_666:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	lhu  	r4,-12[bp]
	      	andi 	r4,r4,#4294967295
	      	asri 	r3,r4,#7
	      	sw   	r3,-64[bp]
	      	lhu  	r4,-12[bp]
	      	and  	r3,r4,#2147483648
	      	beq  	r3,disassem_740
	      	lw   	r3,-64[bp]
	      	ori  	r3,r3,#-16777216
	      	sw   	r3,-64[bp]
disassem_740:
	      	lw   	r4,[r11]
	      	lw   	r6,-64[bp]
	      	asli 	r5,r6,#2
	      	addu 	r3,r4,r5
	      	sw   	r3,-56[bp]
	      	push 	-56[bp]
	      	push 	#disassem_603
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	disassem_646
disassem_667:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	lhu  	r4,-12[bp]
	      	andi 	r4,r4,#4294967295
	      	asri 	r3,r4,#17
	      	sw   	r3,-56[bp]
	      	push 	-56[bp]
	      	push 	#disassem_604
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	disassem_646
disassem_668:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	lhu  	r4,-12[bp]
	      	andi 	r4,r4,#4294967295
	      	asri 	r3,r4,#17
	      	sw   	r3,-56[bp]
	      	push 	-56[bp]
	      	push 	#disassem_605
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	disassem_646
disassem_669:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_606
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_670:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_607
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_671:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_608
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_672:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_609
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_673:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_610
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_674:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_611
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_675:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_612
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_676:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_613
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_677:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_614
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_646
disassem_678:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_615
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_646
disassem_679:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_616
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_646
disassem_680:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_617
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_646
disassem_681:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_618
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_646
disassem_682:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_619
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_646
disassem_683:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_620
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_646
disassem_684:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_621
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_646
disassem_685:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	bsr  	DispInc_
	      	addui	sp,sp,#24
	      	bra  	disassem_646
disassem_686:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_622
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_687:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_623
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_688:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_624
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_689:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_625
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_690:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_626
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_646
disassem_691:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_627
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_646
disassem_692:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_628
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_646
disassem_693:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_629
	      	push 	[r11]
	      	bsr  	DispIndexedAddr_
	      	addui	sp,sp,#24
	      	bra  	disassem_646
disassem_694:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_630
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_695:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_631
	      	push 	[r11]
	      	bsr  	DispLS_
	      	addui	sp,sp,#40
	      	bra  	disassem_646
disassem_696:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	#disassem_632
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRa_
	      	addui	sp,sp,#8
	      	push 	#disassem_633
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_646
disassem_697:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	#disassem_634
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRst_
	      	addui	sp,sp,#8
	      	push 	#disassem_635
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_646
disassem_698:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	#disassem_636
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_646
disassem_699:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	#disassem_637
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRstc_
	      	addui	sp,sp,#8
	      	lw   	r3,-40[bp]
	      	beq  	r3,disassem_742
	      	lw   	r5,-48[bp]
	      	asli 	r4,r5,#15
	      	lhu  	r6,-12[bp]
	      	andi 	r6,r6,#4294967295
	      	asri 	r5,r6,#17
	      	or   	r3,r4,r5
	      	push 	r3
	      	push 	#disassem_638
	      	bsr  	printf_
	      	addui	sp,sp,#16
	      	bra  	disassem_743
disassem_742:
	      	lh   	r4,-76[bp]
	      	sxh  	r4,r4
	      	asri 	r3,r4,#17
	      	push 	r3
	      	push 	#disassem_639
	      	bsr  	printf_
	      	addui	sp,sp,#16
disassem_743:
	      	bra  	disassem_646
disassem_700:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes_
	      	addui	sp,sp,#16
	      	push 	#disassem_640
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	disassem_646
disassem_646:
	      	lw   	r4,[r11]
	      	addu 	r3,r4,#4
	      	sw   	r3,[r11]
	      	lw   	r3,-96[bp]
	      	beq  	r3,disassem_744
	      	bsr  	reverse_video_
	      	sw   	r0,-96[bp]
disassem_744:
	      	lw   	r3,-24[bp]
	      	cmp  	r4,r3,#124
	      	beq  	r4,disassem_642
disassem_643:
disassem_746:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_641:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_746
endpublic

public code disassem20_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_748
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	#disassem_747
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	sw   	r0,-8[bp]
disassem_749:
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#16
	      	bge  	r4,disassem_750
	      	push 	32[bp]
	      	pea  	24[bp]
	      	bsr  	disassem_
	      	addui	sp,sp,#16
disassem_751:
	      	inc  	-8[bp],#1
	      	bra  	disassem_749
disassem_750:
disassem_752:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_748:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_752
endpublic

	rodata
	align	16
	align	8
disassem_747:
	dc	68,105,115,97,115,115,101,109
	dc	58,13,10,0
disassem_640:
	dc	63,63,63,63,63,13,10,0
disassem_639:
	dc	35,36,37,88,13,10,0
disassem_638:
	dc	35,36,37,88,13,10,0
disassem_637:
	dc	76,68,73,32,32,32,0
disassem_636:
	dc	78,79,80,13,10,0
disassem_635:
	dc	13,10,0
disassem_634:
	dc	80,79,80,32,32,32,0
disassem_633:
	dc	13,10,0
disassem_632:
	dc	80,85,83,72,32,32,0
disassem_631:
	dc	83,87,67,82,32,0
disassem_630:
	dc	76,87,65,82,32,0
disassem_629:
	dc	83,87,32,32,32,0
disassem_628:
	dc	83,72,32,32,32,0
disassem_627:
	dc	83,67,32,32,32,0
disassem_626:
	dc	83,66,32,32,32,0
disassem_625:
	dc	83,87,32,32,32,0
disassem_624:
	dc	83,72,32,32,32,0
disassem_623:
	dc	83,67,32,32,32,0
disassem_622:
	dc	83,66,32,32,32,0
disassem_621:
	dc	76,69,65,32,32,0
disassem_620:
	dc	76,87,32,32,32,0
disassem_619:
	dc	76,72,85,32,32,0
disassem_618:
	dc	76,72,32,32,32,0
disassem_617:
	dc	76,67,85,32,32,0
disassem_616:
	dc	76,67,32,32,32,0
disassem_615:
	dc	76,66,85,32,32,0
disassem_614:
	dc	76,66,32,32,32,0
disassem_613:
	dc	76,69,65,32,32,0
disassem_612:
	dc	76,87,32,32,32,0
disassem_611:
	dc	76,72,85,32,32,0
disassem_610:
	dc	76,72,32,32,32,0
disassem_609:
	dc	76,67,85,32,32,0
disassem_608:
	dc	76,67,32,32,32,0
disassem_607:
	dc	76,66,85,32,32,0
disassem_606:
	dc	76,66,32,32,32,0
disassem_605:
	dc	82,84,83,32,32,32,35,37
	dc	88,13,10,0
disassem_604:
	dc	82,84,76,32,32,32,35,37
	dc	88,13,10,0
disassem_603:
	dc	66,82,65,32,32,32,36,37
	dc	88,13,10,0
disassem_602:
	dc	66,83,82,32,32,32,36,37
	dc	88,13,10,0
disassem_601:
	dc	63,63,63,32,32,0
disassem_600:
	dc	66,71,69,32,32,0
disassem_599:
	dc	66,71,84,32,32,0
disassem_598:
	dc	66,76,69,32,32,0
disassem_597:
	dc	66,76,84,32,32,0
disassem_596:
	dc	66,78,69,32,32,0
disassem_595:
	dc	66,69,81,32,32,0
disassem_594:
	dc	69,79,82,32,32,0
disassem_593:
	dc	79,82,32,32,32,0
disassem_592:
	dc	65,78,68,32,32,0
disassem_591:
	dc	68,73,86,85,32,0
disassem_590:
	dc	68,73,86,32,32,0
disassem_589:
	dc	77,85,76,85,32,0
disassem_588:
	dc	77,85,76,32,32,0
disassem_587:
	dc	67,77,80,85,32,0
disassem_586:
	dc	67,77,80,32,32,0
disassem_585:
	dc	83,85,66,85,32,0
disassem_584:
	dc	83,85,66,32,32,0
disassem_583:
	dc	65,68,68,85,32,0
disassem_582:
	dc	65,68,68,32,32,0
disassem_581:
	dc	13,10,0
disassem_580:
	dc	44,0
disassem_579:
	dc	77,84,83,80,82,32,0
disassem_578:
	dc	13,10,0
disassem_577:
	dc	77,70,83,80,82,32,0
disassem_576:
	dc	69,79,82,32,32,0
disassem_575:
	dc	79,82,32,32,32,0
disassem_574:
	dc	65,78,68,32,32,0
disassem_573:
	dc	68,73,86,85,32,0
disassem_572:
	dc	68,73,86,32,32,0
disassem_571:
	dc	77,85,76,85,32,0
disassem_570:
	dc	77,85,76,32,32,0
disassem_569:
	dc	67,77,80,85,32,0
disassem_568:
	dc	67,77,80,32,32,0
disassem_567:
	dc	83,85,66,85,32,0
disassem_566:
	dc	83,85,66,32,32,0
disassem_565:
	dc	65,68,68,85,32,0
disassem_564:
	dc	65,68,68,32,32,0
disassem_563:
	dc	63,63,63,13,10,0
disassem_562:
	dc	82,84,73,13,10,0
disassem_561:
	dc	82,84,69,13,10,0
disassem_560:
	dc	82,84,68,13,10,0
disassem_559:
	dc	87,65,73,13,10,0
disassem_558:
	dc	83,69,73,13,10,0
disassem_557:
	dc	67,76,73,13,10,0
disassem_556:
	dc	73,77,77,13,10,0
disassem_543:
	dc	41,13,10,0
disassem_542:
	dc	91,82,37,100,93,0
disassem_541:
	dc	36,37,88,0
disassem_540:
	dc	36,37,88,0
disassem_539:
	dc	74,77,80,32,32,32,40,0
disassem_538:
	dc	74,83,82,32,32,32,40,0
disassem_537:
	dc	40,0
disassem_536:
	dc	74,65,76,32,32,32,0
disassem_531:
	dc	13,10,0
disassem_530:
	dc	37,115,32,0
disassem_529:
	dc	13,10,0
disassem_528:
	dc	77,79,86,32,32,32,0
disassem_523:
	dc	37,48,54,88,13,10,0
disassem_522:
	dc	37,115,32,0
disassem_517:
	dc	35,36,37,88,13,10,0
disassem_516:
	dc	35,36,37,88,13,10,0
disassem_515:
	dc	37,115,32,0
disassem_511:
	dc	37,115,32,0
disassem_499:
	dc	91,82,37,100,93,13,10,0
disassem_498:
	dc	91,82,37,100,0
disassem_497:
	dc	91,82,37,100,43,82,37,100
	dc	0
disassem_496:
	dc	36,37,88,0
disassem_495:
	dc	37,115,32,82,37,100,44,0
disassem_486:
	dc	66,82,75,63,32,32,35,37
	dc	88,13,10,0
disassem_485:
	dc	73,78,84,32,32,32,35,37
	dc	88,13,10,0
disassem_484:
	dc	68,66,71,32,32,32,35,37
	dc	88,13,10,0
disassem_483:
	dc	83,89,83,32,32,32,35,37
	dc	88,13,10,0
disassem_477:
	dc	93,13,10,0
disassem_476:
	dc	42,37,100,93,13,10,0
disassem_466:
	dc	35,37,100,13,10,0
disassem_465:
	dc	91,82,37,100,93,44,0
disassem_464:
	dc	44,0
disassem_463:
	dc	36,37,88,0
disassem_462:
	dc	36,37,88,0
disassem_461:
	dc	73,78,67,32,32,32,0
disassem_460:
	dc	68,69,67,32,32,32,0
disassem_452:
	dc	13,10,0
disassem_451:
	dc	91,82,37,100,93,13,10,0
disassem_450:
	dc	36,37,88,0
disassem_449:
	dc	36,37,88,0
disassem_429:
	dc	83,80,82,37,100,0
disassem_428:
	dc	68,66,83,84,65,84,0
disassem_427:
	dc	68,66,67,84,82,76,0
disassem_426:
	dc	68,66,65,68,51,0
disassem_425:
	dc	68,66,65,68,50,0
disassem_424:
	dc	68,66,65,68,49,0
disassem_423:
	dc	68,66,65,68,48,0
disassem_422:
	dc	86,66,82,0
disassem_421:
	dc	69,80,67,0
disassem_420:
	dc	73,80,67,0
disassem_419:
	dc	68,80,67,0
disassem_418:
	dc	67,76,75,0
disassem_417:
	dc	84,73,67,75,0
disassem_416:
	dc	67,82,51,0
disassem_415:
	dc	67,82,48,0
disassem_411:
	dc	82,37,100,0
disassem_407:
	dc	82,37,100,0
disassem_403:
	dc	82,37,100,44,0
disassem_399:
	dc	82,37,100,44,0
disassem_395:
	dc	114,37,100,0
disassem_391:
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
