
extern byte RTCC_BUF[60];
extern int Milliseconds;

// Get date from RTCC
private void get_datetime(int *year, int *month, int *day, int *hour, int *minute, int *second)
{
    int nn;

    if (year) {
        nn = RTCC_BUF[6];
        nn = 2000 + (nn & 15) + ((nn & 0xf0) >> 4) * 10;   // BCD to binary
        *year = nn;
    }
    if (month) {
        nn = RTCC_BUF[4];
        nn = (nn & 15) + ((nn & 0x10) >> 4) * 10;   // BCD to binary
        *month = nn;
    }
    if (day) {
        nn = RTCC_BUF[5];
        nn = (nn & 15) + ((nn & 0x30) >> 4) * 10;   // BCD to binary
        *day = nn;
    }
    if (hour) {
        nn = RTCC_BUF[2];
        nn = (nn & 0x0f) + ((nn & 0x30) >> 4) * 10;   // BCD to binary
        nn = nn & 0x3f;
        *hour = nn;
    }
    if (minute) {
        nn = RTCC_BUF[1];
        nn = (nn & 0x0F) + ((nn & 0x70) >> 4) * 10;   // BCD to binary
        *hour = nn;
    }
    if (second) {
        nn = RTCC_BUF[0];
        nn = (nn & 0x0F) + ((nn & 0x70) >> 4) * 10;   // BCD to binary
        *hour = nn;
    }
}

private int ToJul(int year, int month, int day)
{
   int
      JulDay,
      LYear = year,
      LMonth = month,
      LDay = day;

   JulDay = LDay - 32075L + 1461L * (LYear + 4800 + (LMonth - 14L) / 12L) /
      4L + 367L * (LMonth - 2L - (LMonth - 14L) / 12L * 12L) /
      12L - 3L * ((LYear + 4900L + (LMonth - 14L) / 12L) / 100L) / 4L;
   return(JulDay);
}

// Get a 64 bit datetime serial number for the system time variable

private int set_time_serial()
{
	int ii,nn;
	int year, month, day;
	int hours, minutes, seconds, centiseconds;

    get_datetime(&year, &month, &day, &hours, &minutes, &seconds);
	Milliseconds = seconds * 1024 + minutes * 61440 + hours * 3686400 +
		ToJul(year,month,day) * 88473600L;
	return nn;
}

