#include "stdafx.h"
#include <string.h>
#include "txtStream.h"

void txtoStream::printf(char *fmt, char *str)
{
  if (level==0)
    return;
  snprintf(buf, sizeof(buf), fmt, str);
	write(buf);
}

void txtoStream::printf(char *fmt, char *str, int n)
{
  if (level==0)
    return;
 snprintf(buf, sizeof(buf), fmt, str, n);
 write(buf);
}

void txtoStream::printf(char *fmt, char *str, char *str2)
{
  if (level==0)
    return;
 snprintf(buf, sizeof(buf), fmt, str, str2);
 write(buf);
}

void txtoStream::printf(char *fmt, char *str, char *str2, int n)
{
  if (level==0)
    return;
	snprintf(buf, sizeof(buf), fmt, str, str2, n);
	write(buf);
}

void txtoStream::printf(char *fmt, int n)
{
  if (level==0)
    return;
	snprintf(buf, sizeof(buf), fmt, n);
	write(buf);
}

void txtoStream::printf(char *fmt, __int64 n)
{
  if (level==0)
    return;
	snprintf(buf, sizeof(buf), fmt, n);
	write(buf);
}

void txtoStream::printf(char *fmt, int n, int m)
{
  if (level==0)
    return;
	snprintf(buf, sizeof(buf), fmt, n, m);
	write(buf);
}

void txtoStream::printf(char *fmt, int n, char *str)
{
  if (level==0)
    return;
	snprintf(buf, sizeof(buf), fmt, n, str);
	write(buf);
}

void txtoStream::puts(const char *str)
{
  if (level==0)
    return;
  while(*str) {
    putch(*str);
    str++;
  }
}

void txtoStream::writeAsHex(const void *buf, int len)
{
	int n;
	char *cbuf = (char *)buf;

	printf("%04X:", len);
	for (n = 0; n < len; n++) {
		printf("%02X", (int)cbuf[n]);
	}
	printf("\n");
}

void txtiStream::readAsHex(const void *buf, int len)
{
	char cbuf[8];
	char *p;
	int n;
	int val;

	p = (char *)buf;
	read(cbuf, 5);
	for (n = 0; n < len; n++) {
		read(cbuf, 2);
		cbuf[2] = '\0';
		val = strtoul(cbuf, nullptr, 16);
		p[n] = val;
	}
}
