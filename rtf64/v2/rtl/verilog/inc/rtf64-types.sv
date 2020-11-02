// ============================================================================
//        __
//   \\__/ o\    (C) 2019-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// ============================================================================
//
// Types
`ifndef TYPES_SV
`define TYPES_SV		1

typedef logic [`ABITS] tAddress;
typedef logic [7:0] ASID;
typedef logic [63:0] Data;
typedef logic [`QBITS] Qid;			// Issue queue id
typedef logic [`RBITS] Rid;			// Reorder buffer id
typedef logic [2:0] Fuid;				// functional unit id
typedef logic [6:0] RegTag;			// Register tag
typedef logic [7:0] ExcCode;		// Exception code
typedef logic [`SNBITS] Seqnum;	// Sequence number
// Rather than having a number represent a register like the RegTag type, this
// type represents a register with a bit position in a vector.
typedef logic [`AREGS-1:0] RegTagBitmap;
typedef logic [3:0] ILen;

typedef struct packed
{
	ASID asid;
	tAddress adr;
} AddressWithASID;

typedef enum bit[3:0] {
	octa = 4'd0,
	byt = 4'd1,
	wyde = 4'd2,
	tetra = 4'd4,
	ubyt = 4'd5,
	uwyde = 4'd6,
	utetra = 4'd8
} MemSize;

typedef enum bit[2:0] {
	BC_NULL,
	BC_ICACHE,
	BC_WRITEBUF,
	BC_DCACHE0,
	BC_DCACHE1,
	BC_UNCDATA
} BusChannel;

// Different Instruction Formats

typedef struct packed
{
	logic [55:0] payload;
	logic [7:0] opcode;
} Gen_Instruction;

typedef struct packed
{
	logic [31:0] pad;
	logic rec;
	logic [12:0] imm13;
	logic [4:0] Rs1;
	logic [4:0] Rd;
	logic [7:0] opcode;
} RI13_Instruction;

typedef struct packed
{
  logic [31:0] pad;
  logic rec;
  logic [2:0] Funct3;
  logic [4:0] Rs3;
	logic [4:0] Rs2;
	logic [4:0] Rs1;
	logic [4:0] Rd;
  logic [7:0] opcode;
} R3_Instruction;

typedef struct packed
{
	logic [31:0] pad;
	logic rec;
	logic [4:0] Funct5;
	logic [2:0] Fmt;
	logic [4:0] Rs2;
	logic [4:0] Rs1;
	logic [4:0] Rd;
	logic [7:0] opcode;
} R2_Instruction;

typedef struct packed
{
	logic [31:0] pad;
	logic rec;
	logic [2:0] Fmt;
	logic [3:0] Funct4;
	logic pad1;
	logic [4:0] Rs2;
	logic [4:0] Rs1;
	logic [4:0] Rd;
	logic [7:0] opcode;
} Shift_Instruction;

typedef struct packed
{
	logic [31:0] pad;
	logic rec;
	logic [2:0] Fmt;
	logic [3:0] Funct4;
	logic [5:0] imm6;
	logic [4:0] Rs1;
	logic [4:0] Rd;
	logic [7:0] opcode;
} Shifti_Instruction;

typedef struct packed
{
	logic [31:0] pad;
	logic rec;
	logic [2:0] Funct3;
	logic [1:0] pad2;
	logic [2:0] Fmt;
	logic [4:0] Rs2;
	logic [4:0] Rs1;
	logic [2:0] mop;
	logic [1:0] Cd;
	logic [7:0] opcode;
} Set_Instruction;

typedef struct packed
{
  logic [23:0] pad;
  logic [2:0] Funct3;
  logic pad3;
  logic [2:0] om;
  logic pad2;
  logic rec;
  logic pad1;
  logic [11:0] regno;
  logic [4:0] Rs1;
  logic [4:0] Rd;
  logic [7:0] opcode;
} CSR_Instruction;

typedef struct packed
{
  logic [20:0] pad;
  logic [10:0] Const11;
  logic rec;
  logic [12:0] Const13;
  logic [4:0] Rs1;
  logic [4:0] Rd;
  logic [7:0] opcode;
} Perm_Instruction;

typedef struct packed
{
  logic [28:0] pad;
  logic [2:0] Const3;
  logic rec;
  logic [12:0] Const13;
  logic [4:0] Rs1;
  logic [4:0] Rd;
  logic [7:0] opcode;
} Wydndx_Instruction;

typedef struct packed
{
  logic [31:0] pad;
  logic rec;
  logic op;
  logic [5:0] width;
  logic [5:0] offset;
  logic [4:0] Rs1;
  logic [4:0] Rd;
  logic [7:0] opcode;
} Ext_Instruction;

typedef struct packed
{
  logic [31:0] pad;
  logic rec;
  logic [12:0] Const13;
  logic [4:0] Rs1;
  logic [2:0] mop;
  logic [1:0] Cd;
  logic [7:0] opcode;

} Seti_Instruction;

typedef struct packed
{
  logic [39:0] pad;
  logic rec;
  logic [4:0] Const5;
  logic [4:0] Rs1;
  logic [4:0] Rd;
  logic [7:0] opcode;

} Add5_Instruction;

typedef struct packed
{
  logic [39:0] pad;
  logic rec;
  logic [9:0] Const10;
  logic [4:0] Rd;
  logic [7:0] opcode;

} Add22_Instruction;

typedef struct packed
{
  logic [39:0] pad;
  logic rec;
  logic [4:0] Rs2;
  logic [4:0] Rs1;
  logic [4:0] Rd;
  logic [7:0] opcode;

} Add2r_Instruction;

typedef struct packed
{
  logic [47:0] pad;
  logic rec;
  logic [6:0] Const7;
  logic [7:0] opcode;
} Gcsub7_Instruction;

typedef struct packed
{
  logic [31:0] pad;
  logic rec;
  logic [12:0] Const13;
  logic [4:0] Rs1;
  logic [4:0] Rd;
  logic [7:0] opcode;
} Gcsub_Instruction;

typedef struct packed
{
  logic [31:0] Const32;
  logic rec;
  logic [17:0] Const13;
  logic [4:0] Rd;
  logic [7:0] opcode;
} Addui_Instruction;

typedef struct packed
{
  logic [31:0] pad;
  logic [21:0] Disp;
  logic Cn;
  logic Lk;
  logic [7:0] opcode;
} BLR_Instruction;


typedef union packed
{
	logic [63:0] raw;
	Gen_Instruction gen;
	RR_Instruction rr;
	RI8_Instruction ri8;
	RI22_Instruction ri22;
	RI35_Instruction ri35;
	RIS_Instruction ris;
	Branch_Instruction br;
	Jal_Instruction jal;
	Jalrn_Instruction jalrn;
	Ret_Instruction ret;
	Wai_Instruction wai;
	Stp_Instruction stp;
	Brk_Instruction brk;
	Rex_Instruction rex;
	CSR_Instruction csr;
	FLT1_Instruction flt1;
	FLT2_Instruction flt2;
	Cache_Instruction cache;
} tInstruction;

typedef tAddress Address;
typedef tInstruction Instruction;

typedef struct packed
{
	logic [`IQ_ENTRIES-1:0] v;
	logic [`IQ_ENTRIES-1:0] queued;
	logic [`IQ_ENTRIES-1:0] out;
	logic [`IQ_ENTRIES-1:0] agen;
	logic [`IQ_ENTRIES-1:0] mem;
	logic [`IQ_ENTRIES-1:0] done;
	logic [`IQ_ENTRIES-1:0] cmt;
} IQState;

typedef struct packed
{
  logic valid;
  Rid source;
  Data value;
} tArgument;

typedef struct packed
{
	IQState iqs;
	Seqnum [`IQ_ENTRIES-1:0] sn;
	tAddress [`IQ_ENTRIES-1:0] pc;
	ILen [`IQ_ENTRIES-1:0] ilen;
	Instruction [`IQ_ENTRIES-1:0] instr;		// instruction
	tAddress [`IQ_ENTRIES-1:0] predicted_pc;
	logic [`IQ_ENTRIES-1:0] prior_fsync;
	logic [`IQ_ENTRIES-1:0] prior_sync;
	logic [`IQ_ENTRIES-1:0] prior_memdb;
	logic [`IQ_ENTRIES-1:0] prior_memsb;
	logic [`IQ_ENTRIES-1:0] prior_pathchg;
	logic [`IQ_ENTRIES-1:0] fsync;
	logic [`IQ_ENTRIES-1:0] memdb;
	logic [`IQ_ENTRIES-1:0] memsb;
	logic [`IQ_ENTRIES-1:0] sync;
	logic [`IQ_ENTRIES-1:0] fc;
	logic [`IQ_ENTRIES-1:0] canex;
	logic [`IQ_ENTRIES-1:0] alu;
	logic [`IQ_ENTRIES-1:0] alu0;
	logic [`IQ_ENTRIES-1:0] fpu;
	logic [`IQ_ENTRIES-1:0] fpu0;
	logic [`IQ_ENTRIES-1:0] mem;
	logic [`IQ_ENTRIES-1:0] memndx;			// indexed memory instruction
	logic [3:0] [`IQ_ENTRIES-1:0] memsz;			// size of memory operation
	logic [`IQ_ENTRIES-1:0] [31:0] sel;	// select lines, for memory overlap detect
	logic [`IQ_ENTRIES-1:0] load;				// memory load operation
	logic [`IQ_ENTRIES-1:0] store;			// memory store operation
	logic [`IQ_ENTRIES-1:0] store_cr;		// memory store and clear reservation operation
	tAddress [`IQ_ENTRIES-1:0] ma;				// memory address
	tArgument [`IQ_ENTRIES-1:0] argA;	// First argument
  tArgument [`IQ_ENTRIES-1:0] argB;	// Second argument
  tArgument [`IQ_ENTRIES-1:0] argC;	// Third argument
  tArgument [`IQ_ENTRIES-1:0] argT ;	// Target/Source argument
} IQ;

typedef struct packed
{
	logic [`RENTRIES-1:0] v;
	logic [`RENTRIES-1:0] cmt;
} RobState;

typedef struct packed
{
	Qid [`RENTRIES-1:0] id;			// Link to issue queue
	Fuid [`RENTRIES-1:0] fuid;	// link back to functional unit
	tAddress [`RENTRIES-1:0] pc;
	Instruction [`RENTRIES-1:0] instr;
	Data [`RENTRIES-1:0] res;
	RegTag [`RENTRIES-1:0] tgt;
	logic [`RENTRIES-1:0] rfw;
	Data [`RENTRIES-1:0] argA;
	ExcCode [`RENTRIES-1:0] exc;
	RobState rs;
} Rob;

typedef logic [19:0] Key;

typedef struct packed
{
	logic v;
	tAddress adr;
	tInstruction ins;
} tDecodeBuffer;

typedef struct packed
{
  logic predict_taken;
  logic v;
  tAddress adr;
  tInstruction ins;
} tFetchBuffer;

`endif
