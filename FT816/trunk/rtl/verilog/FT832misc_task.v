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
		radr <= {16'h00,sp[15:0]};
		wadr <= {16'h00,sp[15:0]};
		sp <= sp_dec;
		sp[31:16] <= 16'h0000;
	end
	else begin
		radr <= {24'h0001,sp[7:0]};
		wadr <= {24'h0001,sp[7:0]};
		sp[7:0] <= sp[7:0] - 8'd1;
		sp[31:8] <= 24'h1;
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
		radr <= {16'h0000,sp_inc[15:0]};
		sp <= sp_inc;
	end
	else begin
		radr <= {24'h0001,sp_inc[7:0]};
		sp <= {24'h1,sp_inc[7:0]};
	end
end
endtask

task tsk_push;
input [5:0] SW8;
input szFlg;
input szFlg2;
begin
    if (m832) begin
		if (szFlg2) begin
			radr <= sp_dec3;
			wadr <= sp_dec3;
			store_what <= SW8;
			sp <= sp_dec4;
			s32 <= TRUE;
		end
		else if (szFlg) begin
			radr <= sp_dec;
			wadr <= sp_dec;
			s16 <= TRUE;
			store_what <= SW8;
			sp <= sp_dec2;
		end
		else begin
			radr <= sp;
			wadr <= sp;
			store_what <= SW8;
			sp <= sp_dec;
		end
    end
	else if (m816) begin
		if (szFlg2) begin
            radr <= {16'h00,sp_dec3[15:0]};
            wadr <= {16'h00,sp_dec3[15:0]};
            store_what <= SW8;
            sp <= sp_dec4;
			sp[31:16] <= 16'h00;
            s32 <= TRUE;
        end
		else if (szFlg) begin
			radr <= {16'h00,sp_dec[15:0]};
			wadr <= {16'h00,sp_dec[15:0]};
			s16 <= TRUE;
			store_what <= SW8;
			sp <= sp_dec2;
			sp[31:16] <= 16'h00;
		end
		else begin
			radr <= {16'h00,sp[15:0]};
			wadr <= {16'h00,sp[15:0]};
			store_what <= SW8;
			sp <= sp_dec;
			sp[31:16] <= 16'h00;
		end
	end
	else begin
	    // We could be pushing the CS or DS from
	    // emulation mode.
		if (szFlg2) begin
            radr <= {24'h01,sp_dec3[7:0]};
            wadr <= {24'h01,sp_dec3[7:0]};
            store_what <= SW8;
            sp <= sp_dec4;
            sp[31:8] <= 24'd1;
            s32 <= TRUE;
        end
		else if (szFlg) begin
            radr <= {24'h01,sp_dec[8:0]};
            wadr <= {24'h01,sp_dec[8:0]};
            s16 <= TRUE;
            store_what <= SW8;
            sp <= sp_dec2;
            sp[31:8] <= 24'h01;
        end
        else begin
            radr <= {16'h01,sp[7:0]};
            wadr <= {16'h01,sp[7:0]};
            store_what <= SW8;
            sp[7:0] <= sp[7:0] - 8'd1;
            sp[31:8] <= 8'h1;
        end
	end
	data_nack();
	state <= STORE1;
end
endtask

task moveto_ifetch;
begin
	next_state(IFETCH);
end
endtask

