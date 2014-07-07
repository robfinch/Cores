#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "a64.h"
#include "token.h"
#include "symbol.h"

#define MAX_PASS  6

int gCpu = 888;
int verbose = 0;
int debug = 1;
int listing = 1;
int binary_out = 1;
int verilog_out = 1;
int pass;
int lineno;
char *inptr;
char *stptr;
int token;
int phasing_errors;
int bGen = 0;
int segment;
int segprefix = -1;
int64_t code_address;
int64_t data_address;
int64_t bss_address;
int64_t start_address;
FILE *ofp, *vfp;
int regno;
char current_label[500];
char first_org = 1;

char buf[10000];
char masterFile[10000000];
char segmentFile[10000000];
char codebuf[10000000];
char databuf[10000000];
char rodatabuf[10000000];
char tlsbuf[10000000];
char bssbuf[10000000];
uint8_t binfile[10000000];
int binndx;
int binstart;
int mfndx;
int codendx;
int datandx;
int rodatandx;
int tlsndx;
int bssndx;

void emitCode(int cd);
void emitAlignedCode(int cd);
void process_shifti(int oc);
void processFile(char *fname, int searchincl);
void bump_address();

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

void displayHelp()
{
     printf("a64 [options] file\r\n");
     printf("    +v      = verbose output\r\n");
     printf("    -o[bvl] = suppress output file b=binary, v=verilog, l=listing\\r\n");
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

int processOptions(int argc, char **argv)
{
    int nn, mm;
    
    nn = 1;
    do {
        if (nn >= argc-1)
           break;
        if (argv[nn][0]=='-') {
           if (argv[nn][1]=='o') {
               mm = 2;
               while(argv[nn][mm] && !isspace(argv[nn][mm])) {
                   if (argv[nn][mm]=='b')
                       binary_out = 0;
                   else if (argv[nn][mm]=='l')
                       listing = 0;
                   else if (argv[nn][mm]=='v')
                       verilog_out = 0;
               }
           }
           nn++;
        }
        else break;
    } while (1);
    return nn;
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

void emitByte(int64_t cd)
{
    if (segment == codeseg || segment == dataseg || segment == rodataseg) {
        binfile[binndx] = cd & 255LL;
        binndx++;
    }
    if (segment==bssseg) {
       bss_address++;
    }
    else
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

void emitCode(int cd)
{
     emitByte(cd);
}

// ----------------------------------------------------------------------------
// Process a public declaration.
//     public code myfn
// ----------------------------------------------------------------------------

void process_public()
{
    SYM *sym;
    int64_t ca;

    bump_address();
    if (segment==bssseg)
        ca = bss_address;
    else
        ca = code_address;
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
    else if (token==tk_bss) {
         segment = bssseg;
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
// .org $23E200
// ----------------------------------------------------------------------------

void process_org()
{
    int64_t new_address;

    NextToken();
    new_address = expr();
    if (segment==bssseg) {
        bss_address = new_address;
    }
    else {
        if (first_org && segment==codeseg) {
           code_address = new_address;
           start_address = new_address;
           first_org = 0;
        }
        else {
            while(code_address < new_address)
                emitByte(0x00);
        }
    }
    ScanToEOL();
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void process_align()
{
    int64_t v;
    
    NextToken();
    v = expr();
    if (segment==bssseg) {
        while (bss_address % v)
            emitByte(0x00);
    }
    else {
        while (code_address % v)
            emitByte(0x00);
    }
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
            inptr++;
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
            inptr++;
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
            inptr++;
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
            inptr++;
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
// Bump up the address to the next aligned code address.
// ----------------------------------------------------------------------------

void bump_address()
{
     if (gCpu==888)
        Table888_bump_address();
}

// ----------------------------------------------------------------------------
// label:
// ----------------------------------------------------------------------------

void process_label()
{
    SYM *sym;
    static char nm[500];
    int64_t ca;
    int64_t val;
    int isEquate;
    
    isEquate = 0;
    // Bump up the address to align it with a valid code address if needed.
    bump_address();
    if (segment==bssseg)
       ca = bss_address;
    else
        ca = code_address;
    if (lastid[0]=='.') {
        sprintf(nm, "%s%s", current_label, lastid);
    }
    else { 
        strcpy(current_label, lastid);
        strcpy(nm, lastid);
    }
    NextToken();
//    SkipSpaces();
    if (token==tk_equ || token=='=') {
        NextToken();
        val = expr();
        isEquate = 1;
    }
    else prevToken();
//    if (token==tk_eol)
//       prevToken();
    //else if (token==':') inptr++;
    sym = find_symbol(nm);
    if (pass==3) {
        if (sym) {
            if (sym->defined) {
                if (sym->value != val) {
                    printf("Label %s already defined.\r\n", nm);
                    printf("Line %d: %.60s\r\n", lineno, stptr);
                }
            }
            sym->defined = 1;
            if (isEquate) {
                sym->value = val;
                sym->segment = constseg;
            }
            else {
                sym->value = ca;
                sym->segment = segment;
            }
        }
        else {
            sym = new_symbol(nm);    
            sym->defined = 1;
            if (isEquate) {
                sym->value = val;
                sym->segment = constseg;
            }
            else {
                sym->value = ca;
                sym->segment = segment;
            }
        }
    }
    else if (pass>3) {
         if (!sym)
            printf("Internal error: SYM is NULL.\r\n");
         else {
             if (isEquate) {
                 sym->value = val;
             }
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
    bssndx = 0;
    memset(codebuf,0,sizeof(codebuf));
    memset(databuf,0,sizeof(databuf));
    memset(rodatabuf,0,sizeof(rodatabuf));
    memset(tlsbuf,0,sizeof(tlsbuf));
    memset(bssbuf,0,sizeof(bssbuf));
    
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
        else if ((strnicmp(inptr,"bss",3)==0) && !isIdentChar(inptr[3])) {
            segment = bssseg;
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
        case bssseg:
             strncpy(&bssbuf[bssndx], pinptr, inptr-pinptr);
             bssndx += inptr-pinptr;
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
    strcat(masterFile, bssbuf);
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

int checksum(int32_t *val)
{
    int nn;
    int cs;

    cs = 0;
    for (nn = 0; nn < 32; nn++)
        cs ^= (*val & (1 << nn))!=0;
    return cs;
}


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void processMaster()
{
    if (gCpu==888)
       Table888_processMaster();
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
    bss_address = 0;
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
    
    pass = 3;
    if (verbose) printf("Pass 3 - get all symbols, set initial values.\r\n");
    processMaster();
    pass = 4;
    phasing_errors = 0;
    if (verbose) printf("Pass 4 - assemble code.\r\n");
    processMaster();
    if (verbose) printf("Pass 4: phase errors: %d\r\n", phasing_errors);
    pass = 5;
    while (phasing_errors && pass < 10) {
        phasing_errors = 0;
        processMaster();
        if (verbose) printf("Pass %d: phase errors: %d\r\n", pass, phasing_errors);
        pass++;
    }
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Output listing file.
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (listing) {
        strcpy(fname, argv[nn]);
        p = strrchr(fname,'.');
        if (p) {
            *p = '\0';
        }
        strcat(fname, ".lst");
        ofp = fopen(fname,"w");
        bGen = 1;
    }
    processMaster();
    DumpSymbols();
    if (listing)
        fclose(ofp);
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Output binary file.
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (binary_out) {
        strcpy(fname, argv[nn]);
        p = strrchr(fname,'.');
        if (p) {
            *p = '\0';
        }
        strcat(fname, ".bin");
        ofp = fopen(fname,"wb");
        if (ofp) {
            fwrite(binfile,binndx,1,ofp);
            fclose(ofp);    
        }
        else
            printf("Can't create .bin file.\r\n");
    }
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Output Verilog memory declaration
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (verilog_out) {
        strcpy(fname, argv[nn]);
        p = strrchr(fname,'.');
        if (p) {
            *p = '\0';
        }
        strcat(fname, ".ver");
        vfp = fopen(fname, "w");
        if (vfp) {
            for (nn = 0; nn < binndx; nn+=4) {
                fprintf(vfp, "\trommem[%d] = 33'h%01d%02X%02X%02X%02X;\n", 
                    (((start_address+nn)/4)%8192), checksum((int32_t *)&binfile[nn]), binfile[nn+3], binfile[nn+2], binfile[nn+1], binfile[nn]);
            }
            fclose(vfp);
        }
        else
            printf("Can't create .ver file.\r\n");
    }
    return 0;
}
