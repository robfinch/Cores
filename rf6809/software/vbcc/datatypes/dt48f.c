from)
{
  DTTTYPE to;
 	to=(from.a[0]&255LL)|((from.a[1]&255LL)<<8LL)|((from.a[2]&255LL)<<16LL)|
 			((from.a[3]&255LL)<<24LL)|((from.a[4]&255LL)<<32LL)|((from.a[5]&255LL)<<40LL);
  return to;
}
  