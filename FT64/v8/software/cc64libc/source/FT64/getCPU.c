
naked int getCPU()
{
	__asm {
		csrrd	$r1,#1,$r0
		ret
	}
}

