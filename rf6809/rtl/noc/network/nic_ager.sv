// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	nic_ager.sv
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

module nic_ager(clk_i, packet_i, packet_o, ipacket_i, ipacket_o);
input clk_i;
input Packet packet_i;
output Packet packet_o;
input IPacket ipacket_i;
output IPacket ipacket_o;

always_ff @(posedge clk_i)
begin
	packet_o <= packet_i;
	ipacket_o <= ipacket_i;
	// Age only valid packets packet
//	if ((packet_i.sid|packet_i.did) != 6'd0)
	// An age of zero makes the packet immortal.
	if (packet_i.age != 6'd0)
		packet_o.age <= packet_i.age + 2'd1;
//	ipacket_o.age <= ipacket_i.age + 2'd1;
	// If the packet is too old, flag as available.
	if (packet_i.age == 6'd63)
		packet_o <= {$bits(Packet){1'b0}};
//	if (ipacket_i.age == 6'd7)
//		ipacket_o <= {$bits(IPacket){1'b0}};
end

endmodule
