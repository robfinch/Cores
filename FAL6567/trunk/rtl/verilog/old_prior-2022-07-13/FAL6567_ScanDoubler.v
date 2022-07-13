
module FAL6567_ScanConverter(clk8, clk31, hSync8_i, vSync8_i, color_i, hSync31_i, vSync31_i, color_o);
parameter CHIP6567R8 = 2'd0;
parameter CHIP6567OLD = 2'd1;
parameter CHIP6569 = 2'd2;
parameter CHIP6572 = 2'd3;

input clk8;
input clk31;
input hSync8_i;
input vSync8_i;
input [3:0] color_i;
input hSync31_i;
input vSync31_i;
output [3:0] color_o;

reg [3:0] mem [0:137216];
reg [9:0] raster8X;
reg [9:0] raster8XMax;
reg [8:0] raster8Y;
reg [8:0] raster8YMax;
reg phSync8, pvSync8;

reg [10:0] raster31X;
reg [9:0] raster31Y;
reg [9:0] raster31YMax;
reg phSync31, pvSync31;

// Set Limits
always @(chip)
case(chip)
CHIP6567R8:   raster8XMax = 10'd520;
CHIP6567OLD:  raster8XMax = 10'd512;
CHIP6569:     raster8XMax = 10'd504;
CHIP6572:     raster8XMax = 10'd504;
endcase

wire [17:0] adr8 = raster8Y * raster8XMax + raster8X;
wire [17:0] adr31 = raster31Y[9:1] * raster8XMax + raster31X[10:1];

always @(posedge clk8)
begin
phSync8 <= hSync8_i;
pvSync8 <= vSync8_i;
if (hSync8_i && !phSync8)
  raster8X <= 10'd0;
else
  raster8X <= raster8X + 10'd1;
if (vSync8_i && !pvSync8_i)
  raster8Y <= 9'd0;
else if (hSync8_i && !phSync8)
  raster8Y <= raster8Y + 9'd1;
end

always @(posedge clk31)
begin
phSync31 <= hSync31_i;
pvSync31 <= vSync31_i;
if (!hSync31_i && phSync31)
  raster31X <= 10'd0;
else
  raster31X <= raster31X + 10'd1;
if (!vSync31_i && pvSync31_i)
  raster31Y <= 10'd0;
else if (!hSync31_i && phSync31)
  raster31Y <= raster31Y + 10'd1;
end

always @(posedge clk8)
  mem[adr8] <= color_i;

always @(posedge clk8)
  color_o <= mem[adr31];

endmodule
