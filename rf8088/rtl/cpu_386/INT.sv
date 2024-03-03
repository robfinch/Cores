// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  INT.sv
//  - Interrupt handling
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
//
// Fetch interrupt number from instruction stream

rf80386_pkg::INT:
	begin
		eip <= eip + 2'd1;
		int_num <= bundle[7:0];
		tGoto(rf80386_pkg::INT2);
	end
rf80386_pkg::INT2:
	begin
		ad <= idt_base + {int_num,3'd0};
		sel <= 16'h00FF;
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::INT3);
	end
rf80386_pkg::INT3:
	begin
		offset[15: 0] <= igate.offset_lo;
		offset[31:16] <= igate.offset_hi;
		selector <= igate.selector;
		esp <= esp - 4'd4;
		tGoto(rf80386_pkg::INT4);
	end
rf80386_pkg::INT4:
	begin
		ad <= sssp;
		sel <= 16'h000F;
		dat <= flags[31:0];
		tGosub(rf80386_pkg::STORE,rf80386_pkg::INT5);
	end
rf80386_pkg::INT5:
	begin
		esp <= esp - 4'd2;
		tGoto(rf80386_pkg::INT6);
	end
rf80386_pkg::INT6:
	begin
		ad <= sssp;
		sel <= 16'h0003;
		dat <= cs;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::INT7);
	end
rf80386_pkg::INT7:
	begin
		esp <= esp - 4'd4;
		tGoto(rf80386_pkg::INT8);
	end
rf80386_pkg::INT8:
	begin
		ad <= sssp;
		sel <= 16'h000F;
		dat <= ir_ip;
		tGosub(rf80386_pkg::STORE,rf80386_pkg::INT9);
	end
rf80386_pkg::INT9:
	begin
		cs <= selector;
		ip <= offset;
		tGosub(rf80386_pkg::LOAD_CS_DESC,rf80386_pkg::IFETCH);
	end
