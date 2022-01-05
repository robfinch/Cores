import nic_pkg::*;

module sys_node(rst_i, clk_i, packet_i, packet_o);
input rst_i;
input clk_i;
input Packet packet_i;
output Packet packet_o;

reg [5:0] state;

always_ff @(posedge clk_i)
if (rst_i) begin
end
else begin
	packet_o <= packet_i;
	case(state)
	ST_IDLE:
		begin
		end
	endcase
end

endmodule
