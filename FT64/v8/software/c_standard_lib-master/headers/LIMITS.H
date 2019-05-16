/* limits.h standard header -- 8-bit version */
#ifndef _LIMITS
#define _LIMITS
#ifndef _YVALS
#include <yvals.h>
#endif
		/* char properties */
#define CHAR_BIT	16
#if _CSIGN
#define CHAR_MAX	32767
#define CHAR_MIN	(-32767-_C2)
#else
#define CHAR_MAX	65535
#define CHAR_MIN	0
#endif
		/* int properties */
#if _ILONG
#define INT_MAX		0x7FFFFFFFFFFFFFFF
#define INT_MIN		(-0x7FFFFFFFFFFFFFFF-_C2)
#define UINT_MAX	0xFFFFFFFFFFFFFFFFU
#else
#define INT_MAX		0x7FFFFFFF
#define INT_MIN		(-0x7FFFFFFF-_C2)
#define UINT_MAX	0xFFFFFFFFU
#endif
		/* long properties */
#define LONG_MAX	0x7FFFFFFFFFFFFFFF
#define LONG_MIN	(-0x7FFFFFFFFFFFFFFF-_C2)
		/* multibyte properties */
#define MB_LEN_MAX	_MBMAX
		/* signed char properties */
#define SCHAR_MAX	32767
#define SCHAR_MIN	(-32767-_C2)
		/* short properties */
#define SHRT_MAX	0x7FFFFFFF
#define SHRT_MIN	(-0x7FFFFFFF-_C2)
		/* unsigned properties */
#define UCHAR_MAX	65535
#define ULONG_MAX	0xFFFFFFFFFFFFFFFFU
#define USHRT_MAX	0xFFFFFFFFU
#endif
