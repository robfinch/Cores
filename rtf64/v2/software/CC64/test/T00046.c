typedef struct myname {
	int a;
	union u1 {
		int b1;
		int b2;
	};
	struct s2 { union u2 { struct s3 { int c; }; }; };
	struct s4 {
		int d;
	};
} s;

int
main()
{
	s v;
	
	v.a = 1;
	v.b1 = 2;
	v.c = 3;
	v.d = 4;
	
	if (v.a != 1)
		return 1;
	if (v.b1 != 2 && v.b2 != 2)
		return 2;
	if (v.c != 3)
		return 3;
	if (v.d != 4)
		return 4;
	
	return 0;
}
