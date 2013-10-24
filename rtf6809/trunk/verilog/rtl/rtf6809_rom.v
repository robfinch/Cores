
module rtf6809_rom(rclk, rce, pc, insn);
input rclk;
input rce;
input [15:0] pc;
output [63:0] insn;
reg [63:0] insn;

reg [31:0] mem [0:4095];
reg [15:0] rpc,rpcp4;
integer n;

initial begin
	for (n = 0; n < 4096; n = n + 1)
		mem[n] = n;
end

always @(posedge rclk)
	if (rce) rpc <= pc;
always @(posedge rclk)
	if (rce) rpcp4 <= pc + 16'd4;

wire [31:0] insn0 = mem[rpc[13:2]];
wire [31:0] insn1 = mem[rpcp4[13:2]];

always @(rpc or insn0 or insn1)
case(rpc[1:0])
2'b00:	insn <= {insn1,insn0};
2'b01:	insn <= {insn1,insn0[31:8]};
2'b10:	insn <= {insn1,insn0[31:16]};
2'b11:	insn <= {insn1,insn0[31:24]};
endcase

endmodule
