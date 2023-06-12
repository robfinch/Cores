
import fta_bus_pkg::*;

module ledport_fta64(rst, clk, cs, req, resp, led);
input rst;
input clk;
input cs;
input fta_cmd_request64_t req;
output fta_cmd_response64_t resp;
output reg [7:0] led;

always_ff @(posedge clk, posedge rst)
if (rst)
	led <= 'd0;
else begin
	if (cs)
		led <= req.dat[7:0];
end

assign resp.cid = req.cid;
assign resp.tid = req.tid;		
assign resp.ack = cs;
assign resp.err = 'd0;
assign resp.rty = 'd0;
assign resp.pri = 4'd7;
assign resp.adr = req.padr;
assign resp.dat = 'd0;

endmodule
