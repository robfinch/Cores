`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
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
// IOBridge128wb.v
//
// Adds FF's into the io path. This makes it easier for the place and
// route to take place. 
// Multiple devices are connected to the master port side of the bridge.
// The slave side of the bridge is connected to the cpu. The bridge looks
// like just a single device then to the cpu.
// The cost is an extra clock cycle to perform I/O accesses. For most
// devices which are low-speed it doesn't matter much.
//
// 401 LUTs / 276 FFs              
// ============================================================================
//
import fta_bus_pkg::*;

module IOBridge128fta(rst_i, clk_i, s1_req, s1_resp, m_req, ch0resp, ch1resp );
parameter IDLE = 3'd0;
parameter WAIT_ACK = 3'd1;
parameter WAIT_NACK = 3'd2;
parameter WR_ACK = 3'd3;
parameter WR_ACK2 = 3'd4;
parameter ASYNCH = 1'b1;

input rst_i;
input clk_i;
input fta_cmd_request128_t s1_req;
output fta_cmd_response128_t s1_resp;
output fta_cmd_request64_t m_req;
input fta_cmd_response64_t ch0resp;
input fta_cmd_response64_t ch1resp;

integer nn;
reg which;
reg [2:0] state;

reg [7:0] tid1, tid2;
reg [3:0] cid1, cid2;
reg [31:0] adr1, adr2;

// Create low order four address lines.
reg [3:0] s1_a30, s2_a30;

fta_cmd_response64_t [1:0] resps;
fta_cmd_response64_t respo;
assign resps[0] = ch0resp;
assign resps[1] = ch1resp;

fta_respbuf #(2) urespb1
(
	.rst(rst_i),
	.clk(clk_i),
	.resp(resps),
	.resp_o(respo)
)
always @(posedge clk_i)
if (rst_i) begin
	m_req <= 'd0;
end
else begin
  // Filter requests to the I/O address range
  if (s1_req.cyc) begin
    m_req.bte <= s1_req.bte;
    m_req.cti <= s1_req.cti;
    m_req.cyc <= 1'b1;
    m_req.stb <= s1_req.stb;
    m_req.cid <= s1_req.cid;
    m_req.tid <= s1_req.tid;
    m_req.padr <= s1_req.padr;
    m_req.sel <= s1_req.sel[15:8]|s1_req.sel[7:0];
    m_req.we <= s1_req.we;
  end
  else begin
  	m_req.cyc <= 'd0;
  	m_req.stb <= 'd0;
  	m_req.we <= 'd0;
  	m_req.sel <= 'd0;
  	m_req.padr <= 32'hFFFFFFFF;
	end
  if (s1_req.cyc)
		m_req.dat <= s1_req.data1 >> {|s1_req.sel[15:8],6'd0};
	else begin
		m_req.dat <= 'd0;

	// Handle responses	
	s1_resp.ack <= respo.ack;
	s1_resp.err <= respo.err;
	s1_resp.rty <= respo.rty;
	s1_resp.next <= respo.next;
	s1_resp.stall <= respo.stall;
	s1_resp.dat <= {2{respo.dat}};
	s1_resp.cid <= respo.cid;
	s1_resp.tid <= respo.tid;
	s1_resp.adr <= respo.adr;
	s1_resp.pri <= respo.pri;
end

endmodule

