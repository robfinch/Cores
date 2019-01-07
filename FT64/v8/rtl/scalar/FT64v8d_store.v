// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64v8d_store.v
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
//
// ============================================================================
//
STORE:
	if (~ack_i & ~cyc_o) begin
		cyc_o <= `HIGH;
		stb_o <= `HIGH;
		we_o <= `HIGH;
		case(memsize)
		byt_:		sel_o <= 8'h01 << ea[2:0];
		half:		sel_o <= 8'h03 << ea[2:0];
		word:		sel_o <= 8'h0F << ea[2:0];
		dword:	sel_o <= 8'hFF << ea[2:0];
		endcase
		adr_o <= {ea[63:3],3'd0};
		casez({memsize,ea[2:0]})
		{byt_,3'b???}:	dat_o <= {8{b[7:0]}};
		{half,3'b??0}:	dat_o <= {4{b[15:0]}};
		{half,3'b??1}:	dat_o <= {4{b[7:0],b[15:8]}};
		{word,3'b?00}:	dat_o <= {2{b[31:0]}};
		{word,3'b?01}:	dat_o <= {2{b[23:0],b[31:24]}};
		{word,3'b?10}:	dat_o <= {2{b[15:0],b[31:16]}};
		{word,3'b?11}:	dat_o <= {2{b[7:0],b[31:8]}};
		{dword,3'd0}:		dat_o <= b;
		{dword,3'd1}:		dat_o <= {b[55:0],b[63:56]};
		{dword,3'd2}:		dat_o <= {b[47:0],b[63:48]};
		{dword,3'd3}:		dat_o <= {b[39:0],b[63:40]};
		{dword,3'd4}:		dat_o <= {b[31:0],b[63:32]};
		{dword,3'd5}:		dat_o <= {b[23:0],b[63:24]};
		{dword,3'd6}:		dat_o <= {b[15:0],b[63:16]};
		{dword,3'd7}:		dat_o <= {b[7:0],b[63:8]};	
		endcase
		casez({memsize,ea[2:0]})
		{half,3'b111}:	lock_o <= `HIGH;
		{word,3'b101}:	lock_o <= `HIGH;
		{word,3'b110}:	lock_o <= `HIGH;
		{word,3'b111}:	lock_o <= `HIGH;
		{dword,3'd1}:		lock_o <= `HIGH;
		{dword,3'd2}:		lock_o <= `HIGH;
		{dword,3'd3}:		lock_o <= `HIGH;
		{dword,3'd4}:		lock_o <= `HIGH;
		{dword,3'd5}:		lock_o <= `HIGH;
		{dword,3'd6}:		lock_o <= `HIGH;
		{dword,3'd7}:		lock_o <= `HIGH;
		default:				lock_o <= `LOW;
		endcase
		goto (STORE2);
	end
STORE2:
	if (ack_i) begin
		stb_o <= `LOW;
		casez({memsize,ea[2:0]})
		{half,3'b111}:	goto (STORE3);
		{word,3'b101}:	goto (STORE3);
		{word,3'b110}:	goto (STORE3);
		{word,3'b111}:	goto (STORE3);
		{dword,3'd1}:		goto (STORE3);
		{dword,3'd2}:		goto (STORE3);
		{dword,3'd3}:		goto (STORE3);
		{dword,3'd4}:		goto (STORE3);
		{dword,3'd5}:		goto (STORE3);
		{dword,3'd6}:		goto (STORE3);
		{dword,3'd7}:		goto (STORE3);
		default:	
			begin
				cyc_o <= `LOW;
				lock_o <= `LOW;
				we_o <= `LOW;
				sel_o <= 8'h00;
				ret();
			end
		endcase
	end
STORE3:
	if (~ack_i) begin
		stb_o <= `HIGH;
		case(memsize)
		byt_:		sel_o <= 8'h00;
		half:		sel_o <= 8'h01;
		word:
			case(ea[2:0])
			3'd5: sel_o <= 8'h01;
			3'd6: sel_o <= 8'h03;
			3'd7: sel_o <= 8'h07;
			default:	sel_o <= 8'h00;
			endcase
		dword:	sel_o <= ~sel_o;
		endcase
		adr_o <= {adr_o[63:3] + 61'd1,3'd0};
		goto(STORE4);
	end
STORE4:
	if (ack_i) begin
		cyc_o <= `LOW;
		stb_o <= `LOW;
		lock_o <= `LOW;
		we_o <= `LOW;
		sel_o <= 8'h00;
		ret();
	end

