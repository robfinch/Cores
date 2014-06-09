// ============================================================================
// Table887.v
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
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
// ============================================================================
//
// Bit 0 is on the left, bit 15 on the right
//
// Register Immediate Format:
//    5     3   3    5
// +-----+----+----+-----+
// | opc | Ra | Rt | Imm |
// +-----+----+----+-----+
//
// Register-Register Format:
//    5     3   3    3     2
// +-----+----+----+----+----+
// |  2  | Ra | Rb | Rt | Fn |
// +-----+----+----+----+----+
//
// conditional branch format:
//    5     3     8
// +-----+----+--------+
// | 16  | Ra |  disp  |
// +-----+----+--------+
//
// Jump Format:
//    5    3      8
// +-----+---+--------+
// |  20 | ~ |  addr  |
// +-----+---+--------+
// |     address      |
// +------------------+

`define RR1		5'd1
`define RR2		5'd2
`define 	ADD		2'd0
`define		SUB		2'd1
`define 	CMP		2'd2
`define 	CMPU	2'd3
`define RR3		5'd3
`define 	AND		2'd0
`define		OR		2'd1
`define 	XOR		2'd2
`define ADDI	5'd4
`define SUBI	5'd5
`define CMPI	5'd6
`define CMPUI	5'd7
`define ANDI	5'd8
`define ORI		5'd9
`define XORI	5'd10
`define SHIFT	5'd11
`define SHL			2'd0
`define SHR			2'd1
`define SHLI		2'd2
`define SHRI		2'd3
`define LDI		5'd12
`define BEQ		5'd16
`define BNE		5'd17
`define BMI		5'd18
`define BPL		5'd19
`define JMP		5'd20
`define JSR		5'd21
`define RTS		5'd22
`define LW		5'd24
`define SW		5'd25

module Table887(rst_i, clk_i, cyc_o, stb_o, ack_i, we_o, adr_o, dat_i, dat_o);
input rst_i;
input clk_i;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [23:0] adr_o;
input [15:0] dat_i;
output reg [15:0] dat_o;

parameter RESET  =4'd0;
parameter IFETCH1=4'd1;
parameter IFETCH2=4'd2;
parameter DECODE1=4'd3;
parameter DECODE2=4'd4;
parameter DECODE3=4'd5;
parameter EXECUTE=4'd8;
parameter MEMORY =4'd9;
parameter WRITEBACK=4'd10;

reg [3:0] state;					// machine state
reg [23:0] pc;						// program counter
reg [15:0] ir;						// instruction register
wire [2:0] Ra = ir[7:5];			// register port a spec
wire [2:0] Rb = ir[10:8];			// register port b spec
reg [2:0] Rt;						// target register
reg [15:0] regfile [7:0];			// register file
wire [15:0] rfoa,rfob;				// register file outputs
reg [15:0] a,b;						// operand holding registers
wire signed [15:0] as = a;			// convert a to signed a
wire signed [15:0] bs = b;			// convert b to signed b
reg [16:0] res;						// result bus
reg [15:0] operand;
reg [15:0] immediate;
reg take_branch;					// branch flag
reg [5:0] rsp;						// return stack pointer
reg [23:0] return_stack [63:0];		// return address stack

assign rfoa = Ra==3'd0 ? 16'd0 : regfile[Ra];
assign rfob = Rb==3'd0 ? 16'd0 : regfile[Rb];

// Evaluate jump condition
always @*
	case(ir[7:0])
	`BEQ:	take_branch <=  a==16'd0;
	`BNE:	take_branch <=  a!=16'd0;
	`BMI:	take_branch <=  a[15];
	`BPL:	take_branch <= !a[15];
	default:	take_branch <= 1'b0;
	endcase

always @(posedge clk_i)
if (rst_i) begin
	pc <= 24'h0000;
	rsp <= 6'd0;
	next_state(IFETCH1);
end
else begin
case(state)

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// IFETCH Stage
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
IFETCH1:
	begin
		wb_read(pc);
		pc <= pc + 24'd2;
		next_state(IFETCH2);
	end
IFETCH2:
	if (ack_i) begin
		wb_nack();
		ir <= dat_i;
		next_state(DECODE1);
	end

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// DECODE Stage
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
DECODE1:
	begin
		next_state(EXECUTE);
		Rt <= 3'd0;
		a <= rfoa;
		b <= rfob;
		case(ir[7:0])
		`LDI:	begin
					Rt <= ir[7:5];
					immediate <= {{8{ir[15]}},ir[15:8]};
					if (ir[15:8]==8'h80)
						next_state(DECODE2);
				end
		`RR2,`RR3,`SHIFT:	Rt <= ir[13:11];
		`ADDI,`SUBI,`ANDI,`ORI,`XORI,`LW:
			begin
				Rt <= ir[10:8];
				immediate <= {{11{ir[15]}},ir[15:11]};
				if (ir[15:11]==5'h10)
					next_state(DECODE2);
			end
		`CMPI,`CMPUI,`SW:
			begin
				immediate <= {{11{ir[15]}},ir[15:11]};
				if (ir[15:11]==5'h10)
					next_state(DECODE2);
			end
		`JMP:	next_state(DECODE2);
		`JSR:	next_state(DECODE2);
		default:	next_state(EXECUTE);
		endcase
	end
DECODE2:
	begin
		wb_read(pc);
		pc <= pc + 24'd2;
		next_state(DECODE3);
	end
DECODE3:
	if (ack_i) begin
		wb_nack();
		immediate <= dat_i;
		next_state(EXECUTE);
	end

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// EXECUTE Stage
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
EXECUTE:
	begin
		next_state(MEMORY);

		case(ir[7:0])

		// Arithmetic / Logical
		`RR2:
			case(ir[15:14])
			`ADD:	res <= a + b;
			`SUB:	res <= a - b;
			`CMP:	res <= as < bs ? 16'hFFFF : a==b ? 16'h0000 : 16'h0001;
			`CMPU:	res <= a < b ? 16'hFFFF : a==b ? 16'h0000 : 16'h0001;
			endcase
		`RR3:
			case(ir[15:14])
			`AND:	res <= a & b;
			`OR:	res <= a | b;
			`XOR:	res <= a ^ b;
			endcase
		`ADDI:	res <= a + immediate;
		`SUBI:	res <= a - immediate;
		`CMPI:	res <= as < immediate ? 16'hFFFF : a==immediate ? 16'h0000 : 16'h0001;
		`CMPUI:	res <= a < immediate ? 16'hFFFF : a==immediate ? 16'h0000 : 16'h0001;
		`ANDI:	res <= a & immediate;
		`ORI:	res <= a | immediate;
		`XORI:	res <= a ^ immediate;
		// Shift
		`SHIFT:
			case(ir[15:14])
			`SHL:	res <= a << b[3:0];
			`SHR:	res <= a >> b[3:0];
			`SHLI:	res <= a << Rb;
			`SHRI:	res <= a >> Rb;
			endcase
		`LDI:	res <= immediate;

		// Flow Control Instructions
		`BEQ,`BNE,`BMI,`BPL:
			if (take_branch)
				pc <= pc + {{16{ir[15]}},ir[15:8]};
		`JMP:	pc <= {immediate,ir[15:8]};
		`JSR:	begin
					return_stack[rsp-6'd1] <= pc;
					rsp <= rsp - 6'd1;
					pc <= {immediate,ir[15:8]};
				end
		`RTS:	begin
					pc <= return_stack[rsp];
					rsp <= rsp + 6'd1;
				end

		// Memory
		`LW:	wb_read(a+immediate);
		`SW:	wb_write(a+immediate,b);
		endcase
	end

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// MEMORY Stage
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
MEMORY:
	if (cyc_o) begin
		if (ack_i) begin
			wb_nack();
			res <= dat_i;
			next_state(WRITEBACK);
		end
	end
	else
		next_state(WRITEBACK);

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// Writeback Stage
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
WRITEBACK:
	begin
		regfile[Rt] <= res;
		next_state(IFETCH1);
	end

endcase
end

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// Supporting Tasks
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
task wb_read;
input [23:0] adr;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	adr_o <= adr;
end
endtask

task wb_write;
input [23:0] adr;
input [15:0] dat;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b1;
	adr_o <= adr;
	dat_o <= dat;
end
endtask

task wb_nack;
begin
	cyc_o <= 1'b0;
	stb_o <= 1'b0;
	we_o <= 1'b0;
	adr_o <= 24'd0;
	dat_o <= 16'd0;
end
endtask

task next_state;
input [5:0] nxt;
begin
	state <= nxt;
end
endtask

endmodule
