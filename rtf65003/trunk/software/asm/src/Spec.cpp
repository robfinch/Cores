#include <stdio.h>
#include "sym.h"

/****************************************************************************
   Methods operating on specifier class.
****************************************************************************/

/* ----------------------------------------------------------------------------
   Description :
      Return a string representing the indicated storage class.
--------------------------------------------------------------------------- */

char *CSpecifier::sclassStr()
{
   return (
      sclass == CONSTANT ? "CON" :
      sclass == REGISTER ? "REG" :
      sclass == TYPEDEF ? "TYP" :
      sclass == AUTO ? "AUT" :
      sclass == FIXED ? "FIX" :
      "BAD SCLASS"
   );
}


/* ----------------------------------------------------------------------------
   Description :
      Return a string representing the indicated output storage class.
--------------------------------------------------------------------------- */

char *CSpecifier::oclassStr()
{
   return (
      oclass == PUB ? "PUB" :
      oclass == PRI ? "PRI":
      oclass == COM ? "COM":
      oclass == EXT ? "EXT" :
      "(NO OCLS)"
   );
}


/* ----------------------------------------------------------------------------
   Description :
      Return a string representing the indicated noun.
--------------------------------------------------------------------------- */

char *CSpecifier::NounStr()
{
   return (
      noun == BOOL ?       "bool":
      noun == INT ?        "int":
      noun == CHAR ?       "char":
      noun == REAL ?       "real":
      noun == VOID ?       "void":
      noun == LABEL ?      "label":
      noun == DATE ?       "date":
      noun == TIME ?       "time" :
      noun == STRING ?     "string" :
      noun == CURRENCY ?   "currency" :
      noun == BIT ?        "bit" :
      noun == ENUM ?       "enum" :
      noun == STRUCTURE ?  "struct" :
      "BAD NOUN"
   );
}


/* ----------------------------------------------------------------------------
   Description :
      Return a string representing all attributes in a specifier other than
   the noun and storage class.
--------------------------------------------------------------------------- */

char *CSpecifier::AttrStr()
{
   static char str[7];

   str[0] = (char)((_unsigned) ? 'u' : '.');
   str[1] = (char)((_static)   ? 's' : '.');
   str[2] = (char)((_extern)   ? 'e' : '.');
   str[3] = (char)((_long)     ? 'l' : '.');
   str[4] = (char)((_volatile) ? 'v' : '.');
   str[5] = (char)((_unicode)  ? 'u' : '.');
   str[6] = '\0';
   return (str);
}



