
module WaitStates(rst, clk, cs, rdy);
parameter WAIT_STATES = 3;
parameter IDLE = 2'd1;
parameter ACCESS = 2'd2;
input rst;
input clk;
input cs;
output rdy;

reg rdy2;
reg [3:0] rcnt;
reg [1:0] state;
assign rdy = cs & rdy2;
always @(posedge clk)
if (rst) begin
	rcnt <= 4'd0;
	rdy2 <= 1'b0;
	state <= IDLE;
end
else begin
rcnt <= rcnt + 4'd1;
case(state)
IDLE:
	if (cs) begin
		state <= ACCESS;
		rcnt <= 4'd0;
	end
ACCESS:
	begin
		if (rcnt == WAIT_STATES)
			rdy2 <= 1'b1;
		if (rcnt == WAIT_STATES+4'd1) begin
		    rdy2 <= 1'b0;
			state <= IDLE;
		end
	end
endcase
end
endmodule
