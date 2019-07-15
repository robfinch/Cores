/* ===============================================================
	(C) 2001 Bird Computer
	All rights reserved.

	timer.v

		Please read the Licensing Agreement included in
	license.doc. Use of this file is subject to the
	license agreement.

	Reg
	0		Maximum count reg bits[7:0] - read / write
	1		Maximum count reg bits[15:8]
	2		Maximum count reg bits[23:16]
	3		Maximum count reg bits[31:24]
	4		snapshot count bits[7:0] - read only
	5		snapshot count bits[15:8] - read only
	6		snapshot count bits[23:16] - read only
	7		snapshot count bits[31:24] - read only
	8		control reg.
			Read - Bit 7 will be set if the counter has reached
			the maximum (terminal) count since the last time
			this register was reset
			Write - clears the terminal count status
			bit 0 - enables counter to count
			bit 1 - enables auto repeat - if auto repeat is
				enabled, the counter will reset and continue
				counting once the max count is reached
			bit 2 - enables terminal count interrupt
	10		Snap shot reg.
			Write - writing this register causes a snapshot of
			the current count to be taken. The current count as
			at the time of snapshot can then be read from the
			snap shot count registers.
=============================================================== */
module timer(reset, clk, ce, cs, rw, a, di, do, irq);
	input reset;
	input clk;
	input ce;
	input cs;
	input rw;
	input [3:0] a;
	input [7:0] di;
	output [7:0] do;
	output irq;

	reg [31:0] cnt, max_cnt;
	reg [31:0] snap_cnt;
	reg snap_shot;
	reg auto_rep;
	reg cnt_en;
	reg tc;			// terminal count reached
	reg irq_en;

	assign irq = tc & irq_en;
	reg [7:0] do0;
	always @(a or max_cnt) begin
		case(a[1:0])
		2'd0:	do0 <= max_cnt[7:0];
		2'd1:	do0 <= max_cnt[15:8];
		2'd2:	do0 <= max_cnt[23:16];
		2'd3:	do0 <= max_cnt[31:24];
		endcase
	end

	reg [7:0] do1;
	always @(a or snap_cnt) begin
		case(a[1:0])
		2'd0:	do1 <= snap_cnt[7:0];
		2'd1:	do1 <= snap_cnt[15:8];
		2'd2:	do1 <= snap_cnt[23:16];
		2'd3:	do1 <= snap_cnt[31:24];
		endcase
	end

	reg [7:0] do2;
	always @(tc or irq_en or auto_rep or cnt_en) begin
		do2 <= {tc,4'b0,irq_en,auto_rep,cnt_en};
	end

	reg [7:0] do4;
	always @(a[3:2]) begin
		case(a[3:2])
		2'd0:	do4 <= do0;
		2'd1:	do4 <= do1;
		2'd2:	do4 <= do2;
		2'd3:	do4 <= do2;
		endcase
	end
	
	assign do = cs & rw ? do4 : 8'bz;
			
	
	always @(posedge clk) begin
		if (reset) begin
			max_cnt <= 32'd0;
			cnt <= 32'd0;
			cnt_en <= 1'b0;
			auto_rep <= 1'b0;
			tc <= 1'b0;
			irq_en <= 1'b0;
		end
		else begin

			if (ce) begin
				// write registers
				if (cs & ~rw) begin
					case(a[3:0])
					4'd0:	max_cnt[7:0] <= di;
					4'd1:	max_cnt[15:8] <= di;
					4'd2:	max_cnt[23:16] <= di;
					4'd3:	max_cnt[31:24] <= di;
					4'd8:	begin
							cnt_en <= di[0];
							auto_rep <= di[1];
							irq_en <= di[2];
							tc <= 1'b0;
							end
					4'd9:	snap_shot <= 1'b1;
					default:
						;
					endcase
				end
		
				// handle the counter
				if (cnt_en) begin
					if (cnt >= max_cnt) begin
						cnt <= 32'd0;
						tc <= 1'b1;
						if (~auto_rep)
							cnt_en <= 1'b0;
					end
					else
						cnt <= cnt + 1;
				end
	
				// take a snapshot ?
				if (snap_shot) begin
					snap_shot <= 1'b0;
					snap_cnt <= cnt;
				end

			end // ce
		end
	end

endmodule
