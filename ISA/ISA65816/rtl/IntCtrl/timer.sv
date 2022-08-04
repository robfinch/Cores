module timer(rst, clk, ph2, cs, rw, ad, dbi, dbo, irq);
input rst;
input clk;
input ph2;
input cs;
input rw;
input [2:0] ad;
input [7:0] dbi;
output reg [7:0] dbo;
output reg irq;

reg [23:0] clkdv;
reg [23:0] count;
reg [7:0] ctrl;
reg [7:0] tmp;
wire updcount;
reg clrirq;
wire ce;		// count enable
wire irqe;	// irq enable
wire ar;		// auto reload

always_ff @(negedge ph2)
if (rst) begin
	clkdv <= 24'd500000;
	clrirq <= 1'b0;
	ctrl <= 8'h00;
	tmp <= 8'h00;
end
else begin
	clrirq <= 1'b0;
	ctrl[2] <= 1'b0;
	if (cs & ~rw)
		case(ad[2:0])
		3'd0:	clkdv[7:0] <= dbi;
		3'd1: clkdv[15:8] <= dbi;
		3'd2:	clkdv[23:16] <= dbi;
		3'd3: begin
					ctrl <= dbi;
					clrirq <= 1'b1;
					end
		3'd7:	tmp <= dbi;
		default:	;
		endcase
end

always_ff @(posedge ph2)
if (rst) begin
end
else begin
	case(ad[2:0])
	3'd0:	dbo <= clkdv[7:0];
	3'd1: dbo <= clkdv[15:8];
	3'd2:	dbo <= clkdv[23:0];
	3'd3:	dbo <= ctrl;
	3'd4:	dbo <= count[7:0];
	3'd5:	dbo <= count[15:8];
	3'd6:	dbo <= count[23:16];
	3'd7:	dbo <= tmp;
	endcase
end

assign ce = ctrl[0];
assign ar = ctrl[1];
assign irqe = ctrl[6];
assign updcount = ctrl[2];

always_ff @(posedge clk)
if (rst) begin
	count <= 24'd500000;
	irq <= 1'b0;
end
else begin
	if (clrirq)
		irq <= 1'b0;
	if (updcount)
		count <= clkdv;
	else if (count==24'h0) begin
		if (irqe)
			irq <= 1'b1;
		if (ar)
			count <= clkdv;
	end
	else if (ce) begin
		count <= count - 2'd1;
	end
end

endmodule