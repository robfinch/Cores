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
  b->alloc = 0;
  return (b);
}

// Free-up the buffer associated with the structure.
void free_buf(buf_t* buf)
{
  memset(buf->buf, 0, buf->size);
  if (buf->alloc == 0)
    free(buf->buf);
  free(buf);
}

buf_t* clone_buf(buf_t* buf)
{
  buf_t* b;

  b = new_buf();
  b->pos = buf->pos;
  if (buf->buf) {
    b->buf = _strdup(buf->buf);
    b->size = strlen(b->buf) + 1;
  }
  return (b);
}

// Enlarges a buffer by a memory page (4096B).

buf_t* enlarge_buf(buf_t* b)
{
  char* p;
  int osz;
  int oa;

  osz = b->size;
  oa = b->alloc;
  b->size = (b->size + 8191) & 0xfffff000LL;
  if (b->alloc == 0)
    p = realloc(b->buf, b->size);
  else {
    p = malloc(b->size);
    if (p)
      memcpy(p, b->buf, osz);
    b->alloc = 0;
  }
  if (p == NULL) {
    err(5);		// out of memory
    exit(5);
  }
  // If there is already a buffer, zero out new memory page.
  if (b->buf != NULL)
    memset(p + b->size - 4096, 0, 4096);
  // Otherwise, zero out the entire buffer.
  else
    memset(p, 0, b->size);
  // Clear out the freed-up buffer.
  memset(b->buf, 0, osz);
//  if (oa==0 && b->buf != p)
//    free(b->buf);
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
               to concatenate onto the end of the buffer. A value of 1
               indicates to concatenate onto the end of the buffer and retain
               the NULL character at the end of the string.

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
    (*buf)->alloc = 0;
  }
  if ((*buf)->buf == NULL) {
    err(5);
    exit(5);
  }
  lastpos = (*buf)->pos;
  while (lastpos + nn + pos > (*buf)->size)
    *buf = enlarge_buf(*buf);
  if (pos == 0) {
    memcpy_s(&(*buf)->buf[lastpos], (*buf)->size - lastpos, p, nn);
    lastpos += nn;
    (*buf)->buf[lastpos] = 0;
    (*buf)->pos = lastpos;
  }
  else if (pos == 1) {
    memcpy_s(&(*buf)->buf[lastpos], (*buf)->size - lastpos - 1, p, nn+1);
    lastpos += nn + 1;
    (*buf)->buf[lastpos-1] = 0;
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

/* -----------------------------------------------------------------------------
   Description :
      Adds a character to the input buffer.

   Parameters:
      (buf_t*) pointer to a structure referencing a text buffer to put the
               data in.
      (char)   character to add to the buffer

   Modifies:
      The position of the buffer pointer is updated.

   Returns:
    (none)
----------------------------------------------------------------------------- */

void char_to_buf(buf_t** buf, char ch)
{
  int mm;
  char* q = NULL;
  int lastpos = 0;

  if (buf == NULL)
    return;

  if (*buf == NULL)
    *buf = new_buf();
  if ((*buf)->buf == NULL) {
    mm = (1 + 4095) & 0xfffff000;
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
    (*buf)->alloc = 0;
  }
  if ((*buf)->buf == NULL) {
    err(5);
    exit(5);
  }
  lastpos = (*buf)->pos;
  if (lastpos + 1 > (*buf)->size)
    *buf = enlarge_buf(*buf);
  (*buf)->buf[lastpos] = ch;
  lastpos++;
  (*buf)->buf[lastpos] = 0;
  (*buf)->pos = lastpos;
}

