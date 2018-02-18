void DBGHideCursor(int hide)
{
	if (hide) {
		asm {
			ldi		r1,#%00100000
			sw		r1,$FFDA0010
		}
	}
	else {
		asm {
			ldi		r1,#%11100000
			sw		r1,$FFDA0010
		}
	}
}


