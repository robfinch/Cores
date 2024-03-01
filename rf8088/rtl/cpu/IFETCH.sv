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
// - All of the state control flags are reset.
//
// - If the current instruction is a prefix then we want to shift it
//   into the prefix buffer before fetching the instruction. Also
//   interrupts are blocked if the previous instruction is a prefix.
//
// - two bytes are fetched at once if the instruction is aligned on
//   an even address. This saves a bus cycle most of the time.
//
// ToDo:
// - add an exception if more than two prefixes are present.
//
//=============================================================================
//
IFETCH:
	begin
		$display("\r\n******************************************************");
		$display("time: %d", $time);
		$display("CSIP: %h", csip);
		$display("AX=%h  SI=%h", ax, si);
		$display("BX=%h  DI=%h", bx, di);
		$display("CX=%h  BP=%h", cx, bp);
		$display("DX=%h  SP=%h", dx, sp);
		// Reset all instruction processing flags at instruction fetch
		mod <= 2'd0;
		rrr <= 3'd0;
		rm <= 3'd0;
		sxi <= 1'b0;
		hasFetchedModrm <= 1'b0;
		hasFetchedDisp8 <= 1'b0;
		hasFetchedDisp16 <= 1'b0;
		hasFetchedVector <= 1'b0;
		hasStoredData <= 1'b0;
		hasFetchedData <= 1'b0;
		data16 <= 16'h0000;
		cnt <= 7'd0;
//		if (prefix1!=8'h00 && prefix2 !=8'h00 && is_prefix)
//			state <= TRIPLE_PREFIX;
		if (is_prefix) begin
			prefix1 <= ir;
			prefix2 <= prefix1;
		end
		else begin
			prefix1 <= 8'h00;
			prefix2 <= 8'h00;
		end

    if (pe_nmi & checkForInts) begin
      tGoto(INT2);
      rst_nmi <= 1'b1;
      int_num <= 8'h02;
      ir <= `NOP;
    end
    else if (irq_i & ie & checkForInts) begin
      tGoto(INTA0);
      ir <= `NOP;
    end
    else if (ir==`HLT) begin
    	;
    end
    else begin
			tGoto(IFETCH_ACK);
			inta_o <= 1'b0;
			mio_o <= 1'b1;
		end
	end

IFETCH_ACK:
	begin
		$display("CSIP: %h IR: %h",csip,bundle[7:0]);
		nack_ir();
		if (!hasPrefix)
			ir_ip <= ip;
//		ir_ip <= dat_i;
		w <= bundle[0];
		d <= bundle[1];
		v <= bundle[1];
		sxi <= bundle[1];
		sreg2 <= bundle[4:3];
		sreg3 <= {1'b0,bundle[4:3]};
		ir2 <= 8'h00;
		tGoto(DECODE);
	end

// Fetch extended opcode
//
XI_FETCH:
	begin
		nack_ir2();
		tGoto(DECODER2);
	end
