// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	ft64v8d.v
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
//
// ============================================================================
//
module FT64v8d(rst_i, clk_i, nmi_i, irq_i, cause_i, bte_o, cti_o, cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o);
input rst_i;
input clk_i;
input nmi_i;
input [2:0] irq_i;
input [8:0] cause_i;
output reg [1:0] bte_o;
output reg [2:0] cti_o;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [7:0] sel_o;
output reg [63:0] adr_o;
input [63:0] dat_i;
output reg [63:0] dat_o;
`include "FT64v8d_states.v"

parameter byt_ = 2'd0;
parameter half = 2'd1;
parameter word = 2'd2;
parameter dword = 2'd3;

integer n;
reg [7:0] state;
reg [7:0] state1;
reg [7:0] state2;

reg [63:0] ir;
wire [2:0] insn_length;
reg [39:0] pc;
reg [63:0] prog_base;
wire [76:0] pbpc = {prog_base,13'd0} + pc;
reg [63:0] sp;
reg [63:0] data_base;
reg [2:0] ccRt;
reg [63:0] cc;
reg [7:0] cca;
reg [63:0] status;
reg [63:0] semaphore;
reg [63:0] vbr;								// exception vector table base address
reg [8:0] cause;							// exception cause code\

reg rfwr, ccrfwr_all, ccrfwr_ponz;
reg [63:0] regfile [0:31];
reg [63:0] sp [0:3];
reg [4:0] Ra, Rb, Rc, Rt;
reg [63:0] rfoa, rfob, rfoc;

always @*
case(Ra)
5'd0:			rfoa <= 64'h0;
5'd31:		rfoa <= sp[ol];
default:	rfoa <= regfile[Ra];
endcase

always @*
case(Rb)
5'd0:			rfob <= 64'h0;
5'd31:		rfob <= sp[ol];
default:	rfob <= regfile[Rb];
endcase

always @*
case(Rc)
5'd0:			rfoc <= 64'h0;
5'd31:		rfoc <= sp[ol];
default:	rfoc <= regfile[Rc];
endcase

reg bat_wr;
reg [11:0] bat_ndx;
reg [63:0] bat [0:4095];
reg [63:0] bat_o, bat_i;
always @(posedge clk_i)
	bat_o <= bat[bat_ndx];
always @(posedge clk_i)
	if (bat_wr) bat[bat_ndx] <= bat_i;

wire [2:0] im = status[2:0];

FT64v8d_insn_length uil1 (ir[7:0], insn_length);

reg [2:0] Sc;
reg [63:0] a, b, c, imm, res;
wire [63:0] difi = a - imm;
wire [63:0] difr = a - b;
reg [1:0] memsize;
reg su;
wire [63:0] ea = {data_base,13'd0} + a + (c << Sc) + imm;
reg [3:0] irq_sp;
reg [383:0] irq_stack_i;
reg [383:0] irq_stack [0:15];
reg irq_stack_wr;
always @(posedge clk_i)
	if (irq_stack_wr)
		irq_stack[irq_sp] <= irq_stack_i;
wire [383:0] irq_stack_o = irq_stack[irq_sp];

`include "FT64v8d_eval_branch.v"

reg [3:0] icstate,picstate;
reg icnxt;
reg L1_wr;
reg [84:0] L1_adr, L2_adr;
reg [641:0] L2_rdat;

FT64v8d_L1_icache uL1ic
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(icnxt),
	.wr(L1_wr),
	.wr_ack(),
	.wadr(L1_adr),
	.adr((icstate==IDLE||icstate==IC_Next) ? {asid,pbpc} : L1_adr),
	.i(L2_rdat),
	.o(insn),
	.fault(),
	.hit(ihit),
	.invall(),
	.invline()
);

reg pe_nmi;
wire nmi_pe;
edge_det uednmi (.clk(clk_i), .ce(1'b1), .i(nmi_i), .pe(nmi_pe), .ne(), .ee());

always @(posedge clk_i)
if (rst_i) begin
	irq_sp <= 4'h0;
	semaphore <= 64'h0;
	pb <= 64'hFFFFFFFFFFFFFF80;
	pc <= 64'h00000000000C0000;
end
else begin
if (nmi_pe)
	pe_nmi <= 1'b1;
rfwr <= 1'b0;
ccrfwr_all <= 1'b0;
ccrfwr_ponz <= 1'b0;
irq_stack_wr <= 1'b0;
case(state)
`include "FT64v8d_ifetch.v"
`include "FT64v8d_decode.v"
`include "FT64v8d_execute.v"
`include "FT64v8d_brk.v"
`include "FT64v8d_rti.v"
`include "FT64v8d_store.v"
`include "FT64v8d_push.v"
endcase
`include "FT64v8d_writeback.v"

end

task goto;
input [7:0] gst;
begin
	state <= gst;
end
endtask

task call;
input [7:0] tst;
input [7:0] rst;
begin
	state <= tst;
	state2 <= state1;
	state1 <= rst;
end
endtask

task ret;
begin
	state <= state1;
	state1 <= state2;
end
endtask

endmodule
