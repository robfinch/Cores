/* ===============================================================
    (C) 2004  Bird Computer
    All rights reserved.
=============================================================== */

#include <stdio.h>

void displayHelp()
{
    fprintf(stderr,
        "asm68 <source file> [options]\n\n\r"
        "   /o[[-][b][s][-][l][y][:<filename>] - set output option\n\r"
        "      - - indicates disable option\n\r"
        "      b - binary output\r\n"
        "      e - error output file\r\n"
        "      s - S19 file format output\r\n"
        "      l - listing file\r\n"
        "      y - symbol table\r\n"
        "      : - override ouput file name\r\n"
        //       "   /l           - generate listing file\n\r"
        //       "   /r - cross reference file name\n\r"
        "   /Gxx - processor level for assembler\r\n"
        "      00 = 68000/08\r\n"
        "      10 = 68010\r\n"
        "      20 = 68020\r\n"
        "      30 = 68030\r\n"
        "      40 = 68040\r\n"
        "      CPU32\r\n"
        "      EC030 = 68EC030\r\n"
        "      EC040 = 68EC040\r\n"
        "      LC040 = 68LC040\r\n"
		"      FT68000 = FT\r\n"
		"   /Pxx - number of passes to make - default is 2\r\n"
        "Press a key\r\n"
    );
    getchar();
    fprintf(stderr,
        "\r\n"
        "* This program is distributed WITHOUT ANY WARENTEE; without even the implied\r\n"
        "warentee of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\r\n\r\n");
}



