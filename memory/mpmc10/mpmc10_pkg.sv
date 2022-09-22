// ============================================================================
//        __
//   \\__/ o\    (C) 2015-2022  Robert Finch, Waterloo
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
package mpmc10_pkg;

parameter CACHE_ASSOC = 4;

parameter RMW = 0;
parameter NAR = 2;
parameter AMSB = 28;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter CMD_READ = 3'b001;
parameter CMD_WRITE = 3'b000;
// State machine states
parameter IDLE = 4'd0;
parameter PRESET1 = 4'd1;
parameter PRESET2 = 4'd2;
parameter WRITE_DATA0 = 4'd3;
parameter WRITE_DATA1 = 4'd4;
parameter WRITE_DATA2 = 4'd5;
parameter WRITE_DATA3 = 4'd7;
parameter READ_DATA0 = 4'd8;
parameter READ_DATA1 = 4'd9;
parameter READ_DATA2 = 4'd10;
parameter WAIT_NACK = 4'd11;
parameter WRITE_TRAMP = 4'd12;	// write trampoline
parameter WRITE_TRAMP1 = 4'd13;
parameter PRESET3 = 4'd14;

typedef logic [5:0] tranid_t;
typedef logic [7:0] priv_level_t;
typedef logic [31:0] address_t;

// Max number of bytes to transfer in a beat
typedef enum logic [2:0] {
	AXISZ_1 = 3'b000,
	AXISZ_2 = 3'b001,
	AXISZ_4 = 3'b010,
	AXISZ_8 = 3'b011,
	AXISZ_16 = 3'b100,
	AXISZ_32 = 3'b101,
	AXISZ_64 = 3'b110,
	AXISZ_128 = 3'b111
} axi_size_t;

typedef enum logic [1:0] {
	AXI_FIXED = 2'b00,
	AXI_INCR = 2'b01,
	AXI_WRAP = 2'b10
} axi_burst_t;

// Spec has a messed up memory type table, so I've defined the following
// some values which are different than spec.

typedef enum logic [3:0] {
	AXI_DEV_NO_BUFFER = 4'b0000,
	AXI_DEV_BUFFER = 4'b0001,
	AXI_NO_BUFFER_NO_CACHE = 4'b0010,
	AXI_BUFFER_NO_CACHE = 4'b0011,
	AXI_WRITETHRU_NO_ALLOCATE = 4'b1000,
	AXI_WRITETHRU_READ_ALLOCATE = 4'b1001,
	AXI_WRITETHRU_WRITE_ALLOCATE = 4'b1010,
	AXI_WRITETHRU_READ_WRITE_ALLOCATE = 4'b1011,
	AXI_WRITEBACK_NO_ALLOCATE = 4'b1100,
	AXI_WRITEBACK_READ_ALLOCATE = 4'b1101,
	AXI_WRITEBACK_WRITE_ALLOCATE = 4'b1110,
	AXI_WRITEBACK_READ_WRITE_ALLOCATE = 4'b1111
} axi_cache_t;

typedef struct packed
{
	priv_level_t pl;	// privilege level 0 to 255
	logic insn;				// 1=instruction, 0=data
	logic secure;			// 0=secure, 1=non secure
	logic privileged;	// 1=privileged,0=non-privileged
} axi_prot_t;

typedef logic [3:0] axi_qos_t;
typedef logic [3:0] axi_region_t;

typedef enum logic [1:0] {
	AXI_OKAY = 2'b00,
	AXI_EXOKAY = 2'b01,
	AXI_SLVERR = 2'b10,
	AXI_DECERR = 2'b11
} axi_response_t;

typedef struct packed
{
	logic [23:0] tag;
	logic [7:0] modified;
	logic [255:0] data;
} mpmc10_cache_line_t;

typedef struct packed {
	// Globals
	logic ACLK;
	logic ARESETn;
} axi_globals_t;

typedef struct packed {
	logic ARCLK;							// clock, not part of AXI
	logic [3:0] ARCH;					// channel number, not part of AXI
	logic ARSR;
	// Address Channel	
	mpmc10_pkg::tranid_t ARID;
	mpmc10_pkg::address_t ARADDR;
	logic [7:0] ARLEN; 
	mpmc10_pkg::axi_size_t ARSIZE;
	mpmc10_pkg::axi_burst_t ARBURST;
	logic ARLOCK;
	mpmc10_pkg::axi_cache_t ARCACHE;
	mpmc10_pkg::axi_prot_t ARPROT;
	mpmc10_pkg::axi_qos_t ARQOS;
	mpmc10_pkg::axi_region_t ARREGION;
	logic ARUSER;
	logic ARVALID;
	// Data channel
	logic RREADY;
} axi_request_read_t;

typedef struct packed {
	logic [1:0] ARWAY;				// cache way, not part of AXI
	// Address Channel	
	logic ARREADY;
	// Data channel
	mpmc10_pkg::tranid_t RID;
	logic [159:0] RDATA;
	mpmc10_pkg::axi_response_t RRESP;
	logic RLAST;
	logic RUSER;
	logic RVALID;
} axi_response_read128_t;

typedef struct packed {
	logic [1:0] ARWAY;				// cache way, not part of AXI
	// Address Channel	
	logic ARREADY;
	// Data channel
	mpmc10_pkg::tranid_t RID;
	logic [287:0] RDATA;
	mpmc10_pkg::axi_response_t RRESP;
	logic RLAST;
	logic RUSER;
	logic RVALID;
} axi_response_read256_t;

typedef struct packed {
	logic AWCLK;									// write clock (not part of AXI)
	logic [1:0] AWWAY;						// not part of AXI
	logic [3:0] AWCH;
	logic AWCR;
	// Address channel
	mpmc10_pkg::tranid_t AWID;
	mpmc10_pkg::address_t AWADDR;
	logic [7:0] AWLEN;					// burst length -1, number of transfers in burst
	mpmc10_pkg::axi_size_t AWSIZE;
	mpmc10_pkg::axi_burst_t AWBURST;
	logic AWLOCK;								// deprecated (not used for AXI4)
	mpmc10_pkg::axi_cache_t AWCACHE;
	mpmc10_pkg::axi_prot_t AWPROT;
	mpmc10_pkg::axi_qos_t AWQOS;
	mpmc10_pkg::axi_region_t AWREGION;
	logic AWUSER;
	logic AWVALID;
	// Data channel
	logic [159:0] WDATA;
	logic [19:0] WSTRB;					// byte lane enables
	logic WLAST;								// 1= last transfer in write burst
	logic WUSER;
	logic WVALID;								// 1= strobes and data are valid
	// Write response
	logic BREADY;								// 1= master is ready for write response
} axi_request_write128_t;

typedef struct packed {
	logic AWCLK;									// write clock (not part of AXI)
	logic [1:0] AWWAY;						// not part of AXI
	logic [3:0] AWCH;
	logic AWCR;
	// Address channel
	mpmc10_pkg::tranid_t AWID;
	mpmc10_pkg::address_t AWADDR;
	logic [7:0] AWLEN;					// burst length -1, number of transfers in burst
	mpmc10_pkg::axi_size_t AWSIZE;
	mpmc10_pkg::axi_burst_t AWBURST;
	logic AWLOCK;								// deprecated (not used for AXI4)
	mpmc10_pkg::axi_cache_t AWCACHE;
	mpmc10_pkg::axi_prot_t AWPROT;
	mpmc10_pkg::axi_qos_t AWQOS;
	mpmc10_pkg::axi_region_t AWREGION;
	logic AWUSER;
	logic AWVALID;
	// Data channel
	logic [287:0] WDATA;
	logic [35:0] WSTRB;					// byte lane enables
	logic WLAST;								// 1= last transfer in write burst
	logic WUSER;
	logic WVALID;								// 1= strobes and data are valid
	// Write response
	logic BREADY;								// 1= master is ready for write response
} axi_request_write256_t;

typedef struct packed {
	logic AWREADY;							// 1= slave can accept an address
	// Data channel
	logic WREADY;							// 1= slave can accept data
	// Write response
	mpmc10_pkg::tranid_t BID;
	mpmc10_pkg::axi_response_t BRESP;
	logic BUSER;								// optional, user defined
	logic BVALID;							// 1= response is valid
} axi_response_write_t;

typedef struct packed {
	axi_request_read_t read;
	axi_request_write128_t write;
} axi_request_readwrite128_t;

typedef struct packed {
	axi_request_read_t read;
	axi_request_write256_t write;
} axi_request_readwrite256_t;

typedef struct packed {
	axi_response_read128_t read;
	axi_response_write_t write;
} axi_response_readwrite128_t;

typedef struct packed {
	axi_response_read256_t read;
	axi_response_write_t write;
} axi_response_readwrite256_t;


endpackage

interface axi_globals_i;
	// Globals
	logic ACLK;
	logic ARESETn;
	modport gbl (input ACLK, ARESETn);
endinterface

interface axi_response_write256_i;
	logic WCLK;									// write clock (not part of AXI)
	logic [1:0] WWAY;						// not part of AXI
	logic [3:0] WCH;						// write channel not part of AXI
	logic AWCR;									// clear reservation, not part of AXI
	// Address channel
	mpmc10_pkg::tranid_t AWID;
	mpmc10_pkg::address_t AWADDR;
	logic [7:0] AWLEN;					// burst length -1, number of transfers in burst
	mpmc10_pkg::axi_size_t AWSIZE;
	mpmc10_pkg::axi_burst_t AWBURST;
	logic AWLOCK;								// deprecated (not used for AXI4)
	mpmc10_pkg::axi_cache_t AWCACHE;
	mpmc10_pkg::axi_prot_t AWPROT;
	mpmc10_pkg::axi_qos_t AWQOS;
	mpmc10_pkg::axi_region_t AWREGION;
	logic AWUSER;
	logic AWVALID;
	logic AWREADY;							// 1= slave can accept an address
	modport aw (input WCLK, WWAY, AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWLOCK,
		AWCACHE, AWPROT, AWQOS, AWREGION, AWUSER, AWVALID, output AWREADY);
	// Data channel
	logic [287:0] WDATA;
	logic [35:0] WSTRB;					// byte lane enables
	logic WLAST;								// 1= last transfer in write burst
	logic WUSER;
	logic WVALID;								// 1= strobes and data are valid
	logic WREADY;							// 1= slave can accept data
	modport dw (input WDATA, WSTRB, WLAST, WUSER, WVALID, output WREADY);
	// Write response
	mpmc10_pkg::tranid_t BID;
	mpmc10_pkg::axi_response_t BRESP;
	logic BUSER;								// optional, user defined
	logic BVALID;							// 1= response is valid
	logic BREADY;								// 1= master is ready for write response
	modport rw (input BREADY, output BID, BRESP, BUSER, BVALID);
endinterface

interface axi_response_read256_i;
	logic RCLK;									// read clock (not part of AXI)
	logic [1:0] RWAY;					// not part of AXI
	logic [3:0] RCH;					// read channel, not part of AXI
	logic ARSR;								// set reservation, not part of AXI
	// Address Channel	
	mpmc10_pkg::tranid_t ARID;
	mpmc10_pkg::address_t ARADDR;
	logic [7:0] ARLEN;
	mpmc10_pkg::axi_size_t ARSIZE;
	mpmc10_pkg::axi_burst_t ARBURST;
	logic ARLOCK;
	mpmc10_pkg::axi_cache_t ARCACHE;
	mpmc10_pkg::axi_prot_t ARPROT;
	mpmc10_pkg::axi_qos_t ARQOS;
	mpmc10_pkg::axi_region_t ARREGION;
	logic ARUSER;
	logic ARVALID;
	logic ARREADY;
	modport ar (input RCLK, ARID, ARADDR, ARLEN, ARSIZE, ARBURST, ARLOCK,
		ARCACHE, ARPROT, ARQOS, ARREGION, ARUSER, ARVALID, output ARREADY);
	// Data channel
	mpmc10_pkg::tranid_t RID;
	logic [287:0] RDATA;
	mpmc10_pkg::axi_response_t RRESP;
	logic RLAST;
	logic RUSER;
	logic RVALID;
	logic RREADY;
	modport rr (input RREADY, output RID, RDATA, RRESP, RLAST, RUSER, RVALID);
endinterface

interface axi_response_readwrite256_i;
	axi_globals_i gbl();
	axi_response_read256_i read();
	axi_response_write256_i write();
endinterface

interface axi_response_write128_i;
	logic WCLK;									// write clock (not part of AXI)
	logic [1:0] WWAY;						// not part of AXI
	// Address channel
	mpmc10_pkg::tranid_t AWID;
	mpmc10_pkg::address_t AWADDR;
	logic [7:0] AWLEN;					// burst length -1, number of transfers in burst
	mpmc10_pkg::axi_size_t AWSIZE;
	mpmc10_pkg::axi_burst_t AWBURST;
	logic AWLOCK;								// deprecated (not used for AXI4)
	mpmc10_pkg::axi_cache_t AWCACHE;
	mpmc10_pkg::axi_prot_t AWPROT;
	mpmc10_pkg::axi_qos_t AWQOS;
	mpmc10_pkg::axi_region_t AWREGION;
	logic AWUSER;
	logic AWVALID;
	logic AWREADY;							// 1= slave can accept an address
	modport aw (input WCLK, WWAY, AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWLOCK,
		AWCACHE, AWPROT, AWQOS, AWREGION, AWUSER, AWVALID, output AWREADY);
	// Data channel
	logic [159:0] WDATA;
	logic [19:0] WSTRB;					// byte lane enables
	logic WLAST;								// 1= last transfer in write burst
	logic WUSER;
	logic WVALID;								// 1= strobes and data are valid
	logic WREADY;							// 1= slave can accept data
	modport dw (input WDATA, WSTRB, WLAST, WUSER, WVALID, output WREADY);
	// Write response
	mpmc10_pkg::tranid_t BID;
	mpmc10_pkg::axi_response_t BRESP;
	logic BUSER;								// optional, user defined
	logic BVALID;							// 1= response is valid
	logic BREADY;								// 1= master is ready for write response
	modport rw (input BREADY, output BID, BRESP, BUSER, BVALID);
endinterface

interface axi_response_read128_i;
	logic RCLK;									// read clock (not part of AXI)
	logic [1:0] RWAY;					// not part of AXI
	// Address Channel	
	mpmc10_pkg::tranid_t ARID;
	mpmc10_pkg::address_t ARADDR;
	logic [7:0] ARLEN;
	mpmc10_pkg::axi_size_t ARSIZE;
	mpmc10_pkg::axi_burst_t ARBURST;
	logic ARLOCK;
	mpmc10_pkg::axi_cache_t ARCACHE;
	mpmc10_pkg::axi_prot_t ARPROT;
	mpmc10_pkg::axi_qos_t ARQOS;
	mpmc10_pkg::axi_region_t ARREGION;
	logic ARUSER;
	logic ARVALID;
	logic ARREADY;
	modport ar (input RCLK, ARID, ARADDR, ARLEN, ARSIZE, ARBURST, ARLOCK,
		ARCACHE, ARPROT, ARQOS, ARREGION, ARUSER, ARVALID, output ARREADY);
	// Data channel
	mpmc10_pkg::tranid_t RID;
	logic [159:0] RDATA;
	mpmc10_pkg::axi_response_t RRESP;
	logic RLAST;
	logic RUSER;
	logic RVALID;
	logic RREADY;
	modport rr (input RREADY, output RID, RDATA, RRESP, RLAST, RUSER, RVALID);
endinterface

interface axi_response_readwrite128_i;
	axi_globals_i gbl();
	axi_response_read128_i read();
	axi_response_write128_i write();
endinterface

