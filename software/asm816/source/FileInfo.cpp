#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <io.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "err.h"
#include "buf.h"
#include "asmbuf.h"
#include "MyString.h"
#include "fileinfo.h"

namespace RTFClasses
{
	FileInfo::FileInfo(void)
	{
		buf = NULL;
	}

	FileInfo::~FileInfo(void)
	{
		if (lst)
			delete lst;
		lst = NULL;
		if (buf)
			delete buf;
		buf = NULL;
	}

	int FileInfo::load(char *fname)
	{
		int fh;
		int n;
		int ret = 1;
	extern char ForceErr;

		name.copy(fname);
		fh = open(fname, _O_RDONLY);

		if (fh == -1) {
			return 0;
		}

		length = _filelength(fh);
		if (buf)
			delete buf;
		buf = new AsmBuf(length + 20000);
		if (!buf)
			return 0;
		if ((n = read(fh, buf->buf(), length)) <= 0) {
			Err(E_OPEN, fname); // Unable to open file.
			length = 0;
			ret = 0;
		}
		// null terminate buffer
		// character translation from opening the file in text mode
		// can cause the file to contain extraneous data.
		memset(&buf->buf()[n], 0, length-n);
		buf->setlen(strlen(buf->buf()));
		close(fh);
		return ret;
	}
}

