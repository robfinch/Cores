
int main(int argc, char **argv)
{
	int x;

	for (x = 0; x < 10; x++)  {
		printf("Hello World!");
	}
	switch(argc) {
	case 1:	printf("One"); break;
	case 2:	printf("Two"); break;
	case 3:	printf("Three"); break;
	}
	exit(0);
}
