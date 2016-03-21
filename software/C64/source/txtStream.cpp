#include "stdafx.h"
#include <string.h>
#include "txtStream.h"

void txtoStream::printf(char *fmt, char *str)
{
	sprintf(buf, fmt, str);
	write(buf);
}

void txtoStream::printf(char *fmt, char *str, int n)
{
	sprintf(buf, fmt, str, n);
	write(buf);
}

void txtoStream::printf(char *fmt, char *str, char *str2)
{
	sprintf(buf, fmt, str, str2);
	write(buf);
}

void txtoStream::printf(char *fmt, char *str, char *str2, int n)
{
	sprintf(buf, fmt, str, str2, n);
	write(buf);
}

void txtoStream::printf(char *fmt, int n)
{
	sprintf(buf, fmt, n);
	write(buf);
}

void txtoStream::printf(char *fmt, __int64 n)
{
	sprintf(buf, fmt, n);
	write(buf);
}

void txtoStream::printf(char *fmt, int n, int m)
{
	sprintf(buf, fmt, n, m);
	write(buf);
}

void txtoStream::printf(char *fmt, int n, char *str)
{
	sprintf(buf, fmt, n, str);
	write(buf);
}

