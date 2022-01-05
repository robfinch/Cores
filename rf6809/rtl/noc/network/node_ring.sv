import nic_pkg::*;

module node_ring(rst_i, clk_i, packet_i, packet_o);
input rst_i;
input clk_i;
input Packet packet_i;
output Packet packet_o;

Packet [8:0] packets;

assign packets[0] = packet_i;

genvar g;
generate begin : gNodes

for (g = 0; g < 8; g = g + 1)
 	pnode(g[3:0]+1, rst_i, clk_i, packets[g], packets[g+1]);

end
endgenerate

nic_ager uage1(clk_i, packets[8], packet_o);

endmodule

