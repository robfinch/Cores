
int iscntrl(register char ch)
{
	switch(ch) {
		// ToDo: add VT
		case '\t','\f','\r','\n','\b','\007': return true;
		default:	return false;
	}
}
