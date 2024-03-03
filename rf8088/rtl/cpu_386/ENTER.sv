// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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
//
//=============================================================================

rf80386_pkg::ENTER:
	begin
		eip <= eip + 4'd3;
		ad <= sssp;
		ftmp <= esp;
		if (cs_desc.db) begin
			sel <= 16'h000F;
			dat <= ebp;
		end
		else begin
			sel <= 16'h0003;
			dat <= bp;
		end
		if (bundle[23:16]==8'h00)
			tGosub(rf80386_pkg::STORE,rf80386_pkg::ENTER0);
		else if (bundle[23:16]==8'h01) begin
			if (cs_desc.db)
				esp <= esp - 4'd4;
			else
				esp <= esp - 4'd2;
			tGosub(rf80386_pkg::STORE,rf80386_pkg::ENTER1);
		end
		else begin
			if (cs_desc.db)
				esp <= esp - 4'd4;
			else
				esp <= esp - 4'd2;
			tGosub(rf80386_pkg::STORE,rf80386_pkg::ENTERN);
		end
	end
rf80386_pkg::ENTER0:
	begin
		ebp <= ftmp;
		esp <= esp - bundle[15:0];
		tGoto(rf80386_pkg::IFETCH);
	end
rf80386_pkg::ENTER1:
	begin
		ad <= sssp;
		if (cs_desc.db) begin
			sel <= 16'h000F;
			dat <= ftmp;
		end
		else begin
			sel <= 16'h0003;
			dat <= ftmp[15:0];
		end
		tGosub(rf80386_pkg::STORE,rf80386_pkg::ENTER0);
	end
rf80386_pkg::ENTERN:
	begin
		tGoto(rf80386_pkg::ENTER1);
	end
