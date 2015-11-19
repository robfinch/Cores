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
function [31:0] fn_get_sp;
input [31:0] sp;
begin
    if (m832)
        fn_get_sp = sp;
    else if (m816)
        fn_get_sp = {stack_bank,sp[15:0]};
    else
        fn_get_sp = {stack_page,sp[7:0]};
end
endfunction

task set_sp;
begin
    if (m832) begin
		radr <= sp;
        wadr <= sp;
        sp <= sp_dec;
    end
	else if (m816) begin
		radr <= {stack_bank,sp[15:0]};
		wadr <= {stack_bank,sp[15:0]};
		sp <= sp_dec;
		sp[31:16] <= stack_bank;
        bank_wrap <= TRUE;
	end
	else begin
		radr <= {stack_page,sp[7:0]};
		wadr <= {stack_page,sp[7:0]};
		sp[7:0] <= sp[7:0] - 8'd1;
		sp[31:8] <= stack_page;
        page_wrap <= TRUE;
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
        radr <= {stack_bank,sp_inc[15:0]};
        sp <= sp_inc;
        sp[31:16] <= stack_bank;
        bank_wrap <= TRUE;
    end
    else begin
        radr <= {stack_page,sp_inc[7:0]};
        sp <= {stack_page,sp_inc[7:0]};
        page_wrap <= TRUE;
    end
end
endtask

function [31:0] fn_sp_inc;
input [31:0] sp_inc;
begin
    if (m832)
        fn_sp_inc = sp_inc;
    else if (m816)
        fn_sp_inc = {stack_bank,sp_inc[15:0]};
    else
        fn_sp_inc = {stack_page,sp_inc[7:0]};
end
endfunction

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
            radr <= {stack_bank,sp_dec3[15:0]};
            wadr <= {stack_bank,sp_dec3[15:0]};
            store_what <= SW8;
            sp <= sp_dec4;
			sp[31:16] <= stack_bank;
            s32 <= TRUE;
        end
		else if (szFlg) begin
			radr <= {stack_bank,sp_dec[15:0]};
			wadr <= {stack_bank,sp_dec[15:0]};
			s16 <= TRUE;
			store_what <= SW8;
			sp <= sp_dec2;
			sp[31:16] <= stack_bank;
		end
		else begin
			radr <= {stack_bank,sp[15:0]};
			wadr <= {stack_bank,sp[15:0]};
			store_what <= SW8;
			sp <= sp_dec;
			sp[31:16] <= stack_bank;
		end
        bank_wrap <= TRUE;
	end
	else begin
	    // We could be pushing the CS or DS from
	    // emulation mode.
		if (szFlg2) begin
            radr <= {stack_page,sp_dec3[7:0]};
            wadr <= {stack_page,sp_dec3[7:0]};
            store_what <= SW8;
            sp <= sp_dec4;
            sp[31:8] <= 24'd1;
            s32 <= TRUE;
        end
		else if (szFlg) begin
            radr <= {stack_page,sp_dec[8:0]};
            wadr <= {stack_page,sp_dec[8:0]};
            s16 <= TRUE;
            store_what <= SW8;
            sp <= sp_dec2;
            sp[31:8] <= stack_page;
        end
        else begin
            radr <= {stack_page,sp[7:0]};
            wadr <= {stack_page,sp[7:0]};
            store_what <= SW8;
            sp[7:0] <= sp[7:0] - 8'd1;
            sp[31:8] <= stack_page;
        end
        page_wrap <= TRUE;
	end
	data_nack();
	seg <= ss;
	state <= STORE1;
end
endtask

task moveto_ifetch;
begin
	next_state(IFETCH);
end
endtask

