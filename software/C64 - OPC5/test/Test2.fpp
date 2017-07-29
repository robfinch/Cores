int ary[20][45];

int main(int argc, char **argv)
{
	int x, y, z;

	for (y = 0; y < argc; y++) {
		for (z = 0; z < 45; z++)
			ary[y][z] = rand();
	}
	for (x = 0; x < 10; x++)  {
		printf("Hello World!");
	}
	naked switch(argc) {
	case 1:	printf("One"); break;
	case 2:	printf("Two"); break;
	case 3:	printf("Three"); break;
	}
	exit(0);
}
