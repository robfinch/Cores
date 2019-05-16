# Makefile for STDIO
#
PATH = $PATH;D:\Cores5\FT64\v7\software\C64\C64\debug\;D:\Cores5\FT64\v7\software\A64\A64\debug\;D:\Cores5\FT64\v7\software\FPP\FPP\debug\;D:\Cores5\FT64\v7\software\APP\debug\;"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.15.26726\bin\Hostx64\x64"
FPPINC = d:\Cores5\FT64\v7\software\source\;d:\Cores5\FT64\v7\software\FMTK\source\kernel\;d:\Cores5\FT64\v7\software\inc
APPINC = d:\Cores5\FT64\v7\software\source\;d:\Cores5\FT64\v7\software\FMTK\source\kernel\;d:\Cores5\FT64\v7\software\inc
INC = d:\Cores5\FT64\v7\software\source\;d:\Cores5\FT64\v7\software\FMTK\source\kernel\;d:\Cores5\FT64\v7\software\inc
INCLUDE = d:\Cores5\FT64\v7\software\source\;d:\Cores5\FT64\v7\software\FMTK\source\kernel\;d:\Cores5\FT64\v7\software\inc
#CCX = cc64
CFLAGS = -w -S
#CXX = cc64 -w -S 
ASMS =     clearerr.s \
           fclose.s \
           feof.s \
           fflush.s \
           fgetc.s \
           fgetpos.s \
           fgets.s \
           fopen.s \
           fprintf.s \
           fputc.s \
           fputs.s \
           fread.s \
           freopen.s \
           fscanf.s \
           fseek.s \
           fsetpos.s \
           ftell.s \
           fwrite.s \
           getc.s \
           getchar.s \
           gets.s \
           perror.s \
           printf.s \
           putc.s \
           putchar.s \
           puts.s \
           rename.s \
           remove.s \
           rewind.s \
           scanf.s \
           setbuf.s \
           setvbuf.s \
           sprintf.s \
           sscanf.s \
           tmpfile.s \
           tmpnam.s \
           ungetc.s \
           vfprintf.s \
           vprintf.s \
           vsprintf.s \
           xfgpos.s \
           xfiles.s \
           xfopen.s \
           xfoprep.s \
           xfrprep.s \
           xfspos.s \
           xfwprep.s \
           xgenld.s \
           xgetfld.s \
           xgetfloa.s \
           xgetint.s \
           xldtob.s \
           xlitob.s \
           xprintf.s \
           xputfld.s \
           xscanf.s
           
all:	$(ASMS)
	echo "made STDIO"

STDIO:	$(ASMS)
	echo "made STDIO"

.c.s:
	cc64 $(CFLAGS) $<

clean:
	del *.s
	del *.lis
	del *.c.xml
	del *.fpp
	del *.hir
