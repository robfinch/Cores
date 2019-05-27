// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
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
//
`include "rtfItanium-config.sv"
`include "rtfItanium-defines.sv"

module tailptrs(rst_i, clk_i, phit, ip_mask, branchmiss, take_branch0, take_branch1,
	iq_stomp, canq1, canq2, canq3, slot0v, slot1v, slot2v,slot0_jc, slot1_jc, tail0, tail1, tail2);
parameter QENTRIES = `QENTRIES;
input rst_i;
input clk_i;
input phit;
input [2:0] ip_mask;
input branchmiss;
input take_branch0;
input take_branch1;
input [QENTRIES-1:0] iq_stomp;
input canq1;
input canq2;
input canq3;
input slot0v;
input slot1v;
input slot2v;
input slot0_jc;
input slot1_jc;
output reg [`QBITS] tail0;
output reg [`QBITS] tail1;
output reg [`QBITS] tail2;

integer n;

always @(posedge clk_i)
if (rst_i) begin
	tail0 <= 2'd0;
	tail1 <= 2'd1;
	tail2 <= 2'd2;
end
else begin
	if (!branchmiss) begin
	  case({slot0v,slot1v,slot2v}&{3{phit}}&ip_mask)
	  3'b000:	;
	  3'b001:
	    if (canq1) begin
	     	tail0 <= (tail0+2'd1) % QENTRIES;
	     	tail1 <= (tail1+2'd1) % QENTRIES;
	     	tail2 <= (tail2+2'd1) % QENTRIES;
	    end
	  3'b010:
	    if (canq1) begin
	     	tail0 <= (tail0+2'd1) % QENTRIES;
	     	tail1 <= (tail1+2'd1) % QENTRIES;
	     	tail2 <= (tail2+2'd1) % QENTRIES;
	    end
	  3'b011:
	    if (canq1) begin
	      if (slot1_jc) begin
	       	tail0 <= (tail0+2'd1) % QENTRIES;
	       	tail1 <= (tail1+2'd1) % QENTRIES;
		     	tail2 <= (tail2+2'd1) % QENTRIES;
	    	end
	      else if (take_branch1) begin
	       	tail0 <= (tail0+2'd1) % QENTRIES;
	       	tail1 <= (tail1+2'd1) % QENTRIES;
		     	tail2 <= (tail2+2'd1) % QENTRIES;
	      end
	      else begin
	        if (canq2) begin
	          tail0 <= (tail0 + 3'd2) % QENTRIES;
	          tail1 <= (tail1 + 3'd2) % QENTRIES;
			     	tail2 <= (tail2 + 3'd2) % QENTRIES;
	        end
	        else begin    // queued1 will be true
	         	tail0 <= (tail0+2'd1) % QENTRIES;
				   	tail1 <= (tail1+2'd1) % QENTRIES;
			     	tail2 <= (tail2+2'd1) % QENTRIES;
	        end
	      end
	    end
	  3'b100:
	    if (canq1) begin
	     	tail0 <= (tail0+2'd1) % QENTRIES;
	     	tail1 <= (tail1+2'd1) % QENTRIES;
	     	tail2 <= (tail2+2'd1) % QENTRIES;
	    end
	  3'b101:
	    if (canq1) begin
	      if (slot0_jc) begin
	       	tail0 <= (tail0+2'd1) % QENTRIES;
	       	tail1 <= (tail1+2'd1) % QENTRIES;
		     	tail2 <= (tail2+2'd1) % QENTRIES;
	    	end
	      else if (take_branch0) begin
	       	tail0 <= (tail0+2'd1) % QENTRIES;
	       	tail1 <= (tail1+2'd1) % QENTRIES;
		     	tail2 <= (tail2+2'd1) % QENTRIES;
	      end
	      else begin
	        if (canq2) begin
	          tail0 <= (tail0 + 3'd2) % QENTRIES;
	          tail1 <= (tail1 + 3'd2) % QENTRIES;
			     	tail2 <= (tail2 + 3'd2) % QENTRIES;
	        end
	        else begin    // queued1 will be true
	         	tail0 <= (tail0+2'd1) % QENTRIES;
				   	tail1 <= (tail1+2'd1) % QENTRIES;
			     	tail2 <= (tail2+2'd1) % QENTRIES;
	        end
	      end
	    end
	  3'b110:
	    if (canq1) begin
	      if (slot0_jc) begin
	       	tail0 <= (tail0+2'd1) % QENTRIES;
	       	tail1 <= (tail1+2'd1) % QENTRIES;
		     	tail2 <= (tail2+2'd1) % QENTRIES;
	      end
	      else if (take_branch0) begin
	       	tail0 <= (tail0+2'd1) % QENTRIES;
	       	tail1 <= (tail1+2'd1) % QENTRIES;
		     	tail2 <= (tail2+2'd1) % QENTRIES;
	      end
	      else begin
	        if (canq2) begin
	          tail0 <= (tail0 + 3'd2) % QENTRIES;
	          tail1 <= (tail1 + 3'd2) % QENTRIES;
			     	tail2 <= (tail2 + 3'd2) % QENTRIES;
	        end
	        else begin    // queued1 will be true
	         	tail0 <= (tail0+2'd1) % QENTRIES;
				   	tail1 <= (tail1+2'd1) % QENTRIES;
			     	tail2 <= (tail2+2'd1) % QENTRIES;
	        end
	      end
	    end
	  3'b111:
	    if (canq1) begin
	      if (slot0_jc) begin
	       	tail0 <= (tail0+2'd1) % QENTRIES;
	       	tail1 <= (tail1+2'd1) % QENTRIES;
		     	tail2 <= (tail2+2'd1) % QENTRIES;
	      end
	      else if (take_branch0) begin
	       	tail0 <= (tail0+2'd1) % QENTRIES;
	       	tail1 <= (tail1+2'd1) % QENTRIES;
		     	tail2 <= (tail2+2'd1) % QENTRIES;
	      end
	      else begin
	      	if (canq2) begin
	          if (slot1_jc) begin
			       	tail0 <= (tail0+2'd2) % QENTRIES;
			       	tail1 <= (tail1+2'd2) % QENTRIES;
				     	tail2 <= (tail2+2'd2) % QENTRIES;
	          end
			      else if (take_branch1) begin
			       	tail0 <= (tail0+2'd2) % QENTRIES;
			       	tail1 <= (tail1+2'd2) % QENTRIES;
				     	tail2 <= (tail2+2'd2) % QENTRIES;
			      end
			      else begin
			      	if (canq3) begin
			          tail0 <= (tail0 + 3'd3) % QENTRIES;
			          tail1 <= (tail1 + 3'd3) % QENTRIES;
					     	tail2 <= (tail2 + 3'd3) % QENTRIES;
			      	end
			        else if (canq2) begin
			          tail0 <= (tail0 + 3'd2) % QENTRIES;
			          tail1 <= (tail1 + 3'd2) % QENTRIES;
					     	tail2 <= (tail2 + 3'd2) % QENTRIES;
			        end
			        else begin    // queued1 will be true
			         	tail0 <= (tail0+2'd1) % QENTRIES;
						   	tail1 <= (tail1+2'd1) % QENTRIES;
					     	tail2 <= (tail2+2'd1) % QENTRIES;
			        end
		      	end
	      	end
	      	else begin
		       	tail0 <= (tail0+2'd1) % QENTRIES;
		       	tail1 <= (tail1+2'd1) % QENTRIES;
			     	tail2 <= (tail2+2'd1) % QENTRIES;
	      	end
	      end
	    end
	  endcase
	end
	else begin	// if branchmiss
		for (n = QENTRIES-1; n >= 0; n = n - 1)
			// (QENTRIES-1) is needed to ensure that n increments forwards so that the modulus is
			// a positive number.
			if (iq_stomp[n] & ~iq_stomp[(n+(QENTRIES-1))%QENTRIES]) begin
				tail0 <= n;
				tail1 <= (n + 1) % QENTRIES;	
				tail2 <= (n + 2) % QENTRIES;
			end
	    // otherwise, it is the last instruction in the queue that has been mispredicted ... do nothing
	end
end

endmodule
