
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

	for (x = 1; x < 100; x++) {
		for (y = 50; y > 0; --y) {
			for (z = 1; z < 10; z++) {
				putch(rand());
			}
		}
	}
}

void TestFor2()
{
	for (;;)
		putch('h');
}
