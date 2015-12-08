// ============================================================================
//        __
//   \\__/ o\    (C) 2013,2015  Robert Finch, Stratford
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
//
// Thor SuperScalar
//
// ============================================================================
//
module Thor_icachemem(wclk, wce, wr, wa, wd, rclk, pc, insn);
parameter DBW=64;
input wclk;
input wce;
input wr;
input [DBW-1:0] wa;
input [DBW-1:0] wd;
input rclk;
input [DBW-1:0] pc;
output reg [127:0] insn;

wire [127:0] mem0a;
wire [127:0] mem1a;
reg [14:0] pcp16;

generate
begin : gen1
	if (DBW==32) begin
        syncRam2kx32_1w1r uicm0a0 (
            .wclk(wclk),
            .wce(wce && wa[3:2]==2'b00),
            .wr({4{wr}}),
            .wa(wa[14:4]),
            .wd(wd),
            .rclk(rclk),
            .rce(1'b1),
            .ra(pc[14:4]),
            .o(mem0a[31:0])
        );
        syncRam2kx32_1w1r uicm0a1 (
            .wclk(wclk),
            .wce(wce && wa[3:2]==2'b01),
            .wr({4{wr}}),
            .wa(wa[14:4]),
            .wd(wd),
            .rclk(rclk),
            .rce(1'b1),
            .ra(pc[14:4]),
            .o(mem0a[63:32])
        );
        syncRam2kx32_1w1r uicm0a2 (
            .wclk(wclk),
            .wce(wce && wa[3:2]==2'b10),
            .wr({4{wr}}),
            .wa(wa[14:4]),
            .wd(wd),
            .rclk(rclk),
            .rce(1'b1),
            .ra(pc[14:4]),
            .o(mem0a[95:64])
        );
        syncRam2kx32_1w1r uicm0a3 (
            .wclk(wclk),
            .wce(wce && wa[3:2]==2'b11),
            .wr({4{wr}}),
            .wa(wa[14:4]),
            .wd(wd),
            .rclk(rclk),
            .rce(1'b1),
            .ra(pc[14:4]),
            .o(mem0a[127:96])
        );

        syncRam2kx32_1w1r uicm1a0 (
            .wclk(wclk),
            .wce(wce && wa[3:2]==2'b00),
            .wr({4{wr}}),
            .wa(wa[14:4]),
            .wd(wd),
            .rclk(rclk),
            .rce(1'b1),
            .ra(pcp16[14:4]),
            .o(mem1a[31:0])
        );
        syncRam2kx32_1w1r uicm1a1 (
            .wclk(wclk),
            .wce(wce && wa[3:2]==2'b01),
            .wr({4{wr}}),
            .wa(wa[14:4]),
            .wd(wd),
            .rclk(rclk),
            .rce(1'b1),
            .ra(pcp16[14:4]),
            .o(mem1a[63:32])
        );
        syncRam2kx32_1w1r uicm1a2 (
            .wclk(wclk),
            .wce(wce && wa[3:2]==2'b10),
            .wr({4{wr}}),
            .wa(wa[14:4]),
            .wd(wd),
            .rclk(rclk),
            .rce(1'b1),
            .ra(pcp16[14:4]),
            .o(mem1a[95:64])
        );
        syncRam2kx32_1w1r uicm1a3 (
            .wclk(wclk),
            .wce(wce && wa[3:2]==2'b11),
            .wr({4{wr}}),
            .wa(wa[14:4]),
            .wd(wd),
            .rclk(rclk),
            .rce(1'b1),
            .ra(pcp16[14:4]),
            .o(mem1a[127:96])
        );
    end
end
endgenerate

always @(pc)
	pcp16 <= pc[14:0] + 15'd16;
wire [127:0] insn0 = mem0a;
wire [127:0] insn1 = mem1a;
always @(pc or insn0 or insn1)
case(pc[3:0])
4'd0:	insn <= insn0;
4'd1:	insn <= {insn1[7:0],insn0[127:8]};
4'd2:	insn <= {insn1[15:0],insn0[127:16]};
4'd3:	insn <= {insn1[23:0],insn0[127:24]};
4'd4:	insn <= {insn1[31:0],insn0[127:32]};
4'd5:	insn <= {insn1[39:0],insn0[127:40]};
4'd6:	insn <= {insn1[47:0],insn0[127:48]};
4'd7:	insn <= {insn1[55:0],insn0[127:56]};
4'd8:	insn <= {insn1[63:0],insn0[127:64]};
4'd9:	insn <= {insn1[71:0],insn0[127:72]};
4'd10:	insn <= {insn1[79:0],insn0[127:80]};
4'd11:	insn <= {insn1[87:0],insn0[127:88]};
4'd12:	insn <= {insn1[95:0],insn0[127:96]};
4'd13:	insn <= {insn1[103:0],insn0[127:104]};
4'd14:	insn <= {insn1[111:0],insn0[127:112]};
4'd15:	insn <= {insn1[119:0],insn0[127:120]};
endcase

endmodule
