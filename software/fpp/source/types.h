#ifndef TYPES_H
#define TYPES_H

typedef enum {
  DIR_NONE = 0,
  DIR_REPT = 1,
  DIR_ENDM = 2,
  DIR_ENDIF = 3,
  DIR_ENDR = 4,
  DIR_MACR = 5,
  DIR_IF = 6,
  DIR_IFDEF = 7,
  DIR_IRP = 8,
  DIR_ELSE = 9,
  DIR_ELIF = 10
} dir_e;

typedef struct
{
  int num;        // parameter number
  char* name;     // parameter name
  char* def;      // default value
} arg_t;

typedef struct
{
  int size;
  int pos;
  int alloc;      // 0 = malloc, 1 = some other buffer.
  char* buf;
} buf_t;

typedef struct
{
  int defno;
  char *name;    // name of the macro
  buf_t *body;    // text to substitute when macro name is encountered
  int nArgs;     // Number of arguments passed to this macro
  int varg;      // variable argument list indicator
  int line;      // line number macro is defined on
  char *file;    // file macro is defined in
  arg_t** parms;
  buf_t* abody;  // text to substitute when macro name is encountered
  int64_t st;		// start of definiton (index)
  int64_t nd;		// end of definition (index)
  int inst;     // instance counter for this def.
} def_t;

typedef struct
{
  int defno;     // repeat definition number
  def_t* def;    // associated def
  int rcnt;     // current repeat counter (.rept)
  int orcnt;    // original repeat count
  int done;     // 1= done already
  char* st;      
  char* nd;
  int64_t start;  // start and end of repeat definition
  int64_t end;
  int64_t bdystart; // start and end of repeat body text
  int64_t bdyend;
} rep_t;

typedef struct
{
  char *name;
  int len;
  void (*func)(int, char*);
  int syntax;
  int opt;
  dir_e flags;
} directive_t;

typedef struct
{
  FILE* file;
  int64_t bufpos;
} pos_t;

#endif
