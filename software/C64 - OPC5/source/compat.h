#ifndef _COMPAT_H
#define _COMPAT_H

// Compatibility definitions for compiling with GCC on Linux
// David Banks (hoglet) 2017

#ifndef __GNUC__

// On Windows use Rob's FPP pre processor
// The -b option supresses the banner text
#define PREPROCESSOR_CMD "fpp -b %s %s"

#else

// On Linux use gcc's cpp
// the -P option inhibits line markers, as these causes errors in C64
#define PREPROCESSOR_CMD "cpp -P %s %s"

#include <unistd.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <libgen.h>
#include <errno.h>

#define _strdup strdup
#define _access access
#define  __int8 char
#define __int16 short
#define __int64 long long

static inline int min (int a, int b) { return a < b ? a : b; }

static inline int max (int a, int b) { return a > b ? a : b; }

static inline int _dupenv_s(char **buffer, size_t *numberOfElements, const char *varname) {
   if (buffer == NULL || numberOfElements == NULL || varname == NULL) {
      return EINVAL;
   }
   char *env = getenv(varname);
   if (env == NULL) {
      *buffer = NULL;
      *numberOfElements = 0;
   } else {
      *numberOfElements = strlen(env);
      *buffer = (char *)malloc(*numberOfElements);
      strcpy(*buffer, env);
   }
   return 0;
}

static inline void _splitpath(char *path, char *drive, char *dir, char *name, char *ext) {
   char *base = basename(path);
   char *dot = rindex(base, '.');
   if (drive) {
      *drive = '\0';
   }
   if (dir) {
      strcpy(dir, dirname(path));
   }
   if (base) {
      strcpy(name, base);
      if (dot) {
         *(name + (dot - base)) = '\0';
      }
   }
   if (ext) {
      if (dot) {
         strcpy(ext, dot + 1);
      } else {
         *ext = '\0';
      }
   }
}

static inline int _splitpath_s(
   char * path,
   char * drive, size_t driveNumberOfElements,
   char * dir, size_t dirNumberOfElements,
   char * name, size_t nameNumberOfElements,
   char * ext, size_t extNumberOfElements
   ) {
   _splitpath(path, drive, dir, name, ext);
   // TODO: Add error handling
   return 0;
}

static inline void ZeroMemory (void *dst, size_t length) {
   memset(dst, 0, length);
}

static inline unsigned int _rotl(
   unsigned int value,
   int shift
   ) {
   return (value << shift) | (value >> (32 - shift));
}

static inline unsigned int _rotr(
   unsigned int value,
   int shift
   ) {
   return (value >> shift) | (value << (32 - shift));
}

static inline char *strtok_s(
   char *strToken,
   const char *strDelimit,
   char **context
   ) {
}

static inline int strncpy_s(
   char *strDestination,
   size_t numberOfElements,
   const char *strSource,
   size_t count
   ) {
   strncpy(strDestination, strSource, count);
   return 0;

}

static inline int strcpy_s(
   char *strDestination,
   size_t numberOfElements,
   const char *strSource
   ) {
   // TODO: Add error handling
   strncpy(strDestination, strSource, numberOfElements);
   return 0;
}

static inline int strcat_s(
   char *strDestination,
   size_t numberOfElements,
   const char *strSource
   ) {
   // TODO: Add error handling
   strncat(strDestination, strSource, numberOfElements);
   return 0;
}

static inline int _itoa_s(int value, char *buffer,  size_t sizeInCharacters,  int radix) {
   if (radix == 8) {
      snprintf(buffer, sizeInCharacters, "%o", value);
   } else if (radix == 10) {
      snprintf(buffer, sizeInCharacters, "%d", value);
   } else if (radix == 16) {
      snprintf(buffer, sizeInCharacters, "%x", value);
   } else {
      return EINVAL;
   }
   return 0;
}   

static inline int sprintf_s(char* buffer, size_t sizeOfBuffer, const char* format, ...)
{
    va_list ap;
    va_start(ap, format);
    int result = vsnprintf(buffer, sizeOfBuffer, format, ap);
    va_end(ap);
    return result;
}

#endif

#endif

