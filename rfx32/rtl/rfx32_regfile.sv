import rfx32pkg::*;

module rfx32_regfile(rst, clk, branchmiss, livetarget);
input rst;
input clk;
input branchmiss;
input [15:0] livetarget;

reg [15:0] rf_v;

always_ff @(posedge clk, posedge rst)
if (rst) begin
end
else begin
	if (branchmiss) begin
	  if (rf_v[1] == `INV && ~livetarget[1])	rf_v[1] <= `VAL;
	  if (rf_v[2] == `INV && ~livetarget[2])	rf_v[2] <= `VAL;
	  if (rf_v[3] == `INV && ~livetarget[3])	rf_v[3] <= `VAL;
	  if (rf_v[4] == `INV && ~livetarget[4])	rf_v[4] <= `VAL;
	  if (rf_v[5] == `INV && ~livetarget[5])	rf_v[5] <= `VAL;
	  if (rf_v[6] == `INV && ~livetarget[6])	rf_v[6] <= `VAL;
	  if (rf_v[7] == `INV && ~livetarget[7])	rf_v[7] <= `VAL;
	  if (rf_v[8] == `INV && ~livetarget[8])	rf_v[8] <= `VAL;
	  if (rf_v[9] == `INV && ~livetarget[9])	rf_v[9] <= `VAL;
	  if (rf_v[10] == `INV && ~livetarget[10])	rf_v[10] <= `VAL;
	  if (rf_v[11] == `INV && ~livetarget[11])	rf_v[11] <= `VAL;
	  if (rf_v[12] == `INV && ~livetarget[12])	rf_v[12] <= `VAL;
	  if (rf_v[13] == `INV && ~livetarget[13])	rf_v[13] <= `VAL;
	  if (rf_v[14] == `INV && ~livetarget[14])	rf_v[14] <= `VAL;
	  if (rf_v[15] == `INV && ~livetarget[15])	rf_v[15] <= `VAL;
	end
end

endmodule
