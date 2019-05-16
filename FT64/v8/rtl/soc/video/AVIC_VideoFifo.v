module AVIC_VideoFifo(wrst, wclk, wr, di, rrst, rclk, rd, dout, cnt);
input wrst;
input wclk;
input wr;
input [127:0] di;
input rrst;
input rclk;
input rd;
output reg [15:0] dout;
output [7:0] cnt;
reg [7:0] cnt;

reg [7:0] wr_ptr;
reg [10:0] rd_ptr,rrd_ptr;
reg [127:0] mem [0:255];

wire [7:0] wr_ptr_p1 = wr_ptr + 8'd1;
wire [10:0] rd_ptr_p1 = rd_ptr + 11'd1;
reg [10:0] rd_ptrs;

always @(posedge wclk)
	if (wrst)
		wr_ptr <= 8'd0;
	else if (wr) begin
		mem[wr_ptr] <= di;
		wr_ptr <= wr_ptr_p1;
	end
always @(posedge wclk)		// synchronize read pointer to wclk domain
	rd_ptrs <= rd_ptr;

always @(posedge rclk)
	if (rrst)
		rd_ptr <= 11'd0;
	else if (rd)
		rd_ptr <= rd_ptr_p1;
always @(posedge rclk)
	rrd_ptr <= rd_ptr;

always @(posedge rclk)
case(rrd_ptr[2:0])
3'd0:	dout <= mem[rrd_ptr[10:3]][15:0];
3'd1:	dout <= mem[rrd_ptr[10:3]][31:16];
3'd2:	dout <= mem[rrd_ptr[10:3]][47:32];
3'd3:	dout <= mem[rrd_ptr[10:3]][63:48];
3'd4:	dout <= mem[rrd_ptr[10:3]][79:64];
3'd5:	dout <= mem[rrd_ptr[10:3]][95:80];
3'd6:	dout <= mem[rrd_ptr[10:3]][111:96];
3'd7:	dout <= mem[rrd_ptr[10:3]][127:112];
endcase

always @(wr_ptr or rd_ptrs)
	if (rd_ptrs > wr_ptr)
		cnt <= wr_ptr + (9'd256 - rd_ptrs[10:3]);
	else
		cnt <= wr_ptr - rd_ptrs;

endmodule
