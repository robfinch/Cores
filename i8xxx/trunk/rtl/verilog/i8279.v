module i8279(rst_i, clk_i, cyc_i, stb_i, ack_o, we_i, sel_i, adr_i, dat_i, dat_o, sl_o, rl_i, shift, cntl_stb, outa, outb, bd_o, irq_o);
parameter pClkFreq=60000000;
parameter pDivisor=pClkFreq/100000;
input  rst_i;
input  clk_i;
input  cyc_i;
input  stb_i;
output ack_o;
input  we_i;
input  [1:0] sel_i;
input  adr_i;
input  [7:0] dat_i;
output [15:0] dat_o;
reg    [15:0] dat_o;
output [7:0] sl_o;
reg    [7:0] sl_o;
input  [7:0] rl_i;
input  shift;
input  cntl_stb;
output [3:0] outa;
reg    [3:0] outa;
output [3:0] outb;
reg    [3:0] outb;
output bd_o;
reg    bd_o;
output irq_o;

reg [1:0] dd;		// display mode
reg [2:0] kk;		// keyboard mode
reg em;				// error mode
reg read_fifo;
reg [7:0] sensor_ram [7:0];
wire sensor_matrix_mode = (kkk==3'd4) || (kkk==3'd5);
wire scan_ce = ps_cntr==16'd0;

wire cs = cyc_i & stb_i;

//--------------------------------------------
// Scan Counter Section
//--------------------------------------------

reg [12:0] pp;		// clock prescaler
reg [3:0] scan_counter;
reg [12:0] ps_cntr;
wire decoded_scan = kkk[0];

// Scan prescale counter
//
always @(posedge clk_i)
if (rst_i)
	ps_cntr <= 16'd0;
else begin
	if (ps_cntr==16'd0)
		ps_cntr <= pp;
	else
		ps_cntr <= ps_cntr - 16'd1;
end

// Scan counter
// Should be run about 100kHz
//
always @(posedge clk_i)
if (scan_ce)
	scan_counter <= scan_counter + 4'd1;

// Scan counter output
//
always @(posedge clk_i)
if (decoded_scan)
	case(scan_counter[2:0])
	3'd0:	sl_o <= 8'b00000001;
	3'd1:	sl_o <= 8'b00000010;
	3'd2:	sl_o <= 8'b00000100;
	3'd3:	sl_o <= 8'b00001000;
	3'd4:	sl_o <= 8'b00010000;
	3'd5:	sl_o <= 8'b00100000;
	3'd6:	sl_o <= 8'b01000000;
	3'd7:	sl_o <= 8'b10000000;
	endcase
else
	sl_o <= {2{scan_counter}};


//--------------------------------------------
// Display RAM Section
//--------------------------------------------

reg ai;				// auto increment
reg read_ram;
reg write_ram;
reg [3:0] aa;		// display ram address
reg wma,wmb;

wire wra = cyc_i & stb_i & we_i & !adr_i & write_ram & !wma;
wire wrb = cyc_i & stb_i & we_i & !adr_i & write_ram & !wmb;

reg [3:0] display_ramA [15:0];
always @(posedge clk_i)
if (wra) display_ramA[aa] <= dat_i[7:4];

reg [3:0] display_ramB [15:0];
always @(posedge clk_i)
if (wrb) display_ramB[aa] <= dat_i[3:0];

wire [7:0] dr_out = {display_ramA[aa],display_ramB[aa]};

always @(posedge clk_i)
outa <= display_ramA[scan_counter];
always @(posedge clk_i)
outb <= display_ramB[scan_counter];

//--------------------------------------------
// Register Read Output
//--------------------------------------------

always @(cyc_i or stb_i or read_ram or read_fifo or sensor_matrix_mode or aa)
if (cyc_i & stb_i)
	if (read_ram)
		dat_o <= dr_out;
	else if (read_fifo) begin
		if (sensor_matrix_mode) begin
			dat_o <= sensor_ram[aa[2:0]];
			if (ai) aa <= aa + 4'd1;
		end
		else
			dat_o <= fifo_q;
	end
else
	dat_o <= 16'h0000;


always @(posedge clk_i)
if (rst_i) begin
	kkk <= 3'd0;
	pp <= 13'h01FF;
end
else begin
	if (wra|wrb)
		if (ai) aa <= aa + 4'd1;

	if (cyc_i & stb_i) begin
		if (we_i) begin
			if (adr_i) begin
				case(dat_i[7:5])
				3'd0:
					if (sel_i[0] begin
						dd <= dat_i[4:3];
						kkk <= dat_i[2:0];
					end
				3'd1:
					begin
						if (sel_i[0]) pp[ 4:0] <= dat_i[ 4:0];
						if (sel_i[1]) pp[12:5] <= dat_i[15:8];
					end
				3'd2:
					begin
						read_ram <= 1'b0;
						read_fifo <= 1'b1;
						if (sensor_matrix_mode) begin
							aa[2:0] <= dat_i[2:0];
							ai <= dat_i[4];
						end
					end
				3'd3:
					begin
						read_ram <= 1'b1;
						read_fifo <= 1'b0;
						ai <= dat_i[4];
					end
				3'd4:
					begin
						write_ram <= 1'b1;
						aa <= dat_i[3:0];
						ai <= dat_i[4];
					end
				3'd7:
					begin
						em <= dat_i[4];
						irq_o <= 1'b0;
					end
				endcase
			end
			else begin
				if (write_ram) begin
					if (ai) aa <= aa + 4'd1;
				end
			end
		end
		else begin
			if (adr_i) begin
			end
			else begin
				if (read_ram) begin
					if (ai) aa <= aa + 4'd1;
				end
			end
		end
	end
end

endmodule
