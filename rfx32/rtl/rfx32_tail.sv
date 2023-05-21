import rfx32pkg::*;

module rfx32_tail(rst, clk, branchmiss, fetchbuf0_v, fetchbuf1_v,fetchbuf0_instr, iqentry_stomp, iq, tail0, tail1);
input rst;
input clk;
input branchmiss;
input fetchbuf0_v;
input fetchbuf1_v;
input instruction_t fetchbuf0_instr;
input [7:0] iqentry_stomp;
input iq_entry_t [7:0] iq;
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
	else begin
		case ({fetchbuf0_v, fetchbuf1_v})
		2'b00:	;
		2'b01:
			if (iq[tail0].v == INV) begin
				tail0 <= tail0 + 2'd1;
				tail1 <= tail1 + 2'd1;
			end
		2'b10:
			if (iq[tail0].v == INV) begin
				tail0 <= tail0 + 2'd1;
				tail1 <= tail1 + 2'd1;
			end
		2'b11:
			if (iq[tail0].v == INV) begin
				if (fnIsBackBranch(fetchbuf0_instr) == TRUE) begin
					tail0 <= tail0 + 2'd1;
					tail1 <= tail1 + 2'd1;
				end
				else begin
			    if (iq[tail1].v == INV) begin
						tail0 <= tail0 + 3'd2;
						tail1 <= tail1 + 3'd2;
			    end
			    else begin
						tail0 <= tail0 + 3'd1;
						tail1 <= tail1 + 3'd1;
					end				
				end
			end
		endcase
	end
end

endmodule
