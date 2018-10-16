# Makefile for Standard C Library
#
CXX = cc64 -w -S 

ASSERT = .\c_standard_lib-master\ASSERT\xassert.c 
CTYPE =    .\c_standard_lib-master\CTYPE\isalnum.c \
           .\c_standard_lib-master\CTYPE\isalpha.c \
           .\c_standard_lib-master\CTYPE\iscntrl.c \
           .\c_standard_lib-master\CTYPE\isdigit.c \
           .\c_standard_lib-master\CTYPE\isgraph.c \
           .\c_standard_lib-master\CTYPE\islower.c \
           .\c_standard_lib-master\CTYPE\isprint.c \
           .\c_standard_lib-master\CTYPE\ispunct.c \
           .\c_standard_lib-master\CTYPE\isspace.c \
           .\c_standard_lib-master\CTYPE\isupper.c \
           .\c_standard_lib-master\CTYPE\isxdigit.c \
           .\c_standard_lib-master\CTYPE\tolower.c \
           .\c_standard_lib-master\CTYPE\toupper.c \
           .\c_standard_lib-master\CTYPE\xctype.c \
           .\c_standard_lib-master\CTYPE\xtolower.c \
           .\c_standard_lib-master\CTYPE\xtoupper.c

ERRNO =    .\c_standard_lib-master\errno\errno.c

FLOAT =    .\c_standard_lib-master\float\xfloat.c

LOCALE =   .\c_standard_lib-master\locale\localeco.c \
           .\c_standard_lib-master\locale\setlocal.c \
           .\c_standard_lib-master\locale\xdefloc.c \
           .\c_standard_lib-master\locale\xfmtval.c \
           .\c_standard_lib-master\locale\xfreeloc.c \
           .\c_standard_lib-master\locale\xgetloc.c \
           .\c_standard_lib-master\locale\xloctab.c \
           .\c_standard_lib-master\locale\xlocterm.c \
           .\c_standard_lib-master\locale\xmakeloc.c \
           .\c_standard_lib-master\locale\xreadloc.c \
           .\c_standard_lib-master\locale\xsetloc.c \
           .\c_standard_lib-master\locale\xstate.c

MATH =     .\c_standard_lib-master\math\acos.c \
           .\c_standard_lib-master\math\asin.c \
           .\c_standard_lib-master\math\atan.c \
           .\c_standard_lib-master\math\atan2.c \
           .\c_standard_lib-master\math\ceil.c \
           .\c_standard_lib-master\math\cos.c \
           .\c_standard_lib-master\math\cosh.c \
           .\c_standard_lib-master\math\exp.c \
           .\c_standard_lib-master\math\fabs.c \
           .\c_standard_lib-master\math\floor.c \
           .\c_standard_lib-master\math\fmod.c \
           .\c_standard_lib-master\math\frexp.c \
           .\c_standard_lib-master\math\ldexp.c \
           .\c_standard_lib-master\math\log.c \
           .\c_standard_lib-master\math\log10.c \
           .\c_standard_lib-master\math\modf.c \
           .\c_standard_lib-master\math\pow.c \
           .\c_standard_lib-master\math\sin.c \
           .\c_standard_lib-master\math\sinh.c \
           .\c_standard_lib-master\math\sqrt.c \
           .\c_standard_lib-master\math\tan.c \
           .\c_standard_lib-master\math\tanh.c \
           .\c_standard_lib-master\math\xasin.c \
           .\c_standard_lib-master\math\xatan.c \
           .\c_standard_lib-master\math\xdint.c \
           .\c_standard_lib-master\math\xdnorm.c \
           .\c_standard_lib-master\math\xdscale.c \
           .\c_standard_lib-master\math\xdtento.c \
           .\c_standard_lib-master\math\xdtest.c \
           .\c_standard_lib-master\math\xdunscal.c \
           .\c_standard_lib-master\math\xexp.c \
           .\c_standard_lib-master\math\xldunsca.c \
           .\c_standard_lib-master\math\xlog.c \
           .\c_standard_lib-master\math\xpoly.c \
           .\c_standard_lib-master\math\xsin.c \
           .\c_standard_lib-master\math\xvalues.c

SETJMP =   .\c_standard_lib-master\setjmp\setjmp.c \
           .\c_standard_lib-master\setjmp\longjmp.c

SIGNAL =   .\c_standard_lib-master\signal\raise.c \
           .\c_standard_lib-master\signal\signal.c
           
STDIO =    .\c_standard_lib-master\stdio\clearerr.c \
           .\c_standard_lib-master\stdio\fclose.c \
           .\c_standard_lib-master\stdio\feof.c \
           .\c_standard_lib-master\stdio\fflush.c \
           .\c_standard_lib-master\stdio\fgetc.c \
           .\c_standard_lib-master\stdio\fgetpos.c \
           .\c_standard_lib-master\stdio\fgets.c \
           .\c_standard_lib-master\stdio\fopen.c \
           .\c_standard_lib-master\stdio\fprintf.c \
           .\c_standard_lib-master\stdio\fputc.c \
           .\c_standard_lib-master\stdio\fputs.c \
           .\c_standard_lib-master\stdio\fread.c \
           .\c_standard_lib-master\stdio\freopen.c \
           .\c_standard_lib-master\stdio\fscanf.c \
           .\c_standard_lib-master\stdio\fseek.c \
           .\c_standard_lib-master\stdio\fsetpos.c \
           .\c_standard_lib-master\stdio\ftell.c \
           .\c_standard_lib-master\stdio\fwrite.c \
           .\c_standard_lib-master\stdio\getc.c \
           .\c_standard_lib-master\stdio\getchar.c \
           .\c_standard_lib-master\stdio\gets.c \
           .\c_standard_lib-master\stdio\perror.c \
           .\c_standard_lib-master\stdio\printf.c \
           .\c_standard_lib-master\stdio\putc.c \
           .\c_standard_lib-master\stdio\putchar.c \
           .\c_standard_lib-master\stdio\puts.c \
           .\c_standard_lib-master\stdio\rename.c \
           .\c_standard_lib-master\stdio\remove.c \
           .\c_standard_lib-master\stdio\rewind.c \
           .\c_standard_lib-master\stdio\scanf.c \
           .\c_standard_lib-master\stdio\setbuf.c \
           .\c_standard_lib-master\stdio\setvbuf.c \
           .\c_standard_lib-master\stdio\sprintf.c \
           .\c_standard_lib-master\stdio\sscanf.c \
           .\c_standard_lib-master\stdio\tmpfile.c \
           .\c_standard_lib-master\stdio\tmpnam.c \
           .\c_standard_lib-master\stdio\ungetc.c \
           .\c_standard_lib-master\stdio\vfprintf.c \
           .\c_standard_lib-master\stdio\vprintf.c \
           .\c_standard_lib-master\stdio\vsprintf.c \
           .\c_standard_lib-master\stdio\xfgpos.c \
           .\c_standard_lib-master\stdio\xfiles.c \
           .\c_standard_lib-master\stdio\xfopen.c \
           .\c_standard_lib-master\stdio\xfoprep.c \
           .\c_standard_lib-master\stdio\xfrprep.c \
           .\c_standard_lib-master\stdio\xfspos.c \
           .\c_standard_lib-master\stdio\xfwprep.c \
           .\c_standard_lib-master\stdio\xgenld.c \
           .\c_standard_lib-master\stdio\xgetfld.c \
           .\c_standard_lib-master\stdio\xgetfloa.c \
           .\c_standard_lib-master\stdio\xgetint.c \
           .\c_standard_lib-master\stdio\xldtob.c \
           .\c_standard_lib-master\stdio\xlitob.c \
           .\c_standard_lib-master\stdio\xprintf.c \
           .\c_standard_lib-master\stdio\xputfld.c \
           .\c_standard_lib-master\stdio\xscanf.c

ASSERT:
	$(CXX) .\c_standard_lib-master\ASSERT\xassert.c >libc.txt
#
CTYPE:
	$(CXX) .\c_standard_lib-master\CTYPE\isalnum.c >libc.txt
	$(CXX) .\c_standard_lib-master\CTYPE\isalpha.c >>libc.txt
	$(CXX) .\c_standard_lib-master\CTYPE\iscntrl.c >>libc.txt
	$(CXX) .\c_standard_lib-master\CTYPE\isdigit.c >>libc.txt
	$(CXX) .\c_standard_lib-master\CTYPE\isgraph.c >>libc.txt
	$(CXX) .\c_standard_lib-master\CTYPE\islower.c >>libc.txt
	$(CXX) .\c_standard_lib-master\CTYPE\isprint.c >>libc.txt
	$(CXX) .\c_standard_lib-master\CTYPE\ispunct.c >>libc.txt
	$(CXX) .\c_standard_lib-master\CTYPE\isspace.c >>libc.txt
	$(CXX) .\c_standard_lib-master\CTYPE\isupper.c >>libc.txt
	$(CXX) .\c_standard_lib-master\CTYPE\isxdigit.c >>libc.txt
	$(CXX) .\c_standard_lib-master\CTYPE\tolower.c >>libc.txt
	$(CXX) .\c_standard_lib-master\CTYPE\toupper.c >>libc.txt
	$(CXX) .\c_standard_lib-master\CTYPE\xctype.c >>libc.txt
	$(CXX) .\c_standard_lib-master\CTYPE\xtolower.c >>libc.txt
	$(CXX) .\c_standard_lib-master\CTYPE\xtoupper.c >>libc.txt
#
ERRNO:
	$(CXX) .\c_standard_lib-master\errno\errno.c >libc.txt
#
FLOAT:
	$(CXX) .\c_standard_lib-master\float\xfloat.c >libc.txt
#
LOCALE:
	$(CXX) .\c_standard_lib-master\locale\localeco.c >libc.txt
	$(CXX) .\c_standard_lib-master\locale\setlocal.c >>libc.txt
	$(CXX) .\c_standard_lib-master\locale\xdefloc.c >>libc.txt
	$(CXX) .\c_standard_lib-master\locale\xfmtval.c >>libc.txt
	$(CXX) .\c_standard_lib-master\locale\xfreeloc.c >>libc.txt
	$(CXX) .\c_standard_lib-master\locale\xgetloc.c >>libc.txt
	$(CXX) .\c_standard_lib-master\locale\xloctab.c >>libc.txt
	$(CXX) .\c_standard_lib-master\locale\xlocterm.c >>libc.txt
	$(CXX) .\c_standard_lib-master\locale\xmakeloc.c >>libc.txt
	$(CXX) .\c_standard_lib-master\locale\xreadloc.c >>libc.txt
	$(CXX) .\c_standard_lib-master\locale\xsetloc.c >>libc.txt
	$(CXX) .\c_standard_lib-master\locale\xstate.c >>libc.txt
#
MATH:
	$(CXX) .\c_standard_lib-master\math\acos.c >libc.txt
	$(CXX) .\c_standard_lib-master\math\asin.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\atan.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\atan2.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\ceil.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\cos.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\cosh.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\exp.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\fabs.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\floor.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\fmod.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\frexp.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\ldexp.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\log.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\log10.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\modf.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\pow.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\sin.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\sinh.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\sqrt.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\tan.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\tanh.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\xasin.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\xatan.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\xdint.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\xdnorm.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\xdscale.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\xdtento.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\xdtest.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\xdunscal.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\xexp.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\xldunsca.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\xlog.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\xpoly.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\xsin.c >>libc.txt
	$(CXX) .\c_standard_lib-master\math\xvalues.c >>libc.txt
#
SETJMP:
	$(CXX) .\c_standard_lib-master\setjmp\setjmp.c >libc.txt
	$(CXX) .\c_standard_lib-master\setjmp\longjmp.c >>libc.txt
#
SIGNAL:
	$(CXX) .\c_standard_lib-master\signal\raise.c >libc.txt
	$(CXX) .\c_standard_lib-master\signal\signal.c >>libc.txt
#
STDIO:
	$(CXX) .\c_standard_lib-master\stdio\clearerr.c >libc.txt
	$(CXX) .\c_standard_lib-master\stdio\fclose.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\feof.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\fflush.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\fgetc.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\fgetpos.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\fgets.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\fopen.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\fprintf.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\fputc.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\fputs.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\fread.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\freopen.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\fscanf.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\fseek.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\fsetpos.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\ftell.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\fwrite.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\getc.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\getchar.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\gets.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\perror.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\printf.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\putc.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\putchar.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\puts.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\rename.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\remove.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\rewind.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\scanf.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\setbuf.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\setvbuf.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\sprintf.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\sscanf.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\tmpfile.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\tmpnam.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\ungetc.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\vfprintf.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\vprintf.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\vsprintf.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\xfgpos.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\xfiles.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\xfopen.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\xfoprep.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\xfrprep.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\xfspos.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\xfwprep.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\xgenld.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\xgetfld.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\xgetfloa.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\xgetint.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\xldtob.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\xlitob.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\xprintf.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\xputfld.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdio\xscanf.c >>libc.txt
#
STDLIB:
	$(CXX) .\c_standard_lib-master\stdlib\abort.c >libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\abs.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\atexit.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\atof.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\atoi.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\atol.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\bsearch.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\calloc.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\div.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\exit.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\free.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\getenv.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\labs.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\ldiv.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\malloc.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\mblen.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\mbstowcs.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\mbtowc.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\qsort.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\rand.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\realloc.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\srand.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\strtod.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\strtol.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\strtoul.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\system.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\wcstombs.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\wctomb.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\xgetmem.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\xmbtowc.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\xstod.c >>libc.txt
	$(CXX) .\c_standard_lib-master\stdlib\xstoul.c >>libc.txt
#
STRING:
	$(CXX) .\c_standard_lib-master\string\memchr.c >libc.txt
	$(CXX) .\c_standard_lib-master\string\memcmp.c >>libc.txt
	$(CXX) .\c_standard_lib-master\string\memcpy.c >>libc.txt
	$(CXX) .\c_standard_lib-master\string\memmove.c >>libc.txt
	$(CXX) .\c_standard_lib-master\string\memset.c >>libc.txt
	$(CXX) .\c_standard_lib-master\string\strcat.c >>libc.txt
	$(CXX) .\c_standard_lib-master\string\strchr.c >>libc.txt
	$(CXX) .\c_standard_lib-master\string\strcmp.c >>libc.txt
	$(CXX) .\c_standard_lib-master\string\strcoll.c >>libc.txt
	$(CXX) .\c_standard_lib-master\string\strcpy.c >>libc.txt
	$(CXX) .\c_standard_lib-master\string\strcspn.c >>libc.txt
	$(CXX) .\c_standard_lib-master\string\strerror.c >>libc.txt
	$(CXX) .\c_standard_lib-master\string\strlen.c >>libc.txt
	$(CXX) .\c_standard_lib-master\string\strncat.c >>libc.txt
	$(CXX) .\c_standard_lib-master\string\strncpy.c >>libc.txt
	$(CXX) .\c_standard_lib-master\string\strpbrk.c >>libc.txt
	$(CXX) .\c_standard_lib-master\string\strrchr.c >>libc.txt
	$(CXX) .\c_standard_lib-master\string\strspn.c >>libc.txt
	$(CXX) .\c_standard_lib-master\string\strstr.c >>libc.txt
	$(CXX) .\c_standard_lib-master\string\strtok.c >>libc.txt
	$(CXX) .\c_standard_lib-master\string\strxfrm.c >>libc.txt
	$(CXX) .\c_standard_lib-master\string\xstrxfrm.c >>libc.txt
