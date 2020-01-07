// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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

module perceptronPredictor2x(rst, clk, clk2x, clk4x, xbr, xadr, prediction_i, outcome, adr, prediction_o);
parameter AMSB = 63;
input rst;
input clk;
input clk2x;
input clk4x;
input [3:0] xbr;
input [AMSB:0] xadr [3:0];
input [3:0] prediction_i;
input [3:0] outcome;
input [AMSB:0] adr [1:0];
output reg [1:0] prediction_o;

integer n;

reg [22:0] global_history;
wire [175:0] weights_row, weights_rowx, weights_row2;
reg [7:0] wghts [0:21];
reg [7:0] wghts2 [0:21];
reg [175:0] weights_row_new;
reg [7:0] bh, bhx, bhxd, bh2;
reg xbrd;

// Perceptron ram: 256 rows by 176 bits (22 bytes)
// Simple dual port.
perceptronRam weights_ramr0
(
  .a(bhxd),        
  .d(weights_row_new),
  .dpra(bh),
  .clk(clk),
  .we(xbrd),
  .dpo(weights_row)
);

perceptronRam weights_ramr1
(
  .a(bhxd),        
  .d(weights_row_new),
  .dpra(bh2),
  .clk(clk),
  .we(xbrd),
  .dpo(weights_row2)
);

perceptronRam weights_ramw
(
  .a(bhxd),        
  .d(weights_row_new),
  .dpra(bhx),
  .clk(clk),
  .we(xbrd),
  .dpo(weights_rowx)
);

reg [AMSB+2:0] pcs [0:31];
reg [AMSB:0] pc = 1'd0;
reg takbx;
reg prediction;
reg [4:0] pcshead,pcstail;
reg wrhist;

reg xisBr;
reg xtkb;
reg [AMSB:0] xipx;
reg xprediction;
always @*
begin
	xisBr <= xbr[{clk,clk2x}];
	xtkb <= outcome[{clk,clk2x}];
	xipx <= xadr[{clk,clk2x}];
	xprediction <= prediction_i[{clk,clk2x}];
end

always @(posedge clk4x)
if (rst)
	pcstail <= 5'd0;
else begin
	if (xisBr) begin
		pcs[pcstail] <= {xprediction,xtkb,xipx[AMSB:0]};
		pcstail <= pcstail + 5'd1;
	end
end

always @(posedge clk)
if (rst)
	pcshead <= 5'd0;
else begin
	wrhist <= 1'b0;
	if (pcshead != pcstail) begin
		pc <= pcs[pcshead][AMSB:0];
		takbx <= pcs[pcshead][AMSB+1];
		prediction <= pcs[pcshead][AMSB+2];
		wrhist <= 1'b1;
		pcshead <= pcshead + 5'd1;
	end
end

// Ram address hash to select perceptron. Going on the basis that in all
// likelyhood the app is less than 16MB in size.
always @*
	bh <= adr[0][7:0] ^ adr[0][15:8] ^ adr[0][23:16];// ^ adr[0][31:24];
always @*
	bh2 <= adr[1][7:0] ^ adr[1][15:8] ^ adr[1][23:16];// ^ adr[1][31:24];
always @*
	bhx <= pc[7:0] ^ pc[15:8] ^ pc[23:16];// ^ pc[31:24];

// Capture global branch history
always @(posedge clk)
if (rst)
	global_history <= 1'd0;
else begin
	if (wrhist)
		global_history <= {global_history,takbx};
end

always @(posedge clk)
	xbrd <= wrhist;
always @(posedge clk)
	bhxd <= bhx;

genvar g;
generate begin : slice
for (g = 0; g < 22; g = g + 1)
always @*
	wghts[g] = weights_row[g*8+7:g*8];
end
endgenerate

generate begin : slice2
for (g = 0; g < 22; g = g + 1)
always @*
	wghts2[g] = weights_row2[g*8+7:g*8];
end
endgenerate

reg [12:0] sum;
reg [12:0] sum1 [0:4];
reg [12:0] sum2;
reg [12:0] sum2a [0:4];

// Form dot product of input and weights.
always @*
begin
	sum1[0] = 0;
	sum1[1] = 0;
	sum1[2] = 0;
	sum1[3] = 0;
	sum1[4] = 0;
	for (n = 0; n < 5; n = n + 1)
		sum1[0] = global_history[n] ? sum1[0] + {{6{wghts[n][7]}},wghts[n]} : sum1[0] - {{6{wghts[n][7]}},wghts[n]};
	for (n = 5; n < 10; n = n + 1)
		sum1[1] = global_history[n] ? sum1[1] + {{6{wghts[n][7]}},wghts[n]} : sum1[1] - {{6{wghts[n][7]}},wghts[n]};
	for (n = 10; n < 15; n = n + 1)
		sum1[2] = global_history[n] ? sum1[2] + {{6{wghts[n][7]}},wghts[n]} : sum1[2] - {{6{wghts[n][7]}},wghts[n]};
	for (n = 15; n < 20; n = n + 1)
		sum1[3] = global_history[n] ? sum1[3] + {{6{wghts[n][7]}},wghts[n]} : sum1[3] - {{6{wghts[n][7]}},wghts[n]};
	for (n = 20; n < 22; n = n + 1)
		sum1[4] = global_history[n] ? sum1[4] + {{6{wghts[n][7]}},wghts[n]} : sum1[4] - {{6{wghts[n][7]}},wghts[n]};
end

always @*
begin
	sum = 0;	// bias weight
	for (n = 0; n < 5; n = n + 1)
		sum = sum + sum1[n];
end

// Form dot product of input and weights.
always @(posedge clk)
begin
	sum2a[0] = 0;
	sum2a[1] = 0;
	sum2a[2] = 0;
	sum2a[3] = 0;
	sum2a[4] = 0;
	for (n = 0; n < 5; n = n + 1)
		sum2a[0] = global_history[n] ? sum2a[0] + {{6{wghts2[n][7]}},wghts2[n]} : sum2a[0] - {{6{wghts2[n][7]}},wghts2[n]};
	for (n = 5; n < 10; n = n + 1)
		sum2a[1] = global_history[n] ? sum2a[1] + {{6{wghts2[n][7]}},wghts2[n]} : sum2a[1] - {{6{wghts2[n][7]}},wghts2[n]};
	for (n = 10; n < 15; n = n + 1)
		sum2a[2] = global_history[n] ? sum2a[2] + {{6{wghts2[n][7]}},wghts2[n]} : sum2a[2] - {{6{wghts2[n][7]}},wghts2[n]};
	for (n = 15; n < 20; n = n + 1)
		sum2a[3] = global_history[n] ? sum2a[3] + {{6{wghts2[n][7]}},wghts2[n]} : sum2a[3] - {{6{wghts2[n][7]}},wghts2[n]};
	for (n = 20; n < 22; n = n + 1)
		sum2a[4] = global_history[n] ? sum2a[4] + {{6{wghts2[n][7]}},wghts2[n]} : sum2a[4] - {{6{wghts2[n][7]}},wghts2[n]};
end

always @*
begin
	sum2 = 0;	// bias weight
	for (n = 0; n < 5; n = n + 1)
		sum2 = sum2 + sum2a[n];
end

// < 0 means don't take branch, >= 0 means take branch => the take branch
// bit is inverted.
always @(posedge clk)
begin
	prediction_o[0] <= ~sum[12];
	prediction_o[1] <= ~sum2[12];
end

generate begin : train
for (g = 0; g < 22; g = g + 1) begin
always @(posedge clk)
	if (wrhist) begin
		weights_row_new[g*8+7:g*8] <= weights_rowx[g*8+7:g*8];
		if (prediction==global_history[g]) begin
			if (weights_rowx[g*8+7:g*8] != 8'h7F)
				weights_row_new[g*8+7:g*8] <= weights_rowx[g*8+7:g*8] + 2'd1;
		end
		else begin
			if (weights_rowx[g*8+7:g*8] != 8'hFF)
				weights_row_new[g*8+7:g*8] <= weights_rowx[g*8+7:g*8] - 2'd1;
		end
	end
end
end
endgenerate

endmodule
