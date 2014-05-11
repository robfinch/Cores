/*#include <stdio.h>*/

#define LIMIT 1500000
#define PRIMES 100000

int numbers[1500000];
int primes[100000];

int main(){
    int i,j;
	int limit;
	int start_tick,end_tick;

	// Request I/O focus
	asm {
		jsr	(0xFFFF8014>>2)
	}
j1:
	//disable_ints();
	start_tick = get_tick();
	printf("\r\nStart tick %d\r\n", start_tick);

	limit=LIMIT;

 	for (i=0;i<limit;i++){
		numbers[i]=i+2;
	}

    /*sieve the non-primes*/
    for (i=0;i<limit;i++){
        if (numbers[i]!=-1){
            for (j=2*numbers[i]-2;j<limit;j+=numbers[i])
                numbers[j]=-1;
        }
    }

    /*transfer the primes to their own array*/
    j = 0;
    for (i=0;i<limit&&j<PRIMES;i++)
        if (numbers[i]!=-1)
            primes[j++] = numbers[i];

	end_tick = get_tick();
	printf("Clock ticks %d\r\n", end_tick-start_tick);
	printf("Press a key to list primes.");
	getchar();

    /*print*/
    for (i=0;i<PRIMES;i++)
        printf("%d\r\n",primes[i]);

	//enable_ints();

return 0;
}

int printf(char *p)
{
	int *q;
	q = &p;

	for (; *p; p++) {
		if (*p=='%') {
			p++;
			switch(*p) {
			case '%':
				putch('%');
				break;
			case 'c':
				q++;
				putch(*q);
				break;
			case 'd':
				q++;
				putnum(*q);
				break;
			case 's':
				q++;
				putstr(*q);
				break;
			}
		}
		else
			putch(*p);
	}
}

int getchar()
{
	asm {
gc1:
		jsr		($FFFF800C>>2)
		cmp		#-1
		beq		gc1
	}
}

void putch(char ch)
{
	asm {
		ld		r1,3,sp
		jsr		($FFFF8000>>2)
	}
}

void putnum(int num)
{
	asm {
		ld		r1,3,sp
		ld		r2,#5
		jsl		$FFFFF5A4
		;jsr		($FFFF8048>>2)
	}
}

void putstr(char *p)
{
	for (; *p; p++)
		putch(*p);
}

int get_tick()
{
	asm {
		tsr		tick,r1
	}
}

void disable_ints()
{
	asm {
		lda		#0x8001
		sta		0xFFDC0FF2
	}
}

void enable_ints()
{
	asm {
		lda		#0x800F
		sta		0xFFDC0FF2
	}
}

