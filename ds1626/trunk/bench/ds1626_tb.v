// ============================================================================
//        __
//   \\__/ o\    (C) 2008,2013  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
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
//  ds1626:
//
//  Interface to ds1626 TempPod.
//
// ============================================================================
//
module ds1626_tb();
// Commands
parameter START_CNV = 8'h51;
parameter STOP_CNV = 8'h22;
parameter READ_TEMP = 8'hAA;
parameter READ_CONFIG = 8'hAC;
parameter READ_TH = 8'hA1;
parameter READ_TL = 8'hA2;
parameter WRITE_TH = 8'h01;
parameter WRITE_TL = 8'h02;
parameter WRITE_CONFIG = 8'h0C;
parameter POR = 8'h54;

reg rst;
reg clk;
reg cyc;
reg stb;
reg we;
reg [31:0] adr;
reg [15:0] dat;
reg [15:0] t1;
wire ack;
wire [15:0] tdato;
wire rst1626;
wire clk1626;
wire d1626;
wire q1626;
wire en1626;
reg [7:0] state;
reg [15:0] cnt;

initial begin
	#0 rst = 1'b0;
	#0 clk = 1'b0;
	#20 rst = 1'b1;
	#100 rst = 1'b0;
end

always #5 clk = ~clk;

always @(posedge clk)
if (rst) begin
	state <= 0;
end
else begin
	case(state)
	// poll transfer busy bit
	0:	wb_read(32'hFFDC0301);
	1:	wb_ack();
	2:	wait_td();
	3:  wait_rst();
	4:	wb_write(32'hFFDC0301,16'h000f);	// cpu single shot mode, 12 bits resolution
	5:	wb_ack();
	6:	wb_write(32'hFFDC0300,WRITE_CONFIG);
	7:	wb_ack();
	// Poll transfer done
	8:	wb_read(32'hFFDC0301);
	9:	wb_ack();
	10:	wait_td();
	11: wait_rst();
	12:	wb_write(32'hFFDC0301,16'h0000);
	13:	wb_ack();
	14:	wb_write(32'hFFDC0300,START_CNV);
	15:	wb_ack();
	// Poll transfer done
	16:	wb_read(32'hFFDC0301);
	17:	wb_ack();
	18:	wait_td();
	19:	wait_rst();
	20:	wb_write(32'hFFDC0300,READ_CONFIG);
	21:	wb_ack();
	// Poll transfer done
	22:	wb_read(32'hFFDC0301);
	23:	wb_ack();
	24:	wait_td();
	25:	wait_rst();
	26: if (t1[7])
			next_state();
		else
			state <= 20;
	27:	wb_write(32'hFFDC0300,STOP_CNV);
	28:	wb_ack();
	// Poll transfer done
	29:	wb_read(32'hFFDC0301);
	30:	wb_ack();
	31:	wait_td();
	32: wait_rst();
	33:	wb_write(32'hFFDC0300,READ_TEMP);
	34:	wb_ack();
	// Poll transfer done
	35:	wb_read(32'hFFDC0301);
	36:	wb_ack();
	37:	wait_td();
	38:	wait_rst();
	endcase
end

task wait_td;
begin
	if (t1[15])
		state <= state - 2;
	else
		next_state();
	cnt <= 16'd0;
end
endtask

task wait_rst;
begin
	if (cnt[7])
		next_state();
	cnt <= cnt + 1;
end
endtask

task next_state();
begin
	state <= state + 1;
end
endtask

task wb_write;
	input [31:0] ad;
	input [15:0] dt;
begin
	cyc <= 1'b1;
	stb <= 1'b1;
	we <= 1'b1;
	adr <= ad;
	dat <= dt;
	next_state();
end
endtask

task wb_read;
	input [31:0] ad;
begin
	cyc <= 1'b1;
	stb <= 1'b1;
	we <= 1'b0;
	adr <= ad;
	next_state();
end
endtask

task wb_ack;
begin
	if (ack) begin
		cyc <= 1'b0;
		stb <= 1'b0;
		we <= 1'b0;
		adr <= 32'h0;
		t1 <= tdato;
		next_state();
	end
end
endtask

ds1626io #(.pClkFreq(100000000)) u1 (
	.rst_i(rst), 
	.clk_i(clk),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(ack),
	.we_i(we),
	.adr_i({adr,2'b00}),
	.dat_i(dat),
	.dat_o(tdato), 
	.rst1626(rst1626),
	.clk1626(clk1626),
	.d1626(d1626),
	.q1626(q1626),
	.en1626(en1626)
);

endmodule

