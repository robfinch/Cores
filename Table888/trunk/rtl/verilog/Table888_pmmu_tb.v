module Table888_pmmu_tb();
reg rst;
reg clk;
wire cyc;
wire stb;
wire ack;
wire wr;
wire [3:0] sel;
wire [31:0] adr;
wire [31:0] dat;
wire [31:0] dato;
reg [63:0] pta;
wire [63:0] pte;
reg [63:0] vcadr;
wire [63:0] tcadr;
wire rdy;
wire [3:0] p;
wire c,r,w,x,v;
reg [7:0] state;
reg mack;
reg [31:0] mdat;
reg dwr;

initial begin
	clk = 1;
	rst = 0;
	#100 rst = 1;
	#100 rst = 0;
end

always #1 clk = ~clk;	// 500 MHz
Table888_pmmu u1
(
// syscon
.rst_i(rst),
.clk_i(clk),

// master
.soc_o(),		// start of cycle
.cyc_o(cyc),		// bus cycle active
.stb_o(stb),
.lock_o(),		// lock the bus
.ack_i(ack),		// acknowledge from memory system
.wr_o(wr),		// write enable output
.byt_o(sel),	// lane selects (always all active)
.adr_o(adr),
.dat_i(dat),	// data input from memory
.dat_o(dato),	// data to memory

// Translation request / control
.invalidate(),		// invalidate a specific entry
.invalidate_all(),	// causes all entries to be invalidated
.pta(pta),		// page directory/table address register
.rst_pnp(),			// reset the pnp bit
.pnp(),			// page not present
.pte(pte),	// holding place for data

.vcadr(vcadr),		// virtual code address to translate
.tcadr(tcadr),	// translated code address
.rdy(rdy),				// address translation is ready
.p(p),		// privilege (0= supervisor)
.c(c),
.r(r),
.w(w),
.x(x),		// cacheable, read, write and execute attributes
.v(v),			// translation is valid

.wr(dwr),				// cpu is performing write cycle
.vdadr(vcadr),		// virtual data address to translate
.tdadr(),	// translated data address
.drdy(),				// address translation is ready
.dp(),
.dc(),
.dr(),
.dw(),
.dx(),
.dv()
);

assign ack = mack;
assign dat = mdat;

always @(posedge clk)
if (rst) begin
	state <= 0;
	pta <= 64'h0000;
	vcadr <= 64'h0000;
	dwr <= 1'b0;
end
else begin
state <= state + 8'd1;
case(state[7:4])
0:	pta <= 64'h00006005;
1:	vcadr <= 64'h0000;
2:	begin vcadr <= 64'h2056; dwr <= 1'b1; end
3:	begin dwr <= 1'b0; end
endcase
end

always @(adr)
begin
	if (cyc & stb) begin
		mack <= 1'b1;
		case(adr[15:0])
		16'h6000:	mdat <= 32'h50FF;
		16'h6004:	mdat <= 32'h0000;
		16'h5000:	mdat <= 32'h40FF;
		16'h5004:	mdat <= 32'h0000;
		16'h4000:	mdat <= 32'h30FF;
		16'h4004:	mdat <= 32'h0000;
		16'h3000:	mdat <= 32'h20FF;
		16'h3004:	mdat <= 32'h0000;
		16'h2000:	mdat <= 32'h10FF;
		16'h2004:	mdat <= 32'h0000;
		16'h1000:	mdat <= 32'h00FF;
		16'h1004:	mdat <= 32'h1234;
		16'h1010:	mdat <= 32'h55FF;
		16'h1014:	mdat <= 32'h5555;
		endcase
	end
	else begin
		mack <= 1'b0;
		mdat <= 32'h0;
	end
end

endmodule
