#pragma once

#include <string.h>
#include "HashVal.h"

namespace RTFClasses
{
	// String descriptor class.
	// Contains all the attributes and information needed to manage the string.

	class StrDesc
	{
		int m_bufsz;	// size of the buffer used to store the string
		int m_len;		// the length of the string
		char *m_buf;	// pointer to storgage buffer

		StrDesc();
		StrDesc(int);
		~StrDesc();
		friend class String;
	};


	// This class is designed to have a single data member which is a
	// pointer to a string descriptor support class that contains the
	// actual data needed for manipulating strings.

	class String
	{
		StrDesc *desc;
		void round_bufsz(int n);
	protected:
		void realloc(int n, bool preserve);
	public:

		String();
		String(int);
		String(char *);
		String(char *, int);
		String(String &);
		~String();
		char *buf() { return desc->m_buf; };
		char buf(int) const;             // return character at buffer position
		int bufsz() const { return desc->m_bufsz; };
		int len() const { return desc->m_len; };
		void setlen(int n) { desc->m_len = n; };
		void copy(char *str) { copy(str, strlen(str)); };
		void copy(String str);
		void copy(String str, int n);
		void copy(char *str, int n);
		inline void copy(char *, char *, int) const;
		void format(int n);
		int find(char ch);			// look for first occurance of character in string
		int find(int start, char ch);
		int findrev(char ch) const; // look backwards through string for last occurance of character
		int findext() const;    // find filename extension '.'
		int find(String str, int start=0);
		int find(char *, int start=0);
		void add(char *str);            // add onto string
		void add(char ch);              // add character onto string
		void add(String str);
		void rtrim();                   // trim spaces from right
		void ltrim();                   // trim spaces from left
		void trim();                    // trim spaces from both sides
		void rtrim(char ch);            // trim character from right
		void ltrim(char ch);            // trim character from left
		void trim(char ch);             // trim character
		void mid(int start, int n);     // convert to substring
		void left(int n);               // truncate after n leftmost characters
		void right(int n);              // truncate befor n rightmost characters
		void replace(char a, char b);	// replace one character with another
		void removeAll(char ch);		// remove all occurences of a character
		void toLower();
		void toUpper();
		int count(char ch);				// count all occurrences of a character
		String *split(char ch, int *nele=NULL);			// split string into array of strings
		void fill(char ch, int n);   // fill string with char
		void rev(); // reverse order of characters
		HashVal hashAdd();			// hash by summing characters
		HashVal hashSym();		
		HashVal hashPJW() const;	

		bool equalsNoCase(String) const;
		bool equalsNoCase(char *) const;
		bool equals(char *, int) const;
		String &operator=(char*);
		String &operator=(String);
		bool operator==(String) const;
		bool operator!=(String) const;
		bool operator==(char *) const;
		bool operator==(int) const;
		bool operator==(void *) const;
		String operator+(String);
		String operator+(char);
		String operator+(char *);
		String operator+=(char c) { this->add(c); return *this; };
		String operator+=(String s) { this->add(s); return *this; };
		String operator+=(char *s);
		String operator+=(int);
		String operator+(int);
		char operator[](int n) { if (n >= len()) throw 1; return buf()[n]; };
	};

	String &str(int n, char *fmt);
}

