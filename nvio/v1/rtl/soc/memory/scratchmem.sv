// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2019  Robert Finch, Waterloo
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
//
module scratchmem(rst_i, clk_i, cti_i, bok_o, cs_i, cyc_i, stb_i, ack_o, we_i, sel_i, adr_i, dat_i, dat_o);
input rst_i;
input clk_i;
input [2:0] cti_i;
output bok_o;
input cs_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [15:0] sel_i;
input [15:0] adr_i;
input [127:0] dat_i;
output reg [127:0] dat_o;

integer n;

reg [7:0] smemA [4095:0];
reg [7:0] smemB [4095:0];
reg [7:0] smemC [4095:0];
reg [7:0] smemD [4095:0];
reg [7:0] smemE [4095:0];
reg [7:0] smemF [4095:0];
reg [7:0] smemG [4095:0];
reg [7:0] smemH [4095:0];
reg [7:0] smemI [4095:0];
reg [7:0] smemJ [4095:0];
reg [7:0] smemK [4095:0];
reg [7:0] smemL [4095:0];
reg [7:0] smemM [4095:0];
reg [7:0] smemN [4095:0];
reg [7:0] smemO [4095:0];
reg [7:0] smemP [4095:0];
reg [15:4] radr;


initial begin
for (n = 0; n < 4096; n = n + 1)
begin
	smemA[n] = 0;
	smemB[n] = 0;
	smemC[n] = 0;
	smemD[n] = 0;
	smemE[n] = 0;
	smemF[n] = 0;
	smemG[n] = 0;
	smemH[n] = 0;
	smemI[n] = 0;
	smemJ[n] = 0;
	smemK[n] = 0;
	smemL[n] = 0;
	smemM[n] = 0;
	smemN[n] = 0;
	smemO[n] = 0;
	smemP[n] = 0;
end
end

wire cs = cs_i && cyc_i && stb_i;
assign bok_o = cs;
reg csd;
reg wed;
reg [15:0] seld;
reg [15:0] adrd;
reg [127:0] datid;
reg [127:0] datod;

reg [2:0] cnt;
/*
reg rdy,rdy1;
always @(posedge clk_i)
if (rst_i) begin
	rdy1 <= 1'b0;
	rdy <= 1'b0;
end
else begin
	rdy1 <= cs;
	rdy <= rdy1 & cs && cnt!=3'b101;
end
assign ack_o = cs ? (we_i ? 1'b1 : rdy) : 1'b0;
*/
ack_gen #(
	.READ_STAGES(1),
	.WRITE_STAGES(1),
	.REGISTER_OUTPUT(1)
) ag1
(
	.clk_i(clk_i),
	.ce_i(1'b1),
	.i(cs && cnt != 3'b101),
	.we_i(we_i && cs && cnt != 3'b101),
	.o(ack_o)
);


always @(posedge clk_i)
	csd <= cs;
always @(posedge clk_i)
	wed <= we_i;
always @(posedge clk_i)
	seld <= sel_i;
always @(posedge clk_i)
	adrd <= adr_i;
always @(posedge clk_i)
	datid <= dat_i;

always @(posedge clk_i)
	if (cs & we_i) begin
		$display ("wrote to scratchmem: %h=%h:%h", adr_i, dat_i, sel_i);
		/*
		if (adr_i[14:3]==15'h3e9 && dat_i==64'h00) begin
		  $display("3e9=00");
		  $finish;
		end
		*/
	end
always @(posedge clk_i)
	if (csd & wed & seld[0])
		smemA[adrd[15:4]] <= datid[7:0];
always @(posedge clk_i)
	if (csd & wed & seld[1])
		smemB[adrd[15:4]] <= datid[15:8];
always @(posedge clk_i)
  if (csd & wed & seld[2])
    smemC[adrd[15:4]] <= datid[23:16];
always @(posedge clk_i)
  if (csd & wed & seld[3])
    smemD[adrd[15:4]] <= datid[31:24];
always @(posedge clk_i)
  if (csd & wed & seld[4])
    smemE[adrd[15:4]] <= datid[39:32];
always @(posedge clk_i)
  if (csd & wed & seld[5])
    smemF[adrd[15:4]] <= datid[47:40];
always @(posedge clk_i)
  if (csd & wed & seld[6])
    smemG[adrd[15:4]] <= datid[55:48];
always @(posedge clk_i)
  if (csd & wed & seld[7])
    smemH[adrd[15:4]] <= datid[63:56];
always @(posedge clk_i)
  if (csd & wed & seld[8])
    smemI[adrd[15:4]] <= datid[71:64];
always @(posedge clk_i)
  if (csd & wed & seld[9])
    smemJ[adrd[15:4]] <= datid[79:72];
always @(posedge clk_i)
  if (csd & wed & seld[10])
    smemK[adrd[15:4]] <= datid[87:80];
always @(posedge clk_i)
  if (csd & wed & seld[11])
    smemL[adrd[15:4]] <= datid[95:88];
always @(posedge clk_i)
  if (csd & wed & seld[12])
    smemM[adrd[15:4]] <= datid[103:96];
always @(posedge clk_i)
  if (csd & wed & seld[13])
    smemN[adrd[15:4]] <= datid[111:104];
always @(posedge clk_i)
  if (csd & wed & seld[14])
    smemO[adrd[15:4]] <= datid[119:112];
always @(posedge clk_i)
  if (csd & wed & seld[15])
    smemP[adrd[15:4]] <= datid[127:120];

wire pe_cs;
edge_det u1(.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(cs), .pe(pe_cs), .ne(), .ee() );

reg [12:0] ctr;
always @(posedge clk_i)
	if (pe_cs) begin
		if (cti_i==3'b000)
			ctr <= adr_i[15:4];
		else
			ctr <= adr_i[15:4] + 12'd1;
		cnt <= 3'b000;
	end
	else if (cs && cnt[2:0]!=3'b100 && cti_i!=3'b000) begin
		ctr <= ctr + 2'd1;
		cnt <= cnt + 3'd1;
	end

always @(posedge clk_i)
	radr <= pe_cs ? adr_i[15:4] : ctr;

//assign dat_o = cs ? {smemH[radr],smemG[radr],smemF[radr],smemE[radr],
//				smemD[radr],smemC[radr],smemB[radr],smemA[radr]} : 64'd0;

always @(posedge clk_i)
begin
	datod <= {
		smemP[radr],smemO[radr],smemN[radr],smemM[radr],smemL[radr],smemK[radr],smemJ[radr],smemI[radr],
		smemH[radr],smemG[radr],smemF[radr],smemE[radr],smemD[radr],smemC[radr],smemB[radr],smemA[radr]};
	dat_o <= datod;
	if (!we_i & cs)
		$display("read from scratchmem: %h=%h", radr, {
			smemP[radr],smemO[radr],smemN[radr],smemM[radr],smemL[radr],smemK[radr],smemJ[radr],smemI[radr],
			smemH[radr],smemG[radr],smemF[radr],smemE[radr],smemD[radr],smemC[radr],smemB[radr],smemA[radr]});
end

endmodule
