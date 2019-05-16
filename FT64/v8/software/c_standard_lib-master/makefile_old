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
	$(CXX) .\c_standard_lib-master\CTYPE\isalnum.c >ctype.txt
	$(CXX) .\c_standard_lib-master\CTYPE\isalpha.c >>ctype.txt
	$(CXX) .\c_standard_lib-master\CTYPE\iscntrl.c >>ctype.txt
	$(CXX) .\c_standard_lib-master\CTYPE\isdigit.c >>ctype.txt
	$(CXX) .\c_standard_lib-master\CTYPE\isgraph.c >>ctype.txt
	$(CXX) .\c_standard_lib-master\CTYPE\islower.c >>ctype.txt
	$(CXX) .\c_standard_lib-master\CTYPE\isprint.c >>ctype.txt
	$(CXX) .\c_standard_lib-master\CTYPE\ispunct.c >>ctype.txt
	$(CXX) .\c_standard_lib-master\CTYPE\isspace.c >>ctype.txt
	$(CXX) .\c_standard_lib-master\CTYPE\isupper.c >>ctype.txt
	$(CXX) .\c_standard_lib-master\CTYPE\isxdigit.c >>ctype.txt
	$(CXX) .\c_standard_lib-master\CTYPE\tolower.c >>ctype.txt
	$(CXX) .\c_standard_lib-master\CTYPE\toupper.c >>ctype.txt
	$(CXX) .\c_standard_lib-master\CTYPE\xctype.c >>ctype.txt
	$(CXX) .\c_standard_lib-master\CTYPE\xtolower.c >>ctype.txt
	$(CXX) .\c_standard_lib-master\CTYPE\xtoupper.c >>ctype.txt
#
ERRNO:
	$(CXX) .\c_standard_lib-master\errno\errno.c >libc.txt
#
FLOAT:
	$(CXX) .\c_standard_lib-master\float\xfloat.c >libc.txt
#
LOCALE:
	$(CXX) .\c_standard_lib-master\locale\localeco.c >locale.txt
	$(CXX) .\c_standard_lib-master\locale\setlocal.c >>locale.txt
	$(CXX) .\c_standard_lib-master\locale\xdefloc.c >>locale.txt
	$(CXX) .\c_standard_lib-master\locale\xfmtval.c >>locale.txt
	$(CXX) .\c_standard_lib-master\locale\xfreeloc.c >>locale.txt
	$(CXX) .\c_standard_lib-master\locale\xgetloc.c >>locale.txt
	$(CXX) .\c_standard_lib-master\locale\xloctab.c >>locale.txt
	$(CXX) .\c_standard_lib-master\locale\xlocterm.c >>locale.txt
	$(CXX) .\c_standard_lib-master\locale\xmakeloc.c >>locale.txt
	$(CXX) .\c_standard_lib-master\locale\xreadloc.c >>locale.txt
	$(CXX) .\c_standard_lib-master\locale\xsetloc.c >>locale.txt
	$(CXX) .\c_standard_lib-master\locale\xstate.c >>locale.txt
#
MATH:
	$(CXX) .\c_standard_lib-master\math\acos.c >math.txt
	$(CXX) .\c_standard_lib-master\math\asin.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\atan.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\atan2.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\ceil.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\cos.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\cosh.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\exp.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\fabs.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\floor.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\fmod.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\frexp.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\ldexp.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\log.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\log10.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\modf.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\pow.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\sin.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\sinh.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\sqrt.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\tan.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\tanh.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\xasin.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\xatan.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\xdint.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\xdnorm.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\xdscale.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\xdtento.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\xdtest.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\xdunscal.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\xexp.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\xldunsca.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\xlog.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\xpoly.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\xsin.c >>math.txt
	$(CXX) .\c_standard_lib-master\math\xvalues.c >>math.txt
#
SETJMP:
	$(CXX) .\c_standard_lib-master\setjmp\setjmp.c >setjmp.txt
	$(CXX) .\c_standard_lib-master\setjmp\longjmp.c >>setjmp.txt
#
SIGNAL:
	$(CXX) .\c_standard_lib-master\signal\raise.c >signal.txt
	$(CXX) .\c_standard_lib-master\signal\signal.c >>signal.txt
#
STDIO:
	$(CXX) .\c_standard_lib-master\stdio\clearerr.c >stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\fclose.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\feof.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\fflush.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\fgetc.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\fgetpos.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\fgets.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\fopen.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\fprintf.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\fputc.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\fputs.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\fread.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\freopen.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\fscanf.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\fseek.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\fsetpos.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\ftell.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\fwrite.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\getc.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\getchar.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\gets.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\perror.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\printf.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\putc.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\putchar.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\puts.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\rename.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\remove.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\rewind.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\scanf.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\setbuf.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\setvbuf.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\sprintf.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\sscanf.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\tmpfile.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\tmpnam.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\ungetc.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\vfprintf.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\vprintf.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\vsprintf.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\xfgpos.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\xfiles.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\xfopen.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\xfoprep.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\xfrprep.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\xfspos.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\xfwprep.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\xgenld.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\xgetfld.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\xgetfloa.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\xgetint.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\xldtob.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\xlitob.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\xprintf.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\xputfld.c >>stdio.txt
	$(CXX) .\c_standard_lib-master\stdio\xscanf.c >>stdio.txt
#
STDLIB:
	$(CXX) .\c_standard_lib-master\stdlib\abort.c >stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\abs.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\atexit.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\atof.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\atoi.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\atol.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\bsearch.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\calloc.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\div.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\exit.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\free.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\getenv.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\labs.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\ldiv.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\malloc.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\mblen.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\mbstowcs.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\mbtowc.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\qsort.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\rand.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\realloc.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\srand.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\strtod.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\strtol.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\strtoul.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\system.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\wcstombs.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\wctomb.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\xgetmem.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\xmbtowc.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\xstod.c >>stdlib.txt
	$(CXX) .\c_standard_lib-master\stdlib\xstoul.c >>stdlib.txt
#
STRING:
	$(CXX) .\c_standard_lib-master\string\memchr.c >string.txt
	$(CXX) .\c_standard_lib-master\string\memcmp.c >>string.txt
	$(CXX) .\c_standard_lib-master\string\memcpy.c >>string.txt
	$(CXX) .\c_standard_lib-master\string\memmove.c >>string.txt
	$(CXX) .\c_standard_lib-master\string\memset.c >>string.txt
	$(CXX) .\c_standard_lib-master\string\memsetH.c >>string.txt
	$(CXX) .\c_standard_lib-master\string\memsetW.c >>string.txt
	$(CXX) .\c_standard_lib-master\string\strcat.c >>string.txt
	$(CXX) .\c_standard_lib-master\string\strchr.c >>string.txt
	$(CXX) .\c_standard_lib-master\string\strcmp.c >>string.txt
	$(CXX) .\c_standard_lib-master\string\strcoll.c >>string.txt
	$(CXX) .\c_standard_lib-master\string\strcpy.c >>string.txt
	$(CXX) .\c_standard_lib-master\string\strcspn.c >>string.txt
	$(CXX) .\c_standard_lib-master\string\strerror.c >>string.txt
	$(CXX) .\c_standard_lib-master\string\strlen.c >>string.txt
	$(CXX) .\c_standard_lib-master\string\strncat.c >>string.txt
	$(CXX) .\c_standard_lib-master\string\strncpy.c >>string.txt
	$(CXX) .\c_standard_lib-master\string\strpbrk.c >>string.txt
	$(CXX) .\c_standard_lib-master\string\strrchr.c >>string.txt
	$(CXX) .\c_standard_lib-master\string\strspn.c >>string.txt
	$(CXX) .\c_standard_lib-master\string\strstr.c >>string.txt
	$(CXX) .\c_standard_lib-master\string\strtok.c >>string.txt
	$(CXX) .\c_standard_lib-master\string\strxfrm.c >>string.txt
	$(CXX) .\c_standard_lib-master\string\xstrxfrm.c >>string.txt
#
TIME:
	$(CXX) .\c_standard_lib-master\time\asctime.c >time.txt
	$(CXX) .\c_standard_lib-master\time\clock.c >>time.txt
	$(CXX) .\c_standard_lib-master\time\ctime.c >>time.txt
	$(CXX) .\c_standard_lib-master\time\difftime.c >>time.txt
	$(CXX) .\c_standard_lib-master\time\gmtime.c >>time.txt
	$(CXX) .\c_standard_lib-master\time\localtim.c >>time.txt
	$(CXX) .\c_standard_lib-master\time\mktime.c >>time.txt
	$(CXX) .\c_standard_lib-master\time\strftime.c >>time.txt
	$(CXX) .\c_standard_lib-master\time\time.c >>time.txt
	$(CXX) .\c_standard_lib-master\time\xgentime.c >>time.txt
	$(CXX) .\c_standard_lib-master\time\xgetdst.c >>time.txt
	$(CXX) .\c_standard_lib-master\time\xgettime.c >>time.txt
	$(CXX) .\c_standard_lib-master\time\xgetzone.c >>time.txt
	$(CXX) .\c_standard_lib-master\time\xisdst.c >>time.txt
	$(CXX) .\c_standard_lib-master\time\xstrftim.c >>time.txt
	$(CXX) .\c_standard_lib-master\time\xttotm.c >>time.txt
