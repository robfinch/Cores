
int isxdigit(char ch)
{
	if (ch >= 'A' and ch <= 'F') return true;
	if (ch >= 'a' and ch <= 'f') return true;
	if (ch >= '0' and ch <= '9') return true;
	return false;
}

int isdigit(char ch)
{
	if (ch >= '0' and ch <= '9')
		return true;
	return false;
}

int isalpha(char ch)
{
	if (ch >= 'a' and ch <= 'z')
		return true;
	if (ch >= 'A' and ch <= 'Z')
		return true;
	return false;
}

int isalnum(char ch)
{
	if (ch >= '0' and ch <= '9')
		return true;
	if (ch >= 'a' and ch <= 'z')
		return true;
	if (ch >= 'A' and ch <= 'Z')
		return true;
	return false;
}

// ToDo: add vertical tab
int isspace(char ch)
{
	if (ch==' ') return true;
	if (ch=='\t') return true;
	if (ch=='\n') return true;
	if (ch=='\r') return true;
	if (ch=='\f') return true;
	return false;
}

int tolower(char ch)
{
	if (ch >= 'A' and ch <= 'Z')
		ch = ch - 'A' + 'a';
	return ch;
}

int toupper(char ch)
{
	if (ch >= 'a' and ch <= 'a')
		ch = ch - 'a' + 'A';
	return ch;
}

int isupper(char ch)
{
	return ch >= 'A' and ch <= 'Z';
}

int islower(char ch)
{
	return ch >= 'a' and ch <= 'z';
}

int ispunct(char ch)
{
	switch(ch) {
		case '!','"','#','%','&','\'','(',')',';','<','=','>','?',
			'[','\\',']','*','+',',','-','.','/',':','^':
			return true;
		default:	return false;
	}
}

int isgraph(char ch)
{
	return ispunct(ch) || isalnum(ch);
}

int isprint(char ch)
{
	return isgraph(ch) || ch==' ';
}

int iscntrl(char ch)
{
	switch(ch) {
		// ToDo: add VT
		case '\t','\f','\r','\n','\b','\007': return true;
		default:	return false;
	}
}
