`ifndef THOR2020_CONST_SV
`define THOR2020_CONST_SV
// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// ============================================================================

`define VAL		1'b1
`define INV		1'b0
`define TRUE	1'b1
`define FALSE	1'b0

`define cBRK	7'h00

`define PANIC_NONE		4'd0
`define PANIC_INVALIDIQSTATE	4'd1

`define cRT  11:6
`define cRA  17:12
`define cRB  23:18
`define cRC  29:24
`define cSPR  23:12

`define cADD    7'd4
`define cSUB    7'd5
`define cAND    7'd8
`define cOR     7'd9
`define cEOR    7'd10
`define cANDCM  7'd11
`define cNAND   7'd12
`define cNOR    7'd13
`define cENOR   7'd14
`define cORCM   7'd15
`define cSHLP   7'd20
`define cSHRP   7'd21
`define cMUL    7'd24
`define cMULU   7'd25
`define cDIV    7'd26
`define cDIVU   7'd27
`define cDIVR   7'd28
`define cDIVRU  7'd29
`define cCLT    7'd32
`define cCGE    7'd33
`define cCLE    7'd34
`define cCGT    7'd35
`define cCLTU   7'd36
`define cCGEU   7'd37
`define cCLEU   7'd38
`define cCGTU   7'd39
`define cCEQ    7'd40
`define cCNE    7'd41

`define cFMADD  7'd112
`define cFMSUB  7'd113
`define cFNMADD 7'd114
`define cFNMSUB 7'd115
`define cFLOAT2 7'd119

`define cFDIV     7'd7
`define cFSGNJ    7'd8
`define cFLOAT1   7'd9
//`define cFCVT     7'd9
`define cI2F      7'd0
`define cF2I        7'd4
`define cFSIGN      7'd14
`define cFMAN       7'd15
`define cFMOV       7'd16
`define cFTRUNC     7'd12
`define cFISNAN     7'd28
`define cFFINITE    7'd29
`define cFCLASS     7'd30

`define cFCLT   7'd48
`define cFCGE   7'd49
`define cFCLE   7'd50
`define cFCGT   7'd51
`define cFCEQ   7'd52
`define cFCNE   7'd53
`define cFCUN   7'd55


`define cINTERSECT  7'd42
`define cUNION      7'd43
`define cDISJOINT   7'd44

`endif
