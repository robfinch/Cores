extern void rtrim(char *);
extern void ltrim(char *);

char *trim(char *str)
{
	rtrim(str);
	ltrim(str);
	return (str);
}

