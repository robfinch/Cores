`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//                                                                          
// ============================================================================

module rf68000_node_arbiter(id, rst_i, clk_i,
	cpu_cyc, cpu_stb, cpu_ack, cpu_aack, cpu_we, cpu_sel, cpu_adr, cpu_dato, cpu_dati,
	nic_cyc, nic_stb, nic_ack, nic_we, nic_sel, nic_adr, nic_dati, nic_dato,
	ram_en, ram_we, ram_adr, ram_dati, ram_dato);
input [3:0] id;
input rst_i;
input clk_i;
input cpu_cyc;
input cpu_stb;
output reg cpu_ack;
output reg cpu_aack;
input cpu_we;
input [3:0] cpu_sel;
input [31:0] cpu_adr;
input [31:0] cpu_dato;
output reg [31:0] cpu_dati;
input nic_cyc;
input nic_stb;
input nic_we;
output reg nic_ack;
input [3:0] nic_sel;
input [31:0] nic_adr;
output reg [31:0] nic_dati;
input [31:0] nic_dato;
output reg ram_en;
output reg [3:0] ram_we;
output reg [31:0] ram_adr;
input [31:0] ram_dato;
output reg [31:0] ram_dati;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

reg w1;

typedef enum logic [3:0] {
	ST_IDLE = 6'd0,
	ST_ACK = 6'd1,
	ST_RD1 = 6'd2,
	ST_RD2 = 6'd3,
	ST_RD3 = 6'd4,
	ST_RD4 = 6'd5,
	ST_ACKC = 6'd6
} state_t;
state_t state;

always_ff @(posedge clk_i)
if (rst_i) begin
	cpu_ack <= 1'b0;
	cpu_aack <= 1'b0;
	cpu_dati <= 32'h0;
	ram_en <= FALSE;
	ram_we <= 4'h0;
	state <= ST_IDLE;
end
else begin
	// If the cycle is over, clear the ack and reset the data bus.
	if (!(cpu_cyc & cpu_stb)) begin
		cpu_ack <= 1'b0;
		cpu_aack <= 1'b0;
		cpu_dati <= 32'h0;
	end
	if (!(nic_cyc & nic_stb)) begin
		nic_ack <= 1'b0;
		nic_dati <= 32'h0;
	end
	case(state)
	ST_IDLE:
		if (nic_cyc) begin
			w1 <= 1'b0;
			if (nic_adr[31:20]=={8'hFF,id[3:0]}) begin
				ram_adr <= nic_adr;
				ram_dati <= nic_dato;
				ram_we <= {4{nic_we}} & nic_sel;
				ram_en <= TRUE;
				state <= ST_RD1;
			end
			else
				nic_ack <= 1'b1;
		end
		else if (cpu_cyc) begin
			w1 <= 1'b1;
			if (cpu_adr[31:20]==12'h0) begin
				state <= cpu_we ? ST_RD3 : ST_RD1;
				ram_we <= {4{cpu_we}} & cpu_sel;
				ram_en <= TRUE;
				ram_adr <= cpu_adr;
				ram_dati <= cpu_dato;
			end
		end
	// Three cycle read latency.
	ST_RD1:
		begin
			ram_en <= TRUE;
			if (w1) begin
				ram_adr <= cpu_adr;
				ram_we <= {4{cpu_we}} & cpu_sel;
				ram_dati <= cpu_dato;
			end
			else begin
				ram_adr <= nic_adr;
				ram_we <= {4{nic_we}} & nic_sel;
				ram_dati <= nic_dato;
			end
			state <= ST_RD2;
		end
	ST_RD2:
		begin
			ram_en <= TRUE;
			if (w1) begin
				ram_adr <= cpu_adr;
				ram_we <= {4{cpu_we}} & cpu_sel;
				ram_dati <= cpu_dato;
			end
			else begin
				ram_adr <= nic_adr;
				ram_we <= {4{nic_we}} & nic_sel;
				ram_dati <= nic_dato;
			end
			state <= ST_RD3;
		end
	ST_RD3:
		begin
			state <= ST_ACK;
			ram_en <= TRUE;
			if (w1) begin
				ram_adr <= cpu_adr;
				ram_we <= {4{cpu_we}} & cpu_sel;
				ram_dati <= cpu_dato;
			end
			else begin
				ram_adr <= nic_adr;
				ram_we <= {4{nic_we}} & nic_sel;
				ram_dati <= nic_dato;
			end
			if (w1) begin
				cpu_dati <= ram_dato;
				cpu_ack <= 1'b1;
				cpu_aack <= 1'b1;
			end
			else begin
				nic_dati <= ram_dato;
				nic_ack <= 1'b1;
			end
		end
	ST_ACK:
		begin
			ram_en <= FALSE;
			ram_we <= 4'h0;
			if ((nic_ack & nic_cyc & nic_stb) || (cpu_ack & cpu_cyc & cpu_stb))
				;
			else
				state <= ST_IDLE;
		end
	default:
		state <= ST_IDLE;
	endcase
end

endmodule
