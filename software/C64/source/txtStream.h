#pragma once
#include <string.h>
#include <iostream>
#include <fstream>
#include <iomanip>

class txtoStream : public std::ofstream
{
	char buf[4000];
public:
	int level;
public:
	void write(char *buf) {
	   std::ofstream::write(buf, strlen(buf));
       flush(); };
	void printf(char *str) { write(str); };
	void printf(const char *str) { write((char *)str); };
	void printf(char *fmt, char *str);
	void printf(char *fmt, char *str, int n);
	void printf(char *fmt, char *str, char *str2);
	void printf(char *fmt, char *str, char *str2, int n);
	void printf(char *fmt, int n, char *str);
	void printf(char *fmt, int n);
	void printf(char *fmt, int n, int m);
	void printf(char *fmt, __int64 n);
	void putch(char ch) { std::ofstream::write(&ch, 1); };
	void puts(const char *);
};

// Make it easy to disable debugging output
// Mirror the txtoStream class with one that does nothing.

class txtoStreamNull
{
public:
  int level;
  void open(...);
  void close();
  void write(char *) { };
  void printf(...) { };
  void putch(char) { };
  void puts(const char *) {} ;
};

