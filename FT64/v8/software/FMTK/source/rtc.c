#define	I2C_PREL	0
#define	I2C_PREH	1
#define	I2C_CTRL	2
#define	I2C_RXR		3
#define I2C_TXR		3
#define I2C_CMD		4
#define I2C_STAT	5

naked void I2C_Init()
{
	__asm {
		
	}
i2c_setup:
		lea		I2C,a6				
		move.w	#19,I2C_PREL(a6)	; setup prescale for 400kHz clock
		move.w	#0,I2C_PREH(a6)
		lea		I2C2,a6				
		move.w	#19,I2C_PREL(a6)	; setup prescale for 400kHz clock
		move.w	#0,I2C_PREH(a6)
		rts

	
}

