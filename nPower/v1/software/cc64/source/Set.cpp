#include <stdio.h>
#include <ctype.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include "stdafx.h"
#include "set.h"

/* -------------------------------------------------------------------
	Code for set routines.
------------------------------------------------------------------- */

#ifndef min
#define min(a,b)	(((a) < (b)) ? (a) : (b))
#define max(a,b)	(((a) > (b)) ? (a) : (b))
#endif


void CSet::allocBitStorage()
{
	if (size <= SET_DEFAULT_SIZE)
	{
 		size = SET_DEFAULT_SIZE;
		map = dmap;
	}
	else {
		map = (unsigned int *)allocx(sizeof(unsigned int)*size);
//		map = new unsigned int[size];
	}

}


void CSet::copy(const CSet &s)
{
//	if (map != dmap)	// get rid of an old map
//		delete[] map;
	compl = s.compl;
	size = s.size;
	nbits = s.nbits;
	MemberPtr = s.MemberPtr;

	// Either assign default map or allocate memory.
	allocBitStorage();
	memcpy(map, s.map, s.size * sizeof(int));
}


// Assignment (copy) operator
// --------------------------
CSet& CSet::operator=(CSet &s)
{
	if (map != dmap)
		delete[] map;
	compl = s.compl;
	size = s.size;
	nbits = s.nbits;
	MemberPtr = s.MemberPtr;

	// Either assign default map or allocate memory.
	allocBitStorage();
	memcpy(map, s.map, s.size * sizeof(int));
	return *this;
}


// Union of two sets.
// ------------------
CSet CSet::operator|(CSet s)
{
	CSet o;
	int ii, NumWords;

	// Set the size of the bitmap to the greater of the two sizes.
	if (size >= s.size)
	{
		o.size = size;
		o.nbits = nbits;
	}
	else
	{
		o.size = s.size;
		o.nbits = s.nbits;
	}
	o.allocBitStorage();

	NumWords = min(size, s.size);
	// Set bits in output according to union of two sets.
	for (ii = NumWords - 1; ii >= 0; ii--)
		o.map[ii] = map[ii] | s.map[ii];
	// Copy remaining words to output bitset
	if (s.size > size)
		memcpy(&o.map[size], &s.map[size],
            (s.size - size) * sizeof(int));
	else
		memcpy(&o.map[s.size], &map[s.size],
            (size - s.size) * sizeof(int));
	return o;
}


// Union to same set.
// ------------------
CSet& CSet::operator|=(CSet s)
{
	int ii;

	// Set the size of the bitmap to the greater of the two sizes.
	if (size < s.size)
		enlarge(s.size);
	for (ii = min(size,s.size) -1 ; ii >= 0; ii--)
		map[ii] |= s.map[ii];
	return *this;
}


void CSet::add(CSet &s)
{
	int ii;

	// Set the size of the bitmap to the greater of the two sizes.
	if (size < s.size)
		enlarge(s.size);
	for (ii = min(size,s.size) - 1; ii >= 0; ii--)
		map[ii] |= s.map[ii];
}


void CSet::add(CSet *s)
{
	int ii;

	if (s == nullptr)
		return;

	// Set the size of the bitmap to the greater of the two sizes.
	if (size < s->size)
		enlarge(s->size);
	for (ii = min(size,s->size) - 1; ii >= 0; ii--)
		map[ii] |= s->map[ii];
}


/*	-------------------------------------------------------------------
 		Intersection of two sets. If the two sets are not the same
    size then smaller set is used as the size of the output.
-------------------------------------------------------------------- */	

CSet CSet::operator&(CSet s)
{
	CSet o;
	int ii;

	// Set the size of the bitmap to the smaller of the two sizes.
	if (size <= s.size)
	{
		o.size = size;
		o.nbits = nbits;
	}
	else
	{
		o.size = s.size;
		o.nbits = s.nbits;
	}

	o.allocBitStorage();

	// Set bits in output according to union of two sets.
	for (ii = o.size - 1; ii >= 0; ii--)
		o.map[ii] = map[ii] & s.map[ii];
	return o;
}


/* --------------------------------------------------------------------
	Intersection to same set.
-------------------------------------------------------------------- */

CSet& CSet::operator&=(CSet s)
{
	int ii;

	// Set the size of the bitmap to the smaller of the two sizes.
	if (size > s.size)
	{
		memset(&map[size], 0, (size - s.size)*sizeof(int));
		size = s.size;
		nbits = s.nbits;
	}
	
	for (ii = size - 1; ii >= 0; ii--)
		map[ii] &= s.map[ii];
	return *this;
}


/* --------------------------------------------------------------------
	Enlarge set to 'n'. Enlarge works in chunk sizes.
-------------------------------------------------------------------- */

void CSet::enlarge(int n)
{
	unsigned int *p;

	if (n < size)
		return;
	n = (n + 4) & ~3;
	//p = new unsigned int[n];
	p = (unsigned int *)allocx(sizeof(int) * n);
	if (p == NULL)
	{
		fprintf(stderr, "Can't get memory to expand set.\n");
		exit(1);
	}
	memcpy(p, map, size * sizeof(int));
	if (memcmp(p,map,size*sizeof(int)) != 0)
		printf("Set.cpp enlarge error");
//	memset(p+size, 0, (n-size) * sizeof(int)); <- allocx zeros memory
//	if (map != dmap)
//		delete[] map;
	map = p;
	size = n;
	nbits = n * sizeof(int) << 3;
}


/*  Create a new set which contains all members of a set plus a new
    member.
		(s =) s1 + 100;
*/
CSet CSet::operator+(int bit)
{
	CSet s = *this;

	if (bit > s.nbits)
		s.enlarge((bit >> SET_NBIT) + 8);
	s.map[bit >> SET_NBIT] |= (1 << (bit & SET_BMASK));
	return s;
}


/* Create a new set which contains all members of a set except member.
		(s =) s1 - 100;
*/
CSet CSet::operator-(int bit)
{
	CSet s = *this;

	if (bit < s.nbits)
		s.map[bit >> SET_NBIT] &= ~(1 << (bit & SET_BMASK));
	return s;
}


/* Figure out the (symettric)difference between two sets.
*/
CSet CSet::operator-(CSet s)
{
	CSet o;
	int ii;

	o.size = max(size, s.size);
	o.nbits = max(nbits, s.nbits);
	o.allocBitStorage();

	// Set difference of elements common in both sets.
	for (ii = min(size, s.size); --ii >= 0;)
		o.map[ii] = map[ii] ^ s.map[ii];
	// Set remaining elements equal to elements remaining in larger set.
	if (size < s.size)
		for (ii = s.size; --ii >= size;)
			o.map[ii] = s.map[ii];
	else if (size > s.size)
		for (ii = size; --ii >= s.size;)
    		o.map[ii] = map[ii];
	return o;
}


// Flip all bits in set.
CSet CSet::operator!()
{
	int ii;
	CSet o;

	o = *this;
	for (ii = size; --ii >= 0;)
		o.map[ii] = ~map[ii];
	return o;
}

/*
CSet &CSet::operator!()
{
	int ii;

	for (ii = size; --ii >= 0;)
		map[ii] = ~map[ii];
	return *this;
}
*/

/* --------------------------------------------------------------------
   Get the number of elements in the set.
-------------------------------------------------------------------- */

int CSet::NumMember() const
{
	// Stores the number of set bits in each value 0-255
	static unsigned char numbits[] =
	{
		0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4,
		1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
		1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
		2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
		1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
		2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
		2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
		3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
		1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
		2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
		2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
		3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
		2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
		3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
		3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
		4, 5, 5, 6, 5, 6, 6, 7, 5, 6, 6, 7, 6, 7, 7, 8
	};

	int tot = 0, ii;
	unsigned __int8 *pm = (unsigned __int8 *)map;

	for (ii = size * sizeof(int); --ii >= 0;)
		tot += numbits[pm[ii]];
	return (tot);
}


inline void CSet::clear()   // Zero all bits
    { memset((char *)map, 0, size * sizeof(int)); };
inline void CSet::fill()    // Set all bits
    { memset((char *)map, ~0, size * sizeof(int)); };
inline void CSet::complement() { compl = ~compl; };

/* --------------------------------------------------------------------
	Remove member - clears bit in map
-------------------------------------------------------------------- */

void CSet::remove(int x)
{
   if (x < nbits)
      map[x >> SET_NBIT] &= ~(1 << (x & SET_BMASK));
}


/* --------------------------------------------------------------------
	Determines if set is a subset of another.
-------------------------------------------------------------------- */

int CSet::subset(CSet &poss) const
{
	unsigned int *subsetp, *setp;
	int common, tail;

	if(poss.size > size)
	{
		common = size;
		tail = poss.size - size;
	}
	else
	{
		common = poss.size;
		tail = 0;
	}
	subsetp = poss.map;
	setp = map;

	for (; --common >= 0; subsetp++, setp++)
		if ((*subsetp & *setp) != *subsetp)
			return 0;
	while(--tail >= 0)
		if (*subsetp++)
			return 0;
	return 1;
}


/* --------------------------------------------------------------------
	Set set back to default size and clear.
-------------------------------------------------------------------- */

void CSet::truncate()
{
	if (map != dmap)
	{
		delete[] map;
		map = dmap;
	}
	size = SET_DEFAULT_SIZE;
	nbits = SET_DEFAULT_SIZE * sizeof(int) * 8;
	memset(dmap, 0, size * sizeof(int));
}


/* --------------------------------------------------------------------
	Hash the set.
-------------------------------------------------------------------- */

unsigned CSet::hash() const
{
	unsigned int *p;
	unsigned total;
	int j;

	total = 0;
	j = size;
	p = map;

	while(--j >= 0)
		total += *p++;

	return total;
}


/* --------------------------------------------------------------------
		Print the contents of a set bitmap.
-------------------------------------------------------------------- */

int CSet::print(int (*OutRout)(void *a, ...), void *param)
{
	int i,DidSomething = 0;

	resetPtr();
	while((i = nextMember()) >= 0)
	{
		DidSomething++;
		(*OutRout)(param, "%d", i);
	}
	resetPtr();
	if (!DidSomething)
		(*OutRout)(param, "empty", -2);
	return (DidSomething);
}


/* --------------------------------------------------------------------
	Description :
		Print the contents of a set bitmap to a string. A maximum of
    bufsz characters will be printed to the buffer. If there are
    more data than will fit in the buffer then "..." is put at the
    end of the list.
-------------------------------------------------------------------- */

int CSet::sprint(char *buf, int bufsz)
{
	int i;
	int nn;

	resetPtr();
	nn = sprintf_s(buf, bufsz, "{ ");
	while((i = nextMember()) >= 0)
	{
		_itoa_s(i, &buf[nn], bufsz-nn, 10);
		while(buf[nn]) ++nn;
		buf[nn] = ' ';	nn++;
		if (nn > bufsz - 12)
		{
			strcpy_s(&buf[nn], bufsz-nn,"...");
			nn += 3;
			break;
		}
	}
	buf[nn] = '}';	nn++;
	buf[nn] = '\0';
	resetPtr();
	return (nn);
}


/* --------------------------------------------------------------------
	Comparison function.
		returns
			0 if a == b
         1 if a > b
	     -1 if a < b

		The first set containing a bit not in the other set is
    considered to be larger.
-------------------------------------------------------------------- */

int CSet::cmp(CSet& s) const
{
	int j;
	unsigned int *m1, *m2;

	j = min(size, s.size);

	for (m1 = map, m2 = s.map; --j >= 0; m1++, m2++)
		if (*m1 != *m2)
			return (*m1 - *m2);
	// If all words in both sets are the same then check the tail of
    // the larger set and make sure all elements are not set.
	if (size == s.size)
		return 0;
	if (size > s.size)
	{
		for (j = size - s.size; --j >= 0;)
			if (*m1++)
				return 1;
	}
	else
	{
		for (j = s.size - size; --j >= 0;)
			if (*m2++)
         		return -1;
	}
	return 0;
}


/* --------------------------------------------------------------------
		Get the next member in the set.
-------------------------------------------------------------------- */

int CSet::nextMember()
{
	while(MemberPtr < nbits)
	{
		if (test(MemberPtr))
		{
			MemberPtr++;
			return (MemberPtr-1);
		}
		MemberPtr++;
	}
	return (-1);
}

int CSet::prevMember()
{
	while(MemberPtr > 0)
	{
		if (test(MemberPtr-1))
		{
			MemberPtr--;
			return (MemberPtr);
		}
		MemberPtr--;
	}
	return (-1);
}

int CSet::lastMember()
{
	int nn = nbits-1;
	while(!test(nn) && nn > 0) nn--;
	MemberPtr = nn;
	return(nn);
}

int CSet::Member(int n)
{
	resetPtr();
	while(MemberPtr < nbits && n > -1)
	{
		if (test(MemberPtr))
		{
			n--;
			MemberPtr++;
			if (n < 0)
			return (MemberPtr-1);
		}
		MemberPtr++;
	}
	return (-1);
}


/* --------------------------------------------------------------------
-------------------------------------------------------------------- */

int CSet::SetTest(CSet &s)
{
	int i, rval = SET_EQUIV;
	unsigned int *p1, *p2;

	i = max(size, s.size);

	// Make the sets the same size.
	if (s.size > size)
		enlarge(i);
	else if (s.size < size)
		s.enlarge(i);

	p1 = map;
	p2 = s.map;

	for (; --i >=0; p1++, p2++)
	{
		if (*p1 != *p2)
		{
			if (*p1 & *p2)
				return (SET_INTER);
			rval = SET_DISJ;
		}
		else if (*p1 != 0)
			if (rval==SET_DISJ)
				rval = SET_INTER;
	}
	return (rval);
}

int CSet::isSubset(CSet &s)
{
	int i;
	unsigned int *p1, *p2;

	if (s.size > size)
		return (false);
	p1 = map;
	p2 = s.map;
	for (i = s.size; --i >= 0; p1++, p2++) {
		if ((*p1 & *p2) != *p2)
			return (false);
	}
	return (true);
}

/*
void CSet::Serialize(CArchive& ar)
{
	int nn;

	if (ar.IsStoring()) {
		ar << MemberPtr;
		ar << nbits;
		ar << size;
		ar << compl;
		for (nn = 0; nn < size; nn++)
			ar << map[nn];
	}
	else {
		ar >> MemberPtr;
		ar >> nbits;
		ar >> size;
		ar >> compl;
		enlarge(size);
		for (nn = 0; nn < size; nn++)
			ar >> map[nn];
	}
}
*/

void CSet::insert(int64_t val, int base, int len)
{
	while (len > 0) {
		if (val & 1LL)
			add(base);
		else
			remove(base);
		base++;
		len--;
		val = val >> 1LL;
	}
}

void CSet::extract(int64_t* val, int base, int len)
{
	int64_t v;

	v = 0;
	while (len > 0) {
		len--;
		v = v << 1LL;
		if (isMember(base + len))
			v = v | 1;
	}
	if (val)
		*val = v;
}

// Shift the entire set to the right.

bool CSet::shr(int amt)
{
	unsigned int* p;
	int i;
	unsigned int v, c, nc;

	for (; amt > 0; amt--) {
		p = map;
		nc = c = 0;
		for (i = size - 1; i >= 0; i--) {
			v = map[i];
			nc = (v & 1LL) << 63LL;
			v = (v >> 1LL) | c;
			map[i] = v;
			c = nc;
		}
	}
	return (c >> 63LL);
}

// Shift entire set to the left.

bool CSet::shl(int amt)
{
	unsigned int* p;
	int i;
	unsigned int v, c, nc;

	for (; amt > 0; amt--) {
		p = map;
		nc = c = 0;
		for (i = 0; i < size; i++) {
			v = map[i];
			nc = (v >> 63LL) & 1LL;
			v = (v << 1LL) | c;
			map[i] = v;
			c = nc;
		}
	}
	return (c);
}

