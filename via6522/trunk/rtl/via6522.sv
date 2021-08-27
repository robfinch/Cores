// ============================================================================
//        __
//   \\__/ o\    (C) 2004-2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	via6522.sv
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// ============================================================================

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
	pa, pb, ca1, ca2, cb1, cb2,
	pa_i, pb_i, pa_o, pb_o
	);
input rst_i;
input clk_i;
output reg irq_o;
input cs_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [3:0] sel_i;
input [5:2] adr_i;
input [31:0] dat_i;
output reg [31:0] dat_o;

inout tri [31:0] pa;
inout tri [31:0] pb;
input ca1;
inout tri ca2;
inout tri cb1;
inout tri cb2;
input [31:0] pa_i;
input [31:0] pb_i;
output [31:0] pa_o;
output [31:0] pb_o;

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

reg [5:0] ie_delay;
reg [8:0] ier, ierd;	  // interrupt enable register / delayed interrupt enable register
reg [31:0] pai, pbi;		// input registers
reg [31:0] pao, pbo;		// output latches
reg [31:0] pal, pbl;		// input latches
reg pa_le, pb_le;				// latching enable
reg [31:0] ddra, ddrb;	// data direction registers
reg cb1o, cb2o, ca2o;
reg [1:0] t1_mode;
reg t2_mode, t3_mode;
reg [63:0] t1, t2, t3;	// 64 bit timers
reg t1_if;							// timer 1 interrupt flag
reg t2_if;							// timer 2 interrupt flag
reg t3_if;							// timer 3 interrupt flag
reg t3_access;
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
reg [4:0] sr_cnt;				// shift register counter
reg [31:0] sr;					// shift register
reg sr_32;							// shift register 32 bit mode
reg [2:0] sr_mode;			// shift register mode
reg sr_if;
wire ca1_pe, ca1_ne, ca1_ee;
wire ca2_pe, ca2_ne, ca2_ee;
wire cb1_pe, cb1_ne, cb1_ee;
reg ca1_if, cb1_if;
reg ca2_if, cb2_if;
wire pb6_ne;
reg ca1_irq, ca2_irq;
reg cb1_irq, cb2_irq;
reg t1_irq, t2_irq, t3_irq;
reg sr_irq;
wire pe_t1z, pe_t2z, pe_t3z;

edge_det ued1 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(ca1), .pe(ca1_pe), .ne(ca1_ne), .ee(ca1_ee));
edge_det ued2 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(ca2), .pe(ca2_pe), .ne(ca2_ne), .ee(ca2_ee));
edge_det ued3 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(cb1), .pe(cb1_pe), .ne(cb1_ne), .ee(cb1_ee));
edge_det ued4 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(cb2), .pe(cb2_pe), .ne(cb2_ne), .ee(cb2_ee));
edge_det ued5 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(pb[6]), .pe(), .ne(pb6_ne), .ee());
edge_det ued6 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(t3==64'd0), .pe(pe_t3z), .ne(), .ee());
edge_det ued7 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(t2==64'd0), .pe(pe_t2z), .ne(), .ee());
edge_det ued8 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(t1==64'd0), .pe(pe_t1z), .ne(), .ee());


assign ca1_trans = (ca1_mode & ca1_pe) | (~ca1_mode & ca1_ne);
assign ca2_trans = (ca2_mode[2:1]==2'b00&&ca2_ne)||(ca2_mode[2:1]==2'b01&&ca2_pe);
assign cb1_trans = (cb1_mode & cb1_pe) | (~cb1_mode & cb1_ne);
assign cb2_trans = (cb2_mode[2:1]==2'b00&&cb2_ne)||(cb2_mode[2:1]==2'b01&&cb2_pe);

always @(posedge clk_i)
if (rst_i) begin
	ddra <= 32'd0;
	ddrb <= 32'd0;
	ca1_irq <= 1'b0;
	ca2_irq <= 1'b0;
	cb1_irq <= 1'b0;
	cb2_irq <= 1'b0;
	ca2o <= 1'b0;
	cb1o <= 1'b0;
	cb2o <= 1'b0;
	t1_64 <= 1'b0;
	t2_64 <= 1'b0;
	sr_mode <= 3'b000;
	sr_32 <= 1'b0;
	sr_if <= 1'b0;
	t1 <= 64'hFFFFFFFFFFFFFFFF;
	t1_if <= 1'b0;
	t2 <= 64'hFFFFFFFFFFFFFFFF;
	t2_if <= 1'b0;
	t3 <= 64'hFFFFFFFFFFFFFFFF;
	t3_if <= 1'b0;
	t3_access <= 1'b0;
	ier <= 9'h00;
	ie_delay <= 6'h00;
end
else begin
  
  if (ie_delay!=6'h00)
    ie_delay <= ie_delay - 2'd1;
  if (ie_delay==6'h01)
    ier <= ierd;

	// Port A,B input latching
	// Port A input latches always reflect the input pins.
	if (pa_le) begin
		if (ca1_trans)
			pai <= pa_i;
	end
	else
		pai <= pa_i;

	// Port B input latches reflect the contents of the output register if the
	// port pin direction is an output.
	if (pb_le) begin
		if (cb1_trans)
			for (n = 0; n < 32; n = n + 1)
				pbi <= ddrb[n] ? pbo[n] : pb_i[n];
	end
	else begin
		for (n = 0; n < 32; n = n + 1)
			pbi <= ddrb[n] ? pbo[n] : pb_i[n];
	end

 	// Bring ca2 back high on pulse output mode
 	if (ca2_mode==3'b100 && ca1_trans)
 		ca2o <= 1'b1;
 	else if (ca2_mode==3'b101)
 		ca2o <= 1'b1;
	
	t1 <= t1 - 2'd1;
	if (pe_t1z) begin
		t1_if <= 1'b1;
		case(t1_mode)
		2'd1:	t1 <= t1l;
		2'd2:	pbo[7] <= 1'b1;
		2'd3:	
			begin
				pbo[7] <= ~pbo[7];
				t1 <= t1l;
			end
		default:	;
		endcase
	end

	case(t2_mode)
	1'd0:	t2 <= t2 - 2'd1;
	1'd1:	if (pb6_ne) t2 <= t2 - 2'd1;
	endcase
	if (pe_t2z)
		t2_if <= 1'b1;

	t3 <= t3 - 2'd1;
	if (pe_t3z) begin
		t3_if <= 1'b1;
		case(t3_mode)
		1'd1:	t3 <= t3l;
		default:	;
		endcase
	end
		
	case(sr_mode)
	3'b000:	;
	3'b001:
		begin
			if (cb1_ne) begin
				sr_cnt <= sr_cnt - 2'd1;
				sr <= {sr[30:0],cb2};
				if (sr_cnt==5'd0)
					sr_if <= 1'b1;
			end
		end
	3'b010:
		begin
			if (cb1_ne) begin
				sr_cnt <= sr_cnt - 2'd1;
				sr <= {sr[30:0],cb2};
				if (sr_cnt==5'd0)
					sr_if <= 1'b1;
			end
		end
	3'b011:
		begin
			if (cb1_ne) begin
				sr_cnt <= sr_cnt - 2'd1;
				sr <= {sr[30:0],cb2};
				if (sr_cnt==5'd0)
					sr_if <= 1'b1;
			end
		end
	3'b100:
		if (t2[7:0]==8'h00) begin
			if (cb1_ne) begin
				if (sr_32)
					sr <= {sr[30:0],sr[31]};
				else
					sr <= {sr[31:8],sr[6:0],sr[7]};
			end
		end
	3'b101:
		if (t2[7:0]==8'h00) begin
			if (sr_cnt != 5'd0) begin
				if (cb1_ne) begin
					sr_cnt <= sr_cnt - 2'd1;
					if (sr_32)
						sr <= {sr[30:0],sr[31]};
					else
						sr <= {sr[31:8],sr[6:0],sr[7]};
					if (sr_cnt==5'd1)
						sr_if <= 1'b1;
				end
			end
		end
	3'b110:
		if (sr_cnt != 5'd0) begin
			if (cb1_ne) begin
				sr_cnt <= sr_cnt - 2'd1;
				if (sr_32)
					sr <= {sr[30:0],sr[31]};
				else
					sr <= {sr[31:8],sr[6:0],sr[7]};
				if (sr_cnt==5'd1)
					sr_if <= 1'b1;
			end
		end
	3'b111:
		if (cb1_ne) begin
			sr_cnt <= sr_cnt - 2'd1;
			if (sr_32)
				sr <= {sr[30:0],sr[31]};
			else
				sr <= {sr[31:8],sr[6:0],sr[7]};
			if (sr_cnt==5'd1)
				sr_if <= 1'b1;
		end
	endcase

	// CB1 output
	case(sr_mode)
	3'b000:	;
	3'b001:
		if (t2[7:0]==8'h00)
			cb1o <= ~cb1o;
	3'b010:	cb1o <= ~cb1o;
	3'b011:	;	// used as input
	3'b100:
		if (t2[7:0]==8'h00)
			cb1o <= ~cb1o;
	3'b101:
		if (t2[7:0]==8'h00) begin
			if (sr_cnt != 5'd0)
				cb1o <= ~cb1o;
		end
	3'b110:
		if (sr_cnt != 5'd0)
			cb1o <= ~cb1o;
	3'b111:	;	// used as input
	endcase

	// CB2 output
	case(sr_mode)
	3'b000,3'b001,3'b010,3'b011:
	 	if (cb2_mode==3'b100 && cb1_trans)
	 		cb2o <= 1'b1;
	 	else if (cb2_mode==3'b101)
	 		cb2o <= 1'b1;
	3'b100:
		if (t2[7:0]==8'h00) begin
			if (cb1_ne)
				cb2o <= sr_32 ? sr[31] : sr[7];
		end
	3'b101:
		if (t2[7:0]==8'h00) begin
			if (sr_cnt != 5'd0) begin
				if (cb1_ne)
					cb2o <= sr_32 ? sr[31] : sr[7];
			end
			if (sr_cnt==5'd0)
				cb2o <= cb2_mode[0];
		end
	3'b110:
		if (sr_cnt != 5'd0) begin
			if (cb1_ne)
				cb2o <= sr_32 ? sr[31] : sr[7];
		end
	3'b111:
		if (cb1_ne)
			cb2o <= sr_32 ? sr[31] : sr[7];
	endcase

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
			 			ca2o <= 1'b0;
			 		ca1_if <= 1'b0;
			 		ca2_if <= 1'b0;
				end
			`PB:
				begin
					if (sel_i[0]) pbo[7:0] <= dat_i[7:0];
					if (sel_i[1]) pbo[15:8] <= dat_i[15:8];
					if (sel_i[2]) pbo[23:16] <= dat_i[23:16];
					if (sel_i[3]) pbo[31:24] <= dat_i[31:24];
			 		if (cb2_mode==3'b100||cb2_mode==3'b101)
			 			cb2o <= 1'b0;
			 		cb1_if <= 1'b0;
			 		cb2_if <= 1'b0;
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
				if (t3_access) begin
					if (sel_i[0]) t3l[7:0] <= dat_i[7:0];
					if (sel_i[1]) t3l[15:8] <= dat_i[15:8];
					if (sel_i[2]) t3l[23:16] <= dat_i[23:16];
					if (sel_i[3]) t3l[31:24] <= dat_i[31:24];
				end
				else begin
					if (sel_i[0]) t1l[7:0] <= dat_i[7:0];
					if (sel_i[1]) t1l[15:8] <= dat_i[15:8];
					if (sel_i[2]) t1l[23:16] <= dat_i[23:16];
					if (sel_i[3]) t1l[31:24] <= dat_i[31:24];
				end
			`T1CH:
				if (t3_access) begin
					t3 <= {dat_i,t3l[31:0]};
					t3_if <= 1'b0;
				end
				else begin
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
				if (t3_access) begin
					if (sel_i[0]) t3l[7:0] <= dat_i[7:0];
					if (sel_i[1]) t3l[15:8] <= dat_i[15:8];
					if (sel_i[2]) t3l[23:16] <= dat_i[23:16];
					if (sel_i[3]) t3l[31:24] <= dat_i[31:24];
				end
				else begin
					if (sel_i[0]) t1l[7:0] <= dat_i[7:0];
					if (sel_i[1]) t1l[15:8] <= dat_i[15:8];
					if (sel_i[2]) t1l[23:16] <= dat_i[23:16];
					if (sel_i[3]) t1l[31:24] <= dat_i[31:24];
				end
			`T1LH:
				begin
					if (t3_access) begin
						if (sel_i[0]) t3l[39:32] <= dat_i[7:0];
						if (sel_i[1]) t3l[47:40] <= dat_i[15:8];
						if (sel_i[2]) t3l[55:48] <= dat_i[23:16];
						if (sel_i[3]) t3l[63:56] <= dat_i[31:24];
						t3_if <= 1'b0;
					end
					else begin
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
					if (sel_i[0]) begin
						ca1_mode <= dat_i[0];
						ca2_mode <= dat_i[3:1];
				 		cb1_mode <= dat_i[4];
				 		cb2_mode <= dat_i[7:5];
			 		end
			 		if (sel_i[1]) begin
			 			t3_access <= dat_i[8];
			 		end
		 		end
			`SR:
				begin	
					if (sel_i[0]) sr <= dat_i[7:0];
					if (sel_i[1]) sr <= dat_i[15:8];
					if (sel_i[2]) sr <= dat_i[23:16];
					if (sel_i[3]) sr <= dat_i[31:24];
					sr_cnt <= sr_32 ? 5'd31 : 5'd7;
					if (sr_mode==3'b001)
						cb1o <= 1'b1;
					sr_if <= 1'b0;						
				end
			`ACR:
				begin
					if (sel_i[0]) begin
						pa_le <= dat_i[0];
						pb_le <= dat_i[1];
						sr_mode <= dat_i[4:2];
						t2_mode <= dat_i[5];
						t1_mode <= dat_i[7:6];
					end
					if (sel_i[1]) begin
						t1_64 <= dat_i[8];
						t2_64 <= dat_i[9];
						sr_32 <= dat_i[10];
						t3_mode <= dat_i[12];
					end
				end
			`IER:
				begin
					if (sel_i[0]) begin
						if (dat_i[7])
							ierd[6:0] <= ier[6:0] | dat_i[6:0];
						else
							ierd[6:0] <= ier[6:0] & ~dat_i[6:0];
						ier[7] <= 1'b0;
					end
					if (sel_i[1]) begin
						if (dat_i[7])
							ierd[8] <= ier[8] | dat_i[8];
						else
							ierd[8] <= ier[8] & ~dat_i[8];
					end
					if (sel_i[3])
					  ie_delay <= dat_i[29:24];
					else
					  ie_delay <= 6'h01;
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
					dat_o <= pai;
			 		if (ca2_mode==3'b100||ca2_mode==3'b101)
			 			ca2o <= 1'b0;
			 		ca1_if <= 1'b0;
			 		ca2_if <= 1'b0;
				end
			`PB:	
				begin
					dat_o <= pbi;
					cb1_if <= 1'b0;
					cb2_if <= 1'b0;
				end
			`DDRA:	dat_o <= ddra;
			`DDRB:	dat_o <= ddrb;
			`T1CL:
				if (t3_access) begin	
					dat_o <= t3[31:0];
					t3_if <= 1'b0;
				end
				else begin
					dat_o <= t1[31:0];
					t1_if <= 1'b0;
				end
			`T1CH:
				if (t3_access)
					dat_o <= t3[63:32];
				else begin
					if (t1_64)
						dat_o <= t1[63:32];
					else
						dat_o <= {24'd0,t1[15:8]};
				end
			`T1LL:	
				dat_o <= t3_access ? t3l[31:0] : t1l[31:0];
			`T1LH:
				if (t3_access)
					dat_o <= t3l[63:32];
				else begin
					if (t1_64)
						dat_o <= t1l[63:32];
					else
						dat_o <= {24'd0,t1l[15:8]};
				end
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
			`PCR:	dat_o <= {24'd0,cb2_mode,cb1_mode,ca2_mode,ca1_mode};
			`SR:
				begin	
					dat_o <= sr;
					if (sr_mode==3'b001)
						cb1o <= 1'b1;
					sr_cnt <= sr_32 ? 5'd31 : 5'd7;
					sr_if <= 1'b0;
				end
			`ACR:	dat_o <= {19'd0,t3_mode,1'b0,sr_32,t2_64,t1_64,t1_mode,t2_mode,sr_mode,pb_le,pa_le};
			`IFR:	dat_o <= {23'd0,t3_irq,irq_o,t2_irq,t1_irq,cb1_irq,cb2_irq,sr_irq,ca1_irq,ca2_irq};
			`IER:	dat_o <= {23'd0,ier};
			`ORA:	dat_o <= pai;
			endcase
		end
	end

	if (ca2_trans)
		ca2_irq <= ier[0];
	if (ca1_trans)
		ca1_irq <= ier[1];
	if (sr_if)
		sr_irq <= ier[2];
	if (cb2_trans)
		cb2_irq <= ier[3];
	if (cb1_trans)
		cb1_irq <= ier[4];
	if (t1_if)
		t1_irq <= ier[5];
	if (t2_if)
		t2_irq <= ier[6];
	if (t3_if)
		t3_irq <= ier[8];

	irq_o <=
		  (ca2_trans & ier[0])
		| (ca1_trans & ier[1])
		| (sr_if & ier[2])
		| (cb2_trans & ier[3])
		| (cb1_trans & ier[4])
		| (t1_if & ier[5])
		| (t2_if & ier[6])
		| (t3_if & ier[8])
		;
end

// Outputs

genvar g;
generate begin : gPorts
	for (g = 0; g < 32; g = g + 1)
		assign pa[g] = ddra[g] ? pao[g] : 1'bz;
		
	for (g = 0; g < 32; g = g + 1)
		assign pb[g] = ddrb[g] ? pbo[g] : 1'bz;
end
endgenerate

// CA1 is always an input

// CA2,CB1,CB2 output enables

assign ca2 = ca2_mode[2]==1'b0 ? 1'bz :
						 ca2_mode==3'b100 ? ca2o :
						 ca2_mode==3'b101 ? ca2o :
						 ca2_mode==3'b110 ? 1'b0 :
						 1'b1;

assign cb1 = 	sr_mode==3'b000 ? 1'bz :
							sr_mode==3'b001 ? cb1o :
							sr_mode==3'b010 ? cb1o :
							sr_mode==3'b011 ? 1'bz :
							sr_mode==3'b100 ? cb1o :
							sr_mode==3'b101 ? cb1o :
							sr_mode==3'b110 ? cb1o :
							1'bz;

assign cb2 = sr_mode[2]==1'b0 ? (
							cb2_mode[2]==1'b0 ? 1'bz :
							cb2_mode==3'b100 ? cb2o :
							cb2_mode==3'b101 ? cb2o :
							cb2_mode==3'b110 ? 1'b0 :
							1'b1) :
							cb2o;

assign pa_o = pao;
assign pb_o = pbo;
							
endmodule
