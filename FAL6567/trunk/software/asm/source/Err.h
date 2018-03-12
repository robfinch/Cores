#pragma once

#include <setjmp.h>
#include "MyString.h"

#define E_PAREN        2001
#define E_DIV          2002      // division by zero
#define E_NOTDEFINED   2003      // symbol not defined
#define E_DEFINED      2004      // symbol already defined
#define E_LENGTH       2005      // wrong length
#define E_EXPECTREG    2006      // expecting a register
#define E_INV          2008
#define E_PHASE        2011
#define E_CMD          2012      // unknown command line switch
#define E_OPEN         2013
#define E_QUOTE        2014      // no closing quotes
#define E_MOD          2015      // can not calculate mod(0)
#define E_INVREG       2016      // invalid register
#define E_MEMORY       2018      // out of memory
#define E_INVOPMODE    2026      // operand addressing mode not supported by selected processor
#define E_CPAREN       2027      // extra closing ')'
#define E_BRANCH       2028      // branch out of range
#define E_WORDODD      2029      // word assembled at odd address
#define E_IMMTRUNC     2030      // too big for immediate data
#define E_SHIFTCOUNT   2031      // too big for shift count
#define E_QUICKTRUNC   2033      // quick immediate data truncated
#define E_WRITEOUT     2034      // error writing output
#define E_BYTEADDR     2036      // byte address not supported
#define E_STATSIZE     2037      // illegal size for status register
#define E_CCRBYTE      2038      // only byte operations allowed on ccr
#define E_INVOPERAND   2039      // invalid operand
#define E_ONLYLONG     2040      // only long size supported
#define E_PROCLEVEL    2041
#define E_DISPLACEMENT 2042      // displacement too large
#define E_PROC         2043      // processor not supported
#define E_SCALESZ      2044
#define E_INVMIOP      2045      // invalid memory indirect operand component
#define E_SOURCEIMM    2046      // source operand must be immediate
#define E_NOPERAND     2048
#define E_ONLYBYTE     2049      // only byte size supported
#define E_OPERANDS     2050      // too many operands
#define E_SHIFTZERO    2051      // no output for zero shift count
#define E_WORDONLY     2052      // only word size supported
#define E_SCALNOSUP    2053      // index scaling not supported on processor
#define E_MACRONAME    2054      // expecting a macro name
#define E_MACROCOMMA   2055      // expecting ',' separator in macro definition
#define E_FILES        2056      // too many files
#define E_DEFINE       2057      // defined needs symbol name
#define E_EXPR         2058      // error in expression
#define E_EXTRADOT     2059      // extra '.' ignored
#define E_SIZEOP       2060      // size needs symbol name
#define E_PUBLIC       2061      // public needs an address label
#define E_LABEL        2062      // expecting a label
#define E_MACROPARM    2063      // too many macro parameters
#define E_MACROARG     2064      // incorrect number of macro arguments were passed
#define E_TBLOVR       2065      // table overflow
#define E_MACSIZE      2066      // macro too large
#define E_CHAR         2067      // unrecognized characters on line
#define E_ENDM         2068      // extra 'endm' encountered
#define E_ADDRLABEL    2069      // expecting address label
#define E_WORDLONG     2070      // must be either .W or .L
#define E_SIZE         2071      // size does not match existing definition
#define E_LINKCLASS    2072
#define E_LINKVOIDSZ   2073      // void object has zero for size
#define E_LINKLABELSZ  2074      // assuming pointer size for label
#define E_LINKSIZE     2075      // GetSizeof Can't size type
#define E_LINKCONST    2076      // Can't make const for type
#define E_LINKALIGN    2077      // Object aligned on zero boundary
#define E_LINKSCBIT    2078      // SetClassBit, bad storage class
#define E_LINKFLOAT    2079      // compiler does not support floating point
#define E_LINKPREFIX   2080      // GetPrefix, Can't process type
#define E_ONLYBITS	   2081		 // only bits 0-%d available for operation
#define E_INVREGLIST   2082		 // invalid register list
#define E_ARGCOUNT	   2083		 // argument count must be immediate value
#define E_ARGCHK       2084		 // must be between 0 and 255 arguments for callm
#define E_REGSUP	   2085      // register suppression not supported
#define E_MEMIND	   2086		 // memory indirect modes not supported
#define E_ONLYWL	   2087		 // only word or long size supported
#define E_ILLADMD	   2088		 // illegal address mode
#define E_MISSINGBF	   2089		 // missing bitfield specification
#define E_DATAREG	   2090      // expecting a data register
#define E_DATAPAIR	   2091		 // expecting data register pair
#define E_REGPAIR	   2092		 // expecting a register pair
#define E_INDPAIR	   2093		 // expecting register indirect pair
#define E_CACHECODE	   2094      // invalid cache code
#define E_ARIND		   2095		 // expecting (An) address mode
#define E_MISSINGEW    2096		 // missing extension word
#define E_TOOMANYEW	   2097		 // too many extension words defined
#define E_OPSIZE	   2098		 // operation size not supported
#define E_FPREG	       2099		 // expecting a floating point register
#define E_KFACT	       2100		 // k-factor required
#define E_ONLYX        2101      // only extended size supported
#define E_ROMCONSTANT  2102      // use of reserved ROM constant 
#define E_BWLS	       2103		 // must be one of BWLS
#define E_INVCREG	   2104		 // control register not valid on selected processor
#define E_MASK		   2105		 // expecting immediate mask
#define E_MASK2        2106      // mask value out of range, truncated
#define E_FCSEL		   2107	     // function code select out of range
#define E_INVMMUREG	   2108		 // mmu register not valid on selected processor
#define E_MMUXLEVEL	   2109      // expecting level indicator, found
#define E_MMULEVEL     2110      // level value out of range
#define E_XADREG	   2111		 // expecting an address register
#define W_EC40		   2112		 // instruction should not be executed on EC040
#define E_2FEWOPS	   2113      // too few operands
#define E_XDREGPAIR	   2114      // expecting data register or register pair
#define E_DEMOM	       2115		 // demo version, macro limit reached
#define E_DEMOI		   2116      // demo version, file inclusion not supported
#define E_DEMOL		   2117		 // demo version, line number limit reached
#define E_ONLYBW		2118	// only byte or word size supported
#define E_ROTCOUNT		2119	// rotate count must be one
#define E_CABCONST		2120
#define E_REPCNT		2121

#define ERR_MSG_PREFIX

namespace RTFClasses
{
	class Err
	{
	public:
		int num;
		String msg;
	public:
		Err(int num);
		Err(int num, const char *s);
		Err(int num, int data);
	};

	class FatalErr : public Err {
	public:
		FatalErr(int n) : Err(n) {};
		FatalErr(int n, const char *s) : Err(n, s) {};
	};

	class ExprErr : public Err {
	public:
		ExprErr(int n) : Err(n) {};
	};
}
