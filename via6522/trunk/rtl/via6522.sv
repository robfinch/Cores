`define PB		4'd0
`define PA		4'd1
`define DDRB	4'd2
`define DDRA	4'd3
`define T1CL	4'd4
`define T1CH	4'd5
`define T1LL	4'd6
`define T1LH	4'd7
`define T2CL	4'd8
`define T2CH	4'd9
`define SR		4'd10
`define ACR		4'd11
`define PCR		4'd12
`define IFR		4'd13
`define IER		4'd14
`define ORA		4'd15

module via6522(rst_i, clk_i, irq_o, cs_i,
	cyc_i, stb_i, ack_o, we_i, sel_i, adr_i, dat_i, dat_o, 
	pa, pb, ca1, ca2, cb1, cb2);
input rst_i;
input clk_i;
output irq_o;
input cs_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [3:0] sel_i;
input [5:2] adr_i;
input [31:0] dat_i;
output reg [31:0] dat_o;

inout [31:0] pa;
inout [31:0] pb;
input ca1;
inout ca2;
inout cb1;
inout cb2;

integer n;

wire cs = cs_i & cyc_i & stb_i;

ack_gen #(
	.READ_STAGES(2),
	.WRITE_STAGES(0),
	.REGISTER_OUTPUT(1)
) uag1
(
	.clk_i(clk_i),
	.ce_i(1'b1),
	.i(cs),
	.we_i(cs & we_i),
	.o(ack_o)
);

reg [31:0] pai, pbi;		// input registers
reg [31:0] pao, pbo;		// output latches
reg [31:0] pal, pbl;		// input latches
reg pa_le, pb_le;				// latching enable
reg [31:0] ddra, ddrb;	// data direction registers
reg [1:0] t1_mode;
reg t2_mode;
reg [63:0] t1, t2, t3;	// 64 bit timers
reg t1_if;							// timer 1 interrupt flag
reg t2_if;							// timer 2 interrupt flag
reg t3_if;							// timer 3 interrupt flag
reg t1_64, t2_64;
reg [63:0] t1l;
reg [63:0] t2l;
reg [63:0] t3l;
wire ca1_trans, ca2_trans;	// active transitions
wire cb1_trans, cb2_trans;
reg ca1_mode;
reg cb1_mode;
reg [2:0] ca2_mode;
reg [2:0] cb2_mode;
reg [7:0] sr;						// shift register
reg [2:0] s_mode;				// shift register mode
wire ca1_pe, ca1_ne, ca1_ee;
wire ca2_pe, ca2_ne, ca2_ee;
wire pb6_ne;

edge_det ued1 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(ca1), .pe(ca1_pe), .ne(ca1_ne), .ee(ca1_ee));
edge_det ued2 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(ca1), .pe(ca1_pe), .ne(ca1_ne), .ee(ca2_ee));
edge_det ued3 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(pb[6]), .pe(), .ne(pb6_ne), .ee());

assign ca1_trans = (ca1_mode & ca1_pe) | (~ca1_mode & ca1_ne);
assign ca2_trans = (ca2_mode[2:1]==2'b00&&ca2_ne)||(ca2_mode[2:1]==2'b01&&ca2_pe);
assign cb1_trans = (cb1_mode & cb1_pe) | (~cb1_mode & cb1_ne);
assign cb2_trans = (cb2_mode[2:1]==2'b00&&cb2_ne)||(cb2_mode[2:1]==2'b01&&cb2_pe);

always @(posedge clk_i)
if (rst_i) begin
	ddra <= 32'd0;
	ddrb <= 32'd0;
	t1_64 <= 1'b0;
	t2_64 <= 1'b0;
	t1 <= 64'hFFFFFFFFFFFFFFFF;
	t1_if <= 1'b0;
	t2 <= 64'hFFFFFFFFFFFFFFFF;
	t2_if <= 1'b0;
end
else begin

	// Port A,B input latching
	// Port A input latches always reflect the input pins.
	if (pa_le) begin
		if (ca1_trans)
			pai <= pa;
	end
	else
		pai <= pa;

	// Port B input latches reflect the contents of the output register if the
	// port pin direction is an output.
	if (pb_le) begin
		if (cb1_trans)
			for (n = 0; n < 32; n = n + 1)
				pbi <= ddrb[n] ? pbo[n] : pb[n];
	end
	else begin
		for (n = 0; n < 32; n = n + 1)
			pbi <= ddrb[n] ? pbo[n] : pb[n];
	end

 	// Bring ca2 back high on pulse output mode
 	if (ca2_mode==3'b100 && ca1_trans)
 		ca2 <= 1'b1;
 	else if (ca2_mode==3'b101)
 		ca2 <= 1'b1;
 	if (cb2_mode==3'b100 && cb1_trans)
 		cb2 <= 1'b1;
 	else if (cb2_mode==3'b101)
 		cb2 <= 1'b1;
	
	t1 <= t1 - 2'd1;
	if (t1==64'd0) begin
		t1_if <= 1'b1;
		case(t1_mode)
		2'd2:	pbo[7] <= 1'b1;
		2'd3:	pbo[7] <= ~pbo[7];
		default:	;
		endcase
	end

	case(t2_mode)
	1'd0:	t2 <= t2 - 2'd1;
	1'd1:	if (pb6_ne) t2 <= t2 - 2'd1;
	endcase
	if (t2==64'd0)
		t2_if <= 1'b1;

	if (cs) begin
		if (we_i) begin
			case(adr_i)
			`PA:
				begin
					if (sel_i[0]) pao[7:0] <= dat_i[7:0];
					if (sel_i[1]) pao[15:8] <= dat_i[15:8];
					if (sel_i[2]) pao[23:16] <= dat_i[23:16];
					if (sel_i[3]) pao[31:24] <= dat_i[31:24];
			 		if (ca2_mode==3'b100||ca2_mode==3'b101)
			 			ca2 <= 1'b0;
				end
			`PB:
				begin
					if (sel_i[0]) pab[7:0] <= dat_i[7:0];
					if (sel_i[1]) pab[15:8] <= dat_i[15:8];
					if (sel_i[2]) pab[23:16] <= dat_i[23:16];
					if (sel_i[3]) pab[31:24] <= dat_i[31:24];
			 		if (cb2_mode==3'b100||cb2_mode==3'b101)
			 			cb2 <= 1'b0;
				end
			`DDRA:	
				begin
					if (sel_i[0]) ddra[7:0] <= dat_i[7:0];
					if (sel_i[1]) ddra[15:8] <= dat_i[15:8];
					if (sel_i[2]) ddra[23:16] <= dat_i[23:16];
					if (sel_i[3]) ddra[31:24] <= dat_i[31:24];
				end
			`DDRB:	
				begin
					if (sel_i[0]) ddrb[7:0] <= dat_i[7:0];
					if (sel_i[1]) ddrb[15:8] <= dat_i[15:8];
					if (sel_i[2]) ddrb[23:16] <= dat_i[23:16];
					if (sel_i[3]) ddrb[31:24] <= dat_i[31:24];
				end
			`T1CL:
				begin
					if (sel_i[0]) t1l[7:0] <= dat_i[7:0];
					if (sel_i[1]) t1l[15:8] <= dat_i[15:8];
					if (sel_i[2]) t1l[23:16] <= dat_i[23:16];
					if (sel_i[3]) t1l[31:24] <= dat_i[31:24];
				end
			`T1CH:
				begin
					if (t1_64) begin
						if (&sel_i) t1 <= {dat_i,t1l[31:0]};
					end
					else
						t1 <= {48'h0,dat_i[7:0],t1l[7:0]};
					t1_if <= 1'b0;
					if (t1_mode[1]==1'b1)
						pbo[7] <= 1'b0;
				end	
			`T1LL:
				begin
					if (sel_i[0]) t1l[7:0] <= dat_i[7:0];
					if (sel_i[1]) t1l[15:8] <= dat_i[15:8];
					if (sel_i[2]) t1l[23:16] <= dat_i[23:16];
					if (sel_i[3]) t1l[31:24] <= dat_i[31:24];
				end
			`T1LH:
				begin
					if (t1_64) begin
						if (sel_i[0]) t1l[39:32] <= dat_i[7:0];
						if (sel_i[1]) t1l[47:40] <= dat_i[15:8];
						if (sel_i[2]) t1l[55:48] <= dat_i[23:16];
						if (sel_i[3]) t1l[63:56] <= dat_i[31:24];
					end
					else
						t1l[63:8] <= {48'd0,dat_i[7:0]};
					t1_if <= 1'b0;
				end
			`T2CL:
				begin
					if (sel_i[0]) t2l[7:0] <= dat_i[7:0];
					if (sel_i[1]) t2l[15:8] <= dat_i[15:8];
					if (sel_i[2]) t2l[23:16] <= dat_i[23:16];
					if (sel_i[3]) t2l[31:24] <= dat_i[31:24];
				end
			`T2CH:
				begin
					if (t2_64) begin
						if (&sel_i) t2 <= {dat_i,t2l[31:0]};
					end
					else
						t2 <= {48'h0,dat_i[7:0],t2l[7:0]};
					t2_if <= 1'b0;
				end	
			`PCR:
				begin
					ca1_mode <= dat_i[0];
					ca2_mode <= dat_i[3:1];
			 		if (dat_i[3:1]==3'b110)
			 			ca2 <= 1'b0;
			 		else if (dat_i[3:1]==3'b111)
			 			ca2 <= 1'b1;
			 		cb1_mode <= dat_i[4];
			 		cb2_mode <= dat_i[7:5];
			 		if (dat_i[7:5]==3'b110)
			 			cb2 <= 1'b0;
			 		else if (dat_i[7:5]==3'b111)
			 			cb2 <= 1'b1;
				end
			`SR:	sr <= dat_i[7:0];
			`ACR:
				begin
					if (sel_i[0]) begin
						pa_le <= dat_i[0];
						pb_le <= dat_i[1];
						s_mode <= dat_i[4:2];
						t2_mode <= dat_i[5];
						t1_mode <= dat_i[7:6];
					end
					if (sel_i[1]) begin
						t1_64 <= dat_i[8];
						t2_64 <= dat_i[9];
					end
				end
			`ORA:
				begin
					if (sel_i[0]) pao[7:0] <= dat_i[7:0];
					if (sel_i[1]) pao[15:8] <= dat_i[15:8];
					if (sel_i[2]) pao[23:16] <= dat_i[23:16];
					if (sel_i[3]) pao[31:24] <= dat_i[31:24];
				end
			endcase
		end	
		else begin
			case(adr_i)
			`PA:
				begin
			 		if (ca2_mode==3'b100||ca2_mode==3'b101)
			 			ca2 <= 1'b0;
				end
			`DDRA:	dat_o <= ddra;
			`DDRB:	dat_o <= ddrb;
			`T1CL:	
				begin
					dat_o <= t1[31:0];
					t1_if <= 1'b0;
				end
			`T1CH:
				if (t1_64)
					dat_o <= t1[63:32];
				else
					dat_o <= {24'd0,t1[15:8]};
			`T1LL:	dat_o <= t1l[31:0];
			`T1LH:
				if (t1_64)
					dat_o <= t1l[63:32];
				else
					dat_o <= {24'd0,t1l[15:8]};
			`T2CL:	
				begin
					dat_o <= t2[31:0];
					t2_if <= 1'b0;
				end
			`T2CH:
				if (t2_64)
					dat_o <= t2[63:32];
				else
					dat_o <= {24'd0,t2[15:8]};
			`SR:	dat_o <= {24'd0,sr};
			`ORA:	dat_o <= pa;
			endcase
		end
	end
end

always @*
	for (n = 0; n < 32; n = n + 1)
		pa[n] = ddra[n] ? pao[n] : 1'bz;
		
always @*
	for (n = 0; n < 32; n = n + 1)
		pb[n] = ddrb[n] ? pbo[n] : 1'bz;


endmodule
