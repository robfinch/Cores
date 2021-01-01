
#include <xalloc.h>
#include <signal.h>

_Altab _Aldata;
const char **environ;
_Sigfun *_Sigtable[_NSIG];
int errno;

int sbrk(int amt)
{
	return (0);
}

int wait(int *t)
{
	return (*t);
}

int fork(void)
{
	return (0);
}

int execl(const char *a, const char *b, const char *c)
{
	return (0);
}

void _exit(int)
{

}

int open(const char *path, unsigned int a, unsigned int b)
{
	return (0);
}

int close(int fh)
{
	return (0);
}

int read(int fh, char *buf, int count)
{
	return (0);
}

int write(int fh, const unsigned char *buf, int count)
{
	return (0);
}

long lseek(int fh, long pos, int whence)
{
	return (0);
}

int link(const char *nm, const char *nm2)
{
	return (0);
}

int unlink(const char *name)
{
	return (0);
}

int getpid(void)
{

}

int kill(int pid, int sig)
{
	return (0);
}
