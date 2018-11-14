
naked int GetOperatingLevel()
{
	__asm {
		csrrd		$r1,#$044,$r0
		shr			$r1,$r1,#4
		and			$r1,$r1,#3
		ret
	}
}

naked int GetASID()
{
	__asm {
		csrrd			$r1,#$044,r0
		shr				$r1,$r1,#40
		and				$r1,$r1,#$FF
		ret
	}
}

naked void SetASID(register int val)
{
	__asm {
		csrrd			$r1,#$44,r0
		ror				$r1,$r1,#40
		and				$r1,$r1,#$FFFFFFFFFFFFFF00
		and				$r18,$r18,#$FF
		or				$r1,$r1,$r18
		rol				$r1,$r1,#40
		csrrw			$r0,#$44,$r1
		ret
	}
}
