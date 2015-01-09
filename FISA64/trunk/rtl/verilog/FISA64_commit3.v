// ============================================================================
//        __
//   \\__/ o\    (C) 2013, 2015  Robert Finch, Stratford
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
//
// SuperScalar
// Commit phase logic
//
// ============================================================================
//
//	if (commit1_v && commit1_tgt[8:4]==5'h10)
//		pregs[commit1_tgt[3:0]] <= commit1_bus[3:0];
//
// When the INT instruction commits set the hardware interrupt status to disable further interrupts.
if (int_commit)
begin
	$display("*********************");
	$display("*********************");
	$display("Interrupt committing");
	$display("*********************");
	$display("*********************");
	StatusHWI <= `TRUE;
	imb <= im;
	im <= 1'b0;
	// Reset the nmi edge sense circuit but only for an NMI
	if ((iqentry_a0[head0][7:0]==8'hFE && commit0_v && iqentry_op[head0]==`INT) ||
	    (iqentry_a0[head1][7:0]==8'hFE && commit1_v && iqentry_op[head1]==`INT))
		nmi_edge <= 1'b0;
	string_pc <= 64'd0;
end

if (commit0_v) begin
	case(iqentry_op[head0])
	`CLI:	im <= 1'b0;
	`SEI:	im <= 1'b1;
	// When the RTI instruction commits clear the hardware interrupt status to enable interrupts.
	`RTI:	begin
			StatusHWI <= `FALSE;
			im <= imb;
			end
	`LOOP:
		if (lc != 64'd0)
			lc <= lc - 64'd1;
	`MTSPR:
		if (iqentry_tgt[head0]==`LCTR)
			lc <= commit0_bus;
	default:	;
	endcase
end

if (commit0_v && commit1_v) begin
	case(iqentry_op[head1])
	`CLI:	im <= 1'b0;
	`SEI:	im <= 1'b1;
	`RTI:	begin
			StatusHWI <= `FALSE;
			im <= imb;
			end
	`LOOP:
		if (lc != 64'd0)
			lc <= lc - 64'd1;
	`MTSPR:
		if (iqentry_tgt[head1]==`LCTR)
			lc <= commit1_bus;
	default:	;
	endcase
end

//
// COMMIT PHASE (dequeue only ... not register-file update)
//
// look at head0 and head1 and let 'em write to the register file if they are ready
//
if (~|panic)
case ({ iqentry_v[head0],
	iqentry_done[head0],
	iqentry_v[head1],
	iqentry_done[head1],
	iqentry_v[head2],
	iqentry_done[head2]})

	// 6'b00_00_00	none valid - skip all
	// 6'b00_00_01	none valid - skip all
	6'b00_00_00,
	6'b00_00_01,
	6'b00_01_00,
	6'b00_01_01,
	6'b01_00_00,
	6'b01_00_01,
	6'b01_01_00,
	6'b01_01_01,
		if (head0 != tail0 && head1 != tail0 && head2 != tail0)
			inc_head(4'd3);
		else if (head0 != tail0 && head1 != tail0)
			inc_head(4'd2);
		else if (head0 != tail0)
			inc_head(4'd1);

	// skip head0,head1, wait on head2
	6'b00_00_10
	6'b00_01_10,
	6'b01_00_10,
	6'b01_01_10,
		if (head0 != tail0 && head1 != tail0)
			inc_head(4'd2);
		else if (head0 != tail0)
			inc_head(4'd1);
	// skip head0,head1, commit on head2
	6'b00_00_11,
	6'b00_01_11,
	6'b01_00_11,
	6'b01_01_11,
		if (head0 != tail0 && head1 != tail0 && head2 != tail0) begin
			iqentry_v[head2] <= `INV;
			inc_head(4'd3);
		end
		else if (head0 != tail0 && head1 != tail0)
			inc_head(4'd2);
		else if (head0 != tail0)
			inc_head(4'd1);
	// All invalid skip all
//	6'b00_01_00:
//	6'b00_01_01:
//	6'b00_01_11:
	// skip head0, wait on head1
	6'b00_10_00,
	6'b00_10_01,
	6'b00_10_10,
	6'b00_10_11,
	6'b01_10_00,
	6'b01_10_01,
	6'b01_10_10,
	6'b01_10_11,
		if (head0 != tail0)
			inc_head(4'd1);
	// Skip head0 commit head1
	6'b00_11_00,
	6'b01_11_00,
		if (head0 != tail0 && head1 != tail0) begin
			iqentry_v[head1] <= `INV;
			inc_head(4'd2);
		end
		else if (head0 != tail0)
			inc_head(4'd1);
	// skip head0, commit head1, skip head2
	6'b00_11_01,
	6'b01_11_01:
		if (head0 != tail0 && head1 != tail0 && head2 != tail0) begin
			iqentry_v[head1] <= `INV;
			inc_head(4'd3);
		end
		else if (head0 != tail0 && head1 != tail0) begin
			iqentry_v[head1] <= `INV;
			inc_head(4'd2);
		end
		else if (head0 != tail0)
			inc_head(4'd1);
	6'b00_11_10,
	6'b01_11_10:
		if (head0 != tail0 && head1 != tail0) begin
			iqentry_v[head1] <= `INV;
			inc_head(4'd2);
		end
		else if (head0 != tail0)
			inc_head(4'd1);
	6'b00_11_11,
	6'b01_11_11:
		if (head0 != tail0 && head1 != tail0 && head2 != tail0) begin
			iqentry_v[head1] <= `INV;
			iqentry_v[head2] <= `INV;
			inc_head(4'd3);
		end
		else if (head0 != tail0 && head1 != tail0) begin
			iqentry_v[head1] <= `INV;
			inc_head(4'd2);
		end
		else if (head0 != tail0)
			inc_head(4'd1);
	// wait on head0
	6'b10_00_00,
	6'b10_00_01,
	6'b10_00_10
	6'b10_00_11,
	6'b10_01_00,
	6'b10_01_01,
	6'b10_01_10,
	6'b10_01_11,
	6'b10_10_00,
	6'b10_10_01,
	6'b10_10_10,
	6'b10_10_11,
	6'b10_11_00,
	6'b10_11_01,
	6'b10_11_10,
	6'b10_11_11:	;
	// commit head 0, skip head1, skip head2
	6'b11_00_00,
	6'b11_00_01,
	6'b11_01_00,
	6'b11_01_01:
		if (head0 != tail0 && head1 != tail0 && head2 != tail0) begin
			iqentry_v[head0] <= `INV;
			inc_head(4'd3);
		end
		else if (head0 != tail0 && head1 != tail0) begin
			iqentry_v[head0] <= `INV;
			inc_head(4'd2);
		end
		else if (head0 != tail0) begin
			iqentry_v[head0] <= `INV;
			inc_head(4'd1);
		end
	// commit head 0, skip head1, wait on head2
	6'b11_00_10,
	6'b11_01_10:
		if (head0 != tail0 && head1 != tail0) begin
			iqentry_v[head0] <= `INV;
			inc_head(4'd2);
		end
		else if (head0 != tail0) begin
			iqentry_v[head0] <= `INV;
			inc_head(4'd1);
		end
	// commit head0, skip head1, commit head2
	6'b11_00_11,
	6'b11_01_11:
		if (head0 != tail0 && head1 != tail0 && head2 != tail0) begin
			iqentry_v[head0] <= `INV;
			iqentry_v[head2] <= `INV;
			inc_head(4'd3);
		end
		else if (head0 != tail0 && head1 != tail0) begin
			iqentry_v[head0] <= `INV;
			inc_head(4'd2);
		end
		else if (head0 != tail0) begin
			iqentry_v[head0] <= `INV;
			inc_head(4'd1);
		end
	// commit head0 wait on head1
	6'b11_10_00,
	6'b11_10_01,
	6'b11_10_10,
	6'b11_10_11:
		if (head0 != tail0) begin
			iqentry_v[head0] <= `INV;
			inc_head(4'd1);
		end
	// commit head0 commit head1 skip head2
	6'b11_11_00,
	6'b11_11_01:
		if (head0 != tail0 && head1 != tail0 && head2 != tail0) begin
			iqentry_v[head0] <= `INV;
			iqentry_v[head1] <= `INV;
			inc_head(4'd3);
		end
		else if (head0 != tail0 && head1 != tail0) begin
			iqentry_v[head0] <= `INV;
			iqentry_v[head1] <= `INV;
			inc_head(4'd2);
		end
		else if (head0 != tail0) begin
			iqentry_v[head0] <= `INV;
			inc_head(4'd1);
		end
	// commit head0, commit head1, wait on head2
	6'b11_11_10:
		if (head0 != tail0 && head1 != tail0) begin
			iqentry_v[head0] <= `INV;
			iqentry_v[head1] <= `INV;
			inc_head(4'd2);
		end
		else if (head0 != tail0) begin
			iqentry_v[head0] <= `INV;
			inc_head(4'd1);
		end
	// commit head0, commit head1, commit head2
	6'b11_11_11:
		if (head0 != tail0 && head1 != tail0 && head2 != tail0) begin
			iqentry_v[head0] <= `INV;
			iqentry_v[head1] <= `INV;
			iqentry_v[head2] <= `INV;
			inc_head(4'd3);
		end
		else if (head0 != tail0 && head1 != tail0) begin
			iqentry_v[head0] <= `INV;
			iqentry_v[head1] <= `INV;
			inc_head(4'd2);
		end
		else if (head0 != tail0) begin
			iqentry_v[head0] <= `INV;
			inc_head(4'd1);
		end
	endcase
