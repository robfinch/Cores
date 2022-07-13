// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FAL6567_pkg.sv
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
package FAL6567_pkg;

`define TRUE  1'b1
`define FALSE 1'b0
`define LOW   1'b0
`define HIGH  1'b1

parameter PAL = 1'b0;
parameter CHIP6567R8 = 2'd0;
parameter CHIP6567OLD = 2'd1;
parameter CHIP6569 = 2'd2;
parameter CHIP6572 = 2'd3;
parameter LEGACY = 1'b1;
parameter MIBCNT = 16;

parameter pSimRasterEnable = 48;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter SIM = 1'b0;

parameter BUS_IDLE = 0;
parameter BUS_SPRITE = 1;
parameter BUS_REF = 2;
parameter BUS_CG = 3;
parameter BUS_G = 4;
parameter BUS_LS = 5;

// VIC state machine states
parameter VIC_IDLE = 0;   // idle cycle
parameter VIC_SPRITE = 1; // sprite cycle
parameter VIC_REF = 2;   // refresh cycle
parameter VIC_RC = 3;
parameter VIC_CHAR = 4;  // character acccess cycle
parameter VIC_G = 5;
parameter VIC_PAL = 6;	// palette initialization

endpackage
