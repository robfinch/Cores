// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// prtflt.c
// Print a string representation of a float.
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// ============================================================================
//
extern pascal int putstr(register char *p, register int maxchars);
extern pascal int putstrD(register int *p, register int maxchars);

// Put a string representation of a double into a char buffer.
// Buffer must be at least 40 characters in size and at least width characters
// in size.

typedef union _tagFlt
{
	float flt;
	unsigned __int16 w[5];
} uFlt;

// Detect Not-a-Number

static pascal int IsNan80(register float n)
{
	uFlt uf;

	uf.flt = n;

	// If the mantissa is zero, it can't be a NaN.
	if (uf.w[0]==0 && uf.w[1]==0 && uf.w[2]==0 && uf.w[3]==0)
		return (0);
	// Exponent must be 0x7fff
	if ((uf.w[4] & 0x7fff)==0x7fff)
		return (1);
	return (0);
}

// Detect infinity

static pascal int IsInf80(register float n)
{
	uFlt uf;

	uf.flt = n;

	// If the mantissa is non-zero, it can't be a inf.
	if (uf.w[0]!=0 || uf.w[1]!=0 || uf.w[2]!= 0 || uf.w[3]!=0)
		return (0);
	// Exponent must be 0x7fff
	if ((uf.w[4] & 0x7fff)==0x7fff)
		return (1);
	return (0);
}

pascal int sprtflt(register char *buf, register int bufsz, register float dbl, register int width, register int precision, register char E)
{
    int ndx;
    int exp;
    int digit;
    int nn;
    int digits_before_decpt;
	int d1,d2,d3,d4,d5;
	float dbla,dbl2;

	if (bufsz < 40 || bufsz < width)
		return;
    ndx = 0;
	if (IsNan80(dbl)) {
		buf[0] = 'N';
		buf[1] = 'a';
		buf[2] = 'N';
		buf[3] = '\0';
		goto prt;
	}
	if (IsInf80(dbl)) {
		buf[0] = dbl < 0.0 ? '-' : '+';
		buf[1] = 'I';
		buf[2] = 'n';
		buf[3] = 'f';
		buf[4] = '\0';
		goto prt;
	}
    if (dbl < 0.0) {
        dbl = -dbl;
        buf[0] = '-';
        ndx++;
    }
    if (dbl==0.0) {
        buf[ndx]='0';
        ndx++;
        buf[ndx]='\0';
        goto prt;
    }
    exp = 0;

	// Make a small number > 0 so we can get at the digits.
	if (dbl < 1.0) {
		while (dbl < 1.0) {
			dbl *= 1000000.0;
			exp -= 6;  
		}
	}

	// The following is similar to using log10() and pow() functions.
	// Now dbl is >= 1.0
	// Create a number dbl2 on the same order of magnitude as dbl, but
	// less than dbl.
	dbl2 = 1.0;
	dbla = dbl2;
	if (dbl > dbl2) {	// dbl > 1.0 ?
		while (dbl2 <= dbl) {
			dbla = dbl2;
			dbl2 *= 10.0;	// increase power of 10
			exp++;
		}
		// The above loop goes one too far, we want the last value less
		// than dbl.
		dbl2 = dbla;
		exp--;
	}

	// For small constants < 1000000 try and spit out a whole number
    if (exp >= 0 && exp < 6) {
        digits_before_decpt = exp+1;
		exp = 0;
	}
	else if (exp >= -6)
		digits_before_decpt = 1;
	else
		digits_before_decpt = -1;
j1:;

	// Spit out a leading zero before the decimal point for a small number.
    if (exp < -6) {
		buf[ndx] = '0';
		ndx++;
        buf[ndx] = '.';
        ndx++;
    }

	// Now loop processing one digit at a time.
    for (nn = 0; nn < 30 && precision > 0; nn++) {
        digit = 0;
		dbla = dbl;
		// dbl is on the same order of magnitude as dbl2 so
		// a repeated subtract can be used to find the digit.
        while (dbl >= dbl2) {
            dbl -= dbl2;
            digit++;
        }
        buf[ndx] = digit + '0';
		// Now go back and perform just a single subtract and
		// a multiply to find out how much to reduce dbl by.
		// This should improve the accuracy
		if (digit > 2)
			dbl = dbla - dbl2 * digit;
        ndx++;
        digits_before_decpt--;
        if (digits_before_decpt==0) {
           buf[ndx] = '.';
           ndx++;
        }
        else if (digits_before_decpt < 0)
            precision--;
		// Shift the next digit to be tested into position.
        dbl *= 10.0;
    }
	// Trim trailing zeros from the number
    do {
        ndx--;
    } while(buf[ndx]=='0');
    ndx++;

	// Make sure we have at least one digit after the decimal point.
	if (buf[ndx]=='.') {
		ndx++;
		buf[ndx]='0';
		ndx++;
        buf[ndx]='\0';
	}

	// If the number is times 10^0 don't output the exponent
    if (exp==0) {
        buf[ndx]='\0';
        goto prt;
    }

	// Spit out +/-E
    buf[ndx] = E;
    ndx++;
    if (exp < 0) {
        buf[ndx]='-';
        ndx++;
        exp = -exp;
    }
    else {
         buf[ndx]='+';
         ndx++;
    }

	// now process the exponent
    digit = 0;
    while (exp >= 1000) {
        exp -= 1000;
        digit++;
    }
	d1 = digit;
	if (digit) {
		buf[ndx] = digit + '0';
		ndx++;
	}

	digit = 0;
    while (exp >= 100) {
        exp -= 100;
        digit++;
    }
	d2 = digit;
	if (digit==0 && d1==0)
		;
	else {
		buf[ndx] = digit + '0';
		ndx++;
	}
    
	digit = 0;
    while (exp >= 10) {
        exp -= 10;
        digit++;
    }
	d3 = digit;
	if (digit==0 && d1==0 && d2==0)
		;
	else {
		buf[ndx] = digit + '0';
		ndx++;
	}

	digit = 0;
    while (exp >= 1) {
        exp -= 1;
        digit++;
    }
    buf[ndx] = digit + '0';
    ndx++;
    buf[ndx] = '\0';

	// Now pad the number on the left or right as requested.
prt:;
    // pad left
    if (width > 0) {
        if (ndx < width) {
            for (nn = 39; nn >= width-ndx; nn--)
                buf[nn] = buf[nn-(width-ndx)];
            for (; nn >= 0; nn--)
                buf[nn] = ' ';
        }
    }
    // pad right
    if (width < 0) {
        width = -width;
        while (ndx < width) {
            buf[ndx]=' ';
            ndx++;
        }
        buf[ndx]='\0';
    }
    return (ndx);
}

pascal int prtflt(register float dbl, register int width, register int precision, register char E)
{
    char buf[50];
    int nn;

    if (width > 49)
       width = 49;
    if (width < -49)
       width = -49;
    nn = sprtflt(buf, 50, dbl, width, precision, E);
    putstr(buf,49);
    return (nn);
}
