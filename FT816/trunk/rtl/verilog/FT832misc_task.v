// ============================================================================
//        __
//   \\__/ o\    (C) 2015  Robert Finch, Stratford
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
    if (m832) begin
		radr <= sp;
        wadr <= sp;
        sp <= sp_dec;
    end
	else if (m816) begin
		radr <= {8'h00,sp[15:0]};
		wadr <= {8'h00,sp[15:0]};
		sp <= sp_dec;
	end
	else begin
		radr <= {16'h0001,sp[7:0]};
		wadr <= {16'h0001,sp[7:0]};
		sp[7:0] <= sp[7:0] - 8'd1;
		sp[15:8] <= 8'h1;
	end
end
endtask

task inc_sp;
begin
    if (m832) begin
		radr <= sp_inc;
        sp <= sp_inc;
    end
	else if (m816) begin
		radr <= {8'h00,sp_inc[15:0]};
		sp <= sp_inc;
	end
	else begin
		radr <= {16'h0001,sp_inc[7:0]};
		sp <= {8'h1,sp_inc[7:0]};
	end
end
endtask

task tsk_push;
input [5:0] SW8;
input szFlg;
begin
    if (m832) begin
        radr <= sp_dec4;
        wadr <= sp_dec4;
        s32 <= TRUE;
        store_what <= SW8;
        sp <= sp_dec4;
    end
	else if (m816) begin
		if (szFlg) begin
			radr <= {8'h00,sp_dec2[15:0]};
			wadr <= {8'h00,sp_dec2[15:0]};
			s16 <= TRUE;
			store_what <= SW8;
			sp <= sp_dec2;
		end
		else begin
			radr <= {8'h00,sp[15:0]};
			wadr <= {8'h00,sp[15:0]};
			store_what <= SW8;
			sp <= sp_dec;
		end
	end
	else begin
		radr <= {16'h01,sp[7:0]};
		wadr <= {16'h01,sp[7:0]};
		store_what <= SW8;
		sp[7:0] <= sp[7:0] - 8'd1;
		sp[15:8] <= 8'h1;
	end
	state <= STORE1;
end
endtask

task moveto_ifetch;
begin
	vpa <= `TRUE;
	vda <= `TRUE;
	ado <= cs + pc;
	next_state(IFETCH1);
end
endtask

