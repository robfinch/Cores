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
        fn_get_sp = {4'd0,sp};
    else if (m816)
        fn_get_sp = {stack_bank,sp[15:0]};
    else
        fn_get_sp = {stack_page,sp[7:0]};
end
endfunction

function [31:0] fn_add_to_sp;
input [31:0] amt;
begin
    if (m832)
        fn_add_to_sp = sp + amt;
    else if (m816)
        fn_add_to_sp = {stack_bank,sp[15:0] + amt[15:0]};
    else
        fn_add_to_sp = {stack_page,sp[7:0] + amt[7:0]};
end
endfunction

function [31:0] fn_limit;
input [3:0] size;
begin
    case(size)
    4'd0:   fn_limit = 32'd0;
    4'd1:   fn_limit = 32'd255;
    4'd2:   fn_limit = 32'd1023;
    4'd3:   fn_limit = 32'd4095;
    4'd4:   fn_limit = 32'd16383;
    4'd5:   fn_limit = 32'd65535;
    4'd6:   fn_limit = 32'd262143;
    4'd7:   fn_limit = 32'd1048575;
    4'd8:   fn_limit = 32'd4194303;
    4'd9:   fn_limit = 32'd16777215;
    4'd10:  fn_limit = 32'd67108863;
    4'd11:  fn_limit = 32'd268435454;
    4'd12:  fn_limit = 32'd1073741823;
    4'd13:  fn_limit = 32'd4294967295;   // one less
    default:    fn_limit = 32'd4095;
    endcase 
end
endfunction

task set_sp;
begin
    radr <= fn_get_sp(sp);
    wadr <= fn_get_sp(sp);
    sp <= fn_add_to_sp(32'hFFFFFFFF);
	if (m816)
        bank_wrap <= TRUE;
	else if (!m832)
        page_wrap <= TRUE;
end
endtask

task inc_sp;
begin
    radr <= fn_add_to_sp(32'd1);
    sp <= fn_add_to_sp(32'd1);
    if (m816)
        bank_wrap <= TRUE;
    else if (!m832)
        page_wrap <= TRUE;
end
endtask

function [31:0] fn_sp_inc;
input [31:0] sp_inc;
begin
    fn_sp_inc = fn_add_to_sp(32'd1);
end
endfunction

task tsk_push;
input [5:0] SW8;
input szFlg;
input szFlg2;
begin
    if (m832) begin
		if (szFlg2) begin
		    radr <= fn_add_to_sp(32'hFFFFFFFD);
		    wadr <= fn_add_to_sp(32'hFFFFFFFD);
			sp <= fn_add_to_sp(32'hFFFFFFFC);
			store_what <= SW8;
			s32 <= TRUE;
		end
		else if (szFlg) begin
		    radr <= fn_add_to_sp(32'hFFFFFFFF);
            wadr <= fn_add_to_sp(32'hFFFFFFFF);
            sp <= fn_add_to_sp(32'hFFFFFFFE);
			s16 <= TRUE;
			store_what <= SW8;
		end
		else begin
			radr <= sp;
			wadr <= sp;
			store_what <= SW8;
			sp <= fn_add_to_sp(32'hFFFFFFFF);
		end
    end
	else if (m816) begin
		if (szFlg2) begin
		    radr <= fn_add_to_sp(32'hFFFFFFFD);
            wadr <= fn_add_to_sp(32'hFFFFFFFD);
            sp <= fn_add_to_sp(32'hFFFFFFFC);
            store_what <= SW8;
            s32 <= TRUE;
        end
		else if (szFlg) begin
		    radr <= fn_add_to_sp(32'hFFFFFFFF);
            wadr <= fn_add_to_sp(32'hFFFFFFFF);
            sp <= fn_add_to_sp(32'hFFFFFFFE);
			s16 <= TRUE;
			store_what <= SW8;
		end
		else begin
			radr <= {stack_bank,sp[15:0]};
			wadr <= {stack_bank,sp[15:0]};
			store_what <= SW8;
			sp <= fn_add_to_sp(32'hFFFFFFFF);;
		end
        bank_wrap <= TRUE;
	end
	else begin
	    // We could be pushing the CS or DS from
	    // emulation mode.
		if (szFlg2) begin
		    radr <= fn_add_to_sp(32'hFFFFFFFD);
            wadr <= fn_add_to_sp(32'hFFFFFFFD);
            sp <= fn_add_to_sp(32'hFFFFFFFC);
            store_what <= SW8;
            s32 <= TRUE;
        end
		else if (szFlg) begin
		    radr <= fn_add_to_sp(32'hFFFFFFFF);
            wadr <= fn_add_to_sp(32'hFFFFFFFF);
            sp <= fn_add_to_sp(32'hFFFFFFFE);
            s16 <= TRUE;
            store_what <= SW8;
        end
        else begin
            radr <= {stack_page,sp[7:0]};
            wadr <= {stack_page,sp[7:0]};
            store_what <= SW8;
            sp <= fn_add_to_sp(32'hFFFFFFFF);
        end
        page_wrap <= TRUE;
	end
	data_nack();
	seg <= ss_base;
	lmt <= ss_limit;
	state <= STORE1;
end
endtask

task moveto_ifetch;
begin
	next_state(ssm ? SSM1 : IFETCH);
end
endtask

