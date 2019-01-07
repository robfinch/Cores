`define TRUE			1'b1
`define FALSE			1'b0

`define I_BRK			8'h00
`define I_OR6			8'h05
`define I_PHP			8'h08
`define I_OR30		8'h09
`define I_BYTE		8'h0F
`define I_BPL			8'h10
`define I_OR			8'h17
`define I_OR14		8'h19
`define I_UBYTE		8'h1F
`define I_JSR			8'h20
`define I_JSL			8'h22
`define I_AND6		8'h25
`define I_AND30		8'h29
`define I_HALF		8'h2F
`define I_BMI			8'h30
`define I_AND			8'h37
`define I_AND14		8'h39
`define I_UHALF		8'h3F
`define I_RTI			8'h40
`define I_EOR6		8'h45
`define I_PUSH6		8'h48
`define I_EOR30		8'h49
`define I_JMP			8'h4C
`define I_WORD		8'h4F
`define I_BVC			8'h50
`define I_EOR			8'h57
`define I_CLI			8'h58
`define I_EOR14		8'h59
`define I_UWORD		8'h5F
`define I_RTS			8'h60
`define I_BSR			8'h62
`define I_ADD6		8'h65
`define I_ADD30		8'h69
`define I_BVS			8'h70
`define I_ADD			8'h77
`define I_SEI			8'h78
`define I_ADD14		8'h79
`define I_BRA			8'h80
`define I_SDSP		8'h83
`define I_MOV			8'hAA
`define I_CMP6		8'hC5
`define I_CMP30		8'hC9
`defube I_WAI			8'hCB
`define I_BNE			8'hD0
`define I_CMP14		8'hD9
`define I_PUSH3		8'hDA
`define I_NOP			8'hEA
`define I_BEQ			8'hF0
`define I_SUB			8'hF7

`define OM_MACHINE	2'b00
`define STATUS_IM		2:0
`define	STATUS_OM		5:4

// cycle types
`define CTI_CLASSIC		3'b000		// classic cycle
`define CTI_BURST_FXA	3'b001		// fixed address burst
`define CTI_BURST_INC	3'b010		// incrementing address burst
`define CTI_WAIT			3'b011		// waiting for interrupt (non-standard)
`define CTI_VEC_FETCH	3'b100		// vector fetch (non-standard)
`define CTI_BURST_END	3'b111		// end of burst
