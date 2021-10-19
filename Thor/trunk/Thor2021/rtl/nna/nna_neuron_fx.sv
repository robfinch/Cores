// ============================================================================
//        __
//   \\__/ o\    (C) 2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	nna_neuron_fx.sv
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
// Values are represented as sign-magnitude fix point numbers for performance
// reasons.
//
// Core Parameters:
// Name:	 Default
// pInputs	  1024		number of inputs to neuron (should be a power of two).
// pAmsb		 9		most significant bit of memory address
// pFixWidth	32		total width of fixed point values
// pFixFract	16		number of bits in the fractional part of value
// pActivationFile		string containing the name of the file containing
//                      activation levels corresponding to output
//
// Data is fed to the neurons in a serial fashion.
// The adder tree propagation would limit the clock cycle time anyway. So we get
// rid of the adder tree by using serial addition and a faster clock. This
// allows us to have many more inputs per neuron. There is one block ram per
// neuron in order to store weights. There is a second block ram for the
// activation function.

module nna_neuron_fx(rst, clk, sync, wr, wa, wrb, wf, wrx, wrm, wrbc, i, o, done);
parameter pInputs = 1024;	// power of 2, 1024 or less
parameter pAmsb = 9;
parameter pFixWidth = 32;
parameter pFixFract = 16;
parameter pActivationFile = "d:/cores2021/nna/trunk/software/activations/sigmoid.act";
input rst;
input clk;
input sync;						// begin calc
input wr;							// write to weights array
input [pAmsb:0] wa;		// write address
input wrb;						// write to bias value
input wf;							// write to feedback value
input wrx;						// write external input value
input wrm;						// write max count register
input wrbc;						// write base count register
input [pFixWidth-1:0] i;	// input
output reg [pFixWidth-1:0] o;
output done;

reg [pFixWidth-1:0] wmem [0:pInputs-1];
reg [pFixWidth-1:0] xmem [0:pInputs-1];
reg [pFixWidth-1:0] bias;
reg [pFixWidth-1:0] feedback;

reg [pFixWidth-1:0] wb,p1,p2,f,t2;
reg [16:0] base_count = 17'd0;
reg [16:0] max_count = pInputs;

always @(posedge clk)
	if (wr) wmem[wa[pAmsb:0]] <= i;
always @(posedge clk)
	if (wrx) xmem[wa[pAmsb:0]] <= i;
always @(posedge clk)
	if (wrb) bias <= i;
always @(posedge clk)
	if (wf) feedback <= i;
always @(posedge clk)
	if (wrbc) base_count <= i;
always @(posedge clk)
	if (wrm) max_count <= i;

reg [14:0] cnt;
always @(posedge clk)
if (sync)
	cnt <= base_count;
else begin
	if (cnt < max_count+4)
		cnt <= cnt + 2'd1;
end
assign done = cnt==max_count+4;

reg [pFixWidth-1:0] xb;
always @(posedge clk)
begin
	wb <= wmem[cnt];
	xb <= xmem[cnt];
end

reg [pFixWidth-1:0] activationTable [0:1023];
initial begin
	$readmemh(pActivationFile,activationTable);
end

wire sgn = xb[pFixWidth-1] ^ wb[pFixWidth-1];
wire [pFixWidth*2-3:0] m = xb[pFixWidth-2:0] * wb[pFixWidth-2:0];
wire [pFixWidth-1:0] mo = m[pFixWidth*2-3:(pFixFract*2+(pFixWidth-pFixFract))-1]!=0 ? {sgn,{pFixWidth-2{1'b1}}} : {sgn,m[(pFixFract*2+(pFixWidth-pFixFract))-2:pFixFract]};
wire fbsgn = o[pFixWidth-1] ^ feedback[pFixWidth-1];
wire [pFixWidth*2-3:0] fbm = o[pFixWidth-2:0] * feedback[pFixWidth-2:0];
wire [pFixWidth-1:0] fbmo = fbm[pFixWidth*2-3:(pFixFract*2+(pFixWidth-pFixFract))-1]!=0 ? {fbsgn,{pFixWidth-2{1'b1}}} : {fbsgn,fbm[(pFixFract*2+(pFixWidth-pFixFract))-2:pFixFract]};
wire [pFixWidth*2-3:0] t1 = (p2-p1) * f;	// Linear approximate

reg [pFixWidth+10:0] sum;
always @(posedge clk)
if (sync) begin
	sum <= {{11{bias[pFixWidth-1]}},bias} + fbmo;
end
else begin
	if (cnt==base_count)
		;
	else if (cnt < max_count+1)
		sum <= sum + (mo[pFixWidth-1] ? -mo[pFixWidth-2:0] : mo[pFixWidth-2:0]);
	else if (cnt==max_count+1) begin
		sum[pFixWidth-1] <= sum[pFixWidth-1];
		// Check for overflow
		if (sum[pFixWidth+10:pFixWidth] != {11{sum[pFixWidth-1]}}) begin
			sum[pFixWidth-2:0] <= {pFixWidth-1{1'b1}};
			sum[pFixWidth-1] <= sum[pFixWidth+10];
		end
		else begin
			if (sum[pFixWidth-1])
				sum[pFixWidth-2:0] <= -sum[pFixWidth-2:0];
			else
				sum[pFixWidth-2:0] <=  sum[pFixWidth-2:0];
		end
	end
	// Compute a piecewise linear approximation.
	else if (cnt==max_count+2) begin
		f <= sum[pFixWidth-2:0] - {sum[pFixWidth-2:pFixWidth-12],pFixWidth-11'd0};
		p1 <= activationTable[sum[pFixWidth-2:pFixWidth-12]];
		p2 <= activationTable[sum[pFixWidth-2:pFixWidth-12]+2'd1];
	end
	else if (cnt==max_count+3) begin
		t2 <= p1 + t1[pFixWidth+pFixFract-2:pFixFract];
	end
	else if (cnt==max_count+4) begin
		o <= {sum[pFixWidth-1],t2[pFixFract-2:0]};
	end
end

endmodule
