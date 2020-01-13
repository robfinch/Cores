module Gambit_pmmu_tb();
reg rst;
reg clk;
reg [103:0] memo;
wire cyc;
wire stb;
reg ack;
wire we;
wire [7:0] sel;
wire [51:0] adr;
wire [103:0] dato;
wire [103:0] dati;

reg [2:0] vol;
reg [7:0] vpl;
reg [7:0] vasid;
reg vicl;
reg vcyc;
reg vstb;
reg vack;
reg vwe;
reg [7:0] vsel;
reg [51:0] vadr;
reg invall;
reg [51:0] pta;

initial begin
	rst = 1'b0;
	#20 rst = 1'b1;
	#150 rst = 1'b0;
	clk = 1'b0;
	state = 8'h00;
	count = 8'h00;
	vcyc = 1'b0;
	vstb = 1'b0;
	vwe = 1'b0;
	vsel = 8'h00;
	vadr = 52'd0;
	vack = 1'b0;
	invall = 1'b0;
	pta = 52'h01000;
end

reg [103:0] mem [0:4095];
always @*
begin
	casez(adr[14:0])
	15'h000?:	memo = 104'h0;
	15'h001?:	memo = 104'h1234567890123;
	15'h002?:	memo = {4{$urandom()}};
	15'h003?:	memo = {4{$urandom()}};
	15'h004?:	memo = {4{$urandom()}};
	15'h005?:	memo = {4{$urandom()}};
	15'h006?:	memo = {4{$urandom()}};
	15'h007?:	memo = {4{$urandom()}};
	default:	memo = mem[adr[14:3]];
	endcase
end
always @(posedge clk)
	if (we)
		mem[adr[14:13]] <= dato;
assign dati = memo;

reg [7:0] state;
reg [7:0] count;

always #2 clk = ~clk;

always @(posedge clk)
if (rst) begin
	state <= 8'h00;
	count <= 8'h00;
	vcyc <= 1'b0;
	vstb <= 1'b0;
	vwe <= 1'b0;
	vsel <= 8'h00;
	vadr <= 52'h0;
	ack <= 1'b0;
end
else begin
	ack <= cyc;
	case(state)
	8'h00:
		if (!vack) begin
			vol <= 3'b000;
			vpl <= 8'h00;
			vasid <= 8'h00;
			vicl <= 1'b1;
			vcyc <= 1'b1;
			vstb <= 1'b1;
			vwe <= 1'b0;
			vsel <= 8'hFF;
			vadr <= {40'd0,count,4'h0};
			state <= 8'h01;
		end
	8'h01:
		if (vack) begin
			vcyc <= 1'b0;
			vstb <= 1'b0;
			count <= count + 8'd1;
			if (count < 8'd7)
				state <= 8'h00;
			else
				state <= 8'h02;
		end
	8'h02:
		state <= 8'h02;
	endcase
end

Gambit_pmmu #(.AMSB(51)) upmmu1
(
// syscon
	.rst_i(rst),
	.clk_i(clk),

	.age_tick_i(1'b0),			// indicates when to age reference counts

// master
	.cyc_o(cyc),		// valid memory address
	.stb_o(stb),		// strobe
	.lock_o(),	// lock the bus
	.ack_i(ack),		// acknowledge from memory system
	.we_o(we),		// write enable output
	.sel_o(sel),	// lane selects (always all active)
	.padr_o(adr),
	.dat_i(dati),	// data input from memory
	.dat_o(dato),	// data to memory

// Translation request / control
	.invalidate(1'b0),		// invalidate a specific entry
	.invalidate_all(invall),	// causes all entries to be invalidated
	.pta(pta),		// page directory/table address register
	.page_fault(),

	.asid_i(vasid),
	.pl_i(vpl),
	.ol_i(vol),		// operating level
	.icl_i(vicl),				// instruction cache load
	.cyc_i(vcyc),
	.stb_i(vstb),
	.ack_o(vack),
	.we_i(vwe),				    // cpu is performing write cycle
	.sel_i(vsel),
	.vadr_i(vadr),	    // virtual address to translate

	.cac_o(),		// cachable
	.prv_o(),		// privilege violation
	.exv_o(),		// execute violation
	.rdv_o(),		// read violation
	.wrv_o()		// write violation
);

endmodule
 