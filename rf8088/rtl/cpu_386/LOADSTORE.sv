// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  LOADSTORE
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

// Run two bus cycles if the data is badly aligned.

LOAD:
	begin
		ea <= ad;
		ftam_req.blen <= 6'd0;
		ftam_req.bte <= fta_bus_pkg::LINEAR;
		ftam_req.cti <= fta_bus_pkg::CLASSIC;
		ftam_req.cyc <= HIGH;
		ftam_req.stb <= HIGH;
		ftam_req.sel <= sel_shift[15:0];
		ftam_req.we <= LOW;
		ftam_req.vadr <= ad;
		ftam_req.padr <= ad;
		adr_o <= ad;
		cyc_done <= FALSE;
		tGoto(LOAD_ACK);
	end
LOAD_ACK:
	if (ftam_resp.ack) begin
		dat <= (ftam_resp.dat >> {ad[3:0],3'b0}) & ls_mask;
		if (|sel_shift[19:16])
			tGoto(LOAD2);
		else
			tReturn();
	end
	else if (rty_i && !cyc_done) begin
		ea <= ad;
		ftam_req.blen <= 6'd0;
		ftam_req.bte <= fta_bus_pkg::LINEAR;
		ftam_req.cti <= fta_bus_pkg::CLASSIC;
		ftam_req.cyc <= HIGH;
		ftam_req.stb <= HIGH;
		ftam_req.sel <= sel_shift[15:0];
		ftam_req.we <= LOW;
		ftam_req.vadr <= ad;
		ftam_req.padr <= ad;
		adr_o <= ad;
		cyc_done <= FALSE;
	end
	else
		cyc_done <= TRUE;
LOAD2:
	begin
		ea <= {ad[$bits(ad)-1:6]+2'd1,6'd0};
		ftam_req.blen <= 6'd0;
		ftam_req.bte <= fta_bus_pkg::LINEAR;
		ftam_req.cti <= fta_bus_pkg::CLASSIC;
		ftam_req.cyc <= HIGH;
		ftam_req.stb <= HIGH;
		ftam_req.sel <= {12'h0,sel_shift[19:16]};
		ftam_req.we <= LOW;
		ftam_req.vadr <= {ad[$bits(ad)-1:6]+2'd1,6'd0};
		ftam_req.padr <= {ad[$bits(ad)-1:6]+2'd1,6'd0};
		adr_o <= {ad[$bits(ad)-1:6]+2'd1,6'd0};
		cyc_done <= FALSE;
		tGoto(LOAD2_ACK);
	end
LOAD2_ACK:
	if (ftam_resp.ack) begin
		dat <= (dat | (ftam_resp.dat << {5'd16-ad[3:0],3'b0})) & ls_mask;
		tReturn();
	end
	else if (rty_i && !cyc_done) begin
		ea <= {ad[$bits(ad)-1:6]+2'd1,6'd0};
		ftam_req.blen <= 6'd0;
		ftam_req.bte <= fta_bus_pkg::LINEAR;
		ftam_req.cti <= fta_bus_pkg::CLASSIC;
		ftam_req.cyc <= HIGH;
		ftam_req.stb <= HIGH;
		ftam_req.sel <= {12'h0,sel_shift[19:16]};
		ftam_req.we <= LOW;
		ftam_req.vadr <= {ad[$bits(ad)-1:6]+2'd1,6'd0};
		ftam_req.padr <= {ad[$bits(ad)-1:6]+2'd1,6'd0};
		adr_o <= {ad[$bits(ad)-1:6]+2'd1,6'd0};
		cyc_done <= FALSE;
	end
	else
		cyc_done <= TRUE;

STORE:
	begin
		ea <= ad;
		ftam_req.blen <= 6'd0;
		ftam_req.bte <= fta_bus_pkg::LINEAR;
		ftam_req.cti <= fta_bus_pkg::CLASSIC;
		ftam_req.cyc <= HIGH;
		ftam_req.stb <= HIGH;
		ftam_req.sel <= sel_shift[15:0];
		ftam_req.we <= HIGH;
		ftam_req.vadr <= ad;
		ftam_req.padr <= ad;
		ftam_req.data1 <= {128'd0,dat} << {adr[3:0],3'd0};
		adr_o <= ad;
		cyc_done <= FALSE;
		tGoto(STORE_ACK);
	end
STORE_ACK:
	if (rty_i) begin
		ea <= ad;
		ftam_req.blen <= 6'd0;
		ftam_req.bte <= fta_bus_pkg::LINEAR;
		ftam_req.cti <= fta_bus_pkg::CLASSIC;
		ftam_req.cyc <= HIGH;
		ftam_req.stb <= HIGH;
		ftam_req.sel <= sel_shift[15:0];
		ftam_req.we <= HIGH;
		ftam_req.vadr <= ad;
		ftam_req.padr <= ad;
		ftam_req.data1 <= {128'd0,dat} << {adr[3:0],3'd0};
		adr_o <= ad;
		cyc_done <= FALSE;
	end
	else begin
		if (|sel_shift[19:16])
			tGoto(STORE2);
		else
			tReturn();
	end
STORE2:
	begin
		ea <= {ad[$bits(ad)-1:6]+2'd1,6'd0};
		ftam_req.blen <= 6'd0;
		ftam_req.bte <= fta_bus_pkg::LINEAR;
		ftam_req.cti <= fta_bus_pkg::CLASSIC;
		ftam_req.cyc <= HIGH;
		ftam_req.stb <= HIGH;
		ftam_req.sel <= {12'h0,sel_shift[19:16]};
		ftam_req.we <= HIGH;
		ftam_req.vadr <= {ad[$bits(ad)-1:6]+2'd1,6'd0};
		ftam_req.padr <= {ad[$bits(ad)-1:6]+2'd1,6'd0};
		ftam_req.data1 <= {128'd0,dat} << {adr[3:0],3'd0};
		adr_o <= {ad[$bits(ad)-1:6]+2'd1,6'd0};
		tGoto(STORE2_ACK);
	end
STORE2_ACK:
	if (rty_i) begin
		ea <= {ad[$bits(ad)-1:6]+2'd1,6'd0};
		ftam_req.blen <= 6'd0;
		ftam_req.bte <= fta_bus_pkg::LINEAR;
		ftam_req.cti <= fta_bus_pkg::CLASSIC;
		ftam_req.cyc <= HIGH;
		ftam_req.stb <= HIGH;
		ftam_req.sel <= {12'h0,sel_shift[19:16]};
		ftam_req.we <= HIGH;
		ftam_req.vadr <= {ad[$bits(ad)-1:6]+2'd1,6'd0};
		ftam_req.padr <= {ad[$bits(ad)-1:6]+2'd1,6'd0};
		ftam_req.data1 <= {128'd0,dat} >> {5'd16-adr[3:0],3'd0};
		adr_o <= {ad[$bits(ad)-1:6]+2'd1,6'd0};
	end
	else
		tReturn();
