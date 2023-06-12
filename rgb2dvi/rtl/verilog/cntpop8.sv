// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	cntpop8.v
//		- count number of one bits in a byte
//		- simple fast approach - lookup table
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

module cntpop8
(
	input [7:0] i,
	output reg [3:0] o
);

always_comb
	case (i)
	8'b00000000:	o = 0;
	8'b00000001:	o = 1;
	8'b00000010:	o = 1;
	8'b00000011:	o = 2;
	8'b00000100:	o = 1;
	8'b00000101:	o = 2;
	8'b00000110:	o = 2;
	8'b00000111:	o = 3;
	8'b00001000:	o = 1;
	8'b00001001:	o = 2;
	8'b00001010:	o = 2;
	8'b00001011:	o = 3;
	8'b00001100:	o = 2;
	8'b00001101:	o = 3;
	8'b00001110:	o = 3;
	8'b00001111:	o = 4;
         
	8'b00010000:	o = 1;
	8'b00010001:	o = 2;
	8'b00010010:	o = 2;
	8'b00010011:	o = 3;
	8'b00010100:	o = 2;
	8'b00010101:	o = 3;
	8'b00010110:	o = 3;
	8'b00010111:	o = 4;
	8'b00011000:	o = 2;
	8'b00011001:	o = 3;
	8'b00011010:	o = 3;
	8'b00011011:	o = 4;
	8'b00011100:	o = 3;
	8'b00011101:	o = 4;
	8'b00011110:	o = 4;
	8'b00011111:	o = 5;
         
	8'b00100000:	o = 1;
	8'b00100001:	o = 2;
	8'b00100010:	o = 2;
	8'b00100011:	o = 3;
	8'b00100100:	o = 2;
	8'b00100101:	o = 3;
	8'b00100110:	o = 3;
	8'b00100111:	o = 4;
	8'b00101000:	o = 2;
	8'b00101001:	o = 3;
	8'b00101010:	o = 3;
	8'b00101011:	o = 4;
	8'b00101100:	o = 3;
	8'b00101101:	o = 4;
	8'b00101110:	o = 4;
	8'b00101111:	o = 5;
         
	8'b00110000:	o = 2;
	8'b00110001:	o = 3;
	8'b00110010:	o = 3;
	8'b00110011:	o = 4;
	8'b00110100:	o = 3;
	8'b00110101:	o = 4;
	8'b00110110:	o = 4;
	8'b00110111:	o = 5;
	8'b00111000:	o = 3;
	8'b00111001:	o = 4;
	8'b00111010:	o = 4;
	8'b00111011:	o = 5;
	8'b00111100:	o = 4;
	8'b00111101:	o = 5;
	8'b00111110:	o = 5;
	8'b00111111:	o = 6;
           
	// 44 - 1	
	8'b01000000:	o = 1;
	8'b01000001:	o = 2;
	8'b01000010:	o = 2;
	8'b01000011:	o = 3;
	8'b01000100:	o = 2;
	8'b01000101:	o = 3;
	8'b01000110:	o = 3;
	8'b01000111:	o = 4;
	8'b01001000:	o = 2;
	8'b01001001:	o = 3;
	8'b01001010:	o = 3;
	8'b01001011:	o = 4;
	8'b01001100:	o = 3;
	8'b01001101:	o = 4;
	8'b01001110:	o = 4;
	8'b01001111:	o = 5;

	8'b01010000:	o = 2;
	8'b01010001:	o = 3;
	8'b01010010:	o = 3;
	8'b01010011:	o = 4;
	8'b01010100:	o = 3;
	8'b01010101:	o = 4;
	8'b01010110:	o = 4;
	8'b01010111:	o = 5;
	8'b01011000:	o = 3;
	8'b01011001:	o = 4;
	8'b01011010:	o = 4;
	8'b01011011:	o = 5;
	8'b01011100:	o = 4;
	8'b01011101:	o = 5;
	8'b01011110:	o = 5;
	8'b01011111:	o = 6;
           
	8'b01100000:	o = 2;
	8'b01100001:	o = 3;
	8'b01100010:	o = 3;
	8'b01100011:	o = 4;
	8'b01100100:	o = 3;
	8'b01100101:	o = 4;
	8'b01100110:	o = 4;
	8'b01100111:	o = 5;
	8'b01101000:	o = 3;
	8'b01101001:	o = 4;
	8'b01101010:	o = 4;
	8'b01101011:	o = 5;
	8'b01101100:	o = 4;
	8'b01101101:	o = 5;
	8'b01101110:	o = 5;
	8'b01101111:	o = 6;
         
	8'b01110000:	o = 3;
	8'b01110001:	o = 4;
	8'b01110010:	o = 4;
	8'b01110011:	o = 5;
	8'b01110100:	o = 4;
	8'b01110101:	o = 5;
	8'b01110110:	o = 5;
	8'b01110111:	o = 6;
	8'b01111000:	o = 4;
	8'b01111001:	o = 5;
	8'b01111010:	o = 5;
	8'b01111011:	o = 6;
	8'b01111100:	o = 5;
	8'b01111101:	o = 6;
	8'b01111110:	o = 6;
	8'b01111111:	o = 7;

	//  - 2	
	8'b10000000:	o = 1;
	8'b10000001:	o = 2;
	8'b10000010:	o = 2;
	8'b10000011:	o = 3;
	8'b10000100:	o = 2;
	8'b10000101:	o = 3;
	8'b10000110:	o = 3;
	8'b10000111:	o = 4;
	8'b10001000:	o = 2;
	8'b10001001:	o = 3;
	8'b10001010:	o = 3;
	8'b10001011:	o = 4;
	8'b10001100:	o = 3;
	8'b10001101:	o = 4;
	8'b10001110:	o = 4;
	8'b10001111:	o = 5;

	8'b10010000:	o = 2;
	8'b10010001:	o = 3;
	8'b10010010:	o = 3;
	8'b10010011:	o = 4;
	8'b10010100:	o = 3;
	8'b10010101:	o = 4;
	8'b10010110:	o = 4;
	8'b10010111:	o = 5;
	8'b10011000:	o = 3;
	8'b10011001:	o = 4;
	8'b10011010:	o = 4;
	8'b10011011:	o = 5;
	8'b10011100:	o = 4;
	8'b10011101:	o = 5;
	8'b10011110:	o = 5;
	8'b10011111:	o = 6;
        
	8'b10100000:	o = 2;
	8'b10100001:	o = 3;
	8'b10100010:	o = 3;
	8'b10100011:	o = 4;
	8'b10100100:	o = 3;
	8'b10100101:	o = 4;
	8'b10100110:	o = 4;
	8'b10100111:	o = 5;
	8'b10101000:	o = 3;
	8'b10101001:	o = 4;
	8'b10101010:	o = 4;
	8'b10101011:	o = 5;
	8'b10101100:	o = 4;
	8'b10101101:	o = 5;
	8'b10101110:	o = 5;
	8'b10101111:	o = 6;
                           
	8'b10110000:	o = 3;
	8'b10110001:	o = 4;
	8'b10110010:	o = 4;
	8'b10110011:	o = 5;
	8'b10110100:	o = 4;
	8'b10110101:	o = 5;
	8'b10110110:	o = 5;
	8'b10110111:	o = 6;
	8'b10111000:	o = 4;
	8'b10111001:	o = 5;
	8'b10111010:	o = 5;
	8'b10111011:	o = 6;
	8'b10111100:	o = 5;
	8'b10111101:	o = 6;
	8'b10111110:	o = 6;
	8'b10111111:	o = 7;
          
	// 44 - 3	
	8'b11000000:	o = 2;
	8'b11000001:	o = 3;
	8'b11000010:	o = 3;
	8'b11000011:	o = 4;
	8'b11000100:	o = 3;
	8'b11000101:	o = 4;
	8'b11000110:	o = 4;
	8'b11000111:	o = 5;
	8'b11001000:	o = 3;
	8'b11001001:	o = 4;
	8'b11001010:	o = 4;
	8'b11001011:	o = 5;
	8'b11001100:	o = 4;
	8'b11001101:	o = 5;
	8'b11001110:	o = 5;
	8'b11001111:	o = 6;
                           
	8'b11010000:	o = 3;
	8'b11010001:	o = 4;
	8'b11010010:	o = 4;
	8'b11010011:	o = 5;
	8'b11010100:	o = 4;
	8'b11010101:	o = 5;
	8'b11010110:	o = 5;
	8'b11010111:	o = 6;
	8'b11011000:	o = 4;
	8'b11011001:	o = 5;
	8'b11011010:	o = 5;
	8'b11011011:	o = 6;
	8'b11011100:	o = 5;
	8'b11011101:	o = 6;
	8'b11011110:	o = 6;
	8'b11011111:	o = 7;
        
	8'b11100000:	o = 3;
	8'b11100001:	o = 4;
	8'b11100010:	o = 4;
	8'b11100011:	o = 5;
	8'b11100100:	o = 4;
	8'b11100101:	o = 5;
	8'b11100110:	o = 5;
	8'b11100111:	o = 6;
	8'b11101000:	o = 4;
	8'b11101001:	o = 5;
	8'b11101010:	o = 5;
	8'b11101011:	o = 6;
	8'b11101100:	o = 5;
	8'b11101101:	o = 6;
	8'b11101110:	o = 6;
	8'b11101111:	o = 7;
                           
	8'b11110000:	o = 4;
	8'b11110001:	o = 5;
	8'b11110010:	o = 5;
	8'b11110011:	o = 6;
	8'b11110100:	o = 5;
	8'b11110101:	o = 6;
	8'b11110110:	o = 6;
	8'b11110111:	o = 7;
	8'b11111000:	o = 5;
	8'b11111001:	o = 6;
	8'b11111010:	o = 6;
	8'b11111011:	o = 7;
	8'b11111100:	o = 6;
	8'b11111101:	o = 7;
	8'b11111110:	o = 7;
	8'b11111111:	o = 8;

	endcase
		
endmodule

