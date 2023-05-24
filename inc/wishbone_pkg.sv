// ============================================================================
//        __
//   \\__/ o\    (C) 2015-2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
//
package wishbone_pkg;

typedef logic [31:0] wb_address_t;
typedef logic [5:0] wb_burst_len_t;		// number of beats in a burst -1
typedef logic [3:0] wb_channel_t;			// channel for devices like system cache
typedef logic [7:0] wb_tranid_t;			// transaction id
typedef logic [7:0] wb_priv_level_t;	// 0=all access,
typedef logic [3:0] wb_priority_t;		// network transaction priority, higher is better
typedef logic [11:0] wb_asid_t;				// address space identifier

typedef enum logic [1:0] {
	APP = 2'd0,
	SUPERVISOR = 2'd1,
	HYPERVISOR = 2'd2,
	MACHINE = 2'd3
} wb_operating_mode_t;

typedef enum logic [2:0] {
	CLASSIC = 3'b000,
	FIXED = 3'b001,					// constant data address
	INCR = 3'b010,					// incrementing data address
	IRQA = 3'b110,					// interrupt acknowledge
	EOB = 3'b111						// end of data burst
} wb_cycle_type_t;

typedef enum logic [2:0] {
	DATA = 3'b000,
	STACK = 3'b110,
	CODE = 3'b111
} wb_segment_t;

typedef enum logic [2:0] {
	LINEAR = 3'b000,
	WRAP4 = 3'b001,
	WRAP8 = 3'b010,
	WRAP16 = 3'b011,
	WRAP32 = 3'b100,
	WRAP64 = 3'b101,
	WRAP128 = 3'b110
} wb_burst_type_t;

// number of byte transferred in a beat
typedef enum logic [3:0] {
	nul = 4'd0,
	byt = 4'd1,
	wyde = 4'd2,
	tetra = 4'd3,
	penta = 4'd4,
	octa = 4'd5,
	hexi = 4'd6,
	n96 = 4'd7,
	char = 4'd8,
	vect = 4'd10
} wb_size_t;

typedef enum logic [1:0] {
	OKAY = 2'b00,				// no error
	DECERR = 2'd01,			// decode error
	PROTERR = 2'b10,		// security violation
	ERR = 2'b11					// general error
} wb_error_t;

typedef enum logic [3:0] {
	NC_NB = 4'd0,										// Non-cacheable, non-bufferable
	NON_CACHEABLE = 4'd1,
	CACHEABLE_NB = 4'd2,						// Cacheable, non-bufferable
	CACHEABLE = 4'd3,								// Cacheable, bufferable
	WT_NO_ALLOCATE = 4'd8,					// Write Through
	WT_READ_ALLOCATE = 4'd9,
	WT_WRITE_ALLOCATE = 4'd10,
	WT_READWRITE_ALLOCATE = 4'd11,
	WB_NO_ALLOCATE = 4'd12,					// Write Back
	WB_READ_ALLOCATE = 4'd13,
	WB_WRITE_ALLOCATE = 4'd14,
	WB_READWRITE_ALLOCATE = 4'd15
} wb_cache_t;

typedef enum logic [4:0] {
	CMD_NONE = 5'd0,
	CMD_LOAD = 5'd1,
	CMD_LOADZ = 5'd2,
	CMD_STORE = 5'd3,
	CMD_STOREPTR = 5'd4,
	CMD_LEA = 5'd7,
	CMD_DCACHE_LOAD = 5'd10,
	CMD_ICACHE_LOAD = 5'd11,
	CMD_CACHE = 5'd13,
	CMD_SWAP = 5'd16,
	CMD_MIN = 5'd18,
	CMD_MAX = 5'd19,
	CMD_ADD = 5'd20,
	CMD_ASL = 5'd22,
	CMD_LSR = 5'd23,
	CMD_AND = 5'd24,
	CMD_OR = 5'd25,
	CMD_EOR = 5'd26,
	CMD_MINU = 5'd28,
	CMD_MAXU = 5'd29,
	CMD_CAS = 5'd31
} wb_cmd_t;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Read requests
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

typedef struct packed {
	wb_cmd_t cmd;					// command
	wb_burst_type_t bte;	// burst type extension
	wb_cycle_type_t cti;	// cycle type indicator
	wb_burst_len_t blen;	// length of burst-1
	wb_segment_t seg;			// segment
	logic cyc;						// valid cycle
	logic stb;						// data strobe
	wb_address_t adr;			// address
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic sr;							// set reservation
	wb_priv_level_t pl;		// privilege level
	wb_priority_t pri;		// transaction priority
	wb_cache_t cache;			// cache and buffer properties
} wb_read_request8_t;

typedef struct packed {
	wb_cmd_t cmd;					// command
	wb_burst_type_t bte;	// burst type extension
	wb_cycle_type_t cti;	// cycle type indicator
	wb_burst_len_t blen;	// length of burst-1
	wb_segment_t seg;			// segment
	logic cyc;						// valid cycle
	logic stb;						// data strobe
	wb_address_t adr;			// address
	logic [1:0] sel;			// byte lane select
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic sr;							// set reservation
	wb_priv_level_t pl;		// privilege level
	wb_priority_t pri;		// transaction priority
	wb_cache_t cache;			// cache and buffer properties
} wb_read_request16_t;

typedef struct packed {
	wb_cmd_t cmd;					// command
	wb_burst_type_t bte;	// burst type extension
	wb_cycle_type_t cti;	// cycle type indicator
	wb_burst_len_t blen;	// length of burst-1
	wb_segment_t seg;			// segment
	logic cyc;						// valid cycle
	logic stb;						// data strobe
	wb_address_t adr;			// address
	logic [3:0] sel;			// byte lane select
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic sr;							// set reservation
	wb_priv_level_t pl;		// privilege level
	wb_priority_t pri;		// transaction priority
	wb_cache_t cache;			// cache and buffer properties
} wb_read_request32_t;

typedef struct packed {
	wb_cmd_t cmd;					// command
	wb_burst_type_t bte;	// burst type extension
	wb_cycle_type_t cti;	// cycle type indicator
	wb_burst_len_t blen;	// length of burst-1
	wb_segment_t seg;			// segment
	logic cyc;						// valid cycle
	logic stb;						// data strobe
	wb_address_t adr;			// address
	logic [7:0] sel;			// byte lane select
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic sr;							// set reservation
	wb_priv_level_t pl;		// privilege level
	wb_priority_t pri;		// transaction priority
	wb_cache_t cache;			// cache and buffer properties
} wb_read_request64_t;

typedef struct packed {
	wb_cmd_t cmd;					// command
	wb_burst_type_t bte;	// burst type extension
	wb_cycle_type_t cti;	// cycle type indicator
	wb_burst_len_t blen;	// length of burst-1
	wb_segment_t seg;			// segment
	logic cyc;						// valid cycle
	logic stb;						// data strobe
	wb_address_t adr;			// address
	logic [15:0] sel;			// byte lane select
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic sr;							// set reservation
	wb_priv_level_t pl;		// privilege level
	wb_priority_t pri;		// transaction priority
	wb_cache_t cache;			// cache and buffer properties
} wb_read_request128_t;

typedef struct packed {
	wb_cmd_t cmd;					// command
	wb_burst_type_t bte;	// burst type extension
	wb_cycle_type_t cti;	// cycle type indicator
	wb_burst_len_t blen;	// length of burst-1
	wb_segment_t seg;			// segment
	logic cyc;						// valid cycle
	logic stb;						// data strobe
	wb_address_t adr;			// address
	logic [31:0] sel;			// byte lane select
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic sr;							// set reservation
	wb_priv_level_t pl;		// privilege level
	wb_priority_t pri;		// transaction priority
	wb_cache_t cache;			// cache and buffer properties
} wb_read_request256_t;

typedef struct packed {
	wb_cmd_t cmd;					// command
	wb_burst_type_t bte;	// burst type extension
	wb_cycle_type_t cti;	// cycle type indicator
	wb_burst_len_t blen;	// length of burst-1
	wb_segment_t seg;			// segment
	logic cyc;						// valid cycle
	logic stb;						// data strobe
	wb_address_t adr;			// address
	logic [63:0] sel;			// byte lane select
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic sr;							// set reservation
	wb_priv_level_t pl;		// privilege level
	wb_priority_t pri;		// transaction priority
	wb_cache_t cache;			// cache and buffer properties
} wb_read_request512_t;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Command requests
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

typedef struct packed {
	wb_operating_mode_t om;	// operating mode
	wb_cmd_t cmd;					// command
	wb_burst_type_t bte;	// burst type extension
	wb_cycle_type_t cti;	// cycle type indicator
	wb_burst_len_t blen;	// length of burst-1
	wb_size_t sz;					// transfer size
	wb_segment_t seg;			// segment
	logic cyc;						// valid cycle
	logic stb;						// data strobe
	logic we;							// write enable
	wb_asid_t asid;				// address space identifier
	wb_address_t vadr;		// virtual address
	wb_address_t padr;		// physical address
	logic [7:0] dat;			// data
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic csr;						// set or clear reservation we:1=clear 0=set
	wb_priv_level_t pl;		// privilege level
	wb_priority_t pri;		// transaction priority
	wb_cache_t cache;			// cache and buffer properties
} wb_cmd_request8_t;

typedef struct packed {
	wb_operating_mode_t om;	// operating mode
	wb_cmd_t cmd;					// command
	wb_burst_type_t bte;	// burst type extension
	wb_cycle_type_t cti;	// cycle type indicator
	wb_burst_len_t blen;	// length of burst-1
	wb_size_t sz;					// transfer size
	wb_segment_t seg;			// segment
	logic cyc;						// valid cycle
	logic stb;						// data strobe
	logic we;							// write enable
	wb_asid_t asid;				// address space identifier
	wb_address_t vadr;		// virtual address
	wb_address_t padr;		// physical address
	logic [1:0] sel;			// byte lane selects
	logic [15:0] dat;			// data
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic csr;						// set or clear reservation we:1=clear 0=set
	wb_priv_level_t pl;		// privilege level
	wb_priority_t pri;		// transaction priority
	wb_cache_t cache;			// cache and buffer properties
} wb_cmd_request16_t;

typedef struct packed {
	wb_operating_mode_t om;	// operating mode
	wb_cmd_t cmd;					// command
	wb_burst_type_t bte;	// burst type extension
	wb_cycle_type_t cti;	// cycle type indicator
	wb_burst_len_t blen;	// length of burst-1
	wb_size_t sz;					// transfer size
	wb_segment_t seg;			// segment
	logic cyc;						// valid cycle
	logic stb;						// data strobe
	logic we;							// write enable
	wb_asid_t asid;				// address space identifier
	wb_address_t vadr;		// virtual address
	wb_address_t padr;		// physical address
	logic [3:0] sel;			// byte lane selects
	logic [31:0] dat;			// data
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic csr;						// set or clear reservation we:1=clear 0=set
	wb_priv_level_t pl;		// privilege level
	wb_priority_t pri;		// transaction priority
	wb_cache_t cache;			// cache and buffer properties
} wb_cmd_request32_t;

typedef struct packed {
	wb_operating_mode_t om;	// operating mode
	wb_cmd_t cmd;					// command
	wb_burst_type_t bte;	// burst type extension
	wb_cycle_type_t cti;	// cycle type indicator
	wb_burst_len_t blen;	// length of burst-1
	wb_size_t sz;					// transfer size
	wb_segment_t seg;			// segment
	logic cyc;						// valid cycle
	logic stb;						// data strobe
	logic we;							// write enable
	wb_asid_t asid;				// address space identifier
	wb_address_t vadr;		// virtual address
	wb_address_t padr;		// physical address
	logic [7:0] sel;			// byte lane selects
	logic [63:0] dat;			// data
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic csr;						// set or clear reservation we:1=clear 0=set
	wb_priv_level_t pl;		// privilege level
	wb_priority_t pri;		// transaction priority
	wb_cache_t cache;			// cache and buffer properties
} wb_cmd_request64_t;

typedef struct packed {
	wb_operating_mode_t om;	// operating mode
	wb_cmd_t cmd;					// command
	wb_burst_type_t bte;	// burst type extension
	wb_cycle_type_t cti;	// cycle type indicator
	wb_burst_len_t blen;	// length of burst-1
	wb_size_t sz;					// transfer size
	wb_segment_t seg;			// segment
	logic cyc;						// valid cycle
	logic stb;						// data strobe
	logic we;							// write enable
	wb_asid_t asid;				// address space identifier
	wb_address_t vadr;		// virtual address
	wb_address_t padr;		// physical address
	logic [15:0] sel;			// byte lane selects
	logic [127:0] data1;	// data
	logic [127:0] data2;	// data
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic csr;						// set or clear reservation we:1=clear 0=set
	wb_priv_level_t pl;		// privilege level
	wb_priority_t pri;		// transaction priority
	wb_cache_t cache;			// cache and buffer properties
} wb_cmd_request128_t;

typedef struct packed {
	wb_operating_mode_t om;	// operating mode
	wb_cmd_t cmd;					// command
	wb_burst_type_t bte;	// burst type extension
	wb_cycle_type_t cti;	// cycle type indicator
	wb_burst_len_t blen;	// length of burst-1
	wb_size_t sz;					// transfer size
	wb_segment_t seg;			// segment
	logic cyc;						// valid cycle
	logic stb;						// data strobe
	logic we;							// write enable
	wb_asid_t asid;				// address space identifier
	wb_address_t vadr;		// virtual address
	wb_address_t padr;		// physical address
	logic [31:0] sel;			// byte lane selects
	logic [255:0] dat;		// data
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic csr;						// set or clear reservation we:1=clear 0=set
	wb_priv_level_t pl;		// privilege level
	wb_priority_t pri;		// transaction priority
	wb_cache_t cache;			// cache and buffer properties
} wb_cmd_request256_t;

typedef struct packed {
	wb_operating_mode_t om;	// operating mode
	wb_cmd_t cmd;					// command
	wb_burst_type_t bte;	// burst type extension
	wb_cycle_type_t cti;	// cycle type indicator
	wb_burst_len_t blen;	// length of burst-1
	wb_size_t sz;					// transfer size
	wb_segment_t seg;			// segment
	logic cyc;						// valid cycle
	logic stb;						// data strobe
	logic we;							// write enable
	wb_asid_t asid;				// address space identifier
	wb_address_t vadr;		// virtual address
	wb_address_t padr;		// physical address
	logic [63:0] sel;			// byte lane selects
	logic [511:0] dat;		// data
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic csr;						// set or clear reservation we:1=clear 0=set
	wb_priv_level_t pl;		// privilege level
	wb_priority_t pri;		// transaction priority
	wb_cache_t cache;			// cache and buffer properties
} wb_cmd_request512_t;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Read responses
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

typedef struct packed {
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic stall;					// stall pipeline
	logic next;						// advance to next transaction
	logic ack;						// response acknowledge
	logic rty;						// retry
	logic err;						// error
	wb_priority_t pri;		// response priority
	wb_address_t adr;
	logic [7:0] dat;			// data
} wb_cmd_response8_t;

typedef struct packed {
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic stall;					// stall pipeline
	logic next;						// advance to next transaction
	logic ack;						// response acknowledge
	logic rty;						// retry
	logic err;						// error
	wb_priority_t pri;		// response priority
	wb_address_t adr;
	logic [15:0] dat;			// data
} wb_cmd_response16_t;

typedef struct packed {
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic stall;					// stall pipeline
	logic next;						// advance to next transaction
	logic ack;						// response acknowledge
	logic rty;						// retry
	logic err;						// error
	wb_priority_t pri;		// response priority
	wb_address_t adr;
	logic [31:0] dat;			// data
} wb_cmd_response32_t;

typedef struct packed {
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic stall;					// stall pipeline
	logic next;						// advance to next transaction
	logic ack;						// response acknowledge
	logic rty;						// retry
	logic err;						// error
	wb_priority_t pri;		// response priority
	wb_address_t adr;
	logic [31:0] dat;			// data
} wb_response32_t;

typedef struct packed {
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic stall;					// stall pipeline
	logic next;						// advance to next transaction
	logic ack;						// response acknowledge
	logic rty;						// retry
	logic err;						// error
	wb_priority_t pri;		// response priority
	wb_address_t adr;
	logic [63:0] dat;			// data
} wb_cmd_response64_t;

typedef struct packed {
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic stall;					// stall pipeline
	logic next;						// advance to next transaction
	logic ack;						// response acknowledge
	logic rty;						// retry
	logic err;						// error
	wb_priority_t pri;		// response priority
	wb_address_t adr;
	logic [127:0] dat;		// data
} wb_cmd_response128_t;

typedef struct packed {
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic stall;					// stall pipeline
	logic next;						// advance to next transaction
	logic ack;						// response acknowledge
	logic rty;						// retry
	logic err;						// error
	wb_priority_t pri;		// response priority
	wb_address_t adr;
	logic [127:0] dat;		// data
} wb_response128_t;

typedef struct packed {
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic stall;					// stall pipeline
	logic next;						// advance to next transaction
	logic ack;						// response acknowledge
	logic rty;						// retry
	logic err;						// error
	wb_priority_t pri;		// response priority
	wb_address_t adr;
	logic [255:0] dat;		// data
} wb_cmd_response256_t;

typedef struct packed {
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic stall;					// stall pipeline
	logic next;						// advance to next transaction
	logic ack;						// response acknowledge
	logic rty;						// retry
	logic err;						// error
	wb_priority_t pri;		// response priority
	wb_address_t adr;
	logic [511:0] dat;		// data
} wb_cmd_response512_t;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Write responses
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Sometimes write cycles can expect data responses back too. This is typically
// just a single bit. For instance, the reservation status. Write responses all
// have a common structure.

typedef struct packed {
	wb_channel_t cid;			// channel id
	wb_tranid_t tid;			// transaction id
	logic stall;					// stall pipeline
	logic next;						// advance to next transaction
	logic ack;						// response acknowledge
	logic rty;						// retry
	logic err;						// error
	wb_priority_t pri;		// response priority
	logic [7:0] dat;			// data
} wb_write_response_t;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// read/write requests
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

typedef struct packed
{
	wb_read_request8_t read;
	wb_cmd_request8_t write;
} wb_readwrite_request8_t;

typedef struct packed
{
	wb_read_request16_t read;
	wb_cmd_request16_t write;
} wb_readwrite_request16_t;

typedef struct packed
{
	wb_read_request32_t read;
	wb_cmd_request32_t write;
} wb_readwrite_request32_t;

typedef struct packed
{
	wb_read_request64_t read;
	wb_cmd_request64_t write;
} wb_readwrite_request64_t;

typedef struct packed
{
	wb_read_request128_t read;
	wb_cmd_request128_t write;
} wb_readwrite_request128_t;

typedef struct packed
{
	wb_read_request256_t read;
	wb_cmd_request256_t write;
} wb_readwrite_request256_t;

typedef struct packed
{
	wb_read_request512_t read;
	wb_cmd_request512_t write;
} wb_readwrite_request512_t;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// read / write responses
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

typedef struct packed
{
	wb_cmd_response8_t read;
	wb_write_response_t write;
} wb_readwrite_response8_t;

typedef struct packed
{
	wb_cmd_response16_t read;
	wb_write_response_t write;
} wb_readwrite_response16_t;

typedef struct packed
{
	wb_cmd_response32_t read;
	wb_write_response_t write;
} wb_readwrite_response32_t;

typedef struct packed
{
	wb_cmd_response64_t read;
	wb_write_response_t write;
} wb_readwrite_response64_t;

typedef struct packed
{
	wb_cmd_response128_t read;
	wb_write_response_t write;
} wb_readwrite_response128_t;

typedef struct packed
{
	wb_cmd_response256_t read;
	wb_write_response_t write;
} wb_readwrite_response256_t;

typedef struct packed
{
	wb_cmd_response512_t read;
	wb_write_response_t write;
} wb_readwrite_response512_t;

endpackage

interface wb_request_i #(int WID);
	wb_burst_type_t bte;		// burst type extension
	wb_cycle_type_t cti;		// cycle type indicator
	wb_burst_len_t blen;		// length of burst-1
	wb_segment_t seg;				// segment
	logic cyc;							// valid cycle
	logic stb;							// data strobe
	logic we;								// write enable
	wb_address_t adr;				// address
	logic [WID/8-1:0] sel;	// byte lane selects
	logic [WID-1:0] dat;		// data
	wb_channel_t cid;				// channel id
	wb_tranid_t tid;				// transaction id
	logic csr;							// set or clear reservation we:1=clear 0=set
	wb_priv_level_t pl;			// privilege level
	wb_priority_t pri;			// transaction priority
	wb_cache_t cache;				// cache and buffer properties
endinterface

interface wb_response_i #(int WID);
	wb_channel_t cid;				// channel id
	wb_tranid_t tid;				// transaction id
	logic stall;						// stall pipeline
	logic next;							// advance to next transaction
	logic ack;							// response acknowledge
	logic rty;							// retry
	logic err;							// error
	wb_priority_t pri;			// response priority
	logic [WID-1:0] dat;		// data
endinterface
