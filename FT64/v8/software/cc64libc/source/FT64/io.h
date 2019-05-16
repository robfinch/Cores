#ifndef _IO_H
#define _IO_H

// volatile byte loads only have indexed addressing modes.

naked int in8(int port)
{
	__asm {
		lw		$r1,[sp]
		lvb		$r1,[$r1+r0]
		memdb
		ret		
	}	
}

naked int in8u(int port)
{
	__asm {
		lw		$r1,[sp]
		lvbu	$r1,[$r1+r0]
		memdb
		ret		
	}	
}

naked int in16(int port)
{
	__asm {
		lw		$r1,[sp]
		lvc		$r1,[$r1]
		memdb
		ret		
	}	
}

naked int in16u(int port)
{
	__asm {
		lw		$r1,[sp]
		lvcu	$r1,[$r1]
		memdb
		ret		
	}	
}

naked int in32(int port)
{
	__asm {
		lw		$r1,[sp]
		lvh		$r1,[$r1]
		memdb
		ret		
	}	
}

naked int in32u(int port)
{
	__asm {
		lw		$r1,[sp]
		lvhu	$r1,[$r1]
		memdb
		ret		
	}	
}

naked int in64(int port)
{
	__asm {
		lw		$r1,[sp]
		lvw		$r1,[$r1]
		memdb
		ret		
	}	
}

// All the add's are in order to flush the processor queue to
// guarentee the store isn't merged with other stores.

naked void out8(int port, int value)
{
	__asm {
		lw		$r1,[sp]
		lw		$r2,8[sp]
		sb		$r2,[$r1]
	  memdb
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  ret
	}
}

naked void out16(int port, int value)
{
	__asm {
		lw		$r1,[sp]
		lw		$r2,8[sp]
		sc		$r2,[$r1]
	  memdb
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  ret
	}
}

naked void out32(int port, int value)
{
	__asm {
		lw		$r1,[sp]
		lw		$r2,8[sp]
		sh		$r2,[$r1]
	  memdb
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  ret
	}
}

naked void out64(int port, int value)
{
	__asm {
		lw		$r1,[sp]
		lw		$r2,8[sp]
		sw		$r2,[$r1]
	  memdb
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  add		$r0,$r0,#0
	  ret
	}
}

naked int getCPU();

#endif
