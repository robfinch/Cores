// ============================================================================
//        __
//   \\__/ o\    (C) 2022-2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rfx32_cache_pkg.sv
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

package rfx32_cache_pkg;

parameter ITAG_BIT = 14;
parameter DCacheLineWidth = 512;
localparam DCacheTagLoBit = $clog2((DCacheLineWidth/8));
parameter ICacheLineWidth = 512;
localparam ICacheTagLoBit = $clog2((ICacheLineWidth/8))-1;
parameter pL1DCacheWays = 4;

`define TAG_ASID $bits(rfx32pkg::asid_t) + $bits(rfx32pkg::address_t)-ITAG_BIT-1:$bits(rfx32pkg::address_t)-ITAG_BIT

//typedef logic [$bits(rfx32pkg::asid_t) + $bits(rfx32pkg::address_t)-ITAG_BIT-1:0] cache_tag_t;
typedef logic [$bits(rfx32pkg::address_t)-1:ITAG_BIT] cache_tag_t;

typedef struct packed
{
	logic v;		// valid indicator
	logic m;		// modified indicator
	rfx32pkg::asid_t asid;
	logic [$bits(rfx32pkg::address_t)-1:0] vtag;	// virtual tag
	logic [$bits(rfx32pkg::address_t)-1:0] ptag;	// physical tag
	logic [DCacheLineWidth-1:0] data;
} DCacheLine;

typedef struct packed
{
	logic [ICacheLineWidth/128-1:0] v;	// 1 valid bit per 128 bits data
	logic m;		// modified indicator
	rfx32pkg::asid_t asid;
	logic [$bits(rfx32pkg::address_t)-1:0] vtag;	// virtual tag
	logic [$bits(rfx32pkg::address_t)-1:0] ptag;	// physical tag
	logic [ICacheLineWidth-1:0] data;
} ICacheLine;

endpackage
