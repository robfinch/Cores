#include <stdlib.h>

int (abs)(int i)
{
	return ((i < 0) ? -i : i);
}

div_t (div)(int numer, int denom)
{
	div_t val;

	val.quot = numer / denom;
	val.rem = numer - denom * val.quot;
	if (val.quot < 0 && 0 < val.rem) {
		val.quot += 1;
		val.rem -= denom;
	}
	return (val);
}

long (labs)(long i)
{
	return ((i < 0) ? -i : i);
}

ldiv_t (ldiv)(long numer, long denom)
{
	ldiv_t val;

	val.quot = numer / denom;
	val.rem = numer - denom * val.quot;
	if (val.quot < 0 && 0 < val.rem) {
		val.quot += 1;
		val.rem -= denom;
	}
	return (val);
}

void *(bsearch)(const void *key, const void *base, size_t nelem, size_t size, _Cmpfun *cmp)
{
	const char *p;
	size_t n;

	p = base;
	for (p = base, n = nelem; 0 < n;) {
		const size_t pivot = n >> 1;
		const char *q = p + size * pivot;
		const int val = (*cmp)(key,q);

		if (val < 0)
			n = pivot;
		else if (val == 0)
			return ((void *)q);
		else {
			p = q + size;
			n -= pivot + 1;
		}
	}
	return NULL;
}

void (qsort)(void *base, size_t n, size_t size, _Cmpfun *cmp)
{
	size_t i;
	size_t j;
	char *qi;
	char *qj;
	char *qp;
	char *q1;
	char *q2;
	char buf[256];
	size_t m, ms;

	while (1 < n) {
		i = 0;
		j = n - 1;
		qi = base;
		qj = qi + size * j;
		qp = qj;

		while (i < j) {
			while (i < j && (*cmp)(qi,qp) <= 0)
				++i, qi += size;
			while (i < j && (*cmp)(qp,qj) <= 0)
				--j, qj -= size;
			if (i < j) {
				for (ms = size; 0 < ms; ms -= m, q1 += m, q2 -= m) {
					m = ms < sizeof(buf) ? ms : sizeof(buf);
					memcpy(buf, q1, m);
					memcpy(q1, q2, m);
					memcpy(q2, buf, m);
				}
				++i, qi += size;
				--j, qj -= size;
			}
		}
		if (qi != qp) {
			for (m = size; 0 < ms; ms -= m, q1 += m, q2 -= m) {
				m = ms < sizeof(buf) ? ms : sizeof(buf);
				memcpy(buf, q1, m);
				memcpy(q1, q2, m);
				memcpy(q2, buf, m);
			}
		}
		j = n - i;
		if (j < i) {
			if (1 < j)
				qsort(qi, j, size, cmp);
			n = i;
		}
		else {
			if (1 < i)
				qsort(base, i, size, cmp);
			base = qi;
			n = j;
		}
	}
}


// seed the random number generator
void (srand)(unsigned int seed)
{
	_Randseed = seed;
}

// generate a random number in the range 0 to max-1
int (rand)(void)
{
	_Randseed = _Randseed * 1103515245 + 12345;
	return ((unsigned int)(_Randseed >> 16) & RAND_MAX);
}

int (atoi)(const char *s)
{
	return ((int)_Stoul(s, NULL, 10));
}

long (atol)(const char *s)
{
	return ((long)_Stoul(s, NULL, 10));
}

