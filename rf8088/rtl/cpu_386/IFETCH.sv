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
rf80386_pkg::IFETCH:
	begin
		$display("\r\n******************************************************");
		$display("time: %d", $time);
		$display("CSIP: %h", csip);
		$display("EAX=%h  ESI=%h", eax, esi);
		$display("EBX=%h  EDI=%h", ebx, edi);
		$display("ECX=%h  EBP=%h", ecx, ebp);
		$display("EDX=%h  ESP=%h", edx, esp);
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
		lidt <= 1'b0;
		lgdt <= 1'b0;
		lmsw <= 1'b0;
		lsl <= 1'b0;
		ltr <= 1'b0;
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
      tGoto(rf80386_pkg::INT2);
      rst_nmi <= 1'b1;
      int_num <= 8'h02;
      ir <= `NOP;
    end
    else if (irq_i & ie & checkForInts) begin
      tGoto(rf80386_pkg::INTA0);
      ir <= `NOP;
    end
    else if (ir==`HLT) begin
    	;
    end
    else begin
			tGoto(rf80386_pkg::IFETCH_ACK);
		end
	end

rf80386_pkg::IFETCH_ACK:
	begin
		$display("CSIP: %h IR: %h",csip,bundle[7:0]);
		bundle <= ibundle;
		nack_ir();
		if (!hasPrefix)
			ir_ip <= eip;
//		ir_ip <= dat_i;
		w <= ibundle[0];
		d <= ibundle[1];
		v <= ibundle[1];
		sxi <= ibundle[1];
		sreg2 <= ibundle[4:3];
		sreg3 <= {1'b0,ibundle[4:3]};
		ir2 <= 8'h00;
		tGoto(rf80386_pkg::DECODE);
	end

// Fetch extended opcode
//
XI_FETCH:
	begin
		nack_ir2();
		tGoto(rf80386_pkg::DECODER2);
	end
