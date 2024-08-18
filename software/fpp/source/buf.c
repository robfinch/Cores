#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <string.h>
#include <malloc.h>
#include <time.h>
#include <dos.h>
#include <ht.h>
#include <direct.h>
#include <inttypes.h>

#include "fpp.h"

/* ---------------------------------------------------------------------------
   (C) 1992-2024 Robert T Finch

   fpp - PreProcessor for Assembler / Compiler
--------------------------------------------------------------------------- */

buf_t* new_buf()
{
  buf_t* b;

  b = malloc(sizeof(buf_t));
  if (b == NULL) {
  	err(5);		// out of memory
    exit(5);
  }
  b->pos = 0;
  b->size = 0;
  b->buf = NULL;
  return (b);
}

buf_t* enlarge_buf(buf_t* b)
{
  char* p;

  b->size += 4096;
  p = realloc(b->buf, b->size);
  if (p == NULL) {
    err(5);		// out of memory
    exit(0);
  }
  // If there is already a buffer, zero out new memory page.
  if (b->buf != NULL)
    memset(p + b->size - 4096, 0, 4096);
  // Otherwise, zero out the entire buffer.
  else
    memset(p, 0, b->size);
  b->buf = p;
  return (b);
}

/* -----------------------------------------------------------------------------
   Description :
      Copies a macro into the input buffer.

   Parameters:
      (buf_t*) pointer to a structure referencing a text buffer to put the
               data in.
      (char *) pointer to text to add to the buffer
      (int)    the position at which to place the text, A value of 0 indicates
               to concatenate onto the end of the buffer.

   Modifies:
      The position of the buffer pointer is updated.

   Returns:
    (none)
----------------------------------------------------------------------------- */

void insert_into_buf(buf_t** buf, char* p, int pos)
{
  int nn = strlen(p);
  int mm;
  char* q = NULL;
  int lastpos = 0;

  if (buf == NULL)
    return;
  if (p == NULL)
    return;

  if (*buf == NULL)
    *buf = new_buf();
  if ((*buf)->buf == NULL) {
    mm = (nn + 4095) & 0xfffff000;
    if (mm > 1000000) {
      err(5);   // out of memory
      exit(5);
    }
    q = malloc(mm);
    if (q == NULL) {
      err(5);
      exit(5);
    }
    memset(q, 0, mm);
    (*buf)->size = mm;
    (*buf)->buf = q;
    (*buf)->pos = 0;
  }
  if ((*buf)->buf == NULL) {
    err(5);
    exit(5);
  }
  lastpos = (*buf)->pos;
  if (lastpos + nn + pos > (*buf)->size) {
    mm = ((*buf)->size + nn + pos + 4095) & 0xfffff000;
    if (mm > 1000000) {
      err(5);   // out of memory
      exit(5);
    }
    q = realloc((*buf)->buf,mm);
    if (q == NULL)
      exit(0);
    free((*buf)->buf);
    (*buf)->size = mm;
    (*buf)->buf = q;
  }
  if ((*buf)->buf == NULL) {
    err(5);   // out of memory
    exit(5);
  }
  if (pos == 0) {
    memcpy_s(&(*buf)->buf[lastpos], (*buf)->size - lastpos, p, nn);
    lastpos += nn;
    (*buf)->buf[lastpos] = 0;
    (*buf)->pos = lastpos;
  }
  else {
    memmove_s(&(*buf)->buf[pos + nn], (*buf)->size - pos - nn, &(*buf)->buf[pos], nn);
    memcpy_s(&(*buf)->buf[pos], (*buf)->size - pos, p, nn);
    lastpos += nn;
    (*buf)->buf[lastpos] = 0;
    (*buf)->pos = lastpos;
  }
}

