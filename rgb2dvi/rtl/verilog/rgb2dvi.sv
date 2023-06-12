// ============================================================================
//        __
//   \\__/ o\    (C) 2023  Robert Finch, Waterloo
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

module rgb2dvi(rst, PixelClk, SerialClk, red, green, blue, de, hSync, vSync,
	TMDS_Clk_p, TMDS_Clk_n, TMDS_Data_p, TMDS_Data_n);
parameter kParallelWidth = 10;
input rst;								// asynchronous active high reset.
// Clocks
input PixelClk;						// pixel clock
input SerialClk;					// 5x pixel clock
// Video in
input [kParallelWidth-3:0] red;
input [kParallelWidth-3:0] green;
input [kParallelWidth-3:0] blue;
input de;									// display enable
input hSync;
input vSync;
// DVI 1.0 TMDS video interface
output TMDS_Clk_p;
output TMDS_Clk_n;
output [2:0] TMDS_Data_p;
output [2:0] TMDS_Data_n;

reg [kParallelWidth-3:0] pDataIn [0:2];
reg [kParallelWidth-1:0] pDataOutRaw [0:2];
reg [2:0] pC0, pC1;

OutputSERDES
#(.kParallelWidth(kParallelWidth))
uosclk
(
	.rst(rst),
	.PixelClk(PixelClk),
	.SerialClk(SerialClk),
	.pDataIn({{(kParallelWidth/2){1'b1}},{(kParallelWidth/2){1'b0}}}),
	.sDataOut_p(TMDS_Clk_p),
	.sDataOut_n(TMDS_Clk_n)
);

genvar i;
generate begin : gDdataEncoders
	for (i = 0; i < 3; i = i + 1) begin
		TMDS_Encoder uDataEncoder (
			.rst(rst),
			.PixelClk(PixelClk),
			.SerialClk(SerialClk),
			.pDataOutRaw(pDataOutRaw[i]),
			.pDataOut(pDataIn[i]),
			.pC0(pC0[i]),
			.pC1(pC1[i]),
			.de(de)
		);
		OutputSERDES 
		#(.kParallelWidth(kParallelWidth))
		uods (
			.rst(rst),
			.PixelClk(PixelClk),
			.SerialClk(SerialClk),
			.pDataIn(pDataOutRaw[i]),
			.sDataOut_p(TMDS_Data_p[i]),
			.sDataOut_n(TMDS_Data_n[i]),
		);
  end
end
endgenerate

// DVI Output conform DVI 1.0
// except that it sends blank pixel during blanking
// for some reason vid_data is packed in RBG order
always_comb
begin
	pDataIn[2] = red;		// red is channel 2
	pDataIn[1] = green;	// green is channel 1
	pDataIn[0] = blue;	// blue is channel 0
end

always_comb
begin
	pC0 <= 'd0;	// default is low for control signals
	pC1 <= 'd0;
	pC0[0] <= hSync;	// channel 0 carries control signals too
	pC1[0] <= vSync;
end

endmodule
