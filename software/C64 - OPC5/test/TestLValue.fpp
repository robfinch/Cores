
int TestLValue()
{
	int x;
	int y, z;

	x = y + z;

	x = &y + 20;
	x = y + &x;

//	&x = y + z;	// should give an LValue error
}
