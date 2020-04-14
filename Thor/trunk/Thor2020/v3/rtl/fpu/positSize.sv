parameter PSTWID = `PSTWID;
parameter es =
  PSTWID >= 80 ? 4 :
  PSTWID >= 64 ? 3 :
  PSTWID >= 52 ? 3 :
  PSTWID >= 40 ? 3 :
  PSTWID >= 32 ? 2 :
  PSTWID >= 24 ? 2 :
  PSTWID >= 16 ? 1 :
  PSTWID >= 8 ? 1 :
  0 ;

