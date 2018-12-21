
module FT64v8_idecoder(clk, insn, bus);
input [63:0] insn;
output [159:0] bus;

function IsFcu;
input [63:0] insn;
case(insn[7:0])
`JMP,`JMF,`JSR,`JSF,
`RTS,`RTF,`RTI,
`BEQ,`BNE,`BLT,`BGE,`BLE,`BGT,`BLTU,`BGEU,`BLEU,`BGTU,
`BOD,`BEV,`BPA,`BNP,`BVS,`BVC:
	IsFcu = TRUE;
default:	IsFcu = FALSE;
endcase
endfunction

function IsRfw;
input [63:0] insn;
begin
end
endfunction

always @(posedge clk)
begin
	bus[`IB_RA] <= fnRa(insn);
	bus[`IB_RB] <= fnRb(insn);
	bus[`IB_RC] <= fnRc(insn);
	bus[`IB_FCU] <= IsFcu(insn);
	bus[`IB_MEM] <= IsMem(insn);
	bus[`IB_LOAD] <= IsLoad(insn);
	bus[`IB_STORE] <= IsStore(insn);
	bus[`IB_RFW] <= IsRfw(insn);
end

endmodule
