import nic_pkg::*;

module nic_prop(rst_i, clk_i, packet_i, packet_o, ipacket_i, ipacket_o);
input rst_i;
input clk_i;
input Packet packet_i;
output Packet packet_o;
input IPacket ipacket_i;
output IPacket ipacket_o;

always @(posedge clk_i)
if (rst_i) begin
	packet_o <= {$bits(Packet){1'b0}};
	ipacket_o <= {$bits(IPacket){1'b0}};
end
else begin
	packet_o <= packet_i;
	ipacket_o <= ipacket_i;
end

endmodule
