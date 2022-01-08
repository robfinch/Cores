from)
{
	 DTFTYPE to;
   to.a[0]=from&255;
   to.a[1]=(from>>8)&15;
   return to;
}
