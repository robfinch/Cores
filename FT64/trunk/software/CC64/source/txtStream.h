#pragma once
#include <string.h>
#include <iostream>
#include <fstream>
#include <iomanip>

class txtoStream : public std::ofstream
{
	char buf[500];
public:
	int level;
public:
  txtoStream() : std::ofstream() {};
	void write(char *buf) { if (level) {
	   std::ofstream::write(buf, strlen(buf));
       flush(); }};
	void printf(char *str) { if (level) write(str); };
	void printf(const char *str) { if (level) write((char *)str); };
	void printf(char *fmt, char *str);
	void printf(char *fmt, char *str, int n);
	void printf(char *fmt, char *str, char *str2);
	void printf(char *fmt, char *str, char *str2, int n);
	void printf(char *fmt, int n, char *str);
	void printf(char *fmt, int n);
	void printf(char *fmt, int n, int m);
	void printf(char *fmt, __int64 n);
	void putch(char ch) { 
	    if (level) {
	     buf[0] = ch;
	     buf[1] = '\0';
	     buf[2] = '\0';
	     buf[3] = '\0';
       std::ofstream::write(buf, 1);
       }};
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

