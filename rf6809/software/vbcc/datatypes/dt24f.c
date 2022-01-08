from)
{
  DTTTYPE to;
 	to=(from.a[0]&255)|((from.a[1]&255)<<8)|((from.a[2]&255)<<16);
  return to;
}
