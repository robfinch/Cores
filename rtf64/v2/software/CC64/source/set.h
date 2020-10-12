#ifndef SET_H
#define SET_H
#ifndef STRING_H
#include <string.h>
#endif
/*      Header file for set routines.
*/

#define SET_DEFAULT_SIZE     (128 / (sizeof(int) << 3))
#define SET_DIV_WSIZE(bit)   (bit) / (sizeof(int) << 3)
#define SET_ROUND(bit)       (((SET_DIV_WSIZE(bit) + 8) >> 3) << 3)
#define SET_GBIT(s,bit,op) \
    (((s).map)[SET_DIV_WSIZE(bit)] (op) (1 << (bit) & 15))
#define SET_BPW              (sizeof(int) << 3)
#define SET_BMASK            (SET_BPW - 1)
#define SET_NBIT             ((SET_BPW & 32) ? 5 : 4)

#define SET_EQUIV   0
#define SET_DISJ    1
#define SET_INTER   2
#define SET_UNKNOWN	3

extern void *allocx(int);

class CSet //: public CObject
{
   unsigned int dmap[SET_DEFAULT_SIZE];  // Default bitmap - 128 bits
   unsigned int *map;				// Pointer to bit map of elements
   unsigned __int16 MemberPtr;    // for NextMember
   unsigned __int16 nbits;        // Number of bits in map.
   unsigned __int8 size;          // number of int's of bitmap.
   unsigned __int8 compl;         // Negative true set if compl is true

   int cmp(CSet&) const;
   int SetTest(CSet &);
   void allocBitStorage();
public:
	void enlarge(int);            // increase size of set
	void Create() {
		map = dmap;
		size = SET_DEFAULT_SIZE;
		nbits = SET_DEFAULT_SIZE * sizeof(int) << 3;
		MemberPtr = 0;
		compl = 0;
		clear(); 
	};
	static CSet *MakeNew() {
		CSet *p;

		p = (CSet *)allocx(sizeof(CSet));
		p->Create();
		return (p);
	};
	CSet() {
		Create();
	};
	CSet(const CSet &s) { copy(s); };
	~CSet() {
		//if (map != dmap)
		//	delete[] map;
	};

   // Assignment other operators
   //---------------------------
	void copy(const CSet &s);

    CSet& operator=(CSet&);     			// Assignment (copy)
	CSet operator!();           			// s = not s1
	CSet operator|(CSet);      			// s = s1 union s2
	CSet& operator|=(CSet);    			// s1 = s1 union s2
	CSet operator&(CSet);      			// s = s1 intersection s2
	CSet& operator&=(CSet);   			// s1 = s1 intersection s2
	int operator&(int bit)
        { return isMember(bit); };  // is n a member of s ?
	CSet operator+(int);        // s = s1 plus element
	CSet operator-(int);        // s = s1 minus element
	CSet operator-(CSet);     // s = (symmetric) difference bewteen s1, s2

	// Relational operators
    //---------------------
	int operator==(CSet &s) const { return cmp(s) ? 0 : 1; };
	int operator!=(CSet &s) const { return cmp(s) ? 1 : 0; };
	int operator>(CSet &s) const { return (cmp(s) > 0) ? 1 : 0; };
	int operator<(CSet &s) const { return (cmp(s) < 0) ? 1 : 0; };
	int operator>=(CSet &s) const { return (cmp(s) >= 0) ? 1 : 0; };
	int operator<=(CSet &s) const { return (cmp(s) <= 0) ? 1 : 0; };

   // Functions
   //----------
	// Add a new element to the set.
	inline void add(int bit)
	{
		if (bit > nbits)
			enlarge(bit >> SET_NBIT);
		map[bit >> SET_NBIT] |= (1 << (bit & SET_BMASK));
	};
	void add(CSet &s);
	void add(CSet *s);
//	inline void add(int);       // add member to set
	void remove(int);    // Remove member - clears bit in map
	inline void remove(CSet &s)
	{
		int ii;
		ii = min(size, s.size);
		while (--ii >= 0)
			map[ii] &= ~s.map[ii];
	}
	inline void remove(CSet *s)
	{
		int ii;
		ii = min(size, s->size);
		while (--ii >= 0)
			map[ii] &= ~s->map[ii];
	}
	int resetPtr() {
      int i = MemberPtr;
      MemberPtr = 0;
      return i; };
	int SetPtr(int n) {
      int i = MemberPtr;
      MemberPtr = (unsigned __int16)n;
      return i; };
	  int Member(int n);
	int nextMember();
	int prevMember();
	int lastMember();
	int length() const { return sizeof(int) * size << 3; };
	int NumMember() const;  // Number of 'ON' elements in set
	int print(int (*)(void *,...), void*);
	int sprint(char *, int);
	unsigned hash() const;
	int subset(CSet &) const;
	void truncate();
	void clear();					// Zero all bits
	void fill();					// Set all bits
	void complement();
	int isDisjoint(CSet &s) { return (SetTest(s) == SET_DISJ); };
	int isIntersecting(CSet &s) { return (SetTest(s) == SET_INTER); };
	int isEmpty() { return NumMember() == 0; };
	int isMember(int bit) { return ((bit >= nbits)||bit < 0 ? 0 : (map[bit >> SET_NBIT] & (1 << (bit & SET_BMASK)))) != 0; }; // is n a member of s ?
	int test(int x) { return (isMember(x)) ? !compl : compl; };
	int isSubset(CSet &);
	void insert(int64_t val, int base, int len);
	void extract(int64_t* val, int base, int len);
	bool shr(int amt);
	bool shl(int amt);

//	void Serialize(CArchive& ar);
};
#endif
