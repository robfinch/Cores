#define TRUE    1
#define FALSE   0
#define RR      2
#define MTSPR       0x1E
#define MFSPR       0x1F
#define PCTRL       0x37
#define CLI             0x00
#define SEI             0x01
#define WAI             0x03
#define RTD             0x1D
#define RTE             0x1E
#define RTI             0x1F
#define ADD     4
#define SUB     5
#define CMP     6
#define MUL     7
#define DIV     8
#define MOD     9
#define LDI     0x0A
#define AND     12
#define OR      13
#define EOR     14
#define ADDU    0x14
#define SUBU    0x15
#define CMPU    0x16
#define MULU    0x17
#define DIVU    0x18
#define MODU    0x19
#define Bcc     0x3D
#define BEQ         0
#define BNE         1
#define BGT         2
#define BGE         3
#define BLT         4
#define BLE         5
#define RTL     0x37
#define BSR     0x39
#define BRA     0x3A
#define RTS     0x3B
#define NOP     0x3F
#define LB      0x40
#define LBU     0x41
#define LC      0x42
#define LCU     0x43
#define LH      0x44
#define LHU     0x45
#define LW      0x46
#define LWAR    0x5C
#define SB      0x60
#define SC      0x61
#define SH      0x62
#define SW      0x63
#define PUSH    0x67
#define POP     0x57
#define SWCR    0x6E
#define IMM     0x7C

extern pascal putstr2(char *);

void SetCurAttr(unsigned short int attr)
{
     asm {
         lw    r1,24[bp]
         bsr   SetCurrAttr
     }
}

void reverse_video() {
    unsigned short int attr;
    attr = GetCurrAttr();
    attr = ((attr >> 10) << 19) | ((attr >> 19) << 10);
    SetCurAttr(attr);
}

void DumpInsnBytes(unsigned int ad, unsigned int ir)
{
     printf("%06X %02X %02X %02X %02X\t", ad, (ir & 0xff), ((ir >> 8) & 0xFF), ((ir >> 16) & 0xFF),((ir>>24)&0xFF));
}

static void DispRst(ir) {
    printf("r%d", ((ir >> 12) & 0x1F));
}

static void DispRstc(ir) {
    printf("R%d,", ((ir >> 12) & 0x1F));
}

static void DispRac(ir) {
    printf("R%d,", ((ir >> 7) & 0x1F));
}

static void DispRa(ir) {
    printf("R%d", ((ir >> 7) & 0x1F));
}

static void DispRb(ir) {
    printf("R%d,", ((ir >> 17) & 0x1F));
}

static void DispSpr(int ir)
{
    int nn;
    
    nn = (ir >> 17) & 0xFF;
    switch(nn) {
    case 0: printf("CR0"); break;
    case 3: printf("CR3"); break;
    case 6: printf("CLK"); break;
    case 7: printf("DPC"); break;
    case 8: printf("IPC"); break;
    case 9: printf("EPC"); break;
    case 10: printf("VBR"); break;
    case 50: printf("DBAD0"); break;
    case 51: printf("DBAD1"); break;
    case 52: printf("DBAD2"); break;
    case 53: printf("DBAD3"); break;
    case 54: printf("DBCTRL"); break;
    case 55: printf("DBSTAT"); break;
    default: printf("SPR%d", nn);
    }
}

static void DispMemAddress(hasPrefix, prefix, ir)
{
    short int sir;

    sir = ir;
    if (hasPrefix) {
        printf("$%X", (prefix << 15)|(ir>>17));
    }
    else
        printf("$%x", (sir >> 17));
    if (((ir >> 7) & 0x1F) != 0)
        printf("[R%d]\r\n",((ir >> 7) & 0x1F));
    else
        printf("\r\n");
}

static void DispLS(int ad, char *mne, int hasPrefix, int prefix, int ir)
{
    DumpInsnBytes(ad, ir);
    printf("%s ", mne);
    DispRstc(ir);
    DispMemAddress(hasPrefix, prefix, ir);
}
static void DispRI(int ad, char *mne, int hasPrefix, int prefix, int ir)
{
    short int sir;

    sir = ir;
    DumpInsnBytes(ad, ir);
    printf("%s ", mne);
    DispRstc(ir);
    DispRac(ir);
    if (hasPrefix)
        printf("#$%X\r\n", (prefix << 15)|(ir>>17));
    else
        printf("#$%X\r\n", (sir >> 17));
}

void DispBcc(int ad, char *mne, int ir)
{
     int nn;
     int disp;

     disp = ((ir >> 17) & 0x7fff) << 2;
     if (ir & 0x80000000)
         disp |= 0xFFFFFFFFFFFF0000L;
     DumpInsnBytes(ad, ir);
     printf("%s ", mne);
     DispRac(ir);
     printf("%06X\r\n", ad + disp);
}
void DispRR(int ad, char *mne, int ir)
{
     DumpInsnBytes(ad, ir);
     printf("%s ", mne);
     DispRstc(ir);
     DispRac(ir);
     DispRb(ir);
}
 

void disassem(unsigned int *ad, unsigned int hilite_ad)
{
    unsigned short int *mem;
    unsigned short int ir;
    unsigned int opcode;
    unsigned int funct;
    int hasPrefix;
    int prefix;
    int nn;
    int disp;
    unsigned int ad1;
    short int sir;
    int isFirstPrefix;
    int isRV;

    mem = (unsigned short int *)0;
    hasPrefix = FALSE;
    prefix = 0;
    isFirstPrefix = TRUE;
    isRV = FALSE;

    do {
        if ((*ad)==hilite_ad) {
            reverse_video();
            isRV = TRUE;
        }
        ad1 = (*ad) >> 2;
        ir = mem[ad1];
        sir = ir;
        opcode = ir & 0x7F;
        funct = (ir >> 25) & 0x7F;
        switch(opcode) {
        case IMM:
             hasPrefix = TRUE;
             if (isFirstPrefix) {
                 prefix = sir >> 7;
                 if (prefix & 0x1000000)
                     prefix |= 0xFFFFFFFFFF000000L;
             }
             else
                 prefix = (prefix << 25) | (ir >> 7);
             DumpInsnBytes(*ad, ir);
             printf("IMM\r\n");
             isFirstPrefix = FALSE;
             break;
        case RR:
             switch (funct) {
             case PCTRL:
                  switch((ir >> 17) & 0x1f) {
                  case CLI:  DumpInsnBytes(*ad,ir); printf("CLI\r\n"); break;
                  case SEI:  DumpInsnBytes(*ad,ir); printf("SEI\r\n"); break;
                  case WAI:  DumpInsnBytes(*ad,ir); printf("WAI\r\n"); break;
                  case RTD:  DumpInsnBytes(*ad,ir); printf("RTD\r\n"); break;
                  case RTE:  DumpInsnBytes(*ad,ir); printf("RTE\r\n"); break;
                  case RTI:  DumpInsnBytes(*ad,ir); printf("RTI\r\n"); break;
                  default:   DumpInsnBytes(*ad,ir); printf("???\r\n"); break;
                  }
                  break;
             case ADD: DispRR(*ad, "ADD   ", ir); break;
             case ADDU: DispRR(*ad, "ADDU  ", ir); break; 
             case SUB: DispRR(*ad, "SUB   ", ir); break;
             case SUBU: DispRR(*ad, "SUBU  ", ir); break; 
             case CMP: DispRR(*ad, "CMP   ", ir); break;
             case CMPU: DispRR(*ad, "CMPU  ", ir); break; 
             case MUL: DispRR(*ad, "MUL   ", ir); break;
             case MULU: DispRR(*ad, "MULU  ", ir); break; 
             case DIV: DispRR(*ad, "DIV   ", ir); break;
             case DIVU: DispRR(*ad, "DIVU  ", ir); break; 
             case AND: DispRR(*ad, "AND   ", ir); break;
             case OR: DispRR(*ad, "OR    ", ir); break;
             case EOR: DispRR(*ad, "EOR   ", ir); break;
             case MFSPR:
                  DumpInsnBytes(*ad, ir);
                  printf("MFSPR ");
                  DispRstc(ir);
                  DispSpr(ir);
                  printf("\r\n");
                  break;
             case MTSPR:
                  DumpInsnBytes(*ad, ir);
                  printf("MTSPR ");
                  DispSpr(ir);
                  printf(",");
                  DispRa(ir);
                  printf("\r\n");
                  break;
             }
             break;
        case ADD:  DispRI(*ad, "ADD   ", hasPrefix, prefix, ir); break;
        case ADDU:  DispRI(*ad, "ADDU  ", hasPrefix, prefix, ir); break;
        case SUB:  DispRI(*ad, "SUB   ", hasPrefix, prefix, ir); break;
        case SUBU:  DispRI(*ad, "SUBU  ", hasPrefix, prefix, ir); break;
        case CMP:  DispRI(*ad, "CMP   ", hasPrefix, prefix, ir); break;
        case CMPU:  DispRI(*ad, "CMPU  ", hasPrefix, prefix, ir); break;
        case MUL:  DispRI(*ad, "MUL   ", hasPrefix, prefix, ir); break;
        case MULU:  DispRI(*ad, "MULU  ", hasPrefix, prefix, ir); break;
        case DIV:  DispRI(*ad, "DIV   ", hasPrefix, prefix, ir); break;
        case DIVU:  DispRI(*ad, "DIVU  ", hasPrefix, prefix, ir); break;
        case AND:  DispRI(*ad, "AND   ", hasPrefix, prefix, ir); break;
        case OR:  DispRI(*ad, "OR    ", hasPrefix, prefix, ir); break;
        case EOR:  DispRI(*ad, "EOR   ", hasPrefix, prefix, ir); break;
        case Bcc:
             switch((ir >> 12) & 7) {
             case BEQ:  DispBcc(*ad, "BEQ   ", ir); break;
             case BNE:  DispBcc(*ad, "BNE   ", ir); break;
             case BLT:  DispBcc(*ad, "BLT   ", ir); break;
             case BLE:  DispBcc(*ad, "BLE   ", ir); break;
             case BGT:  DispBcc(*ad, "BGT   ", ir); break;
             case BGE:  DispBcc(*ad, "BGE   ", ir); break;
             case 6:
             case 7:    DispBcc(*ad, "???   ", ir); break;
             }
             break;
        case BSR:
             DumpInsnBytes(*ad, ir);
             disp = ir >> 7;
             if (ir & 0x80000000) disp |= 0xFFFFFFFFFF000000L;
             nn = ad + (disp << 2);
             printf("BSR   $%X\r\n", nn);
             break;
        case BRA:
             DumpInsnBytes(*ad, ir);
             disp = ir >> 7;
             if (ir & 0x80000000) disp |= 0xFFFFFFFFFF000000L;
             nn = ad + (disp << 2);
             printf("BRA   $%X\r\n", nn);
             break;
        case RTL:
             DumpInsnBytes(*ad, ir);
             nn = ir >> 17;
             printf("RTL   #%X\r\n",nn);
             break;
        case RTS:
             DumpInsnBytes(*ad, ir);
             nn = ir >> 17;
             printf("RTS   #%X\r\n",nn);
             break;
        case LB: DispLS(*ad, "LB    ", hasPrefix, prefix, ir); break;
        case LBU: DispLS(*ad, "LBU   ", hasPrefix, prefix, ir); break;
        case LC: DispLS(*ad, "LC    ", hasPrefix, prefix, ir); break;
        case LCU: DispLS(*ad, "LCU   ", hasPrefix, prefix, ir); break;
        case LH: DispLS(*ad, "LH    ", hasPrefix, prefix, ir); break;
        case LHU: DispLS(*ad, "LHU   ", hasPrefix, prefix, ir); break;
        case LW: DispLS(*ad, "LW    ", hasPrefix, prefix, ir); break;
        case SB: DispLS(*ad, "SB    ", hasPrefix, prefix, ir); break;
        case SC: DispLS(*ad, "SC    ", hasPrefix, prefix, ir); break;
        case SH: DispLS(*ad, "SH    ", hasPrefix, prefix, ir); break;
        case SW: DispLS(*ad, "SW    ", hasPrefix, prefix, ir); break;
        case LWAR: DispLS(*ad, "LWAR  ", hasPrefix, prefix, ir); break;
        case SWCR: DispLS(*ad, "SWCR  ", hasPrefix, prefix, ir); break;
        case PUSH: DumpInsnBytes(*ad, ir); printf("PUSH  "); DispRa(ir); printf("\r\n"); break;
        case POP:  DumpInsnBytes(*ad, ir); printf("POP   "); DispRst(ir); printf("\r\n"); break;
        case NOP: DumpInsnBytes(*ad, ir); printf("NOP   \r\n"); break;
        case LDI:
             DumpInsnBytes(*ad, ir); 
             printf("LDI   ");
             DispRstc(ir);
             if (hasPrefix)
                 printf("#$%X\r\n", (prefix << 15)|(ir>>17));
             else
                 printf("#$%X\r\n", (sir >> 17));
             break;
             
        default: DumpInsnBytes(*ad, ir); printf("????? \r\n"); break;
        }
        *ad = *ad + 4;
        if (isRV) {
           reverse_video();
           isRV = FALSE;
        }
    } while (opcode==IMM);
}

void disassem20(unsigned int ad, unsigned int hilite_ad)
{
    int nn;
    unsigned int ad1;

    printf("Disassem:\r\n");
    for (nn = 0; nn < 16; nn++) {
        disassem(&ad, hilite_ad);
    }
}

