extern int (*ExecAddress)();
typedef struct _tag
{
	int var;
	int (*fptr)(int);
} Tag;

void TestFuncptr()
{
	Tag *ag;

	(*ExecAddress)();
	(*(ag->fptr))(21);
}
