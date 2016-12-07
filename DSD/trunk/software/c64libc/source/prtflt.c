// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Waterloo
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
extern pascal int putstrW(register int *p, register int maxchars);

// Put a string representation of a double into a char buffer.
// Buffer must be at least 40 characters in size and at least width characters
// in size.

pascal int sprtflt(register int *buf, register float dbl, register int width, register int precision, register char E)
{
    int ndx;
    int exp, expcnt;
    int digit;
    int nn;
    int digits_before_decpt;
	int d1,d2,d3,d4;

    ndx = 0;
    if (dbl < 0.0) {
        dbl = -dbl;
        buf[0] = '-';
        ndx++;
    }
    if (dbl==0.0) {
        buf[ndx]='0';
        ndx++;
        buf[ndx]='\0';
        return (ndx);
    }
    exp = 0;
	if (dbl < 1.0) {
		while (dbl < 1.0) {
			dbl *= 1000000.0;
			exp -= 6;  
		}
	}
	else if (dbl >= 100000.0) {
		while (dbl >= 100000.0) {
			dbl /= 100000.0;
			exp += 5;
		}
	}
	while (dbl < 100000.0) {
        dbl *= 10.0;
        exp--;
    }
    digits_before_decpt = 1;
    expcnt = exp+7;
    if (exp+7 >= 0 && exp+7 < 8) {
        digits_before_decpt = exp+7;
        digits_before_decpt--;
        expcnt = 2;
    }
j1:;
    expcnt -= 2;
    exp = digits_before_decpt;
    if (exp <= 0) {
        buf[ndx] = '.';
        ndx++;
        if (exp < 0) {
           buf[ndx] = '0';
           ndx++;
        }
    }
    for (nn = 0; nn < 16 && precision > 0; nn++) {
        digit = 0;
        while (dbl >= 100000.0) {
            dbl -= 100000.0;
            digit++;
        }
        buf[ndx] = digit + '0';
        ndx++;
        exp--;
        if (exp==0) {
           buf[ndx] = '.';
           ndx++;
        }
        else if (exp < 0)
            precision--;
        dbl *= 10.0;
    }
    do {
        ndx--;
    } while(buf[ndx]=='0');
    ndx++;
	if (buf[ndx]=='.')
		ndx+=2;
    if (expcnt==0) {
        buf[ndx]='\0';
        goto prt;
    }
    buf[ndx] = E;
    ndx++;
    if (expcnt < 0) {
        buf[ndx]='-';
        ndx++;
        expcnt = -expcnt;
    }
    else {
         buf[ndx]='+';
         ndx++;
    }
    digit = 0;
    while (expcnt >= 1000) {
        expcnt -= 1000;
        digit++;
    }
	d1 = digit;
	if (digit) {
		buf[ndx] = digit + '0';
		ndx++;
	}
    digit = 0;
    while (expcnt >= 100) {
        expcnt -= 100;
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
    while (expcnt >= 10) {
        expcnt -= 10;
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
    while (expcnt >= 0) {
        expcnt -= 1;
        digit++;
    }
    buf[ndx] = digit + '0';
    ndx++;
    buf[ndx] = '\0';
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
    int buf[50];
    int nn;

    if (width > 49)
       width = 49;
    if (width < -49)
       width = -49;
    nn = sprtflt(buf, dbl, width, precision, E);
    putstrW(buf,49);
    return (nn);
}
