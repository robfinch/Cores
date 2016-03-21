#include "stdafx.h"
extern char *rtrim(char *);
extern char *ltrim(char *);

char *trim(char *str)
{
	rtrim(str);
	ltrim(str);
	return (str);
}

