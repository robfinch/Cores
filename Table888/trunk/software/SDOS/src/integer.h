/*-------------------------------------------*/
/* Integer type definitions for FatFs module */
/*-------------------------------------------*/

#ifndef _FF_INTEGER
#define _FF_INTEGER

#ifdef _WIN32	/* FatFs development platform */

#include <windows.h>
#include <tchar.h>

#else			/* Embedded platform */

/* This type MUST be 8 bit */
//typedef unsigned char	BYTE;
typedef byte BYTE;

/* These types MUST be 16 bit */
//typedef short			SHORT;
//typedef unsigned short	WORD;
//typedef unsigned short	WCHAR;
typedef __int16 SHORT;
typedef unsigned __int16 WORD;
typedef unsigned __int16 WCHAR;

/* These types MUST be 16 bit or 32 bit */
//typedef int				INT;
//typedef unsigned int	UINT;
typedef __int32 INT;
typedef unsigned __int32 UINT;

/* These types MUST be 32 bit */
//typedef long			LONG;
//typedef unsigned long	DWORD;
typedef __int32 LONG;
typedef unsigned __int32 DWORD;

#endif

#endif
