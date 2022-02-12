module TimeoutList(rst_i, clk_i, dec, insert, timeout_i, tid_i, zeros_o, empty_o, rdq_i);
input rst_i;
input clk_i;
input dec;
input insert;
input [47:0] timeout_i;
input [11:0] tid_i;
output [11:0] zeros_o;
output empty_o;
input rdq_i;

reg [3:0] state, state1;
parameter IDLE = 4'd0;
parameter REMOVE = 4'd1;
parameter SEARCH = 4'd2;
parameter AT_END = 4'd3;
parameter INSERT = 4'd4;
parameter INSERT1 = 4'd5;
parameter SET_NEXT = 4'd6;
parameter SET_TIMEOUT = 4'd7;
parameter SET_NEXT_TIMEOUT = 4'd8;

reg [11:0] head;
reg [47:0] timeout_h;
reg [47:0] timeout [0:4095];
reg [11:0] tid [0:4095];
reg [11:0] next [0:4095];
reg [11:0] n,m;
reg [11:0] ndx;
reg ack;
reg wrq;

ReadyFifo uqx (
  .clk(clk_i),                // input wire clk
  .srst(rst_i),              // input wire srst
  .din(head),                // input wire [7 : 0] din
  .wr_en(wrq),            // input wire wr_en
  .rd_en(rdq_i),            // input wire rd_en
  .dout(zeros_o),              // output wire [7 : 0] dout
  .full(),              // output wire full
  .empty(empty_o),            // output wire empty
  .valid(),            // output wire valid
  .data_count()  // output wire [5 : 0] data_count
);


always_ff @(posedge clk_i)
if (rst_i)
	state <= IDLE;
else
	case(state)
	IDLE:
		if (!ack) begin
			// Perform a decrement cycle
			if (dec) begin
				if (head) begin
					tmout <= timeout[head] - 2'd1;
					if (timeout[head]==48'd1)
						state <= REMOVE;
					else begin
						tndx <= head;
						state <= SET_TIMEOUT;
						state1 <= IDLE;
					end
				end
			end
			else if (insert) begin
				if (head==0) begin
					head <= tid_i;
					nxt <= 'd0;
					tmout <= timeout_i;
					nndx <= tid_i;
					tndx <= tid_i;
					state <= SET_NEXT_TIMEOUT;
					state1 <= IDLE;
					ack <= 1'b1;
				end
				else begin
					n <= head;
					m <= 'd0;
					timeout_h <= timeout_i;
					state <= SEARCH;
				end
			end
		end
	// Keep popping the head of the list until a NULL is hit, or the timeout
	// will be non-zero.
	REMOVE:
		begin
			head <= next[head];
			if (head==12'd0)
				state <= IDLE;
			else if (timeout[head]!=48'd1)
				state <= IDLE;
		end
	SEARCH:
		// Insert at end?
		if (n==12'd0) begin
			tndx <= tid_i;
			nndx <= tid_i;
			tmout <= timeout_h;
			ndx <= 'd0;
			state <= SET_NEXT_TIMEOUT;
			state1 <= AT_END;
		end
		else if (timeout_h > timeout[n]) begin
			timeout_h <= timeout_h - timeout[n];
			m <= n;
			n <= next[n];
		end
		else
			state <= INSERT;
	AT_END:
		begin
			nndx <= m;
			ndx <= tid_i;
			state <= SET_NEXT;
			state1 <= IDLE;
			ack <= 1'b1;
		end
	// timeout_h < timeout[n]
	INSERT:
		begin
			tmout <= timeout[n] - timeout_h;
			tndx <= n;
			nndx <= tid_i;
			ndx <= n;
			state <= SET_NEXT_TIMEOUT;
			state1 <= INSERT1;
		end
	INSERT1:
		begin
			if (m) begin
				nndx <= m;
				ndx <= tid_i;
				state <= SET_NEXT;
				state1 <= IDLE;
			end
			else begin
				head <= tid_i;
				state <= IDLE;
			end
			ack <= 1'b1;
		end
	SET_NEXT:
		begin
			next[nndx] <= nxt;
			state <= state1;
		end
	SET_TIMEOUT:
		begin
			timeout[tndx] <= tmout;
			state <= state1;
		end
	SET_NEXT_TIMEOUT:
		begin
			next[nndx] <= nxt;
			timeout[tndx] <= tmout;
			state <= state1;
		end
	default:
		state <= IDLE;
	endcase

endmodule
