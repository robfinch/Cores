#pragma once
#include <string.h>
#include <iostream>
#include <fstream>
#include <iomanip>

class txtoStream : public std::ofstream
{
	char buf[4000];
public:
	void write(char *buf) { std::ofstream::write(buf, strlen(buf));
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
};

