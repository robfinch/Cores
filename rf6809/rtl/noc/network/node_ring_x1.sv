// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	node_ring_x1.sv
//
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

import nic_pkg::*;

module node_ring_x1(rst_i, clk_i, packet_i, packet_o, rpacket_i, rpacket_o,
	ipacket_i, ipacket_o);
input rst_i;
input clk_i;
input Packet packet_i;
output Packet packet_o;
input Packet rpacket_i;
output Packet rpacket_o;
input IPacket ipacket_i;
output IPacket ipacket_o;
parameter N=8;

Packet [N:0] packets;
Packet [N:0] rpackets;
IPacket [N:0] ipackets;
reg [35:0] pc [0:N];

assign packets[0] = packet_i;
assign rpackets[0] = rpacket_i;
assign ipackets[0] = ipacket_i;

genvar g;
generate begin : gNodes


for (g = 0; g < N; g = g + 1)
 	pnode_x1 upn (
 		.id(g[5:0]+1),
 		.rst_i(rst_i),
 		.clk_i(clk_i),
 		.packet_i(packets[g]),
 		.packet_o(packets[g+1]),
 		.rpacket_i(rpackets[g]),
 		.rpacket_o(rpackets[g+1]),
 		.ipacket_i(ipackets[g]),
 		.ipacket_o(ipackets[g+1]),
 		.pc(pc[g])
 	);

end
endgenerate

nic_ager uage1(
	.clk_i(clk_i),
	.packet_i(packets[N]),
	.packet_o(packet_o),
	.rpacket_i(rpackets[N]),
	.rpacket_o(rpacket_o),
	.ipacket_i(ipackets[N]),
	.ipacket_o(ipacket_o)
);

endmodule
