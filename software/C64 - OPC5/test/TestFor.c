
int TestFor()
{
	int x, y, z;

	for (x = 1; x < 100; x++) {
		putch('a');
	}

	y = 50;
	for (; y > 0;) {
		putch('b');
		--y;
	}

	for (z = 1; z < 10; ) ;
}
