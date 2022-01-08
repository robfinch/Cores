from)
{
	 DTFTYPE to;
   to.a[0]=from&255LL;
   to.a[1]=(from>>8LL)&255LL;
   to.a[2]=(from>>16LL)&255LL;
   to.a[3]=(from>>24LL)&255LL;
   to.a[4]=(from>>32LL)&255LL;
   to.a[5]=(from>>40LL)&255LL;
   to.a[6]=(from&0x800000000000LL)?255LL:0LL;
   to.a[7]=(from&0x800000000000LL)?255LL:0LL;
   return to;
}
