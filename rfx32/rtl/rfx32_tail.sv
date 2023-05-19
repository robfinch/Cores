import rfx32pkg::*;

module rfx32_tail(rst, clk, branchmiss, tail0, tail1);
input rst;
input clk;
input branchmiss;
output reg [2:0] tail0;
output reg [2:0] tail1;

always_ff @(posedge clk, posedge rst)
if (rst) begin
	tail0 <= 3'd0;
	tail1 <= 3'd1;
end
else begin
	if (branchmiss) begin	// if branchmiss
    if (iqentry_stomp[0] & ~iqentry_stomp[7]) begin
			tail0 <= 0;
			tail1 <= 1;
    end
    else if (iqentry_stomp[1] & ~iqentry_stomp[0]) begin
			tail0 <= 1;
			tail1 <= 2;
    end
    else if (iqentry_stomp[2] & ~iqentry_stomp[1]) begin
			tail0 <= 2;
			tail1 <= 3;
    end
    else if (iqentry_stomp[3] & ~iqentry_stomp[2]) begin
			tail0 <= 3;
			tail1 <= 4;
    end
    else if (iqentry_stomp[4] & ~iqentry_stomp[3]) begin
			tail0 <= 4;
			tail1 <= 5;
    end
    else if (iqentry_stomp[5] & ~iqentry_stomp[4]) begin
			tail0 <= 5;
			tail1 <= 6;
    end
    else if (iqentry_stomp[6] & ~iqentry_stomp[5]) begin
			tail0 <= 6;
			tail1 <= 7;
    end
    else if (iqentry_stomp[7] & ~iqentry_stomp[6]) begin
			tail0 <= 7;
			tail1 <= 0;
    end
	end
end

endmodule
