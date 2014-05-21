// ============================================================================
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
//       ||
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
//
task set_sp;
begin
	if (m816) begin
		radr <= {spage[31:24],8'h00,sp[15:0]};
		wadr <= {spage[31:24],8'h00,sp[15:0]};
		sp <= sp_dec;
	end
	else begin
		radr <= {spage[31:16],8'h01,sp[7:0]};
		wadr <= {spage[31:16],8'h01,sp[7:0]};
		sp[7:0] <= sp[7:0] - 8'd1;
		sp[15:8] <= 8'h1;
	end
end
endtask

task inc_sp;
begin
	if (m816) begin
		radr <= {spage[31:24],8'h00,sp_inc[15:0]};
		sp <= sp_inc;
	end
	else begin
		radr <= {spage[31:16],8'h01,sp_inc[7:0]};
		sp <= {8'h1,sp_inc[7:0]};
	end
end
endtask

task tsk_push;
input [5:0] SW8;
input [5:0] SW16;
input szFlg;
begin
	if (m816) begin
		if (szFlg) begin
			radr <= {spage[31:24],8'h00,sp_dec[15:0]};
			wadr <= {spage[31:24],8'h00,sp_dec[15:0]};
			store_what <= SW16;
			sp <= sp_dec2;
		end
		else begin
			radr <= {spage[31:24],8'h00,sp[15:0]};
			wadr <= {spage[31:24],8'h00,sp[15:0]};
			store_what <= SW8;
			sp <= sp_dec;
		end
	end
	else begin
		radr <= {spage[31:16],8'h01,sp[7:0]};
		wadr <= {spage[31:16],8'h01,sp[7:0]};
		store_what <= SW8;
		sp[7:0] <= sp[7:0] - 8'd1;
		sp[15:8] <= 8'h1;
	end
	state <= STORE1;
end
endtask


// This task is called by load_tsk() to load data to the appropriate bus.

task sized_load;
input [7:0] dat8;
input [15:0] dat16;
input [31:0] dat;
output [31:0] b;
begin
	if (ubytePrefix)
		b <= dat8;
	else if (bytePrefix)
		b <= {{24{dat8[7]}},dat8};
	else if (ucharPrefix)
		b <= dat16;
	else if (charPrefix)
		b <= {{16{dat16[15]}},dat16};
	else
		b <= dat;
end
endtask

