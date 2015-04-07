	code
	align	16
public code SetNormAttr:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         push  r6
         lw    r1,24[bp]
         ldi   r6,#$22
         sys   #410
         pop   r6
     
disassem_601:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code GetNormAttr:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         push  r6
         ldi   r6,#$23
         sys   #410
         pop   r6
     
disassem_603:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code reverse_video:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_604
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	bsr  	GetNormAttr
	      	mov  	r3,r1
	      	andi 	r3,r3,#4294967295
	      	sh   	r3,-4[bp]
	      	lhu  	r3,-4[bp]
	      	andi 	r3,r3,#4294967295
	      	asri 	r3,r3,#10
	      	asli 	r3,r3,#19
	      	lhu  	r4,-4[bp]
	      	andi 	r4,r4,#4294967295
	      	asri 	r4,r4,#19
	      	asli 	r4,r4,#10
	      	or   	r3,r3,r4
	      	sh   	r3,-4[bp]
	      	lhu  	r3,-4[bp]
	      	push 	r3
	      	bsr  	SetNormAttr
	      	addui	sp,sp,#8
disassem_605:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_604:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_605
endpublic

public code DumpInsnBytes:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_607
	      	mov  	bp,sp
	      	lw   	r3,32[bp]
	      	asri 	r3,r3,#24
	      	and  	r3,r3,#255
	      	push 	r3
	      	lw   	r3,32[bp]
	      	asri 	r3,r3,#16
	      	and  	r3,r3,#255
	      	push 	r3
	      	lw   	r3,32[bp]
	      	asri 	r3,r3,#8
	      	and  	r3,r3,#255
	      	push 	r3
	      	lw   	r3,32[bp]
	      	and  	r3,r3,#255
	      	push 	r3
	      	push 	24[bp]
	      	push 	#disassem_606
	      	bsr  	printf
	      	addui	sp,sp,#48
disassem_608:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_607:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_608
endpublic

DispRst:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_611
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#12
	      	and  	r3,r3,#31
	      	push 	r3
	      	push 	#disassem_610
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_612:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_611:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_612
DispRstc:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_615
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#12
	      	and  	r3,r3,#31
	      	push 	r3
	      	push 	#disassem_614
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_616:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_615:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_616
DispRac:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_619
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#7
	      	and  	r3,r3,#31
	      	push 	r3
	      	push 	#disassem_618
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_620:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_619:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_620
DispRa:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_623
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#7
	      	and  	r3,r3,#31
	      	push 	r3
	      	push 	#disassem_622
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_624:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_623:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_624
DispRb:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_627
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#31
	      	push 	r3
	      	push 	#disassem_626
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_628:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_627:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_628
DispSpr:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_645
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#255
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_647
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_648
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_649
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_650
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_651
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_652
	      	cmp  	r4,r3,#9
	      	beq  	r4,disassem_653
	      	cmp  	r4,r3,#10
	      	beq  	r4,disassem_654
	      	cmp  	r4,r3,#50
	      	beq  	r4,disassem_655
	      	cmp  	r4,r3,#51
	      	beq  	r4,disassem_656
	      	cmp  	r4,r3,#52
	      	beq  	r4,disassem_657
	      	cmp  	r4,r3,#53
	      	beq  	r4,disassem_658
	      	cmp  	r4,r3,#54
	      	beq  	r4,disassem_659
	      	cmp  	r4,r3,#55
	      	beq  	r4,disassem_660
	      	bra  	disassem_661
disassem_647:
	      	push 	#disassem_630
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_646
disassem_648:
	      	push 	#disassem_631
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_646
disassem_649:
	      	push 	#disassem_632
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_646
disassem_650:
	      	push 	#disassem_633
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_646
disassem_651:
	      	push 	#disassem_634
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_646
disassem_652:
	      	push 	#disassem_635
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_646
disassem_653:
	      	push 	#disassem_636
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_646
disassem_654:
	      	push 	#disassem_637
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_646
disassem_655:
	      	push 	#disassem_638
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_646
disassem_656:
	      	push 	#disassem_639
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_646
disassem_657:
	      	push 	#disassem_640
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_646
disassem_658:
	      	push 	#disassem_641
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_646
disassem_659:
	      	push 	#disassem_642
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_646
disassem_660:
	      	push 	#disassem_643
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_646
disassem_661:
	      	push 	-8[bp]
	      	push 	#disassem_644
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_646:
disassem_662:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_645:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_662
DispMemAddress:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_668
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,40[bp]
	      	sh   	r3,-4[bp]
	      	lw   	r3,24[bp]
	      	beq  	r3,disassem_669
	      	lw   	r3,32[bp]
	      	asli 	r3,r3,#15
	      	lw   	r4,40[bp]
	      	asri 	r4,r4,#17
	      	or   	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_664
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_670
disassem_669:
	      	lh   	r3,-4[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#17
	      	push 	r3
	      	push 	#disassem_665
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_670:
	      	lw   	r3,40[bp]
	      	asri 	r3,r3,#7
	      	and  	r3,r3,#31
	      	beq  	r3,disassem_671
	      	lw   	r3,40[bp]
	      	asri 	r3,r3,#7
	      	and  	r3,r3,#31
	      	push 	r3
	      	push 	#disassem_666
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_672
disassem_671:
	      	push 	#disassem_667
	      	bsr  	printf
	      	addui	sp,sp,#8
disassem_672:
disassem_673:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_668:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_673
DispInc:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_682
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	lw   	r3,40[bp]
	      	sh   	r3,-4[bp]
	      	lw   	r3,40[bp]
	      	asri 	r3,r3,#7
	      	and  	r3,r3,#31
	      	sw   	r3,-16[bp]
	      	lw   	r3,40[bp]
	      	asri 	r3,r3,#12
	      	and  	r3,r3,#31
	      	sw   	r3,-24[bp]
	      	lw   	r3,-24[bp]
	      	and  	r3,r3,#16
	      	cmp  	r3,r3,#16
	      	bne  	r3,disassem_683
	      	lw   	r3,-24[bp]
	      	ori  	r3,r3,#-16
	      	sw   	r3,-24[bp]
	      	lw   	r3,-24[bp]
	      	neg  	r3,r3
	      	sw   	r3,-24[bp]
	      	push 	#disassem_675
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_684
disassem_683:
	      	push 	#disassem_676
	      	bsr  	printf
	      	addui	sp,sp,#8
disassem_684:
	      	lw   	r3,24[bp]
	      	beq  	r3,disassem_685
	      	lw   	r3,32[bp]
	      	asli 	r3,r3,#15
	      	lw   	r4,40[bp]
	      	asri 	r4,r4,#17
	      	or   	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_677
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_686
disassem_685:
	      	lh   	r3,-4[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#17
	      	push 	r3
	      	push 	#disassem_678
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_686:
	      	lw   	r3,-16[bp]
	      	bne  	r3,disassem_687
	      	push 	#disassem_679
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_688
disassem_687:
	      	push 	-16[bp]
	      	push 	#disassem_680
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_688:
	      	push 	-24[bp]
	      	push 	#disassem_681
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_689:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_682:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_689
PrintSc:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_693
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	cmp  	r3,r3,#1
	      	ble  	r3,disassem_694
	      	push 	24[bp]
	      	push 	#disassem_691
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_695
disassem_694:
	      	push 	#disassem_692
	      	bsr  	printf
	      	addui	sp,sp,#8
disassem_695:
disassem_696:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_693:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_696
DispBrk:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_702
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	lhu  	r3,24[bp]
	      	andi 	r3,r3,#4294967295
	      	asri 	r3,r3,#30
	      	and  	r3,r3,#3
	      	sw   	r3,-8[bp]
	      	lhu  	r3,24[bp]
	      	andi 	r3,r3,#4294967295
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#511
	      	sw   	r3,-16[bp]
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_704
	      	cmp  	r4,r3,#1
	      	beq  	r4,disassem_705
	      	cmp  	r4,r3,#2
	      	beq  	r4,disassem_706
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_707
	      	bra  	disassem_703
disassem_704:
	      	push 	-16[bp]
	      	push 	#disassem_698
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_705:
	      	push 	-16[bp]
	      	push 	#disassem_699
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_706:
	      	push 	-16[bp]
	      	push 	#disassem_700
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_707:
	      	push 	-16[bp]
	      	push 	#disassem_701
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_703:
disassem_708:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_702:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_708
DispIndexedAddr:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_715
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	lhu  	r3,40[bp]
	      	andi 	r3,r3,#4294967295
	      	asri 	r3,r3,#24
	      	sw   	r3,-8[bp]
	      	lhu  	r3,40[bp]
	      	andi 	r3,r3,#4294967295
	      	asri 	r3,r3,#7
	      	and  	r3,r3,#31
	      	sw   	r3,-16[bp]
	      	lhu  	r3,40[bp]
	      	andi 	r3,r3,#4294967295
	      	asri 	r3,r3,#12
	      	and  	r3,r3,#31
	      	sw   	r3,-32[bp]
	      	lhu  	r3,40[bp]
	      	andi 	r3,r3,#4294967295
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#31
	      	sw   	r3,-24[bp]
	      	lhu  	r3,40[bp]
	      	andi 	r3,r3,#4294967295
	      	asri 	r3,r3,#22
	      	and  	r3,r3,#3
	      	sw   	r3,-40[bp]
	      	ldi  	r3,#1
	      	lw   	r4,-40[bp]
	      	asl  	r3,r3,r4
	      	sw   	r3,-40[bp]
	      	lhu  	r3,40[bp]
	      	push 	r3
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	-32[bp]
	      	push 	32[bp]
	      	push 	#disassem_710
	      	bsr  	printf
	      	addui	sp,sp,#24
	      	lw   	r3,-8[bp]
	      	beq  	r3,disassem_716
	      	push 	-8[bp]
	      	push 	#disassem_711
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_716:
	      	lw   	r3,-16[bp]
	      	beq  	r3,disassem_718
	      	lw   	r3,-24[bp]
	      	beq  	r3,disassem_718
	      	push 	#disassem_712
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	-40[bp]
	      	bsr  	PrintSc
	      	addui	sp,sp,#8
	      	bra  	disassem_719
disassem_718:
	      	lw   	r3,-16[bp]
	      	bne  	r3,disassem_720
	      	push 	-24[bp]
	      	push 	#disassem_713
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	push 	-40[bp]
	      	bsr  	PrintSc
	      	addui	sp,sp,#8
	      	bra  	disassem_721
disassem_720:
	      	lw   	r3,-24[bp]
	      	bne  	r3,disassem_722
	      	push 	#disassem_714
	      	bsr  	printf
	      	addui	sp,sp,#8
disassem_722:
disassem_721:
disassem_719:
disassem_724:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_715:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_724
DispLS:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_727
	      	mov  	bp,sp
	      	push 	56[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_726
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	push 	56[bp]
	      	bsr  	DispRstc
	      	addui	sp,sp,#8
	      	push 	56[bp]
	      	push 	48[bp]
	      	push 	40[bp]
	      	bsr  	DispMemAddress
	      	addui	sp,sp,#24
disassem_728:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_727:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_728
DispRI:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_733
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,56[bp]
	      	sh   	r3,-4[bp]
	      	push 	56[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_730
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	push 	56[bp]
	      	bsr  	DispRstc
	      	addui	sp,sp,#8
	      	push 	56[bp]
	      	bsr  	DispRac
	      	addui	sp,sp,#8
	      	lw   	r3,40[bp]
	      	beq  	r3,disassem_734
	      	lw   	r3,48[bp]
	      	asli 	r3,r3,#15
	      	lw   	r4,56[bp]
	      	asri 	r4,r4,#17
	      	or   	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_731
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_735
disassem_734:
	      	lh   	r3,-4[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#17
	      	push 	r3
	      	push 	#disassem_732
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_735:
disassem_736:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_733:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_736
public code DispBcc:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_739
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	lw   	r3,40[bp]
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#32767
	      	asli 	r3,r3,#2
	      	sw   	r3,-16[bp]
	      	lw   	r3,40[bp]
	      	and  	r3,r3,#2147483648
	      	beq  	r3,disassem_740
	      	lw   	r3,-16[bp]
	      	ori  	r3,r3,#-65536
	      	sw   	r3,-16[bp]
disassem_740:
	      	push 	40[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_737
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	push 	40[bp]
	      	bsr  	DispRac
	      	addui	sp,sp,#8
	      	lw   	r3,24[bp]
	      	lw   	r4,-16[bp]
	      	addu 	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_738
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_742:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_739:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_742
endpublic

public code DispRR:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_747
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	lhu  	r3,40[bp]
	      	andi 	r3,r3,#4294967295
	      	asri 	r3,r3,#25
	      	sw   	r3,-8[bp]
	      	lhu  	r3,40[bp]
	      	andi 	r3,r3,#4294967295
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#31
	      	sw   	r3,-16[bp]
	      	lhu  	r3,40[bp]
	      	push 	r3
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#13
	      	bne  	r3,disassem_748
	      	lw   	r3,-16[bp]
	      	bne  	r3,disassem_748
	      	push 	#disassem_743
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,40[bp]
	      	push 	r3
	      	bsr  	DispRstc
	      	addui	sp,sp,#8
	      	lhu  	r3,40[bp]
	      	push 	r3
	      	bsr  	DispRa
	      	addui	sp,sp,#8
	      	push 	#disassem_744
	      	bsr  	printf
	      	addui	sp,sp,#8
disassem_750:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_748:
	      	push 	32[bp]
	      	push 	#disassem_745
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	lhu  	r3,40[bp]
	      	push 	r3
	      	bsr  	DispRstc
	      	addui	sp,sp,#8
	      	lhu  	r3,40[bp]
	      	push 	r3
	      	bsr  	DispRac
	      	addui	sp,sp,#8
	      	lhu  	r3,40[bp]
	      	push 	r3
	      	bsr  	DispRb
	      	addui	sp,sp,#8
	      	push 	#disassem_746
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_750
disassem_747:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_750
endpublic

public code DispJALI:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_759
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	lh   	r3,32[bp]
	      	sh   	r3,-20[bp]
	      	lhu  	r3,32[bp]
	      	andi 	r3,r3,#4294967295
	      	asri 	r3,r3,#12
	      	and  	r3,r3,#31
	      	sw   	r3,-8[bp]
	      	lhu  	r3,32[bp]
	      	andi 	r3,r3,#4294967295
	      	asri 	r3,r3,#7
	      	and  	r3,r3,#31
	      	sw   	r3,-16[bp]
	      	lhu  	r3,32[bp]
	      	push 	r3
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	lw   	r3,-8[bp]
	      	beq  	r3,disassem_760
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#31
	      	beq  	r3,disassem_762
	      	push 	#disassem_751
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,32[bp]
	      	push 	r3
	      	bsr  	DispRstc
	      	addui	sp,sp,#8
	      	push 	#disassem_752
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_763
disassem_762:
	      	push 	#disassem_753
	      	bsr  	printf
	      	addui	sp,sp,#8
disassem_763:
	      	bra  	disassem_761
disassem_760:
	      	push 	#disassem_754
	      	bsr  	printf
	      	addui	sp,sp,#8
disassem_761:
	      	lw   	r3,40[bp]
	      	beq  	r3,disassem_764
	      	lw   	r3,48[bp]
	      	asli 	r3,r3,#15
	      	lhu  	r4,32[bp]
	      	andi 	r4,r4,#4294967295
	      	asri 	r4,r4,#17
	      	or   	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_755
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_765
disassem_764:
	      	lh   	r3,-20[bp]
	      	sxh  	r3,r3
	      	asri 	r3,r3,#17
	      	beq  	r3,disassem_766
	      	lh   	r3,-20[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#17
	      	push 	r3
	      	push 	#disassem_756
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_766:
disassem_765:
	      	lw   	r3,-16[bp]
	      	beq  	r3,disassem_768
	      	push 	-16[bp]
	      	push 	#disassem_757
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_768:
	      	push 	#disassem_758
	      	bsr  	printf
	      	addui	sp,sp,#8
disassem_770:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_759:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_770
endpublic

public code disassem:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_856
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
disassem_857:
	      	lw   	r3,[r11]
	      	lw   	r4,32[bp]
	      	cmp  	r3,r3,r4
	      	bne  	r3,disassem_859
	      	bsr  	reverse_video
	      	ldi  	r3,#1
	      	sw   	r3,-96[bp]
disassem_859:
	      	lw   	r3,[r11]
	      	asri 	r3,r3,#2
	      	sw   	r3,-72[bp]
	      	lw   	r3,-72[bp]
	      	asli 	r3,r3,#2
	      	lhu  	r4,0[r12+r3]
	      	sh   	r4,-12[bp]
	      	lh   	r3,-12[bp]
	      	sh   	r3,-76[bp]
	      	lhu  	r3,-12[bp]
	      	and  	r3,r3,#127
	      	sw   	r3,-24[bp]
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#4294967295
	      	asri 	r3,r3,#25
	      	and  	r3,r3,#127
	      	sw   	r3,-32[bp]
	      	lw   	r3,-24[bp]
	      	cmp  	r4,r3,#124
	      	beq  	r4,disassem_862
	      	cmp  	r4,r3,#2
	      	beq  	r4,disassem_863
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_864
	      	cmp  	r4,r3,#20
	      	beq  	r4,disassem_865
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_866
	      	cmp  	r4,r3,#21
	      	beq  	r4,disassem_867
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_868
	      	cmp  	r4,r3,#22
	      	beq  	r4,disassem_869
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_870
	      	cmp  	r4,r3,#23
	      	beq  	r4,disassem_871
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_872
	      	cmp  	r4,r3,#24
	      	beq  	r4,disassem_873
	      	cmp  	r4,r3,#12
	      	beq  	r4,disassem_874
	      	cmp  	r4,r3,#13
	      	beq  	r4,disassem_875
	      	cmp  	r4,r3,#14
	      	beq  	r4,disassem_876
	      	cmp  	r4,r3,#61
	      	beq  	r4,disassem_877
	      	cmp  	r4,r3,#62
	      	beq  	r4,disassem_878
	      	cmp  	r4,r3,#56
	      	beq  	r4,disassem_879
	      	cmp  	r4,r3,#57
	      	beq  	r4,disassem_880
	      	cmp  	r4,r3,#58
	      	beq  	r4,disassem_881
	      	cmp  	r4,r3,#55
	      	beq  	r4,disassem_882
	      	cmp  	r4,r3,#59
	      	beq  	r4,disassem_883
	      	cmp  	r4,r3,#64
	      	beq  	r4,disassem_884
	      	cmp  	r4,r3,#65
	      	beq  	r4,disassem_885
	      	cmp  	r4,r3,#66
	      	beq  	r4,disassem_886
	      	cmp  	r4,r3,#67
	      	beq  	r4,disassem_887
	      	cmp  	r4,r3,#68
	      	beq  	r4,disassem_888
	      	cmp  	r4,r3,#69
	      	beq  	r4,disassem_889
	      	cmp  	r4,r3,#70
	      	beq  	r4,disassem_890
	      	cmp  	r4,r3,#71
	      	beq  	r4,disassem_891
	      	cmp  	r4,r3,#72
	      	beq  	r4,disassem_892
	      	cmp  	r4,r3,#73
	      	beq  	r4,disassem_893
	      	cmp  	r4,r3,#74
	      	beq  	r4,disassem_894
	      	cmp  	r4,r3,#75
	      	beq  	r4,disassem_895
	      	cmp  	r4,r3,#76
	      	beq  	r4,disassem_896
	      	cmp  	r4,r3,#77
	      	beq  	r4,disassem_897
	      	cmp  	r4,r3,#78
	      	beq  	r4,disassem_898
	      	cmp  	r4,r3,#79
	      	beq  	r4,disassem_899
	      	cmp  	r4,r3,#100
	      	beq  	r4,disassem_900
	      	cmp  	r4,r3,#96
	      	beq  	r4,disassem_901
	      	cmp  	r4,r3,#97
	      	beq  	r4,disassem_902
	      	cmp  	r4,r3,#98
	      	beq  	r4,disassem_903
	      	cmp  	r4,r3,#99
	      	beq  	r4,disassem_904
	      	cmp  	r4,r3,#104
	      	beq  	r4,disassem_905
	      	cmp  	r4,r3,#105
	      	beq  	r4,disassem_906
	      	cmp  	r4,r3,#106
	      	beq  	r4,disassem_907
	      	cmp  	r4,r3,#107
	      	beq  	r4,disassem_908
	      	cmp  	r4,r3,#92
	      	beq  	r4,disassem_909
	      	cmp  	r4,r3,#110
	      	beq  	r4,disassem_910
	      	cmp  	r4,r3,#103
	      	beq  	r4,disassem_911
	      	cmp  	r4,r3,#87
	      	beq  	r4,disassem_912
	      	cmp  	r4,r3,#63
	      	beq  	r4,disassem_913
	      	cmp  	r4,r3,#10
	      	beq  	r4,disassem_914
	      	bra  	disassem_915
disassem_862:
	      	ldi  	r3,#1
	      	sw   	r3,-40[bp]
	      	lw   	r3,-88[bp]
	      	beq  	r3,disassem_916
	      	lh   	r3,-76[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#7
	      	sw   	r3,-48[bp]
	      	lw   	r3,-48[bp]
	      	and  	r3,r3,#16777216
	      	beq  	r3,disassem_918
	      	lw   	r3,-48[bp]
	      	ori  	r3,r3,#-16777216
	      	sw   	r3,-48[bp]
disassem_918:
	      	bra  	disassem_917
disassem_916:
	      	lw   	r3,-48[bp]
	      	asli 	r3,r3,#25
	      	lhu  	r4,-12[bp]
	      	andi 	r4,r4,#4294967295
	      	asri 	r4,r4,#7
	      	or   	r3,r3,r4
	      	sw   	r3,-48[bp]
disassem_917:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_771
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	sw   	r0,-88[bp]
	      	bra  	disassem_861
disassem_863:
	      	lw   	r3,-32[bp]
	      	cmp  	r4,r3,#55
	      	beq  	r4,disassem_921
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_922
	      	cmp  	r4,r3,#20
	      	beq  	r4,disassem_923
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_924
	      	cmp  	r4,r3,#21
	      	beq  	r4,disassem_925
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_926
	      	cmp  	r4,r3,#22
	      	beq  	r4,disassem_927
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_928
	      	cmp  	r4,r3,#23
	      	beq  	r4,disassem_929
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_930
	      	cmp  	r4,r3,#24
	      	beq  	r4,disassem_931
	      	cmp  	r4,r3,#12
	      	beq  	r4,disassem_932
	      	cmp  	r4,r3,#13
	      	beq  	r4,disassem_933
	      	cmp  	r4,r3,#14
	      	beq  	r4,disassem_934
	      	cmp  	r4,r3,#31
	      	beq  	r4,disassem_935
	      	cmp  	r4,r3,#30
	      	beq  	r4,disassem_936
	      	bra  	disassem_920
disassem_921:
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#4294967295
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#31
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_938
	      	cmp  	r4,r3,#1
	      	beq  	r4,disassem_939
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_940
	      	cmp  	r4,r3,#29
	      	beq  	r4,disassem_941
	      	cmp  	r4,r3,#30
	      	beq  	r4,disassem_942
	      	cmp  	r4,r3,#31
	      	beq  	r4,disassem_943
	      	bra  	disassem_944
disassem_938:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_772
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_937
disassem_939:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_773
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_937
disassem_940:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_774
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_937
disassem_941:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_775
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_937
disassem_942:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_776
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_937
disassem_943:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_777
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_937
disassem_944:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_778
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_937
disassem_937:
	      	bra  	disassem_920
disassem_922:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_779
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_920
disassem_923:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_780
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_920
disassem_924:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_781
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_920
disassem_925:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_782
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_920
disassem_926:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_783
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_920
disassem_927:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_784
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_920
disassem_928:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_785
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_920
disassem_929:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_786
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_920
disassem_930:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_787
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_920
disassem_931:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_788
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_920
disassem_932:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_789
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_920
disassem_933:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_790
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_920
disassem_934:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_791
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_920
disassem_935:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_792
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRstc
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispSpr
	      	addui	sp,sp,#8
	      	push 	#disassem_793
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_920
disassem_936:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_794
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispSpr
	      	addui	sp,sp,#8
	      	push 	#disassem_795
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRa
	      	addui	sp,sp,#8
	      	push 	#disassem_796
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_920
disassem_920:
	      	bra  	disassem_861
disassem_864:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_797
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_865:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_798
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_866:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_799
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_867:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_800
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_868:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_801
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_869:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_802
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_870:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_803
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_871:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_804
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_872:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_805
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_873:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_806
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_874:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_807
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_875:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_808
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_876:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_809
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_877:
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#4294967295
	      	asri 	r3,r3,#12
	      	and  	r3,r3,#7
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_946
	      	cmp  	r4,r3,#1
	      	beq  	r4,disassem_947
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_948
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_949
	      	cmp  	r4,r3,#2
	      	beq  	r4,disassem_950
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_951
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_952
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_952
	      	bra  	disassem_945
disassem_946:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_810
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_945
disassem_947:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_811
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_945
disassem_948:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_812
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_945
disassem_949:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_813
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_945
disassem_950:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_814
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_945
disassem_951:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_815
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_945
disassem_952:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_816
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_945
disassem_945:
	      	bra  	disassem_861
disassem_878:
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DispJALI
	      	addui	sp,sp,#32
	      	bra  	disassem_861
disassem_879:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispBrk
	      	addui	sp,sp,#8
	      	bra  	disassem_861
disassem_880:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#4294967295
	      	asri 	r3,r3,#7
	      	sw   	r3,-64[bp]
	      	lhu  	r3,-12[bp]
	      	and  	r3,r3,#2147483648
	      	beq  	r3,disassem_953
	      	lw   	r3,-64[bp]
	      	ori  	r3,r3,#-16777216
	      	sw   	r3,-64[bp]
disassem_953:
	      	lw   	r3,[r11]
	      	lw   	r4,-64[bp]
	      	asli 	r4,r4,#2
	      	addu 	r3,r3,r4
	      	sw   	r3,-56[bp]
	      	push 	-56[bp]
	      	push 	#disassem_817
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_861
disassem_881:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#4294967295
	      	asri 	r3,r3,#7
	      	sw   	r3,-64[bp]
	      	lhu  	r3,-12[bp]
	      	and  	r3,r3,#2147483648
	      	beq  	r3,disassem_955
	      	lw   	r3,-64[bp]
	      	ori  	r3,r3,#-16777216
	      	sw   	r3,-64[bp]
disassem_955:
	      	lw   	r3,[r11]
	      	lw   	r4,-64[bp]
	      	asli 	r4,r4,#2
	      	addu 	r3,r3,r4
	      	sw   	r3,-56[bp]
	      	push 	-56[bp]
	      	push 	#disassem_818
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_861
disassem_882:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#4294967295
	      	asri 	r3,r3,#17
	      	sw   	r3,-56[bp]
	      	push 	-56[bp]
	      	push 	#disassem_819
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_861
disassem_883:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#4294967295
	      	asri 	r3,r3,#17
	      	sw   	r3,-56[bp]
	      	push 	-56[bp]
	      	push 	#disassem_820
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_861
disassem_884:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_821
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_885:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_822
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_886:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_823
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_887:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_824
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_888:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_825
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_889:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_826
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_890:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_827
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_891:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_828
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_892:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_829
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_861
disassem_893:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_830
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_861
disassem_894:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_831
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_861
disassem_895:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_832
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_861
disassem_896:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_833
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_861
disassem_897:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_834
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_861
disassem_898:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_835
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_861
disassem_899:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_836
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_861
disassem_900:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	bsr  	DispInc
	      	addui	sp,sp,#24
	      	bra  	disassem_861
disassem_901:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_837
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_902:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_838
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_903:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_839
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_904:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_840
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_905:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_841
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_861
disassem_906:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_842
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_861
disassem_907:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_843
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_861
disassem_908:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_844
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_861
disassem_909:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_845
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_910:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_846
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_861
disassem_911:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_847
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRa
	      	addui	sp,sp,#8
	      	push 	#disassem_848
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_861
disassem_912:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_849
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRst
	      	addui	sp,sp,#8
	      	push 	#disassem_850
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_861
disassem_913:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_851
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_861
disassem_914:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_852
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRstc
	      	addui	sp,sp,#8
	      	lw   	r3,-40[bp]
	      	beq  	r3,disassem_957
	      	lw   	r3,-48[bp]
	      	asli 	r3,r3,#15
	      	lhu  	r4,-12[bp]
	      	andi 	r4,r4,#4294967295
	      	asri 	r4,r4,#17
	      	or   	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_853
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_958
disassem_957:
	      	lh   	r3,-76[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#17
	      	push 	r3
	      	push 	#disassem_854
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_958:
	      	bra  	disassem_861
disassem_915:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_855
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_861
disassem_861:
	      	lw   	r3,[r11]
	      	addu 	r3,r3,#4
	      	sw   	r3,[r11]
	      	lw   	r3,-96[bp]
	      	beq  	r3,disassem_959
	      	bsr  	reverse_video
	      	sw   	r0,-96[bp]
disassem_959:
	      	lw   	r3,-24[bp]
	      	cmp  	r3,r3,#124
	      	beq  	r3,disassem_857
disassem_858:
disassem_961:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_856:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_961
endpublic

public code disassem20:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_963
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	#disassem_962
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	sw   	r0,-8[bp]
disassem_964:
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#16
	      	bge  	r3,disassem_965
	      	push 	32[bp]
	      	pea  	24[bp]
	      	bsr  	disassem
	      	addui	sp,sp,#16
disassem_966:
	      	inc  	-8[bp],#1
	      	bra  	disassem_964
disassem_965:
disassem_967:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_963:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_967
endpublic

	rodata
	align	16
	align	8
disassem_962:
	dc	68,105,115,97,115,115,101,109
	dc	58,13,10,0
disassem_855:
	dc	63,63,63,63,63,13,10,0
disassem_854:
	dc	35,36,37,88,13,10,0
disassem_853:
	dc	35,36,37,88,13,10,0
disassem_852:
	dc	76,68,73,32,32,32,0
disassem_851:
	dc	78,79,80,13,10,0
disassem_850:
	dc	13,10,0
disassem_849:
	dc	80,79,80,32,32,32,0
disassem_848:
	dc	13,10,0
disassem_847:
	dc	80,85,83,72,32,32,0
disassem_846:
	dc	83,87,67,82,32,0
disassem_845:
	dc	76,87,65,82,32,0
disassem_844:
	dc	83,87,32,32,32,0
disassem_843:
	dc	83,72,32,32,32,0
disassem_842:
	dc	83,67,32,32,32,0
disassem_841:
	dc	83,66,32,32,32,0
disassem_840:
	dc	83,87,32,32,32,0
disassem_839:
	dc	83,72,32,32,32,0
disassem_838:
	dc	83,67,32,32,32,0
disassem_837:
	dc	83,66,32,32,32,0
disassem_836:
	dc	76,69,65,32,32,0
disassem_835:
	dc	76,87,32,32,32,0
disassem_834:
	dc	76,72,85,32,32,0
disassem_833:
	dc	76,72,32,32,32,0
disassem_832:
	dc	76,67,85,32,32,0
disassem_831:
	dc	76,67,32,32,32,0
disassem_830:
	dc	76,66,85,32,32,0
disassem_829:
	dc	76,66,32,32,32,0
disassem_828:
	dc	76,69,65,32,32,0
disassem_827:
	dc	76,87,32,32,32,0
disassem_826:
	dc	76,72,85,32,32,0
disassem_825:
	dc	76,72,32,32,32,0
disassem_824:
	dc	76,67,85,32,32,0
disassem_823:
	dc	76,67,32,32,32,0
disassem_822:
	dc	76,66,85,32,32,0
disassem_821:
	dc	76,66,32,32,32,0
disassem_820:
	dc	82,84,83,32,32,32,35,37
	dc	88,13,10,0
disassem_819:
	dc	82,84,76,32,32,32,35,37
	dc	88,13,10,0
disassem_818:
	dc	66,82,65,32,32,32,36,37
	dc	88,13,10,0
disassem_817:
	dc	66,83,82,32,32,32,36,37
	dc	88,13,10,0
disassem_816:
	dc	63,63,63,32,32,0
disassem_815:
	dc	66,71,69,32,32,0
disassem_814:
	dc	66,71,84,32,32,0
disassem_813:
	dc	66,76,69,32,32,0
disassem_812:
	dc	66,76,84,32,32,0
disassem_811:
	dc	66,78,69,32,32,0
disassem_810:
	dc	66,69,81,32,32,0
disassem_809:
	dc	69,79,82,32,32,0
disassem_808:
	dc	79,82,32,32,32,0
disassem_807:
	dc	65,78,68,32,32,0
disassem_806:
	dc	68,73,86,85,32,0
disassem_805:
	dc	68,73,86,32,32,0
disassem_804:
	dc	77,85,76,85,32,0
disassem_803:
	dc	77,85,76,32,32,0
disassem_802:
	dc	67,77,80,85,32,0
disassem_801:
	dc	67,77,80,32,32,0
disassem_800:
	dc	83,85,66,85,32,0
disassem_799:
	dc	83,85,66,32,32,0
disassem_798:
	dc	65,68,68,85,32,0
disassem_797:
	dc	65,68,68,32,32,0
disassem_796:
	dc	13,10,0
disassem_795:
	dc	44,0
disassem_794:
	dc	77,84,83,80,82,32,0
disassem_793:
	dc	13,10,0
disassem_792:
	dc	77,70,83,80,82,32,0
disassem_791:
	dc	69,79,82,32,32,0
disassem_790:
	dc	79,82,32,32,32,0
disassem_789:
	dc	65,78,68,32,32,0
disassem_788:
	dc	68,73,86,85,32,0
disassem_787:
	dc	68,73,86,32,32,0
disassem_786:
	dc	77,85,76,85,32,0
disassem_785:
	dc	77,85,76,32,32,0
disassem_784:
	dc	67,77,80,85,32,0
disassem_783:
	dc	67,77,80,32,32,0
disassem_782:
	dc	83,85,66,85,32,0
disassem_781:
	dc	83,85,66,32,32,0
disassem_780:
	dc	65,68,68,85,32,0
disassem_779:
	dc	65,68,68,32,32,0
disassem_778:
	dc	63,63,63,13,10,0
disassem_777:
	dc	82,84,73,13,10,0
disassem_776:
	dc	82,84,69,13,10,0
disassem_775:
	dc	82,84,68,13,10,0
disassem_774:
	dc	87,65,73,13,10,0
disassem_773:
	dc	83,69,73,13,10,0
disassem_772:
	dc	67,76,73,13,10,0
disassem_771:
	dc	73,77,77,13,10,0
disassem_758:
	dc	41,13,10,0
disassem_757:
	dc	91,82,37,100,93,0
disassem_756:
	dc	36,37,88,0
disassem_755:
	dc	36,37,88,0
disassem_754:
	dc	74,77,80,32,32,32,40,0
disassem_753:
	dc	74,83,82,32,32,32,40,0
disassem_752:
	dc	40,0
disassem_751:
	dc	74,65,76,32,32,32,0
disassem_746:
	dc	13,10,0
disassem_745:
	dc	37,115,32,0
disassem_744:
	dc	13,10,0
disassem_743:
	dc	77,79,86,32,32,32,0
disassem_738:
	dc	37,48,54,88,13,10,0
disassem_737:
	dc	37,115,32,0
disassem_732:
	dc	35,36,37,88,13,10,0
disassem_731:
	dc	35,36,37,88,13,10,0
disassem_730:
	dc	37,115,32,0
disassem_726:
	dc	37,115,32,0
disassem_714:
	dc	91,82,37,100,93,13,10,0
disassem_713:
	dc	91,82,37,100,0
disassem_712:
	dc	91,82,37,100,43,82,37,100
	dc	0
disassem_711:
	dc	36,37,88,0
disassem_710:
	dc	37,115,32,82,37,100,44,0
disassem_701:
	dc	66,82,75,63,32,32,35,37
	dc	88,13,10,0
disassem_700:
	dc	73,78,84,32,32,32,35,37
	dc	88,13,10,0
disassem_699:
	dc	68,66,71,32,32,32,35,37
	dc	88,13,10,0
disassem_698:
	dc	83,89,83,32,32,32,35,37
	dc	88,13,10,0
disassem_692:
	dc	93,13,10,0
disassem_691:
	dc	42,37,100,93,13,10,0
disassem_681:
	dc	35,37,100,13,10,0
disassem_680:
	dc	91,82,37,100,93,44,0
disassem_679:
	dc	44,0
disassem_678:
	dc	36,37,88,0
disassem_677:
	dc	36,37,88,0
disassem_676:
	dc	73,78,67,32,32,32,0
disassem_675:
	dc	68,69,67,32,32,32,0
disassem_667:
	dc	13,10,0
disassem_666:
	dc	91,82,37,100,93,13,10,0
disassem_665:
	dc	36,37,88,0
disassem_664:
	dc	36,37,88,0
disassem_644:
	dc	83,80,82,37,100,0
disassem_643:
	dc	68,66,83,84,65,84,0
disassem_642:
	dc	68,66,67,84,82,76,0
disassem_641:
	dc	68,66,65,68,51,0
disassem_640:
	dc	68,66,65,68,50,0
disassem_639:
	dc	68,66,65,68,49,0
disassem_638:
	dc	68,66,65,68,48,0
disassem_637:
	dc	86,66,82,0
disassem_636:
	dc	69,80,67,0
disassem_635:
	dc	73,80,67,0
disassem_634:
	dc	68,80,67,0
disassem_633:
	dc	67,76,75,0
disassem_632:
	dc	84,73,67,75,0
disassem_631:
	dc	67,82,51,0
disassem_630:
	dc	67,82,48,0
disassem_626:
	dc	82,37,100,0
disassem_622:
	dc	82,37,100,0
disassem_618:
	dc	82,37,100,44,0
disassem_614:
	dc	82,37,100,44,0
disassem_610:
	dc	114,37,100,0
disassem_606:
	dc	37,48,54,88,32,37,48,50
	dc	88,32,37,48,50,88,32,37
	dc	48,50,88,32,37,48,50,88
	dc	9,0
;	global	DispRR
;	global	DumpInsnBytes
;	global	GetNormAttr
;	global	disassem
;	global	SetNormAttr
;	global	reverse_video
	extern	printf
;	global	DispBcc
;	global	DispJALI
;	global	disassem20
	extern	putstr2
