// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	life.v
//  Conway's Game of Life
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
// 4010 LUTs / 30 BRAM's (Artix7) (512x256 areana)
// ============================================================================
//
`define HCELLS  256
`define VCELLS  256
`define VAMSB   7

// Memory for life cells.
// The environment is 512x256

module liferam(wclk, wce, wadr, i, rclk, rce, ra0, ra1, ra2, rclk3, ra3, o0, o1, o2, o3);
input wclk;
input wce;
input [`VAMSB:0] wadr;
input [`HCELLS-1:0] i;
input rclk;
input rce;
input [`VAMSB:0] ra0;
input [`VAMSB:0] ra1;
input [`VAMSB:0] ra2;
input rclk3;
input [`VAMSB:0] ra3;
output [`HCELLS-1:0] o0;
output [`HCELLS-1:0] o1;
output [`HCELLS-1:0] o2;
output [`HCELLS-1:0] o3;

reg [`HCELLS-1:0] mem [0:`VCELLS-1];
reg [`VAMSB:0] rra0, rra1, rra2, rra3;

always @(posedge wclk)
    if (wce) mem[wadr] <= i;

always @(posedge rclk)
    rra0 <= ra0;
always @(posedge rclk)
    rra1 <= ra1;
always @(posedge rclk)
    rra2 <= ra2;
always @(posedge rclk3)
    rra3 <= ra3;

assign o0 = mem[rra0];
assign o1 = mem[rra1];
assign o2 = mem[rra2];
assign o3 = mem[rra3];

endmodule

// Calculate whether a cell is alive or dead.
module lifecalc(self, n, alive);
input self;
input [7:0] n;
output alive;

wire [3:0] sum = n[0] + n[1] + n[2] + n[3] + n[4] + n[5] + n[6] + n[7];
assign alive = self ? (sum==4'd2 || sum===4'd3) : (sum==4'd3);

endmodule

// Calculate life for an entire row of cells.

module lifecalc_parallel(row0, row1, row2, alive);
input [`HCELLS-1:0] row0;
input [`HCELLS-1:0] row1;
input [`HCELLS-1:0] row2;
output [`HCELLS-1:0] alive;

genvar g;
generate
begin : lifecal
for (g = 0; g < `HCELLS; g = g + 1)
begin : lf1
lifecalc ul (
    .self(row1[g]),
    .n({
    // three cells above
    (g==`HCELLS-1 ? {row0[0],row0[`HCELLS-1],row0[`HCELLS-2]} :
             g==0 ? {row0[1],row0[0],row0[`HCELLS-1]} :  
                     row0[(g+1):(g-1)]),
    // cell on either side
    (g==`HCELLS-1 ? {row1[0],row1[`HCELLS-2]} :
             g==0 ? {row1[1],row1[`HCELLS-1]} :  
                    {row1[(g+1)],row1[(g-1)]}),
    // three cells below
    (g==`HCELLS-1 ? {row2[0],row2[`HCELLS-1],row2[`HCELLS-2]} :
             g==0 ? {row2[1],row2[0],row2[`HCELLS-1]} :  
                     row2[(g+1):(g-1)])}),
    .alive(alive[g])
);
end
end
endgenerate
endmodule

module lifegame(rst_i,clk_i,cyc_i,stb_i,ack_o,we_i,adr_i,dat_i,dat_o,vclk,vsync,hsync,rgb_i,rgb_o);
input rst_i;
input clk_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [31:0] adr_i;
input [31:0] dat_i;
output [31:0] dat_o;
input vclk;
input vsync;
input hsync;
input [23:0] rgb_i;
output reg [23:0] rgb_o;

// Control regs
reg [31:0] freq;
reg [23:0] color;
reg [23:0] bkcolor;
reg [11:0] window_left;                 // position of left edge of window
reg [11:0] window_top;                  // position of top edge of window
reg scalex,scaley;                      // screen scaling 0=1:1, 1 = 2:1
reg tbk;                                // transparent background
reg disp;                               // display enable
reg calc;                               // calculation enable
reg load;

reg [31:0] cnt;
wire [`VAMSB:0] radr = cnt[`VAMSB+18:18];
reg [`VAMSB:0] wadr0,wadr1,wadr2,wadr3;
wire [`HCELLS-1:0] alive;
reg [`HCELLS-1:0] alive1,alive2,alive3;
reg [11:0] scanline;
reg [11:0] dotcnt;
wire pe_hsync,pe_vsync;
wire [`HCELLS-1:0] row0, row1, row2, row3;
reg [511:0] d;
reg [`HCELLS-1:0] q,q1;
reg [`VAMSB:0] load_row;

wire cs = cyc_i && stb_i && (adr_i[31:16]==16'hFFD3);
assign ack_o = cs;

assign dat_o = 32'h0000;

always @(posedge clk_i)
if (rst_i) begin
    calc <= 1'b0;
    load <= 1'b0;
    disp <= 1'b1;
    freq <= 32'h10;
    color <= 24'hFF_FF_FF;
    bkcolor <= 24'h00_00_00;
    tbk <= 1'b0;
    window_left <= 12'd240;
    window_top <= 12'hF80;
    scalex <= 1'b1;
    scaley <= 1'b1;
end
else begin
    load <= 1'b0;
    if (cs) begin
        if (we_i)
            case(adr_i[6:2])
            5'b00000:   d[31:0] <= dat_i;
            5'b00001:   d[63:32] <= dat_i;
            5'b00010:   d[95:64] <= dat_i;
            5'b00011:   d[127:96] <= dat_i;
            5'b00100:   d[159:128] <= dat_i;
            5'b00101:   d[191:160] <= dat_i;
            5'b00110:   d[223:192] <= dat_i;
            5'b00111:   d[255:224] <= dat_i;
            5'b01000:   d[287:256] <= dat_i;
            5'b01001:   d[319:288] <= dat_i;
            5'b01010:   d[351:320] <= dat_i;
            5'b01011:   d[383:352] <= dat_i;
            5'b01100:   d[415:384] <= dat_i;
            5'b01101:   d[447:416] <= dat_i;
            5'b01110:   d[479:448] <= dat_i;
            5'b01111:   d[511:480] <= dat_i;
            5'b10000:   load_row <= dat_i[`VAMSB:0];
            5'b10001:   begin
                        load <= dat_i[0];
                        calc <= dat_i[1];
                        disp <= dat_i[2];
                        end
            5'b10010:   freq <= dat_i;
                        // color control
            5'b10011:   color <= dat_i;
            5'b10100:   begin
                        bkcolor <= dat_i[23:0];
                        tbk <= dat_i[31];
                        end
                        // window control
            5'b10101:   begin
                        window_left <= dat_i[11:0];
                        window_top <= dat_i[27:16];
                        scalex <= dat_i[15];
                        scaley <= dat_i[31];
                        end
            default:    ;
            endcase
    end
end

liferam u1
(
    .wclk(clk_i),
    .wce(load|(calc&cnt[17])),
    .wadr(load ? load_row : wadr3),
    .i(load ? d[`HCELLS-1:0] : alive3),
    .rclk(clk_i),
    .rce(cnt[17]),
    .ra0(radr-8'd1),
    .ra1(radr),
    .ra2(radr+8'd1),
    .rclk3(pe_hsync),
    .ra3(scaley ? scanline[8:1] : scanline[7:0]),
    .o0(row0),
    .o1(row1),
    .o2(row2),
    .o3(row3)
);

lifecalc_parallel u2 (row0, row1, row2, alive);

// This counter to slow the game down to a better viewing pace.
always @(posedge clk_i)
if (rst_i)
    cnt <= 32'd0;
else
    cnt <= cnt + freq;

// Pipeline the write-back. The write-back needs to occur at least three cycles
// after the read and calculation. So that the calculation for a given row isn't
// affected by the update of the previous row. Need to simulate an everything
// is calculated in parallel environment.

always @(posedge clk_i)
begin
    alive1 <= alive;
    alive2 <= alive1;
    alive3 <= alive2;
//    wadr0 <= radr;
    wadr1 <= radr;
    wadr2 <= wadr1;
    wadr3 <= wadr2;
end

//-------------------------------------------------------------
// Video Stuff
//-------------------------------------------------------------

edge_det edh1
(
	.rst(rst_i),
	.clk(vclk),
	.ce(1'b1),
	.i(hsync),
	.pe(pe_hsync),
	.ne(),
	.ee()
);

edge_det edv1
(
	.rst(rst_i),
	.clk(vclk),
	.ce(1'b1),
	.i(vsync),
	.pe(pe_vsync),
	.ne(),
	.ee()
);

wire blank = (scaley ? |scanline[11:9] : |scanline[11:8]) ||
            (dotcnt < window_left) || (dotcnt > window_left + (`HCELLS << scalex));

always @(posedge vclk)
    if (pe_vsync)
        scanline <= window_top;
    else if (pe_hsync)
        scanline <= scanline + 12'd1;
always @(posedge vclk)
    if (pe_hsync)
        dotcnt <= 12'd0;
    else
        dotcnt <= dotcnt + 12'd1;

always @(posedge vclk)
    if (pe_hsync)
        q <= row3;
    else if (!blank & (scalex ? dotcnt[0] : 1'b1))
        q <= {q[`HCELLS-2:0],1'b0};

always @(posedge vclk)
    if (blank|~disp)
        rgb_o <= rgb_i;
    else
        rgb_o <= q[`HCELLS-1] ? color : tbk ? rgb_i : bkcolor; 

endmodule
