from)
{
  DTTTYPE to;
 	to=(from.a[0]&255)|((from.a[1]&15)<<8);
  return to;
}
