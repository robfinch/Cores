
void sleep(int milliseconds)
{
	if (FMTK_Inited==0x12345678) {

	}
	else {
		for (milliseconds *= 10000; milliseconds >= 0; milliseconds--)
			;
	}
}
