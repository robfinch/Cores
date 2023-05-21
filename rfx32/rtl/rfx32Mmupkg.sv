// ============================================================================
//        __
//   \\__/ o\    (C) 2022-2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rfx32Mmupkg.sv
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//                                                                          
// ============================================================================

package rfx32Mmupkg;

`define SMALL_TLB	1'b1

parameter PAGE_SIZE = 16384;
parameter ENTRIES = 1024;
parameter LOG_PAGE_SIZE = $clog2(PAGE_SIZE);
parameter LOG_ENTRIES = $clog2(ENTRIES);

parameter ITAG_BIT = 12;
parameter DCacheLineWidth = 512;
localparam DCacheTagLoBit = $clog2((DCacheLineWidth/8))-1;
parameter ICacheLineWidth = 256;
localparam ICacheTagLoBit = $clog2((ICacheLineWidth/8))-1;

`define TAG_ASID $bits(rfx32pkg::asid_t) + $bits(rfx32pkg::address_t)-ITAG_BIT-1:$bits(rfx32pkg::address_t)-ITAG_BIT

typedef logic [5:0] tlb_count_t;
typedef logic [2:0] rwx_t;

typedef enum logic [3:0] {
	ST_RST = 4'd0,
	ST_RUN = 4'd1,
	ST_INVALL1 = 4'd7,
	ST_INVALL2 = 4'd8,
	ST_INVALL3 = 4'd9,
	ST_INVALL4 = 4'd10,
	ST_UPD1 = 4'd11,
	ST_UPD2 = 4'd12,
	ST_UPD3 = 4'd13
} tlb_state_t;

typedef struct packed
{
	logic [7:0] resv3;
	logic [7:0] dev_type;
	logic resv2;
	logic [2:0] s;
	logic resv1;
	logic [2:0] gran;
	logic [3:0] cache;
	logic [3:0] rwx;
} REGION_ATTR;

typedef struct packed
{
	REGION_ATTR [3:0] at;
	rfx32pkg::physical_address_t cta;
	rfx32pkg::physical_address_t pmt;
	logic [31:0] lock;
} REGION;

typedef struct packed
{
	logic vm;
	logic n;
	logic pm;
	logic [3:0] cache;
	logic e;						// 1= encrypted
	logic [1:0] al;
	logic compressed;
	logic [20:0] resv;
	logic [7:0] pl;
	logic [23:0] key;
	logic [31:0] access_count;
	logic [15:0] acl;
	logic [15:0] share_count;
} PMTE;	// 128 bits

// Page Table Entry
typedef struct packed
{
	logic [63:0] ppn;
	logic v;
	logic [4:0] lvl;
	logic [2:0] rgn;
	logic m;
	logic a;
	logic t;							// Type, 0=MPP, 1=PTP
	logic s;
	logic g;
	logic [1:0] sw;
	logic [3:0] cache;
	rwx_t [3:0] rwx;
} PTE;	// 96 bits

// Small page table entry. Physical memory < 64TB.
typedef struct packed
{
	logic [31:0] ppn;			// 46 bit address space
	logic v;
	logic [4:0] lvl;
	logic [2:0] rgn;
	logic m;
	logic a;
	logic t;							// Type, 0=MPP, 1=PTP
	logic s;
	logic g;
	logic [1:0] sw;
	logic [3:0] cache;
	rwx_t [3:0] rwx;
} SPTE;	// 64 bits

typedef struct packed
{
	logic [3:0] resv4;
	rfx32pkg::asid_t asid;
	logic [1:0] resv2;
	logic [77:0] vpn;
} VPN;	// 96 bits

// Small VPN, Virtual memory < 2^60B
typedef struct packed
{
	logic [3:0] resv4;
	rfx32pkg::asid_t asid;
	logic [1:0] resv2;
	logic [69:24] vpn;
} SVPN;	// 64 bits

typedef struct packed
{
	logic v;
	logic [2:0] lvl;
	logic [3:0] sw;
	logic t;
	logic m;
	logic [2:0] rwx;
	logic a;
	logic [17:0] ppn;
} PDE;	// 32 bits

typedef struct packed
{
	tlb_count_t count;
	logic [2:0] lru;
	PTE pte;
	VPN vpn;
} TLBE;

typedef struct packed
{
	tlb_count_t count;
	logic [2:0] lru;
	SPTE pte;
	SVPN vpn;
} STLBE;

// Small Hash Page Table Entry
// Used to map 32-bit virtual addresses into a 36-bit physical address space.
typedef struct packed
{
	logic [11:0] asid;
	logic [4:0] bc;
	logic [17:0] vpn;
	logic [21:0] ppn;
	logic sw;
	logic m;
	logic a;
	logic g;
	logic c;
	logic [2:0] rwx;
} SHPTE;	// 64 bits

// Hash Page Table Entry
typedef struct packed
{
	logic [31:0] vpnhi;
	logic [31:0] ppnhi;
	logic [11:0] asid;
	logic [4:0] bc;
	logic [17:0] vpn;
	logic [21:0] ppn;
	logic sw;
	logic m;
	logic a;
	logic g;
	logic c;
	logic [2:0] rwx;
} HPTE;	// 128 bits

typedef struct packed
{
	logic v;
	rfx32pkg::address_t adr;
	PDE pde;
} PDCE;

`define PtePerPtg 8
`define PtgSize 2048
`define StripsPerPtg	10

integer PtePerPtg = `PtePerPtg;
integer PtgSize = `PtgSize;

typedef struct packed
{
	HPTE [`PtePerPtg-1:0] ptes;
} PTG;	// 1024 bits

typedef struct packed
{
	SHPTE [`PtePerPtg-1:0] ptes;
} SPTG;	// 512 bits

typedef struct packed
{
	logic v;
	rfx32pkg::address_t dadr;
	PTG ptg;
} PTGCE;
parameter PTGC_DEP = 8;

typedef enum logic [6:0] {
	MEMORY_INIT = 7'd0,
	MEMORY_IDLE = 7'd1,
	MEMORY_DISPATCH = 7'd2,
	MEMORY3 = 7'd3,
	MEMORY4 = 7'd4,
	MEMORY5 = 7'd5,
	MEMORY_ACK = 7'd6,
	MEMORY_NACK = 7'd7,
	MEMORY8 = 7'd8,
	MEMORY9 = 7'd9,
	MEMORY10 = 7'd10,
	MEMORY11 = 7'd11,
	MEMORY_ACKHI = 7'd12,
	MEMORY13 = 7'd13,
	DATA_ALIGN = 7'd14,
	MEMORY_KEYCHK1 = 7'd15,
	MEMORY_KEYCHK2 = 7'd16,
	KEYCHK_ERR = 7'd17,
	TLB1 = 7'd21,
	TLB2 = 7'd22,
	TLB3 = 7'd23,
	RGN1 = 7'd25,
	RGN2 = 7'd26,
	RGN3 = 7'd27,
	IFETCH0 = 7'd30,
	IFETCH1 = 7'd31,
	IFETCH2 = 7'd32,
	IFETCH3 = 7'd33,
	IFETCH4 = 7'd34,
	IFETCH5 = 7'd35,
	IFETCH6 = 7'd36,
	IFETCH1a = 7'd37,
	IFETCH1b = 7'd38,
	IFETCH3a = 7'd39,
	DFETCH2 = 7'd42,
	DFETCH5 = 7'd43,
	DFETCH6 = 7'd44,
	DFETCH7 = 7'd45,
	DSTORE1 = 7'd46,
	DSTORE2 = 7'd47,
	DSTORE3 = 7'd48,
	KYLD = 7'd51,
	KYLD2 = 7'd52,
	KYLD3 = 7'd53,
	KYLD4 = 7'd54,
	KYLD5 = 7'd55,
	KYLD6 = 7'd56,
	KYLD7 = 7'd57,
	MEMORY1 = 7'd60,
	MFSEL1 = 7'd61,
	MEMORY_ACTIVATE = 7'd62,
	MEMORY_ACTIVATE_HI = 7'd63,
	IPT_FETCH1 = 7'd64,
	IPT_FETCH2 = 7'd65,
	IPT_FETCH3 = 7'd66,
	IPT_FETCH4 = 7'd67,
	IPT_FETCH5 = 7'd68,
	IPT_RW_PTG2 = 7'd69,
	IPT_RW_PTG3 = 7'd70,
	IPT_RW_PTG4 = 7'd71,
	IPT_RW_PTG5 = 7'd72,
	IPT_RW_PTG6 = 7'd73,
	IPT_WRITE_PTE = 7'd75,
	IPT_IDLE = 7'd76,
	MEMORY5a = 7'd77,
	PT_FETCH1 = 7'd81,
	PT_FETCH2 = 7'd82,
	PT_FETCH3 = 7'd83,
	PT_FETCH4 = 7'd84,
	PT_FETCH5 = 7'd85,
	PT_FETCH6 = 7'd86,
	PT_RW_PTE1 = 7'd92,
	PT_RW_PTE2 = 7'd93,
	PT_RW_PTE3 = 7'd94,
	PT_RW_PTE4 = 7'd95,
	PT_RW_PTE5 = 7'd96,
	PT_RW_PTE6 = 7'd97,
	PT_RW_PTE7 = 7'd98,
	PT_WRITE_PTE = 7'd99,
	PMT_FETCH1 = 7'd101,
	PMT_FETCH2 = 7'd102,
	PMT_FETCH3 = 7'd103,
	PMT_FETCH4 = 7'd104,
	PMT_FETCH5 = 7'd105,
	PT_RW_PDE1 = 7'd108,
	PT_RW_PDE2 = 7'd109,
	PT_RW_PDE3 = 7'd110,
	PT_RW_PDE4 = 7'd111,
	PT_RW_PDE5 = 7'd112,
	PT_RW_PDE6 = 7'd113,
	PT_RW_PDE7 = 7'd114,
	PTG1 = 7'd115,
	PTG2 = 7'd116,
	PTG3 = 7'd117,
	MEMORY_UPD1 = 7'd118,
	MEMORY_UPD2 = 7'd119
} mem_state_t;

parameter IPT_CLOCK1 = 7'd1;
parameter IPT_CLOCK2 = 7'd2;
parameter IPT_CLOCK3 = 7'd3;

endpackage
