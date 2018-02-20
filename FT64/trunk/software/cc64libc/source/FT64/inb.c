
int inb(unsigned int port)
{
     asm {
        lw    r2,32[bp]
		memdb
        lvb	  r1,zs:[r2]
     }
}

int inbu(unsigned int port)
{
     asm {
        lw    r2,32[bp]
		memdb
        lvb	  r1,zs:[r2]
		zxb	  r1,r1
     }
}

