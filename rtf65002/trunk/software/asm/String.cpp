#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include "HashVal.h"
#include "MyString.h"

/*
inline static int strlen(char *str)
{
	int i;

	for (i = 0; str[i]; i++);
	return i;
}
*/

namespace RTFClasses
{

	StrDesc *StrDesc::first = NULL;

	inline void String::copy(char *a, char *b, int n) const
	{
		for (int i = 0; i < n; i++)
			a[i] = b[i];
	}


	// Construct descriptor object
	// Default buffer size
	StrDesc::StrDesc(String *str)
	{
		m_str = str;
		m_buf = new char[32];
		if (m_buf==NULL)
			throw "Out of string descriptor space.";
		m_buf[0] = '\0';
		m_bufsz = 32;
		m_len = 0;
		insertBefore(first);
		first = this;
	};


	// Construct descriptor object
	StrDesc::StrDesc(String *str, int n)
	{
		n = ((n+32)&~31);
		m_str = str;
		m_buf = new char[n];
		if (m_buf==NULL)
			throw "Out of string descriptor space.";
		m_buf[0] = '\0';
		m_bufsz = n;
		m_len = 0;
		insertBefore(first);
		first = this;
	};


	// Delete descriptor
	StrDesc::~StrDesc()
	{
		if (m_buf) {
			memset(m_buf, '\0', m_bufsz);
			delete[] m_buf;
			m_buf = NULL;
		}
		if (!prev)
			first = (StrDesc *)next;
		removeFromList();
	}

	void StrDesc::destroyAll()
	{
		StrDesc *p, *q;
		String *s;
		while (p=(StrDesc *)first) {
			s = ((StrDesc *)p)->m_str;
			delete p;		// deleting p will reset first
			s->desc = NULL;
		}
	}


	void String::round_bufsz(int n) {
		desc->m_bufsz = ((n+32)&~31);
	};

	void String::realloc(int n, bool preserve) {
		if (!preserve) {
			delete desc;
			desc = new StrDesc(this,n+1);
		}
		else {
			int len = n < desc->m_len ? n : desc->m_len;
			StrDesc *newbuf;
			newbuf = new StrDesc(this,n+1);
			if (newbuf==NULL)
				throw "Out of string descriptor space.";
			copy(newbuf->m_buf, desc->m_buf, len+1);
			newbuf->m_len = len;
			delete desc;
			desc = newbuf;
		}
	};

	String::String() {
		desc = new StrDesc(this,32);
	};

	String::String(int n) {
		desc = new StrDesc(this,n);
	}


	String::String(char *s)
	{
		int n = strlen(s);
		desc = new StrDesc(this,n+1);
		copy(desc->m_buf, s, n+1);
		desc->m_len = n;
	};

	String::String(char *s, int n)
	{
		int nn = strlen(s);
		desc = new StrDesc(this,(n < nn ? nn : n)+1);
		copy(desc->m_buf, s, nn+1);
		desc->m_len = nn;
	};

	String::String(String &a)
	{
		int n = a.len();
		desc = new StrDesc(this,n+1);
		copy(desc->m_buf, a.buf(), n);
		desc->m_len = n;
		desc->m_buf[n] = '\0';
	};


	String::~String() {
		if (desc)
			delete desc;
		desc = NULL;
	};

	void String::destroyAllDesc() {
		StrDesc::destroyAll();
	}

	void String::copy(char *str, int n)
	{
		if (desc->m_bufsz < n+1)
			realloc(n+1, false);
		copy(desc->m_buf, str, n+1);
		desc->m_len = n;
		desc->m_buf[n] = '\0';
	};

	void String::copy(String str)
	{
		int n = str.len();
		if (desc->m_bufsz < n+1)
			realloc(n+1, false);
		copy(desc->m_buf, str.buf(), n);
		desc->m_buf[n] = '\0';
		desc->m_len = n;
	};

	void String::copy(String str, int n)
	{
		n = n < str.len() ? n : str.len();
		if (desc->m_bufsz < n+1)
			realloc(n+1, false);
		copy(desc->m_buf, str.buf(), n);
		desc->m_buf[n] = '\0';
		desc->m_len = n;
	};

	// look forwards through String for character
	int String::find(int start, char ch)
	{
		int i;
		
		for (i = start; desc->m_buf[i]!=ch && i < desc->m_len; i++);
		return i < desc->m_len ? i : -1;
	};

	// look forwards through String for character
	int String::find(char ch)
	{
		int i;
		
		for (i = 0; desc->m_buf[i]!=ch && i < desc->m_len; i++);
		return i < desc->m_len ? i : -1;
	};

	// look backwards through String for character
	int String::findrev(char ch) const
	{
		int i;

		for (i = desc->m_len-1; desc->m_buf[i]!=ch && i>=0; --i);
		return i;
	};

	// find filename extension '.'
	int String::findext() const {
		int n = len();
		for (; n > 0; n--) {
			if (desc->m_buf[n]=='.')
				return n;
			if (desc->m_buf[n] == '\\' || desc->m_buf[n]=='/')
				return n+1;
		}
		return n;
	};

	int String::find(String str, int st)
	{
		int ii, jj;

		while ((jj = find(st, str.buf(0))) != -1) {	// Find the first character
			st = jj + 1;
			for (ii = 0; ii < str.len(); ii++, jj++) {
				if (jj >= len())
					return -1;
				if (buf(jj) != str.buf(ii))
					goto j1;
			}
			return st-1;
j1:;
		}
		return -1;
	}

	int String::find(char *str, int st)
	{
		int ii, jj;

		while ((jj = find(st, str[0])) != -1) {	// Find the first character
			st = jj + 1;
			for (ii = 0; str[ii]; ii++, jj++) {
				if (jj >= len())
					return -1;
				if (buf(jj) != str[ii])
					goto j1;
			}
			return st-1;
j1:;
		}
		return -1;
	}

	void String::add(String s)
	{
		int n = s.len();
		int newlen = desc->m_len + n;
		int oldlen = desc->m_len;
		if (desc->m_bufsz < newlen+1) {
			realloc(newlen+1, true);
		}
		copy(&desc->m_buf[oldlen],s.buf(),n+1);
		desc->m_len = newlen;
		desc->m_buf[desc->m_len] = '\0';
	};

	void String::add(char *str)
	{
		int n = strlen(str);
		int newlen = desc->m_len + n;
		int oldlen = desc->m_len;
		if (desc->m_bufsz < newlen+1) {
			realloc(newlen+1, true);
		}
		copy(&desc->m_buf[oldlen],str,n+1);
		desc->m_len = newlen;
		desc->m_buf[desc->m_len] = '\0';
	};

	void String::add(char ch)
	{
		if (desc->m_bufsz < desc->m_len + 2) {
			realloc(desc->m_len + 2, true);
		}
		desc->m_buf[desc->m_len++] = ch;
		desc->m_buf[desc->m_len] = 0;
	};

	void String::rtrim()
	{
		for (; desc->m_len > 0; --(desc->m_len))
		{
			if (desc->m_buf[desc->m_len-1] > 0x20)
				break;
		}
		desc->m_buf[desc->m_len] = 0;
	};

	void String::ltrim()
	{
		int n;
		for (n = 0; n < desc->m_len; n++) {
			if (desc->m_buf[n] > 0x20)
				break;
		}
		desc->m_len -= n;
		copy(desc->m_buf, &desc->m_buf[n], desc->m_len);
		desc->m_buf[desc->m_len] = 0;
	};

	void String::trim()
	{
		rtrim();
		ltrim();
	};

	void String::rtrim(char ch)
	{
		for (; desc->m_len > 0; --(desc->m_len))
		{
			if (desc->m_buf[desc->m_len-1]!=ch)
				break;
		}
		desc->m_buf[desc->m_len] = 0;
	};

	void String::ltrim(char ch)
	{
		int n;
		for (n = 0; n < len(); n++) {
			if (desc->m_buf[n]!=ch)
				break;
		}
		desc->m_len -= n;
		copy(desc->m_buf, &desc->m_buf[n], len());
		desc->m_buf[len()] = 0;
	};

	void String::trim(char ch)
	{
		rtrim(ch);
		ltrim(ch);
	};

	void String::mid(int start, int n)
	{
		if (start <= len() && start + n <= len() && start >= 0 && n >= 0) {
    		copy(desc->m_buf, &desc->m_buf[start], n+1);
			desc->m_buf[n] = '\0';
			desc->m_len = n;
		}
	}

	void String::fill(char ch, int n)
	{
		if (len() < n + 1)
			realloc(n + 1, false);
		for (int i = 0; i < n; i++)
    		desc->m_buf[i]=ch;
		desc->m_buf[n] = 0;
		desc->m_len = n;
	}


	// reverse the order of characters in a string
	void String::rev() {
		int i, j;
		char ch;

		for (i = 0, j = desc->m_len-1; i < j; i++, j--)
			ch = desc->m_buf[i];
			desc->m_buf[i] = desc->m_buf[j];
			desc->m_buf[j] = ch;
	}

	void String::left(int n)
	{
		if (n < len() && n >= 0) {
			desc->m_len = n;
			desc->m_buf[n] = 0;
		}
	}

	void String::right(int n)
	{
		if (n < len() && n >= 0) {
    		desc->m_len = n;
    		copy(desc->m_buf, &desc->m_buf[len()-n], n+1);
			desc->m_buf[desc->m_len] = '\0';
		}
	}

	// count all occurrences of a character
	int String::count(char ch)
	{
		int i,j;
		
		for (i = j = 0; i < len(); i++)
			if (desc->m_buf[i]==ch)
				j++;
		return j;
	}

	// replace one character with another
	void String::replace(char a, char b)
	{
		int i;
		
		for (i = 0; i < len(); i++)
			if (desc->m_buf[i]==a)
				desc->m_buf[i]= b;
	}

	// remove all occurrances of a character
	void String::removeAll(char ch)
	{
		int i,j;

		for (i = j = 0; i < len(); i++)
			if (desc->m_buf[i]!=ch) {
				desc->m_buf[j]=desc->m_buf[i];
				j++;
			}
		desc->m_buf[j] = 0;
		desc->m_len = j;
	}


	// Split a string into an array of strings
	String *String::split(char ch, int *nele)
	{
		int i,n,j,pi;
		String *strs;

		n = count(ch);
		if (nele)
			*nele = n;
		strs = new String[n+1];
		for (i = j = pi = 0; i < len(); i++)
			if (desc->m_buf[i]==ch) {
				desc->m_buf[i]=0;
				if (j < n) {
					strs[j].copy(&desc->m_buf[pi]);
					j++;
				}
				desc->m_buf[i]=ch;
				pi = i+1;
			}
		// copy the last string
		strs[j].copy(&desc->m_buf[pi]);

		return strs;
	}

	// return character at specified buffer position
	char String::buf(int n) const
	{
		if (n < desc->m_len && n >= 0)
			return desc->m_buf[n];
		else
			return 0;
	}


	void String::toUpper()
	{
		for (int i = 0; i < len(); i++)
			desc->m_buf[i] = toupper(desc->m_buf[i]);
	}

	void String::toLower()
	{
		for (int i = 0; i < len(); i++)
			desc->m_buf[i] = tolower(desc->m_buf[i]);
	}

	bool String::equalsNoCase(String b) const
	{
		if (len() != b.len())
			return false;
		else {
    		int i;

    		for (i = 0; i < len() && toupper(desc->m_buf[i])==toupper(b.desc->m_buf[i]); i++);
    		return i==len();
		}
	}


	bool String::equalsNoCase(char *b) const
	{
   		int i;

   		for (i = 0; i < len() && toupper(desc->m_buf[i])==toupper(b[i]); i++);
   		return i==len();
	}


	bool String::equals(char *b, int n) const
	{
   		int i;

		if (len() != n)
			return false;
   		for (i = 0; i < len() && i < n && toupper(desc->m_buf[i])==toupper(b[i]); i++);
   		return i==len();
	}


	String &String::operator=(char *s)
	{
		this->copy(s, strlen(s));
		return *this;
	};

	String &String::operator=(String s)
	{
		this->copy(s);
		return *this;
	};


	bool String::operator==(int n) const
	{
		if (n==0)
			return len()==0;
		return false;
	};

	bool String::operator==(void *v) const
	{
		if (v==0)
			return len()==0;
		return false;
	};

	bool String::operator==(String b) const
	{
		if (len() != b.len())
			return false;
		else {
    		int i;

    		for (i = 0; i < len() && desc->m_buf[i]==b.desc->m_buf[i]; i++);
    		return i==len();
		}
	}


	bool String::operator==(char *s) const
	{
    	int i;

    	for (i = 0; i < len() && s[i] && desc->m_buf[i]==s[i]; i++);
    	return i==len() && s[i]=='\0';
	}


	bool String::operator!=(String b) const
	{
		if (len() != b.len())
			return true;
		else {
    		int i;

    		for (i = 0; i < len() && desc->m_buf[i]==b.desc->m_buf[i]; i++);
    		return i!=len();
		}
	}


	String String::operator+(String b)
	{
		String ns(*this);
		ns.add(b.buf());
		return ns;
	};

	String String::operator+(char *str)
	{
		String ns(*this);
		ns.add(str);
		return ns;
	};

	String String::operator+(char ch)
	{
		String ns(*this);
		ns.add(ch);
		return ns;
	};

	String String::operator+(int n)
	{
		char buf[50];

		String ns(*this);
		_itoa(n,buf,10);
		ns.add(buf);
		return ns;
	};

	String String::operator+=(char *str)
	{
		this->add(str);
		return *this;
	};

	String String::operator+=(int n)
	{
		char buf[50];

		_itoa(n,buf,10);
		this->add(buf);
		return *this;
	};

	HashVal String::hashAdd()
	{
		HashVal h;
		int i;

		h.delta = 1;
		for (i = h.hash = 0; desc->m_buf[i]; i++)
			h.hash += desc->m_buf[i];
		return (h);
	}


	/*		Hash function for symbols/identifier strings. Computes a hash delta for
		use with delta hash class.
	Strings contain characters
			_abcdefghijklmnopqrtsuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789
	*/

	HashVal String::hashSym()
	{
		HashVal tmp;
		char *key = desc->m_buf;

		tmp.hash = len();
		for (; *key; key++)
		{
			tmp.hash = _rotl(tmp.hash, 2) ^ *key;
			tmp.delta = _rotr(tmp.delta, 2) ^ *key;
		}
//		if (!(tmp.delta %= size))
//			tmp.delta = 1;
		return tmp;
	}


	/* HashPJW Aho's - version
	*/
	HashVal String::hashPJW() const
	{
		static HashVal h;
		unsigned g;
		char *name = desc->m_buf;

		h.delta = 1;
		h.hash = 0;
		for (; *name; ++name)
		{
			h.hash = (h.hash << 4) + *name;
			if (g = h.hash & 0xf0000000)
				h.hash = (h.hash^(g>>24)) & 0x0fffffff;
		}
		return (h);
	}
}
