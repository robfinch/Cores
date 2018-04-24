`define TRUE    1'b1
`define FALSE   1'b0
`define HIGH    1'b1
`define LOW     1'b0

`define RST_VECT    32'h00000000

`define R2      8'h02
`define ADD     8'h04
`define SUB     8'h05
`define CMP     8'h06
`define AND     8'h07
`define OR      8'h08
`define XOR     8'h09
`define CSR     8'h0F

`define ADDU    8'h14
`define SUBU    8'h15
`define CMPU    8'h16
`define LEA     8'h26
`define LEAX    8'h27

`define JMP     8'h40
`define BEQ     8'h46
`define BNE     8'h47
`define BLT     8'h48
`define BGE     8'h49
`define BLE     8'h4A
`define BGT     8'h4B 
`define BLTU    8'h4C
`define BGEU    8'h4D
`define BLEU    8'h4E
`define BGTU    8'h4F 

`define CALL    8'h50
`define BEQI    8'h56
`define BNEI    8'h57
`define BLTI    8'h58
`define BGEI    8'h59
`define BLEI    8'h5A
`define BGTI    8'h5B 
`define BLTUI   8'h5C
`define BGEUI   8'h5D
`define BLEUI   8'h5E
`define BGTUI   8'h5F 

`define LDB     8'h80
`define LDBU    8'h81
`define LDW     8'h82
`define LDWU    8'h83
`define LDT     8'h84
`define LDTU    8'h85
`define LDD     8'h86
`define LDVDAR  8'h8E

`define STB     8'h90
`define STW     8'h91
`define STT     8'h92
`define STD     8'h93
`define STDCR   8'h95
`define INC     8'h96
`define FPUSH   8'h9A
`define FPOP    8'h9B
`define PEA     8'h9C

`define LDBX    8'hA0
`define LDBUX   8'hA1
`define LDWX    8'hA2
`define LDWUX   8'hA3
`define LDTX    8'hA4
`define LDTUX   8'hA5
`define LDDX    8'hA6

`define STBX    8'hB0
`define STWX    8'hB1
`define STTX    8'hB2
`define STDX    8'hB3
`define STDCRX  8'hB5
`define INCX    8'hB6

`define MOV     8'hE0
`define BRK     8'hE1
`define NOP     8'hEA
`define FPUSH   8'hEB
`define FPOP    8'hEC
`define PUSH    8'hED
`define POP     8'hEE
`define RET     8'hEF

`define FLOAT1  8'hF1
`define FLOAT2  8'hF2

// R2 opcode
`define SHL     8'h30
`define SHR     8'h31
`define ASL     8'h32
`define ASR     8'h33
`define ROL     8'h34
`define ROR     8'h35

`define SHLI    8'h40
`define SHRI    8'h41
`define ASLI    8'h42
`define ASRI    8'h43
`define ROLI    8'h44
`define RORI    8'h45

`define NAND    8'h48
`define NOR     8'h49
`define XNOR    8'h4A
`define ANDN    8'h4B
`define ORN     8'h4C

`define FLT_IADR    9'd484
`define FLT_UNIMP   9'd485
`define FLT_STACK   9'd504
`define FLT_DBE     9'd508
`define FLT_IBE     9'd509
