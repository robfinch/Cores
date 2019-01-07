// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	ft64v8d_rti.v
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
RTI1:
	begin
		status <= irq_stack_o[63:0];
		cc <= irq_stack_o[127: 64];
		pc <= irq_stack_o[191:128];
		prog_base <= irq_stack_o[255:192];
		sp <= irq_stack_o[319:256];
		data_base <= irq_stack_o[383:320];
		semaphore[0] <= 1'b0;
		irq_sp <= irq_sp + 4'd1;
		goto (IFETCH);
	end
