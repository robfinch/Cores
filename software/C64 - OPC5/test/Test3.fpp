void print(char *ptr)
{
	while(*ptr) {
		outch(*ptr);
		ptr++;
	}
}

void main() {
	print("Hello world\r\n");
}
