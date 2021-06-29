#include <stdio.h>
#include <dos.h>
#include <string.h>

#define MODEREG   0x3d8
#define INDEX     0x3d4
#define DATA      0x3d5

main()
{
   int i, mode;
   char c1, c2;
   char far *scrn = (char far *)0xb8000000;
   /* ----------------------------------------------------------
         Low resolution graphics mode is set in the following
      manner.

         1) The maximum scan line address is set to 3. This
            restriction is neccessary because each pair of
            pixels on the low resolution screen requires
            two bytes. Since there are 160 low resolution
            pixels horizontally on the graphics screen, a
            maximum of 100 rows of pixels can be displayed.

         2) The CRT controller is set up for a display width
            of 80 characters. This is done because of CRT
            timing considerations in low res mode and also
            the limited amount of memory available.

         3) Two modes are possible 160 x 100 and 80 x 200
   ---------------------------------------------------------- */
   static int table[] =
   {
		111,   // Horizontal total
		 80,   // Horizontal displayed
       90,   // H. Sync position
       10,   // Sync width
      126,   // Vertical total
        6,   // Vertical total adjust
      100,   // Vertical displayed
      114,   // V. Sync position
        2,   // Interlace Mode and skew
        1,   // Max Scan line address
        6,   // Cursor Start
        7,   // Cursor End
        0,   // Start address high
        0,   // Start address low
        0,   // Cursor address high
        0    // Cursor address low
   };
   /* -----------------------------
			Setup for low res mode.
			Bit breakdown
			0 0 = 40 x 25 1 = 80 x 25 mode (clock divide)
			1 0 = alphanumeric 1 = 320 x 200 graphics mode
			2 0 = colour mode 1 = black and white mode
			3 0 = disable video 1 = enable
			4 1 = hi res 2 colour mode 640 x 200
			5 0 = use high bit of attribute for intensity not blinking.
			6 nothing
			7 nothing
	----------------------------- */
	mode = 0xc9;        // 11001001
	outp(MODEREG, mode);
   for (i = 0; i < 15; i++)
   {
      outp(INDEX, i);
      outp(DATA, table[i]);
   }
   for(i = 0; i < 0x4000; i += 2)
   {
      scrn[i] = 221;
      scrn[i+1] = 0;
   }
   for(i = 0; i < 512; i += 2)
      scrn[i+1] = i / 2;
   getch();
}
