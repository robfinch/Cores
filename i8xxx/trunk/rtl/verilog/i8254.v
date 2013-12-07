// ============================================================================
//        __
//   \\__/ o\    (C) 2013  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
//
module i8254(rst_i, clk_i, cyc_i, stb_i, we_i, adr_i, dat_i, dat_o,
clk0_i, gate0_i, out0_o, clk1_i, gate1_i, out1_o, clk2_i, gate2_i, out2_o);
input rst_i;
input clk_i;
input cyc_i;
input stb_i;
input we_i;
input [1:0] adr_i;
input [7:0] dat_i;
output [7:0] dat_o;
reg [7:0] dat_o;
input clk0_i;
input gate0_i;
output out0_o;
reg out0_o;
input clk1_i;
input gate1_i;
output out1_o;
reg out1_o;
input clk2_i;
input gate2_i;
output out2_o;
reg out2_o;

i8254Cntr u1
(
	.n(0),
	.wb_clk_i(clk_i),
	.cyc_i(cyc_i),
	.stb_i(stb_i),
	.we_i(we_i),
	.adr_i(adr_i),
	.dat_i(dat_i),
	.dat_o(c0_dato),
	.clk_i(clk0_i),
	.gate_i(gate0_i),
	.out_o(out0_o)
);

i8254Cntr u2
(
	.n(1),
	.wb_clk_i(clk_i),
	.cyc_i(cyc_i),
	.stb_i(stb_i),
	.we_i(we_i),
	.adr_i(adr_i),
	.dat_i(dat_i),
	.dat_o(c1_dato),
	.clk_i(clk1_i),
	.gate_i(gate1_i),
	.out_o(out1_o)
);

i8254Cntr u3
(
	.n(2),
	.wb_clk_i(clk_i),
	.cyc_i(cyc_i),
	.stb_i(stb_i),
	.we_i(we_i),
	.adr_i(adr_i),
	.dat_i(dat_i),
	.dat_o(c2_dato),
	.clk_i(clk2_i),
	.gate_i(gate2_i),
	.out_o(out2_o)
);

endmodule


// According to the spacs the 8254 contains three identical counter modules,
// so we make them that way.
//
module i8254Cntr(n, wb_clk_i,cyc_i,stb_i,we_i,adr_i,dat_i,dat_o,clk_i,gate_i,out_o);
input [1:0] n;
input wb_clk_i;
input cyc_i;
input stb_i;
input we_i;
input [1:0] adr_i;
input [7:0] dat_i;
output [7:0] dat_o;
reg [7:0] dat_o;
input clk_i;
input gate_i;
output out_o;

reg [2:0] mode;
reg bcd;
reg [1:0] rw;
reg [1:0] rwt;
wire z1,z2,z3,z4;
reg [15:0] ic;
wire [15:0] icby2 = ic[15:1];
wire [15:0] q;
reg [15:0] ol;
reg latch;
reg latchStatus;
reg nullCount;
reg outl;
reg out1;
reg og;
reg ce;
reg ld;
reg ForceLow,ForceHigh;

nybcnt u1
(
	.bcd(bcd),
	.clk(clk_i),
	.ce(ce),
	.ld(ld),
	.by2(mode==3'd3),
	.d(mode==3'd3 ? {ic[3:1],1'b0} : ic[3:0]),
	.q(q[3:0]),
	.zero(z1)
);

nybcnt u2
(
	.bcd(bcd),
	.clk(clk_i),
	.ce(ce & z1),
	.ld(ld),
	.by2(1'b0),
	.d(ic[7:4]),
	.q(q[7:4]),
	.zero(z2)
);

nybcnt u3
(
	.bcd(bcd),
	.clk(clk_i),
	.ce(ce & z2),
	.ld(ld),
	.by2(1'b0),
	.d(ic[11:8]),
	.q(q[11:8]),
	.zero(z3)
);

nybcnt u4
(
	.bcd(bcd),
	.clk(clk_i),
	.ce(ce & z3),
	.ld(ld),
	.by2(1'b0),
	.d(ic[15:12]),
	.q(q[15:12]),
	.zero(z4)
);

always @(posedge clk_i)
	og <= gate_i;

always @(posedge clk_i)
	if (!latchStatus)
		outl <= out_o;

always @(posedge clk_i)
	if (!latch)
		ol <= q;

always @(posedge wb_clk_i)
begin
	// When the counter loads, the null count is cleared.
	if (ld)
		nullCount <= 1'b0;
	// Once the counter has loaded, the software trigger is cleared.
	case(mode)
	3'd0:	if (ld)	trig <= 1'b0;
	3'd2:	if (ld) trig <= 1'b0;
	3'd3:	if (ld) trig <= 1'b0;
	3'd4:	if (ld)	trig <= 1'b0;
	endcase
	if (ld) begin
		ForceLow <= 1'b0;
		ForceHigh <= 1'b0;
	end

	if (cyc_i & stb_i) begin
		if (we_i) begin
			case(adr_i)
			2'b11:
				begin
					nullCount <= 1'b1;
					if (dat_i[7:6]==2'b11) begin
						if (dat_i[5]==1'b0) begin
							if (n==0 && dat_i[1])
								latch <= 1'b1;
							else if (n==1 && dat_i[2])
								latch <= 1'b1;
							else if (n==2 && dat_i[3])
								latch <= 1'b1;
						end
						if (dat_i[4]==1'b0) begin
							if (n==0 && dat_i[1])
								latchStatus <= 1'b1;
							else if (n==1 && dat_i[2])
								latchStatus <= 1'b1;
							else if (n==2 && dat_i[3])
								latchStatus <= 1'b1;
						end
					end
					else begin
						if (dat_i[7:6]==n) begin
							bcd <= dat_i[0];
							mode <= dat_i[3:1];
							rw <= dat_i[5:4];
							rwt <= dat_i[5:4];
							case(dat_i[3:1])
							3'd0:	ForceLow <= 1'b1;
							3'd1:	ForceHigh <= 1'b1;
							3'd2:	ForceHigh <= 1'b1;
							3'd3:	ForceHigh <= 1'b1;
							3'd4:	ForceHigh <= 1'b1;
							3'd5:	ForceHigh <= 1'b1;
							endcase
						end
					end
				end
			default:
				if (adr_i==n) begin
					case(rwt)
					2'b00:	latch <= 1'b1;
					2'b01:	begin 
								ic[7:0] <= dat_i; nullCount <= 1'b1;
								if (mode==3'd0 || mode==3'd2 || mode==3'd3 || mode==3'd4)
									trig <= 1'b1;
							end
					2'b10:	begin 
								ic[15:8] <= dat_i; nullCount <= 1'b1;
								if (mode==3'd0 || mode==3'd2 || mode==3'd3 || mode==3'd4)
									trig <= 1'b1;
							end
					2'b11:	begin ic[7:0] <= dat_i; rwt[0] <= 1'b0; nullCount <= 1'b1; end
					endcase
				end
			endcase
		end
		else begin
			case(adr_i)
			2'b11:
				begin
				end
			default:
				if (adr_i==n) begin
					if (latchStatus) begin
						dat_o <= {outl,nullCount,rw,mode,bcd};
						latchStatus <= 1'b0;
					end
					else
						case(rwt)
						2'b01:	begin dat_o <= ol[7:0]; latch <= 1'b0; end
						2'b10:	begin dat_o <= ol[15:8]; latch <= 1'b0; end
						2'b11:	begin dat_o <= ol[7:0]; rwt[0] <= 1'b0; end
						endcase
				end
			endcase
		end
	end
end

always @(mode)
case(mode)
3'd0:		ce <= gate_i && q!=16'd0;	// event count
3'd1:		ce <= q!=16'h0000;			// One shot
3'd2,3'd6:	ce <= gate_i;				// continuous
3'd3,3'd7:	ce <= 1'b1;					// continuous square wave
3'd4:		ce <= gate_i && q!=16'd0;	// software triggered strobe
3'd5:		ce <= q!=16'd0;				// hardware triggered strobe
endcase

always @(posedge clk_i)
begin
	case(mode)
	3'd0:		if (trig==1'b0)
					ld <= 1'b0;
	3'd1:		ld <= 1'b0;
	3'd2,3'd6:	if (trig==1'b0 || q==ic)
					ld <= 1'b0;
	3'd3,3'd7:	if (trig==1'b0 || q==ic)
					ld <= 1'b0;
	3'd4:		if (trig==1'b0)
					ld <= 1'b0;
	3'd5:		ld <= 1'b0;
	endcase
	case(mode)
	3'd0:	if (trig)			// mode 0: counter is loaded on write to initial count
				ld <= 1'b1;
	3'd1:	if (gate_i & ~og)	// mode 1: counter reloads on a trigger
				ld <= 1'b1;
	3'd2,3'd6:	if (trig || q==16'd1)	// mode 2: counter reloads when count==0
					ld <= 1'b1;
	3'd3,3'd7:	if (trig || q==16'd2 || (gate_i & ~og))	// mode 3: counter reloads when count==0 or an initial count is set
					ld <= 1'b1;
	3'd4:	if (trig)			// mode 4: counter is loaded on write to initial count
				ld <= 1'b1;
	3'd5:	if (gate_i & ~og)	// Mode 5: counter is loaded on rising edge of gate
				ld <= 1'b1;
	endcase
end

// When in mode3, and an odd count, delay the load pulse by a clock cycle when 
// the out signal is high.
reg ld1,ld2,ld3;
always @(posedge clk_i)			// delay ld by a clock pulse
	ld2 <= ld;
always @(ld2 or ld or ic or out1)
	if (out1==1'b1 && ic[0])
		ld1 <= ld2;
	else
		ld1 <= ld;
always @(posedge clk_i)			// delay ld by a clock pulse
	ld3 <= ld1;

always @(posedge clk_i)
begin
	if (ForceHigh)
		out1 <= 1'b1;
	else if (ForceLow)
		out1 <= 1'b0;
	else
		case(mode)
		3'd0:	if (trig)
					out1 <= 1'b0;
				else if (q==16'd1)
					out1 <= 1'b1;
		3'd1:	begin
					if (gate_i & ~og)	// mode 1: a trigger sets out low
						out1 <= 1'b0;
					if (q==16'd1)	// a zero count forces out high
						out1 <= 1'b1;
				end
		3'd2,3'd6:	out1 <= q!=16'd2;
		// If gate goes low, the output is forced high; otherwise the output
		// toggles with the load signal.
		3'd3,3'd7:	gate_i ? ((ld1 & ~ld3) ? out1 <= ~out1 : out1 <= out1) : 1'b1;
		3'd4:	out1 <= q!=16'd1;
		3'd5:	out1 <= q!=16'd1;
		endcase
end

always @(mode or gate_i)
begin
	out_o <= out1;
	case(mode)
	// Force output high immediately if gate goes low. Note that output will go high
	// after one clock cycle anyway and is normally high in mode 2.
	3'd2,3'd6:	if (gate_i==1'b0) out_o <= 1'b1;
	3'd3,3'd7:	if (gate_i==1'b0) out_o <= 1'b1;
	endcase
end
endmodule


// Four bit binary or bcd down counter. When counting down by two, the counter is 
// loaded with an even count.
//
module nybcnt(bcd, clk, ce, ld, by2, d, q, zero);
input bcd;
input clk;
input ce;
input ld;
input by2;
input [3:0] d;
output [3:0] q;
reg [3:0] q;
output zero;

assign zero = q==4'd0;

always @(posedge clk)
begin
	if (ld) begin
		q <= d;
	end
	else if (ce) begin
		if (bcd) begin
			if (q==4'd0)
				q <= by2 ? 4'd8 : 4'd9;
			else
				q <= q - (by2 ? 4'd2 : 4'd1);
		end
		else begin
			if (q==4'd0)
				q <= by2 ? 4'hE : 4'hF;
			else
				q <= q - (by2 ? 4'd2 : 4'd1);
		end
	end
end

endmodule
