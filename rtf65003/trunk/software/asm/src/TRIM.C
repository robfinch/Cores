extern rtrim(char *);
extern ltrim(char *);

char *trim(char *str)
{
	rtrim(str);
	ltrim(str);
	return (str);
}

