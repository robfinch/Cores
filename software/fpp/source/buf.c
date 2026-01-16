/*
// ============================================================================
//        __
//   \\__/ o\    (C) 1992-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ============================================================================
*/

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
  if (buf) {
    if (buf->alloc < 2)
      memset(buf->buf, 0, buf->size);
    if (buf->alloc == 0)
      free(buf->buf);
    free(buf);
  }
}

buf_t* clone_buf(buf_t* buf)
{
  buf_t* b;

  b = new_buf();
  b->pos = buf->pos;
  if (buf->buf) {
    if (buf->size) {
      b->buf = malloc(buf->size);
      if (b->buf == NULL) {
        err(5);
        exit(5);
      }
      memcpy(b->buf, buf->buf, buf->size);
      b->size = buf->size;
      return (b);
    }
    b->buf = _strdup(buf->buf);
    b->size = strlen(b->buf) + 1;
  }
  return (b);
}

// Enlarges a buffer by a memory page (4096B).

void enlarge_buf(buf_t** b1)
{
  char* p;
  int osz;
  int oa;
  buf_t* b = (*b1);

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
  if (b->buf)
    memset(b->buf, 0, osz);
//  if (oa==0 && b->buf != p)
//    free(b->buf);
  b->buf = p;
  (*b1) = b;
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
    if (mm == 0)
      mm = 4096;
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
    enlarge_buf(buf);
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
    enlarge_buf(buf);
  (*buf)->buf[lastpos] = ch;
  lastpos++;
  (*buf)->buf[lastpos] = 0;
  (*buf)->pos = lastpos;
}

int64_t get_input_buf_ndx()
{
  int64_t ndx;

  ndx = inptr - inbuf->buf;
  if (ndx > inbuf->size || ndx < 0) {
    printf("ndxerr");
    if (ndx < 0)
      ndx = 0;
    else
      ndx = inbuf->size;
  }
  return (ndx);
}

void set_input_buf_ptr(int64_t ndx)
{
  if (ndx > inbuf->size || ndx < 0) {
    printf("bad index");
    if (ndx < 0)
      ndx = 0;
    else
      ndx = inbuf->size;
  }
  inptr = inbuf->buf + ndx;
}

int check_buf_ptr(buf_t* buf, char* ptr)
{
  if (ptr - buf->buf > buf->size || ptr - buf->buf < 0)
    return (0);
  return 1;
}
