
module Timeouter(rst_i, clk_i, dec_i, set_i, qry_i, tid_i, timeout_i, timeout_o, zeros_o, done_o);
input rst_i;
input clk_i;
input dec_i;
input set_i;
input qry_i;
input [3:0] tid_i;
input [31:0] timeout_i;
output reg [31:0] timeout_o;
output reg [15:0] zeros_o;
output reg done_o;

reg [31:0] tmo [0:15];
reg [3:0] ndx;
reg [2:0] state;
parameter IDLE = 3'd0;
parameter DEC1 = 3'd1;
parameter SET1 = 3'd2;
parameter QRY1 = 3'd3;

always @(posedge clk_i)
if (rst_i) begin
	zeros_o <= 16'hFFFF;
	done_o <= 1'b1;
	goto (IDLE);
end
else begin
case(state)
IDLE:
	begin
		if (dec_i) begin
			ndx <= 4'd0;
			goto (DEC1);
		end
		else if (set_i) begin
			ndx <= tid_i;
			done_o <= 1'b0;
			goto (SET1);
		end
		else if (qry_i) begin
			ndx <= tid_i;
			done_o <= 1'b0;
			goto (QRY1);
		end		
	end
DEC1:
	begin
		ndx <= ndx + 1;
		if (tmo[ndx] > 32'd0) begin
			tmo[ndx] <= tmo[ndx] - 2'd1;
			zeros_o[ndx] <= 1'b0;
		end
		else
			zeros_o[ndx] <= 1'b1;
		if (ndx==4'd15) begin
			goto (IDLE);
		end
	end
SET1:
	begin
		tmo[ndx] <= timeout_i;
		done_o <= 1'b1;
		goto (IDLE);
	end
QRY1:
	begin
		timeout_o <= tmo[ndx];
		done_o <= 1'b1;
		goto (IDLE);
	end
endcase
end

task goto;
input [2:0] nst;
begin
	state <= nst;
end
endtask

endmodule
