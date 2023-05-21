import rfx32pkg::*;

module rfx32_regfile(rst, clk,
	commit0_v, commit1_v, commit0_tgt, commit1_tgt, commit0_bus, commit1_bus,
	rf);
input rst;
input clk;
input commit0_v;
input commit1_v;
input [4:0] commit0_tgt;
input [4:0] commit1_tgt;
input value_t commit0_bus;
input value_t commit1_bus;
output value_t [31:0] rf;

integer n,n1;

initial begin
	for (n = 0; n < 32; n = n + 1)
		rf[n] = 'd0;
end

always_ff @(posedge clk, posedge rst)
if (rst) begin
	for (n1 = 0; n1 < 32; n1 = n1 + 1)
		rf[n1] = 'd0;
end
else begin
	//
	// COMMIT PHASE (register-file update only ... dequeue is elsewhere)
	//
	// look at head0 and head1 and let 'em write the register file if they are ready
	//
	// why is it happening here and not in another phase?
	// want to emulate a pass-through register file ... i.e. if we are reading
	// out of r3 while writing to r3, the value read is the value written.
	// requires BLOCKING assignments, so that we can read from rf[i] later.
	//
	if (commit0_v) begin
    rf[ commit0_tgt ] = commit0_bus;
    if (commit0_tgt != 'd0) $display("r%d <- %h", commit0_tgt, commit0_bus);
	end
	if (commit1_v) begin
    rf[ commit1_tgt ] = commit1_bus;
    if (commit1_tgt != 'd0) $display("r%d <- %h", commit1_tgt, commit1_bus);
	end

	rf[0] = 0;

end

endmodule
