public DoubleDouble add(DoubleDouble y)
{
   double a, b, c, d, e, f;
   e = this.hi + y.hi;
   d = this.hi - e;
   a = this.lo + y.lo;
   f = this.lo - a;
   d = ((this.hi - (d + e)) + (d + y.hi)) + a;
   b = e + d;
   c = ((this.lo - (f + a)) + (f + y.lo)) + (d + (e - b));
   a = b + c;
   return new DoubleDouble(a, c + (b - a));
}

public DoubleDouble mul(DoubleDouble y)
{
   double a, b, c, d, e;
   a = 0x08000001 * this.hi;
   a += this.hi - a;
   b = this.hi - a;
   c = 0x08000001 * y.hi;
   c += y.hi - c;
   d = y.hi - c;
   e = this.hi * y.hi;
   c = (((a * c - e) + (a * d + b * c)) + b * d) + (this.lo * y.hi + this.hi * y.lo);
   a = e + c;
   return new DoubleDouble(a, c + (e - a));
}
