
module rtf6809_icachemem(wclk, wce, wr, wa, i, rclk, rce, pc, insn);

reg [31:0] mem [0:1023];
reg [15:0] rpc;

always @(posedge rclk)
	if (rce) rpc <= pc;
assign insn = mem[rpc];

endmodule
