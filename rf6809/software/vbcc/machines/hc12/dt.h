

/* Machine generated file. DON'T TOUCH ME! */


#ifndef DT_H
#define DT_H 1
typedef signed char zchar;
typedef unsigned char zuchar;
typedef signed short zshort;
typedef unsigned short zushort;
typedef signed short zint;
typedef unsigned short zuint;
typedef signed int zlong;
typedef unsigned int zulong;
typedef __int64 zllong;
typedef signed __int64 zullong;
typedef struct {char a[4];} dt11f;
typedef dt11f zfloat;
typedef float dt11t;
dt11t dtcnv11f(dt11f);
dt11f dtcnv11t(dt11t);
typedef struct {char a[8];} dt12f;
typedef dt12f zdouble;
typedef double dt12t;
dt12t dtcnv12f(dt12f);
dt12f dtcnv12t(dt12t);
typedef struct {char a[8];} dt13f;
typedef dt13f zldouble;
typedef double dt13t;
dt13t dtcnv13f(dt13f);
dt13f dtcnv13t(dt13t);
typedef unsigned short zpointer;
#define zc2zm(x) ((__int64)(x))
#define zs2zm(x) ((__int64)(x))
#define zi2zm(x) ((__int64)(x))
#define zl2zm(x) ((__int64)(x))
#define zll2zm(x) ((__int64)(x))
#define zm2zc(x) ((signed char)(x))
#define zm2zs(x) ((signed short)(x))
#define zm2zi(x) ((signed short)(x))
#define zm2zl(x) ((signed int)(x))
#define zm2zll(x) ((__int64)(x))
#define zuc2zum(x) ((signed __int64)(x))
#define zus2zum(x) ((signed __int64)(x))
#define zui2zum(x) ((signed __int64)(x))
#define zul2zum(x) ((signed __int64)(x))
#define zull2zum(x) ((signed __int64)(x))
#define zum2zuc(x) ((unsigned char)(x))
#define zum2zus(x) ((unsigned short)(x))
#define zum2zui(x) ((unsigned short)(x))
#define zum2zul(x) ((unsigned int)(x))
#define zum2zull(x) ((signed __int64)(x))
#define zum2zm(x) ((__int64)(x))
#define zm2zum(x) ((signed __int64)(x))
#define zf2zld(x) dtcnv13t((double)dtcnv11f(x))
#define zd2zld(x) dtcnv13t((double)dtcnv12f(x))
#define zld2zf(x) dtcnv11t((float)dtcnv13f(x))
#define zld2zd(x) dtcnv12t((double)dtcnv13f(x))
#define zld2zm(x) ((__int64)dtcnv13f(x))
#define zm2zld(x) dtcnv13t((double)(x))
#define zld2zum(x) ((signed __int64)dtcnv13f(x))
#define zum2zld(x) dtcnv13t((double)(x))
#define zp2zum(x) ((signed __int64)(x))
#define zum2zp(x) ((unsigned short)(x))
#define l2zm(x) ((__int64)(x))
#define ul2zum(x) ((signed __int64)(x))
#define d2zld(x) dtcnv13t((double)(x))
#define zm2l(x) ((long)(x))
#define zum2ul(x) ((unsigned long)(x))
#define zld2d(x) ((double)dtcnv13f(x))
#define zmadd(a,b) ((a)+(b))
#define zumadd(a,b) ((a)+(b))
#define zldadd(a,b) dtcnv13t(dtcnv13f(a)+dtcnv13f(b))
#define zmsub(a,b) ((a)-(b))
#define zumsub(a,b) ((a)-(b))
#define zldsub(a,b) dtcnv13t(dtcnv13f(a)-dtcnv13f(b))
#define zmmult(a,b) ((a)*(b))
#define zummult(a,b) ((a)*(b))
#define zldmult(a,b) dtcnv13t(dtcnv13f(a)*dtcnv13f(b))
#define zmdiv(a,b) ((a)/(b))
#define zumdiv(a,b) ((a)/(b))
#define zlddiv(a,b) dtcnv13t(dtcnv13f(a)/dtcnv13f(b))
#define zmmod(a,b) ((a)%(b))
#define zummod(a,b) ((a)%(b))
#define zmlshift(a,b) ((a)<<(b))
#define zumlshift(a,b) ((a)<<(b))
#define zmrshift(a,b) ((a)>>(b))
#define zumrshift(a,b) ((a)>>(b))
#define zmand(a,b) ((a)&(b))
#define zumand(a,b) ((a)&(b))
#define zmor(a,b) ((a)|(b))
#define zumor(a,b) ((a)|(b))
#define zmxor(a,b) ((a)^(b))
#define zumxor(a,b) ((a)^(b))
#define zmmod(a,b) ((a)%(b))
#define zummod(a,b) ((a)%(b))
#define zmkompl(a) (~(a))
#define zumkompl(a) (~(a))
#define zmleq(a,b) ((a)<=(b))
#define zumleq(a,b) ((a)<=(b))
#define zldleq(a,b) (dtcnv13f(a)<=dtcnv13f(b))
#define zmeqto(a,b) ((a)==(b))
#define zumeqto(a,b) ((a)==(b))
#define zldeqto(a,b) (dtcnv13f(a)==dtcnv13f(b))
#endif
