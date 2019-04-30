
int *TestTypecast(int *a)
{
	int *tmp;

	(int *)(*tmp) = a;
	return (int *)21;
}