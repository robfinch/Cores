
int TestFor()
{
	int x, y;

	for (x = 1; x < 100; x++) {
		putch('a');
	}

	y = 50;
	for (; y > 0;) {
		putch('b');
		--y;
	}
}
