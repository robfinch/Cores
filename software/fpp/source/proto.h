#ifndef PROTO_H
#define PROTO_H

#define IsIdentChar(ch)       strchr(identchars, (ch))
#define IsFirstIdentChar(ch)  (isalpha((ch)) || (ch) == '_')
#define PeekCh()              (*inptr)

buf_t* new_buf();
void free_buf(buf_t*);
void enlarge_buf(buf_t** b);
buf_t* clone_buf(buf_t* b);
void insert_into_buf(buf_t** buf, char* p, int pos);
void char_to_buf(buf_t** buf, char ch);
int64_t get_input_buf_ndx();
void set_input_buf_ptr(int64_t ndx);
int check_buf_ptr(buf_t* buf, char* ptr);

def_t* new_def();
void free_def(def_t* def);
def_t* clone_def(def_t*);

pos_t* GetPos();
void SetPos(pos_t*);
size_t SymSpaceLeft();

int icmp(const void *, const void *);
int fcmp(char *, def_t *);
int ecmp(def_t *);
char *StoreBody(char *,...);
char *StorePlainStr(char *);
char *StoreStr(char *, ...);



void err(int, ...);
int64_t expeval(int* undef);
int directive(char* p, char** pos);
int directive_id(char* p, char** pos);

void ProcFile(char*);
int ProcLine(void);
int NextCh();
int NextNonSpace(int);
void SkipSpaces();
void unNextCh(void);
char *GetIdentifier();
void ScanPastEOL();
void input_to(buf_t*);
void fetch_line();
int peek_eof();

buf_t *GetMacroBody(def_t*, int opt, int rpt, int dodir);
char *GetMacroArg(void);
int GetMacroParmList(arg_t *[]);
void SubMacro(buf_t*, int, int);
char *SubMacroArg(char *, int, char *, arg_t* def);
int SubParmMacro(def_t* p, int opt, pos_t* id_pos);
void mac_collect(buf_t** buf, int opt);

int SearchAndSub(def_t* excld, int opt, char** nd);
int SearchAndSubBuf(buf_t** buf, int opt, char** nd);
void SearchForDefined(void);
void DoPastes(char *);

void ddefine(int, char*);
void derror(int, char*);
void dinclude(int, char*);
void delse(int, char*);
void delif(int, char*);
void dendif(int, char*);
void difdef(int, char*);
void difndef(int, char*);
void dif(int, char*);
void dundef(int, char*);
void dline(int, char*);
void dpragma(int, char*);
void dendm(int, char*);
void drept(int, char*);
void dendr(int, char*);

void searchenv(char *filename, char *envname, char *pathname, int pathsize);
// Utility type functions
char* rtrim(char*);
char* strip_quotes(char*);
char* strip_blank_lines(char*);
char* strip_directives(char*);
int is_blank(char*);
int count_lines(char* buf);
int line_length(char* buf);

char syntax_ch();
int GetReptArgList(arg_t* arglist[], int opt);

SHashVal HashFnc(def_t *);

#endif
