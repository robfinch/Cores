/* ---------------------------------------------------------------
   2009  Robert T Finch

      Program to take binary file and split it into 
	separate files.
--------------------------------------------------------------- */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void fputc_rep(char ch, FILE *fp, int n);

main(int argc, char *argv[])
{
   FILE *fp;
   FILE *ofp[8];
   char ofname[8][512], ifname[512], *ptr;
   int xx, yy;
   static char *oext[8] = { ".o0", ".o1", ".o2", ".o3", ".04", ".o5", ".o6", ".o7" };
   int nStream = 2;
   int wStream = 1;
   int ch;

   puts("split - binary file splitting utility.");
   puts("2009-2020  Robert Finch");
   if (argc != 3)
   {
      puts("split <filename> <option>");
      puts("\tSplits an input file into up to eight output files.");
	  puts("\t<option> has two parts - a character code b,h,w,d and the number of");
	  puts("\toutput streams");
	  puts("\tthe character code indicates the output stream (file) width ");
	  puts("\t(b=byte,h=halfword (16 bits),w=word(32 bits),d=double word (64 bits)");
	  puts("\tExample: split test.bin w4");
	  puts("\t\twill treat test.bin as a series of word (32 bit) values");
	  puts("\t\tand split the test.bin file into four output files (test.o0, test.o1, ...)");
	  puts("\t\tfrom the input file.");
      puts("\tInput file name default extension is '.bin'.");
      exit(0);
   }
   if (argv[2][0] == 'b')
		wStream = 1;
   else if (argv[2][0] == 'B')
		wStream = 1;
   else if (argv[2][0] == 'h')
		wStream = 2;
   else if (argv[2][0] == 'H')
		wStream = 2;
   else if (argv[2][0] == 'w')
		wStream = 4;
   else if (argv[2][0] == 'W')
		wStream = 4;
   else if (argv[2][0] == 'd')
		wStream = 8;
   else if (argv[2][0] == 'D')
		wStream = 8;
   else {
		printf("Invalid stream width\r\n");
		exit(0);
   }

   nStream = atoi(&argv[2][1]);
   if (nStream > 8 || nStream < 1) {
	   printf("Only one to eight streams allowed.\r\n");
	   exit(0);
   }

   strcpy(ifname, argv[1]);
   if (!strchr(ifname, '.'))
      strcat(ifname, ".bin");

	// Build output file names
	for (xx = 0; xx < nStream; xx++) {
		strcpy(ofname[xx], argv[1]);
		ptr = strrchr(ofname[xx], '.');
		if (ptr)
			*ptr = '\0';
		strcat(ofname[xx], oext[xx]);
	}

   if ((fp = fopen(ifname, "rb")) == NULL)
   {
      printf("Error opening '%s'\n", ifname);
      exit(0);
   }
   for (xx = 0; xx < nStream; xx++) {
		if ((ofp[xx] = fopen(ofname[xx], "wb")) == NULL)
		{
			printf("Error opening stream '%s'\n", ofname[xx]);
			exit(0);
		}
	}

	while(!feof(fp))
	{
		for (xx = 0; xx < nStream; xx++) {
			for (yy = wStream-1; yy >= 0; --yy) {
				ch=fgetc(fp);
				if (ch==EOF) {
					fputc_rep(0x00, ofp[xx], yy);
					goto j1;
				}
				fputc(ch, ofp[xx]);
			}
		}
	}
j1:
	fcloseall();
	return (0);
}

void fputc_rep(char ch, FILE *fp, int n)
{
	int xx;

	for (xx = 0; xx < n; xx++)
		fputc(ch, fp);
}
