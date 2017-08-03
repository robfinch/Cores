
int nums [30];

int main()
{
	int c,c1,c2;
	int n;

	c1 = 0;
	c2 = 1;
	for (n = 0; n < 23; n = n + 1) {
		if (n < 1) {
			nums[0] = 1;
			c = 1;
		}
		else {		
			nums[n] = c;
			c = c1 + c2;
			c1 = c2;
			c2 = c;
		}
	}
}
