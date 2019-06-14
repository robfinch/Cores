#ifndef HT_H

typedef struct {
   unsigned int hash;
   unsigned int delta;
} SHashVal;

typedef struct {
   SHashVal (*Hash)(void *);
   int (*IsEqual)(const void *, const void*);   // Must return 0 if hash entry = entry search for
   int  (*IsEqualName)(char *, const void *);
   int size;
   int width;
   void *table;
} SHashTbl;

void *htFind(SHashTbl *, void *);
void *htFind2(SHashTbl *, char *);
void *htDelete(SHashTbl *, void *);
void *htInsert(SHashTbl *, void *);
SHashVal htSymHash(SHashTbl *, char *);
#define HT_H
#endif
