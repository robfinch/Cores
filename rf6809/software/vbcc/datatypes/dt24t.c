from)
{
	 DTFTYPE to;
   to.a[0]=from&255;
   to.a[1]=(from>>8)&255;
   to.a[2]=(from>>16)&255;
   to.a[3]=(from&0x800000)?255:0;
   return to;
}
