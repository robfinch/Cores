#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "a64.h"
#include "token.h"
#include "symbol.h"

#define MAX_PASS  6

int verbose = 0;
int debug = 0;
int pass;
int lineno;
char *inptr;
char *stptr;
int token;
int phasing_errors;
int bGen = 0;
char segment;
int segprefix = -1;
int64_t code_address;
int64_t data_address;
FILE *ofp;
int regno;
char current_label[500];
char first_org = 1;

enum {
    codeseg = 0,
    dataseg = 1,
    stackseg = 2,
    rodataseg = 3,
    tlsseg = 4,
    bssseg = 5,
};

char buf[10000];
char masterFile[10000000];
char segmentFile[10000000];
char codebuf[10000000];
char databuf[10000000];
char rodatabuf[10000000];
char tlsbuf[10000000];
uint8_t binfile[10000000];
int binndx;
int binstart;
int mfndx;
int codendx;
int datandx;
int rodatandx;
int tlsndx;

void emitCode(int cd);
void emitAlignedCode(int cd);
void process_shifti(int oc);
void processFile(char *fname, int searchincl);

void displayHelp()
{
     printf("a64 [options] file\r\n");
}

int processOptions(int argc, char **argv)
{
    int nn;
    
    nn = 1;
    do {
        if (nn >= argc-1)
           break;
        if (argv[nn][0]=='-') {
           nn++;
        }
        else break;
    } while (1);
    return nn;
}

// ---------------------------------------------------------------------------
// Emit constant extension for memory operands.
// ---------------------------------------------------------------------------

void emitImm4(int64_t v)
{
     if (v < -8L || v > 7L) {
          emitAlignedCode(0xfd);
          emitCode((v >> 4) & 255);
          emitCode((v >> 12) & 255);
          emitCode((v >> 20) & 255);
          emitCode((v >> 28) & 255);
     }
     if (((v < 0) && ((v >> 36) != -1L)) || ((v > 0) && ((v >> 36) != 0L))) {
          emitAlignedCode(0xfe);
          emitCode((v >> 36) & 255);
          emitCode((v >> 44) & 255);
          emitCode((v >> 52) & 255);
          emitCode((v >> 60) & 255);
     }
}
 
// ---------------------------------------------------------------------------
// Emit constant extension for memory operands.
// ---------------------------------------------------------------------------

void emit14(int64_t v)
{
     if (v < -8192L || v > 8191L) {
          emitAlignedCode(0xfd);
          emitCode((v >> 14) & 255);
          emitCode((v >> 22) & 255);
          emitCode((v >> 30) & 255);
          emitCode((v >> 38) & 255);
     }
     if (((v < 0) && ((v >> 46) != -1L)) || ((v > 0) && ((v >> 46) != 0L))) {
          emitAlignedCode(0xfe);
          emitCode((v >> 46) & 255);
          emitCode((v >> 54) & 255);
          emitCode((v >> 62) & 255);
          emitCode(0x00);
     }
}
 
// ---------------------------------------------------------------------------
// Emit constant extension for 16-bit operands.
// ---------------------------------------------------------------------------

void emit16(int64_t v)
{
     if (v < -32768L || v > 32767L) {
          emitAlignedCode(0xfd);
          emitCode((v >> 16) & 255);
          emitCode((v >> 24) & 255);
          emitCode((v >> 32) & 255);
          emitCode((v >> 40) & 255);
     }
     if (((v < 0) && ((v >> 48) != -1L)) || ((v > 0) && ((v >> 48) != 0L))) {
          emitAlignedCode(0xfe);
          emitCode((v >> 48) & 255);
          emitCode((v >> 56) & 255);
          emitCode(0x00);
          emitCode(0x00);
     }
}

// ---------------------------------------------------------------------------
// Emit constant extension for 24-bit operands.
// ---------------------------------------------------------------------------

void emitImm24(int64_t v)
{
     if (v < -8388608L || v > 8388607L) {
          emitAlignedCode(0xfd);
          emitCode((v >> 24) & 255);
          emitCode((v >> 32) & 255);
          emitCode((v >> 40) & 255);
          emitCode((v >> 48) & 255);
     }
     if (((v < 0) && ((v >> 56) != -1L)) || ((v > 0) && ((v >> 56) != 0L))) {
          emitAlignedCode(0xfe);
          emitCode((v >> 56) & 255);
          emitCode(0x00);
          emitCode(0x00);
          emitCode(0x00);
     }
}

// ---------------------------------------------------------------------------
// Emit constant extension for 32-bit operands.
// ---------------------------------------------------------------------------

void emitImm32(int64_t v)
{
     if (v < -2147483648LL || v > 2147483647LL) {
          emitAlignedCode(0xfd);
          emitCode((v >> 32) & 255);
          emitCode((v >> 40) & 255);
          emitCode((v >> 48) & 255);
          emitCode((v >> 56) & 255);
     }
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

void emitByte(int64_t cd)
{
    if (segment == codeseg || segment == dataseg || segment == rodataseg) {
        binfile[binndx] = cd & 255LL;
        binndx++;
    }
    code_address++;
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

void emitChar(int64_t cd)
{
     emitByte(cd & 255LL);
     emitByte((cd >> 8) & 255LL);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

void emitHalf(int64_t cd)
{
     emitChar(cd & 65535LL);
     emitChar((cd >> 16) & 65535LL);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

void emitWord(int64_t cd)
{
     emitHalf(cd & 0xFFFFFFFFLL);
     emitHalf((cd >> 32) & 0xFFFFFFFFLL);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

void emit_insn(int64_t oc)
{
     emitAlignedCode(oc & 255);
     emitCode((oc >> 8) & 255);
     emitCode((oc >> 16) & 255);
     emitCode((oc >> 24) & 255);
     emitCode((oc >> 32) & 255);
}
 
// ---------------------------------------------------------------------------
// Emit code aligned to a code address.
// ---------------------------------------------------------------------------

void emitAlignedCode(int cd)
{
     int64_t ad;

     ad = code_address & 15;
     while (ad != 0 && ad != 5 && ad != 10) {
         emitByte(0x00);
         ad = code_address & 15;
     }
     emitByte(cd);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

void emitCode(int cd)
{
     emitByte(cd);
}

// ---------------------------------------------------------------------------
// brnz r1,label
// ---------------------------------------------------------------------------

void process_bcc(int oc)
{
    int Ra;
    int64_t val;
    int64_t disp;

    Ra = getRegister();
    need(',');
    NextToken();
    val = expr();
    disp = (val & 0xFFFFFFFFFFFF0000L) - (code_address & 0xFFFFFFFFFFFF0000L); 
    emitAlignedCode(oc);
    emitCode(Ra);
    emitCode(val & 255);
    emitCode((val >> 8) & 255);
    emitCode((disp >> 16) & 31);
}

// ---------------------------------------------------------------------------
// brnz r1,label
// ---------------------------------------------------------------------------

void process_bra(int oc)
{
    int64_t val;
    int64_t disp;

    val = expr();
    disp = (val & 0xFFFFFFFFFFFF0000L) - (code_address & 0xFFFFFFFFFFFF0000L); 
    emitAlignedCode(oc);
    emitCode(0x00);
    emitCode(val & 255);
    emitCode((val >> 8) & 255);
    emitCode((disp >> 16) & 31);
}

// ---------------------------------------------------------------------------
// jmp main
// jsr [r19]
// jmp (tbl,r2)
// ---------------------------------------------------------------------------

void process_jmp(int oc)
{
    int64_t addr;
    int Ra;

    NextToken();
    // Memory indirect ?
    if (token=='(' || token=='[') {
       Ra = getRegister();
       if (Ra==-1) {
           NextToken();
           addr = expr();
           prevToken();
           if (token==',') {
               Ra = getRegister();
               if (Ra==-1) Ra = 0;
           }
           if (token!=')' && token != ']')
               printf("Missing close bracket.\r\n");
           emitImm24(addr);
           emitAlignedCode(oc+2);
           emitCode(Ra);
           emitCode(addr & 255);
           emitCode((addr >> 8) & 255);
           emitCode((addr >> 16) & 255);
           return;
       }
       // Simple [Rn]
       else {
            if (token != ')' && token!=']')
                printf("Missing close bracket\r\n");
            emitAlignedCode(oc + 4);
            emitCode(Ra);
            emitCode(0x00);
            emitCode(0x00);
            emitCode(0x00);
            return;
       }
    }
    addr = expr();
    prevToken();
    // d(Rn)? 
    if (token=='(' || token=='[') {
        Ra = getRegister();
        if (Ra==-1) {
            printf("Illegal jump address mode.\r\n");
            Ra = 0;
        }
        emitImm24(addr);
        emitAlignedCode(oc+4);
        emitCode(Ra);
        emitCode(addr & 255);
        emitCode((addr >> 8) & 255);
        emitCode((addr >> 16) & 255);
        return;
    }

    emitImm32(addr);
    emitAlignedCode(oc);
    emitCode(addr & 255);
    emitCode((addr >> 8) & 255);
    emitCode((addr >> 16) & 255);
    emitCode((addr >> 24) & 255);
}

// ---------------------------------------------------------------------------
// subui r1,r2,#1234
// ---------------------------------------------------------------------------

void process_riop(int oc)
{
    int Ra;
    int Rt;
    char *p;
    int64_t val;
    
    p = inptr;
    Rt = getRegister();
    need(',');
    Ra = getRegister();
    need(',');
    NextToken();
    val = expr();
    emit16(val);
    emitAlignedCode(oc);
    emitCode(Ra);
    emitCode(Rt);
    emitCode(val & 255);
    emitCode((val >> 8) & 255);
}

// ---------------------------------------------------------------------------
// addu r1,r2,r12
// ---------------------------------------------------------------------------

void process_rrop(int oc)
{
    int Ra;
    int Rb;
    int Rt;
    char *p;

    p = inptr;
    Ra = getRegister();
    need(',');
    Rb = getRegister();
    need(',');
    NextToken();
    if (token=='#') {
        inptr = p;
        switch(oc) {
        case 0x04: process_riop(0x04); return;  // add
        case 0x14: process_riop(0x14); return;  // addu
        case 0x05: process_riop(0x05); return;  // sub
        case 0x15: process_riop(0x15); return;  // subu
        case 0x06: process_riop(0x06); return;  // cmp
        case 0x07: process_riop(0x07); return;  // mul
        case 0x08: process_riop(0x08); return;  // div
        case 0x09: process_riop(0x09); return;  // mod
        case 0x17: process_riop(0x17); return;  // mulu
        case 0x18: process_riop(0x18); return;  // divu
        case 0x19: process_riop(0x19); return;  // modu
        case 0x20: process_riop(0x0C); return;  // and
        case 0x21: process_riop(0x0D); return;  // or
        case 0x22: process_riop(0x0E); return;  // eor
        // Sxx
        case 0x60: process_riop(0x30); return;
        case 0x61: process_riop(0x31); return;
        case 0x68: process_riop(0x38); return;
        case 0x69: process_riop(0x39); return;
        case 0x6A: process_riop(0x3A); return;
        case 0x6B: process_riop(0x3B); return;
        case 0x6C: process_riop(0x3C); return;
        case 0x6D: process_riop(0x3D); return;
        case 0x6E: process_riop(0x3E); return;
        case 0x6F: process_riop(0x3F); return;
        // Shift
        case 0x40: process_shifti(0x50); return;
        case 0x41: process_shifti(0x51); return;
        case 0x42: process_shifti(0x52); return;
        case 0x43: process_shifti(0x53); return;
        case 0x44: process_shifti(0x54); return;
        }
        return;
    }
    prevToken();
    Rt = getRegister();
    prevToken();
    emitAlignedCode(2);
    emitCode(Ra);
    emitCode(Rb);
    emitCode(Rt);
    emitCode(oc);
}

// ---------------------------------------------------------------------------
// not r3,r3
// ---------------------------------------------------------------------------

void process_rop(int oc)
{
    int Ra;
    int Rt;

    Rt = getRegister();
    need(',');
    Ra = getRegister();
    prevToken();
    emitAlignedCode(1);
    emitCode(Ra);
    emitCode(Rt);
    emitCode(0x00);
    emitCode(oc);
}

// ---------------------------------------------------------------------------
// expr
// expr[Reg]
// expr[Reg+Reg*sc]
// [Reg]
// [Reg+Reg*sc]
// ---------------------------------------------------------------------------

void mem_operand(int64_t *disp, int *regA, int *regB, int *sc, int *sg)
{
     int64_t val;

     // chech params
     if (disp == (int64_t *)NULL)
         return;
     if (regA == (int *)NULL)
         return;
     if (regB == (int *)NULL)
         return;
     if (sc==(int *)NULL)
         return;
     if (sg==(int *)NULL)
         return;

     *disp = 0;
     *regA = -1;
     *regB = -1;
     *sc = 0;
     *sg = 1;
     if (token!='[') {;
          val = expr();
          *disp = val;
     }
     if (token=='[') {
         *regA = getRegister();
         if (*regA == -1) {
             printf("expecting a register\r\n");
         }
         if (*regA==255 || *regA==253)
            *sg = 2;
         else if (*regA==254 || *regA==252)
            *sg = 0;
//         NextToken();
         if (token=='+') {
              *sc = 0;
              *regB = getRegister();
              if (*regB == -1) {
                  printf("expecting a register\r\n");
              }
              if (token=='*') {
                  NextToken();
                  val = expr();
                  prevToken();
//                  if (token!=tk_icon) {
//                      printf("expecting a scaling factor.\r\n");
//                      printf("token %d %c\r\n", token, token);
//                  }
                  switch(val) {
                  case 0: *sc = 0; break;
                  case 1: *sc = 0; break;
                  case 2: *sc = 1; break;
                  case 4: *sc = 2; break;
                  case 8: *sc = 3; break;
                  default: printf("Illegal scaling factor.\r\n");
                  }
              }
         }
         need(']');
     }
}

// ---------------------------------------------------------------------------
// sw disp[r1],r2
// sw [r1+r2],r3
// ----------------------------------------------------------------------------

void process_store(int oc)
{
    int Ra;
    int Rb;
    int Rs;
    int sc;
    int sg;
    int64_t disp;

    Rs = getRegister();
    expect(',');
    mem_operand(&disp, &Ra, &Rb, &sc, &sg);
    if (segprefix >= 0)
       sg = segprefix;
    if (Rs < 0) {
        printf("Expecting a source register.\r\n");
        ScanToEOL();
        return;
    }
    if (Rb > 0) {
       emitImm4(disp);
       emitAlignedCode(oc + 8);
       emitCode(Ra);
       emitCode(Rb);
       emitCode(Rs);
       emitCode((disp << 4) | sc | ((sg & 3) << 2));
       return;
    }
    if (disp < 0xFFFFFFFFFFFFE000L || disp > 0x1FFFL)
       emit14(disp);
    emitAlignedCode(oc);
    if (Ra < 0) Ra = 0;
    emitCode(Ra);
    emitCode(Rs);
    emitCode(((disp << 2) & 0xFC) | (sg & 3));
    emitCode((disp >> 6) & 255);
    ScanToEOL();
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void process_ldi(int oc)
{
    int Rt;
    int64_t val;

    Rt = getRegister();
    expect(',');
    val = expr();
    emitImm24(val);
    emitAlignedCode(oc);
    emitCode(Rt);
    emitCode(val & 255);
    emitCode((val >> 8) & 255);
    emitCode((val >> 24) & 255);
}

// ----------------------------------------------------------------------------
// lw r1,disp[r2]
// lw r1,[r2+r3]
// ----------------------------------------------------------------------------

void process_load(int oc)
{
    int Ra;
    int Rb;
    int Rt;
    int sc;
    int sg;
    char *p;
    int64_t disp;

    p = inptr;
    Rt = getRegister();
    if (Rt < 0) {
        printf("Expecting a target register.\r\n");
//        printf("Line:%.60s\r\n",p);
        ScanToEOL();
        inptr-=2;
        return;
    }
    expect(',');
    mem_operand(&disp, &Ra, &Rb, &sc, &sg);
    if (segprefix >= 0)
        sg = segprefix;
    if (Rb >= 0) {
       emitImm4(disp);
       if (oc==0x87) {
          printf("Address mode not supported.\r\n");
          return;
       }
       if (oc==0x92) oc = 0x8F;  // LEA
       else oc = oc + 8;
       emitAlignedCode(oc);
       emitCode(Ra);
       emitCode(Rb);
       emitCode(Rt);
       emitCode((disp << 4) | sc | ((sg & 3) << 2));
       return;
    }
    if (disp < 0xFFFFFFFFFFFFE000L || disp > 0x1FFF)
       emit14(disp);
    emitAlignedCode(oc);
    if (Ra < 0) Ra = 0;
    emitCode(Ra);
    emitCode(Rt);
    emitCode(((disp << 2) & 0xFC) | (sg & 3));
    emitCode((disp >> 6) & 255);
    ScanToEOL();
}

// ----------------------------------------------------------------------------
// lmr r1,r12,[r252]
// ----------------------------------------------------------------------------

void process_lmr(int oc)
{
    int Ra;
    int Rb;
    int Rc;
    
    Ra = getRegister();
    need(',');
    Rb = getRegister();
    need(',');
    NextToken();
    if (token=='[') {
        Rc = getRegister();
        need(']');
    }
    else
        Rc = getRegister();
    emitAlignedCode(0x02);
    emitCode(Ra);
    emitCode(Rb);
    emitCode(Rc);
    emitCode(oc);
}

// ----------------------------------------------------------------------------
// Process a public declaration.
//     public code myfn
// ----------------------------------------------------------------------------

void process_public()
{
    SYM *sym;
    int64_t ca;

    ca = code_address;
    if ((ca & 15)==15)
        ca++;
    NextToken();
    if (token==tk_code) {
        segment = codeseg;
    }
    else if (token==tk_rodata) {
         segment = rodataseg;
    }
    else if (token==tk_data) {
         segment = dataseg;
    }
    NextToken();
    if (token != tk_id) {
        printf("Identifier expected. Token %d\r\n", token);
        printf("Line:%.60s", stptr);
    }
    else {
        sym = find_symbol(lastid);
        if (pass == 3) {
            if (sym) {
                if (sym->defined)
                    printf("Symbol already defined.\r\n");
            }
            else {
                sym = new_symbol(lastid);
            }
            if (sym) {
                sym->defined = 1;
                sym->value = ca;
                sym->segment = segment;
            }
        }
        else if (pass > 3) {
             if (sym->value != ca) {
                phasing_errors++;
                sym->phaserr = '*';
                 if (bGen) printf("%s=%06llx ca=%06llx\r\n", sym->name,  sym->value, code_address);
             }
             else
                 sym->phaserr = ' ';
            sym->value = ca;
        }
        strcpy(current_label, lastid);
    }
    ScanToEOL();
}

// ----------------------------------------------------------------------------
// extern somefn
// ----------------------------------------------------------------------------

void process_extern()
{
    NextToken();
    if (token != tk_id)
        printf("Expecting an identifier.\r\n");
}

// ----------------------------------------------------------------------------
// push r1/r2/r3/r4
// push #123
// ----------------------------------------------------------------------------

void process_pushpop(int oc)
{
    int Ra,Rb,Rc,Rd;
    int64_t val;

    Ra = -1;
    Rb = -1;
    Rc = -1;
    Rd = -1;
    NextToken();
    if (token=='#' && oc==0xA6) {  // Filter to PUSH
       val = expr();
       emitImm32(val);
       emitAlignedCode(0xAD);                        
       emitCode(val & 255);
       emitCode((val >> 8) & 255);
       emitCode((val >> 16) & 255);
       emitCode((val >> 24) & 255);
    }
    else {
        prevToken();
        Ra = getRegister();
        if (token=='/' || token==',') {
            Rb = getRegister();
            if (token=='/' || token==',') {
                Rc = getRegister();
                if (token=='/' || token==',') {
                    Rd = getRegister();
                }
            }
        }
        prevToken();
        emitAlignedCode(oc);
        emitCode(Ra>=0 ? Ra : 0);
        emitCode(Rb>=0 ? Rb : 0);
        emitCode(Rc>=0 ? Rc : 0);
        emitCode(Rd>=0 ? Rd : 0);
    }
}
 
// ----------------------------------------------------------------------------
// mov r1,r2
// ----------------------------------------------------------------------------

void process_mov(int oc)
{
     int Ra;
     int Rt;
     
     Rt = getRegister();
     need(',');
     Ra = getRegister();
     emitAlignedCode(0x01);
     emitCode(Ra);
     emitCode(Rt);
     emitCode(0x00);
     emitCode(oc);
     prevToken();
}

// ----------------------------------------------------------------------------
// .org $23E200
// ----------------------------------------------------------------------------

void process_org()
{
    int64_t new_address;

    NextToken();
    new_address = expr();
    if (first_org)
       code_address = new_address;
    else {
        while(code_address < new_address)
            emitByte(0x00);
    }
    first_org = 0;
    ScanToEOL();
}

// ----------------------------------------------------------------------------
// rts
// rts #24
// ----------------------------------------------------------------------------

void process_rts(int oc)
{
     int64_t val;

     val = 0;
     NextToken();
     if (token=='#') {
        val = expr();
     }
     emitAlignedCode(oc);
     emitCode(0x00);
     emitCode(val & 255);
     emitCode((val >> 8) & 255);
     emitCode(0x00);
}

// ----------------------------------------------------------------------------
// shli r1,r2,#5
// ----------------------------------------------------------------------------

void process_shifti(int oc)
{
     int Ra;
     int Rt;
     int64_t val;
     
     Rt = getRegister();
     need(',');
     Ra = getRegister();
     need(',');
     NextToken();
     val = expr();
     emitAlignedCode(0x02);
     emitCode(Ra);
     emitCode(val & 63);
     emitCode(Rt);
     emitCode(oc);
}

// ----------------------------------------------------------------------------
// gran r1
// ----------------------------------------------------------------------------

void process_gran()
{
    int Rt;

    Rt = getRegister();
    emitAlignedCode(0x01);
    emitCode(0x00);
    emitCode(Rt);
    emitCode(0x00);
    emitCode(0x00);
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void process_align()
{
    int64_t v;
    
    NextToken();
    v = expr();
    while (code_address % v)
        emitByte(0x00);
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void process_db()
{
    int64_t val;

    SkipSpaces();
    //NextToken();
    while(token!=tk_eol) {
        SkipSpaces();
        if (*inptr=='\n') break;
        if (*inptr=='"') {
            inptr++;
            while (*inptr!='"') {
                if (*inptr=='\\') {
                    inptr++;
                    switch(*inptr) {
                    case '\\': emitByte('\\'); inptr++; break;
                    case 'r': emitByte(0x13); inptr++; break;
                    case 'n': emitByte(0x0A); inptr++; break;
                    case 'b': emitByte('\b'); inptr++; break;
                    case '"': emitByte('"'); inptr++; break;
                    default: inptr++; break;
                    }
                }
                else {
                    emitByte(*inptr);
                    inptr++;
                }
            }
        }
        else if (*inptr=='\'') {
            inptr++;
            emitByte(*inptr);
            inptr++;
            if (*inptr!='\'') {
                printf("Missing ' in character constant.\r\n");
            }
        }
        else {
            NextToken();
            val = expr();
            emitByte(val & 255);
            prevToken();
        }
        SkipSpaces();
        if (*inptr!=',')
            break;
        inptr++;
    }
    ScanToEOL();
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void process_dc()
{
    int64_t val;

    SkipSpaces();
    while(token!=tk_eol) {
        SkipSpaces();
        if (*inptr=='"') {
            inptr++;
            while (*inptr!='"') {
                if (*inptr=='\\') {
                    inptr++;
                    switch(*inptr) {
                    case '\\': emitChar('\\'); inptr++; break;
                    case 'r': emitChar(0x13); inptr++; break;
                    case 'n': emitChar(0x0A); inptr++; break;
                    case 'b': emitChar('\b'); inptr++; break;
                    case '"': emitChar('"'); inptr++; break;
                    default: inptr++; break;
                    }
                }
                else {
                    emitChar(*inptr);
                    inptr++;
                }
            }
        }
        else if (*inptr=='\'') {
            inptr++;
            emitChar(*inptr);
            inptr++;
            if (*inptr!='\'') {
                printf("Missing ' in character constant.\r\n");
            }
        }
        else {
             NextToken();
            val = expr();
            emitChar(val);
            prevToken();
        }
        SkipSpaces();
        if (*inptr!=',')
            break;
        inptr++;
    }
    ScanToEOL();
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void process_dh()
{
    int64_t val;

    SkipSpaces();
    while(token!=tk_eol) {
        SkipSpaces();
        if (*inptr=='"') {
            inptr++;
            while (*inptr!='"') {
                if (*inptr=='\\') {
                    inptr++;
                    switch(*inptr) {
                    case '\\': emitHalf('\\'); inptr++; break;
                    case 'r': emitHalf(0x13); inptr++; break;
                    case 'n': emitHalf(0x0A); inptr++; break;
                    case 'b': emitHalf('\b'); inptr++; break;
                    case '"': emitHalf('"'); inptr++; break;
                    default: inptr++; break;
                    }
                }
                else {
                    emitHalf(*inptr);
                    inptr++;
                }
            }
        }
        else if (*inptr=='\'') {
            inptr++;
            emitHalf(*inptr);
            inptr++;
            if (*inptr!='\'') {
                printf("Missing ' in character constant.\r\n");
            }
        }
        else {
             NextToken();
            val = expr();
            emitHalf(val);
            prevToken();
        }
        SkipSpaces();
        if (*inptr!=',')
            break;
        inptr++;
    }
    ScanToEOL();
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void process_dw()
{
    int64_t val;

    SkipSpaces();
    while(token!=tk_eol) {
        SkipSpaces();
        if (*inptr=='"') {
            inptr++;
            while (*inptr!='"') {
                if (*inptr=='\\') {
                    inptr++;
                    switch(*inptr) {
                    case '\\': emitWord('\\'); inptr++; break;
                    case 'r': emitWord(0x13); inptr++; break;
                    case 'n': emitWord(0x0A); inptr++; break;
                    case 'b': emitWord('\b'); inptr++; break;
                    case '"': emitWord('"'); inptr++; break;
                    default: inptr++; break;
                    }
                }
                else {
                    emitWord(*inptr);
                    inptr++;
                }
            }
        }
        else if (*inptr=='\'') {
            inptr++;
            emitWord(*inptr);
            inptr++;
            if (*inptr!='\'') {
                printf("Missing ' in character constant.\r\n");
            }
        }
        else {
             NextToken();
            val = expr();
            emitWord(val);
            prevToken();
        }
        SkipSpaces();
        if (*inptr!=',')
            break;
        inptr++;
    }
    ScanToEOL();
}

// ----------------------------------------------------------------------------
// fill.b 252,0x00
// ----------------------------------------------------------------------------

void process_fill()
{
    char sz = 'b';
    int64_t count;
    int64_t val;
    int64_t nn;

    if (*inptr=='.') {
        inptr++;
        if (strchr("bchwBCHW",*inptr)) {
            sz = tolower(*inptr);
            inptr++;
        }
        else
            printf("Illegal fill size.\r\n");
    }
    SkipSpaces();
    NextToken();
    count = expr();
    prevToken();
    need(',');
    NextToken();
    val = expr();
    prevToken();
    for (nn = 0; nn < count; nn++)
        switch(sz) {
        case 'b': emitByte(val); break;
        case 'c': emitChar(val); break;
        case 'h': emitHalf(val); break;
        case 'w': emitWord(val); break;
        }
}

// ----------------------------------------------------------------------------
// label:
// ----------------------------------------------------------------------------

void process_label()
{
    SYM *sym;
    static char nm[500];
    int64_t ca;
    
    ca = code_address;
    if ((ca & 15)==15)
        ca++;
    if (lastid[0]=='.') {
        sprintf(nm, "%s%s", current_label, lastid);
    }
    else { 
        strcpy(current_label, lastid);
        strcpy(nm, lastid);
    }
    SkipSpaces();
    if (*inptr==':') inptr++;
    sym = find_symbol(nm);
    if (pass==3) {
        if (sym) {
            if (sym->defined) {
                printf("Label already defined.\r\n");
            }
            sym->defined = 1;
            sym->value = ca;
            sym->segment = codeseg;
        }
        else {
            sym = new_symbol(nm);    
            sym->defined = 1;
            sym->value = ca;
            sym->segment = codeseg;
        }
    }
    else if (pass>3) {
         if (!sym)
            printf("Internal error: SYM is NULL.\r\n");
         else {
             if (sym->value != ca) {
                 phasing_errors++;
                 sym->phaserr = '*';
                 if (bGen) printf("%s=%06llx ca=%06llx\r\n", sym->name,  sym->value, code_address);
             }
             else
                 sym->phaserr = ' ';
             sym->value = ca;
         }
    }
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void process_mtspr(int oc)
{
    int spr;
    int Ra;
    
    spr = getSprRegister();
    need(',');
    Ra = getRegister();
    emitAlignedCode(0x01);
    emitCode(Ra);
    emitCode(spr);
    emitCode(0x00);
    emitCode(oc);
    if (Ra >= 0)
    prevToken();
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void process_mfspr(int oc)
{
    int spr;
    int Rt;
    
    Rt = getRegister();
    need(',');
    spr = getSprRegister();
    emitAlignedCode(0x01);
    emitCode(spr);
    emitCode(Rt);
    emitCode(0x00);
    emitCode(oc);
    if (spr >= 0)
    prevToken();
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void processMaster()
{
    int nn,mm;
    int64_t ca;
    int first;
    int64_t bs1, bs2;

    lineno = 1;
    binndx = 0;
    binstart = 0;
    bs1 = 0;
    bs2 = 0;
    inptr = &masterFile[0];
    stptr = inptr;
    code_address = 0;
    first_org = 1;
    ca = code_address;
    memset(current_label,0,sizeof(current_label));
    NextToken();
    while (token != tk_eof) {
//        printf("%d\r", lineno);
        switch(token) {
        case tk_eol:
             segprefix = -1;
             if (bGen && (segment==codeseg || segment==dataseg || segment==rodataseg)) {
             if ((ca & 15)==15) {
                 ca++;
                 binstart++;
             }
            nn = binstart;
            if (binfile[binstart]==0xfd) {
                fprintf(ofp, "%06x ", ca);
                for (nn = binstart; nn < binstart + 5 && nn < binndx; nn++) {
                    fprintf(ofp, "%02x ", binfile[nn]);
                }
                fprintf(ofp, "   ; imm\n");
                 if (((ca+5) & 15)==15) {
                     ca+=6;
                     binstart+=6;
                     nn++;
                 }
                 else {
                      ca += 5;
                      binstart += 5;
                 }
            }
             if (binfile[binstart]==0xfe) {
                fprintf(ofp, "%06x ", ca);
                for (nn = binstart; nn < binstart + 5 && nn < binndx; nn++) {
                    fprintf(ofp, "%02x ", binfile[nn]);
                }
                fprintf(ofp, "   ; imm\n");
                 if (((ca+5) & 15)==15) {
                     ca+=6;
                     nn++;
                 }
                 else {
                      ca += 5;
                 }
            }
            first = 1;
            while (nn < binndx) {
                fprintf(ofp, "%06x ", ca);
                for (mm = nn; nn < mm + 8 && nn < binndx; nn++) {
                    fprintf(ofp, "%02x ", binfile[nn]);
                }
                for (; nn < mm + 8; nn++)
                    fprintf(ofp, "   ");
                if (first) {
                    fprintf(ofp, "\t%.*s\n", inptr-stptr-1, stptr);
                    first = 0;
                }
                else
                    fprintf(ofp, "\n");
                ca += 8;
            }
            // empty (codeless) line
            if (binstart==binndx) {
                fprintf(ofp, "%24s\t%.*s\n", "", inptr-stptr, stptr);
            }
            } // bGen
            binstart = binndx;
            stptr = inptr;
            ca = code_address;
            lineno++;
            break;
        case tk_add:  process_rrop(0x04); break;
        case tk_addi: process_riop(0x04); break;
        case tk_addu: process_rrop(0x14); break;
        case tk_addui: process_riop(0x14); break;
        case tk_align: process_align(); continue; break;
        case tk_and:  process_rrop(0x20); break;
        case tk_andi:  process_riop(0x0C); break;
        case tk_asr:  process_rrop(0x44); break;
        case tk_asri: process_shifti(0x54); break;
        case tk_beq: process_bcc(0x40); break;
        case tk_bge: process_bcc(0x4A); break;
        case tk_bgeu: process_bcc(0x4E); break;
        case tk_bgt: process_bcc(0x48); break;
        case tk_bgtu: process_bcc(0x4C); break;
        case tk_ble: process_bcc(0x49); break;
        case tk_bleu: process_bcc(0x4D); break;
        case tk_blt: process_bcc(0x4B); break;
        case tk_bltu: process_bcc(0x4F); break;
        case tk_bmi: process_bcc(0x44); break;
        case tk_bne: process_bcc(0x41); break;
        case tk_bpl: process_bcc(0x45); break;
        case tk_bra: process_bra(0x46); break;
        case tk_brnz: process_bcc(0x59); break;
        case tk_brz:  process_bcc(0x58); break;
        case tk_bvc: process_bcc(0x43); break;
        case tk_bvs: process_bcc(0x42); break;
        case tk_bss: segment = bssseg; break;
        case tk_cli: emit_insn(0x3100000001); break;
        case tk_cmp: process_rrop(0x06); break;
        case tk_code: segment = codeseg; break;
        case tk_com: process_rop(0x06); break;
        case tk_cs:  segprefix = 0; break;
        case tk_db:  process_db(); break;
        case tk_dbnz: process_bcc(0x5A); break;
        case tk_dc:  process_dc(); break;
        case tk_dh:  process_dh(); break;
        case tk_div: process_rrop(0x08); break;
        case tk_divu: process_rrop(0x18); break;
        case tk_ds:  segprefix = 1; break;
        case tk_dw:  process_dw(); break;
        case tk_end: goto j1;
        case tk_endpublic: break;
        case tk_eor: process_rrop(0x22); break;
        case tk_eori: process_riop(0x0E); break;
        case tk_extern: process_extern(); break;
        case tk_fill: process_fill(); break;
        case tk_gran: process_gran(0x14); break;
        case tk_jmp: process_jmp(0x50); break;
        case tk_jsr: process_jmp(0x51); break;
        case tk_lb:  process_load(0x80); break;
        case tk_lbu: process_load(0x81); break;
        case tk_lc:  process_load(0x82); break;
        case tk_lcu: process_load(0x83); break;
        case tk_ldi: process_ldi(0x16); break;
        case tk_lea: process_load(0x92); break;
        case tk_lh:  process_load(0x84); break;
        case tk_lhu: process_load(0x85); break;
        case tk_lmr: process_lmr(0x31); break;
        case tk_lw:  process_load(0x86); break;
        case tk_mfspr: process_mfspr(0x49); break;
        case tk_mod: process_rrop(0x09); break;
        case tk_modu: process_rrop(0x19); break;
        case tk_mov: process_mov(0x04); break;
        case tk_mtspr: process_mtspr(0x48); break;
        case tk_mul: process_rrop(0x07); break;
        case tk_muli: process_riop(0x07); break;
        case tk_mulu: process_rrop(0x17); break;
        case tk_mului: process_riop(0x17); break;
        case tk_neg: process_rop(0x05); break;
        case tk_not: process_rop(0x07); break;
        case tk_or:  process_rrop(0x21); break;
        case tk_ori: process_riop(0x0D); break;
        case tk_org: process_org(); break;
        case tk_pop:  process_pushpop(0xA7); break;
        case tk_public: process_public(); break;
        case tk_push: process_pushpop(0xA6); break;
        case tk_rol: process_rrop(0x41); break;
        case tk_ror: process_rrop(0x443); break;
        case tk_rti: emit_insn(0x4000000001); break;
        case tk_rts: process_rts(0x60); break;
        case tk_sb:  process_store(0xa0); break;
        case tk_sc:  process_store(0xa1); break;
        case tk_sei: emit_insn(0x3000000001); break;
        case tk_seq:  process_rrop(0x60); break;
        case tk_seqi: process_riop(0x30); break;
        case tk_sge:  process_rrop(0x6A); break;
        case tk_sgt:  process_rrop(0x68); break;
        case tk_sle:  process_rrop(0x69); break;
        case tk_slt:  process_rrop(0x6B); break;
        case tk_sgeu:  process_rrop(0x6E); break;
        case tk_sgtu:  process_rrop(0x6C); break;
        case tk_sleu:  process_rrop(0x6D); break;
        case tk_sltu:  process_rrop(0x6F); break;
        case tk_sgei:  process_rrop(0x3A); break;
        case tk_sgti:  process_rrop(0x38); break;
        case tk_slei:  process_rrop(0x39); break;
        case tk_slti:  process_rrop(0x3B); break;
        case tk_sgeui:  process_rrop(0x3E); break;
        case tk_sgtui:  process_rrop(0x3C); break;
        case tk_sleui:  process_rrop(0x3D); break;
        case tk_sltui:  process_rrop(0x3F); break;
        case tk_sne:  process_rrop(0x61); break;
        case tk_snei: process_riop(0x31); break;
        case tk_sh:  process_store(0xa2); break;
        case tk_shl:  process_rrop(0x40); break;
        case tk_shli: process_shifti(0x50); break;
        case tk_shru: process_rrop(0x42); break;
        case tk_shrui: process_shifti(0x52); break;
        case tk_smr: process_lmr(0x30); break;
        case tk_ss:  segprefix = 2; break;
        case tk_sub:  process_rrop(0x05); break;
        case tk_subi: process_riop(0x05); break;
        case tk_subu: process_rrop(0x15); break;
        case tk_subui: process_riop(0x15); break;
        case tk_sxb: process_rop(0x08); break;
        case tk_sxc: process_rop(0x09); break;
        case tk_sxh: process_rop(0x0A); break;
        case tk_sw:  process_store(0xa3); break;
        case tk_id:  process_label(); break;
        case tk_xor: process_rrop(0x22); break;
        case tk_xori: process_riop(0x0E); break;
        }
        NextToken();
    }
j1:
    ;
}

// ----------------------------------------------------------------------------
// Group and reorder the segments in the master file.
//     code          placed first
//     rodata        followed by
//     data
//     tls
// ----------------------------------------------------------------------------

void processSegments()
{
    char *pinptr;
    int segment;
    
    if (verbose)
       printf("Processing segments.\r\n");
    inptr = &masterFile[0];
    pinptr = inptr;
    codendx = 0;
    datandx = 0;
    rodatandx = 0;
    tlsndx = 0;
    memset(codebuf,0,sizeof(codebuf));
    memset(databuf,0,sizeof(databuf));
    memset(rodatabuf,0,sizeof(rodatabuf));
    memset(tlsbuf,0,sizeof(tlsbuf));
    
    while (*inptr) {
        SkipSpaces();
        if (*inptr=='.') inptr++;
        if ((strnicmp(inptr,"code",4)==0) && !isIdentChar(inptr[4])) {
            segment = codeseg;
        }
        else if ((strnicmp(inptr,"data",4)==0) && !isIdentChar(inptr[4])) {
            segment = dataseg;
        }
        else if ((strnicmp(inptr,"rodata",6)==0) && !isIdentChar(inptr[6])) {
            segment = rodataseg;
        }
        else if ((strnicmp(inptr,"tls",3)==0) && !isIdentChar(inptr[3])) {
            segment = tlsseg;
        }
        ScanToEOL();
        inptr++;
        switch(segment) {
        case codeseg:   
             strncpy(&codebuf[codendx], pinptr, inptr-pinptr);
             codendx += inptr-pinptr;
             break;
        case dataseg:
             strncpy(&databuf[datandx], pinptr, inptr-pinptr);
             datandx += inptr-pinptr;
             break;
        case rodataseg:
             strncpy(&rodatabuf[rodatandx], pinptr, inptr-pinptr);
             rodatandx += inptr-pinptr;
             break;
        case tlsseg:
             strncpy(&tlsbuf[tlsndx], pinptr, inptr-pinptr);
             tlsndx += inptr-pinptr;
             break;
        }
        pinptr = inptr;
    }
    memset(masterFile,0,sizeof(masterFile));
    strcpy(masterFile, codebuf);
    strcat(masterFile, rodatabuf);
    strcat(masterFile, "\r\n.align 4096\r\n");
    strcat(masterFile, databuf);
    strcat(masterFile, "\r\n.align 4096\r\n");
    strcat(masterFile, tlsbuf);
    if (debug) {
        FILE *fp;
        fp = fopen("a64-segments.asm", "w");
        if (fp) {
                fwrite(masterFile, 1, strlen(masterFile), fp);
                fclose(fp);
        }
    }
}

// ----------------------------------------------------------------------------
// Look for .include directives and include the files.
// ----------------------------------------------------------------------------

void processLine(char *line)
{
    char *p;
    int quoteType;
    static char fnm[300];
    char *fname;
    int nn;

    p = line;
    while(isspace(*p)) p++;
    if (!*p) goto addToMaster;
    // see if the first thing on the line is an include directive
    if (*p=='.') p++;
    if (strnicmp(p, "include", 7)==0 && !isIdentChar(p[7]))
    {
        p += 7;
        // Capture the file name
        while(isspace(*p)) p++;
        if (*p=='"') { quoteType = '"'; p++; }
        else if (*p=='<') { quoteType = '>'; p++; }
        else quoteType = ' ';
        nn = 0;
        do {
           fnm[nn] = *p;
           p++; nn++;
           if (quoteType==' ' && isspace(*p)) break;
           else if (*p == quoteType) break;
           else if (*p=='\n') break;
        } while(nn < sizeof(fnm)/sizeof(char));
        fnm[nn] = '\0';
        fname = strdup(fnm);
        processFile(fname,1);
        free(fname);
        return;
    }
    // Not an include directive, then just copy the line to the master buffer.
addToMaster:
    strcpy(&masterFile[mfndx], line);
    mfndx += strlen(line);
}

// ----------------------------------------------------------------------------
// Build a aggregate of all the included files into a single master buffer.
// ----------------------------------------------------------------------------

void processFile(char *fname, int searchincl)
{
     FILE *fp;
     char *pathname;

     if (verbose)
        printf("Processing file:%s\r\n", fname);
     pathname = (char *)NULL;
     fp = fopen(fname, "r");
     if (!fp) {
         if (searchincl) {
             searchenv(fname, "INCLUDE", &pathname);
             if (strlen(pathname)) {
                 fp = fopen(pathname, "r");
                 if (fp) goto j1;
             }
         }
         printf("Can't open file <%s>\r\n", fname);
         goto j2;
     }
j1:
     while (!feof(fp)) {
         fgets(buf, sizeof(buf)/sizeof(char), fp);
         processLine(buf);
     }
     fclose(fp);
j2:
     if (pathname)
         free(pathname);
}


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

int main(int argc, char *argv[])
{
    int nn;
    static char fname[500];
    char *p;

    ofp = stdout;
    nn = processOptions(argc, argv);
    if (nn > argc-1) {
       displayHelp();
       return 0;
    }
    strcpy(fname, argv[nn]);
    mfndx = 0;
    code_address = 0;
    memset(masterFile,0,sizeof(masterFile));
    if (verbose) printf("Pass 1 - collect all input files.\r\n");
    processFile(fname,0);   // Pass 1, collect all include files
    if (debug) {
        FILE *fp;
        fp = fopen("a64-master.asm", "w");
        if (fp) {
                fwrite(masterFile, 1, strlen(masterFile), fp);
                fclose(fp);
        }
    }
    if (verbose) printf("Pass 2 - group and reorder segments\r\n");
    processSegments();     // Pass 2, group and order segments
    ofp = fopen("a64-lst.lst","w");
    pass = 3;
    if (verbose) printf("Pass 3 - get all symbols, set initial values.\r\n");
    processMaster();       // Pass 3, get all symbols, set initial values
    pass = 4;
    phasing_errors = 0;
    if (verbose) printf("Pass 4 - assemble code.\r\n");
    processMaster();       // Pass 4, first try at code
    if (verbose) printf("Pass 4: phase errors: %d\r\n", phasing_errors);
    pass = 5;
    while (phasing_errors && pass < 10) {
        phasing_errors = 0;
        processMaster();       // Pass 5, first try at code
        if (verbose) printf("Pass %d: phase errors: %d\r\n", pass, phasing_errors);
        pass++;
    }
    bGen = 1;
    processMaster();       // last pass, generate output
    DumpSymbols();
    fclose(ofp);
    strcpy(fname, argv[nn]);
    p = strrchr(fname,'.');
    if (p) {
        *p = '\0';
    }
    strcat(fname, ".bin");
    ofp = fopen(fname,"wb");
    fwrite(binfile,binndx,1,ofp);
    fclose(ofp);    
    return 0;
}
