// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//
// Ported to System Verilog from the Digilent rgb2dvi project
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

module OutputSERDES(rst,PixelClk,SerialClk,pDataIn,sDataOut_p,sDataOut_n);
parameter kParallelWidth = 10;
input rst;
input PixelClk;
input SerialClk;
input [kParallelWidth-1:0] pDataIn;
output sDataOut_p;
output sDataOut_n;

wire ocascade1, ocascade2;
reg [13:0] pDataIn_q;

// Differential output buffer for TMDS I/O standard 
OBUFDS 
#(.IOSTANDARD("TMDS_33"))
OutputBuffer
(
	.I(sDataOut),
	.O(sDataOut_p),
	.OB(sDataOut_n)
);
      
// Serializer, 10:1 (5:1 DDR), master-slave cascaded
OSERDESE2
#(
	.DATA_RATE_OQ("DDR"),
	.DATA_RATE_TQ("SDR"),
	.DATA_WIDTH(kParallelWidth),
	.TRISTATE_WIDTH(1),
	.TBYTE_CTL("FALSE"),
	.TBYTE_SRC("FALSE"),
	.SERDES_MODE("MASTER")	
)
SerializerMaster
(
	.OFB(),	// feedback path for data
	.OQ(sDataOut),
  // SHIFTOUT1 / SHIFTOUT2: 1-bit (each) output: Data output expansion (1-bit each)
	.SHIFTOUT1(),
	.SHIFTOUT2(),
	.TBYTEOUT(),
	.TFB(),
	.TQ(),
	.CLK(SerialClk),
	.CLKDIV(PixelClk),
  // D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
	.D1(pDataIn_q[13]),
	.D2(pDataIn_q[12]),
	.D3(pDataIn_q[11]),
	.D4(pDataIn_q[10]),
	.D5(pDataIn_q[ 9]),
	.D6(pDataIn_q[ 8]),
	.D7(pDataIn_q[ 7]),
	.D8(pDataIn_q[ 6]),
	.OCE(1),			// output data clock enable
	.RST(rst),
  // SHIFTIN1 / SHIFTIN2: 1-bit (each) input: Data input expansion (1-bit each)
	.SHIFTIN1(ocascade1),
	.SHIFTIN2(ocascade2),
  // T1 - T4: 1-bit (each) input: Parallel 3-state inputs
	.T1(0),
	.T2(0),
	.T3(0),
	.T4(0),
	.TBYTEIN(0),		// byte group tri-state
	.TCE(0)					// 3-state clock enable
);

OSERDESE2
#(
	.DATA_RATE_OQ("DDR"),
	.DATA_RATE_TQ("SDR"),
	.DATA_WIDTH(kParallelWidth),
	.TRISTATE_WIDTH(1),
	.TBYTE_CTL("FALSE"),
	.TBYTE_SRC("FALSE"),
	.SERDES_MODE("SLAVE")	
)
SerializerSlave
(
	.OFB(),	// feedback path for data
	.OQ(),
  // SHIFTOUT1 / SHIFTOUT2: 1-bit (each) output: Data output expansion (1-bit each)
	.SHIFTOUT1(ocascade1),
	.SHIFTOUT2(ocascade2),
	.TBYTEOUT(),
	.TFB(),
	.TQ(),
	.CLK(SerialClk),
	.CLKDIV(PixelClk),
  // D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
	.D1(0),
	.D2(0),
	.D3(pDataIn_q[5]),
	.D4(pDataIn_q[4]),
	.D5(pDataIn_q[3]),
	.D6(pDataIn_q[2]),
	.D7(pDataIn_q[1]),
	.D8(pDataIn_q[0]),
	.OCE(1),			// output data clock enable
	.RST(rst),
  // SHIFTIN1 / SHIFTIN2: 1-bit (each) input: Data input expansion (1-bit each)
	.SHIFTIN1(0),
	.SHIFTIN2(0),
  // T1 - T4: 1-bit (each) input: Parallel 3-state inputs
	.T1(0),
	.T2(0),
	.T3(0),
	.T4(0),
	.TBYTEIN(0),		// byte group tri-state
	.TCE(0)					// 3-state clock enable
);

//----------------------------------------------------------- 
// Concatenate the serdes inputs together. Keep the timesliced
// bits together, and placing the earliest bits on the right
// ie, if data comes in 0, 1, 2, 3, 4, 5, 6, 7, ...
// the output will be 3210, 7654, ...
//-----------------------------------------------------------   

integer slice_count;
always_comb
begin
	pDataIn_q = 'd0;
	for (slice_count = 0; slice_count < kParallelWidth; slice_count = slice_count + 1)
  	// DVI sends least significant bit first 
   	// OSERDESE2 sends D1 bit first
		pDataIn_q[14-slice_count-1] = pDataIn[slice_count];
end

endmodule
