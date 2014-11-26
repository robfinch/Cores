// ============================================================================
// bus_task.v
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
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
task opcode_read;
begin
	vpa <= `TRUE;
	vda <= `TRUE;
	rwo <= `TRUE;
	ado <= pc;
end
endtask

task insn_read;
input [23:0] adr;
begin
	vpa <= `TRUE;
	vda <= `FALSE;
	rwo <= `TRUE;
	ado <= adr;
end
endtask

task data_read;
input [23:0] adr;
begin
	vpa <= `FALSE;
	vda <= `TRUE;
	rwo <= `TRUE;
	ado <= adr;
end
endtask

task data_write;
input [7:0] dat;
begin
	vpa <= `FALSE;
	vda <= `TRUE;
	rwo <= `FALSE;
	ado <= wadr;
	dbo <= dat;
end
endtask

task data_nack;
begin
	vpa <= `FALSE;
	vda <= `FALSE;
	rwo <= `TRUE;
	ado <= 24'h000000;
	dbo <= 8'h00;
end
endtask

