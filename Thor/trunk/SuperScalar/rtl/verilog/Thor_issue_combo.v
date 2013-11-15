// ============================================================================
//        __
//   \\__/ o\    (C) 2013  Robert Finch, Stratford
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
// Thor SuperScalar
// Issue combinational logic
//
// ============================================================================
//
assign  iqentry_imm[0] = fnHasConst(iqentry_op[0]),
	iqentry_imm[1] = fnHasConst(iqentry_op[1]),
	iqentry_imm[2] = fnHasConst(iqentry_op[2]),
	iqentry_imm[3] = fnHasConst(iqentry_op[3]),
	iqentry_imm[4] = fnHasConst(iqentry_op[4]),
	iqentry_imm[5] = fnHasConst(iqentry_op[5]),
	iqentry_imm[6] = fnHasConst(iqentry_op[6]),
	iqentry_imm[7] = fnHasConst(iqentry_op[7]);

//
// additional logic for ISSUE
//
// for the moment, we look at ALU-input buffers to allow back-to-back issue of 
// dependent instructions ... we do not, however, look ahead for DRAM requests 
// that will become valid in the next cycle.  instead, these have to propagate
// their results into the IQ entry directly, at which point it becomes issue-able
//

wire args_valid[0:7];
assign args_valid[0] =
			(iqentry_p_v[3'd0]
				|| (iqentry_p_s[3'd0]==alu0_sourceid && alu0_dataready)
				|| (iqentry_p_s[3'd0]==alu1_sourceid && alu1_dataready))
			&& (iqentry_a1_v[0] 
				|| (iqentry_a1_s[0] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a1_s[0] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a2_v[0] 
				|| (iqentry_mem[0] & ~iqentry_agen[0])
				|| (iqentry_a2_s[0] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a2_s[0] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a3_v[0] 
				|| (iqentry_mem[0] & ~iqentry_agen[0])
				|| (iqentry_a3_s[0] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a3_s[0] == alu1_sourceid && alu1_dataready));

assign args_valid[1] =
			(iqentry_p_v[3'd1]
				|| (iqentry_p_s[3'd1]==alu0_sourceid && alu0_dataready)
				|| (iqentry_p_s[3'd1]==alu1_sourceid && alu1_dataready))
			&& (iqentry_a1_v[1] 
				|| (iqentry_a1_s[1] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a1_s[1] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a2_v[1] 
				|| (iqentry_mem[1] & ~iqentry_agen[1])
				|| (iqentry_a2_s[1] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a2_s[1] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a3_v[1] 
				|| (iqentry_mem[1] & ~iqentry_agen[1])
				|| (iqentry_a3_s[1] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a3_s[1] == alu1_sourceid && alu1_dataready));

assign args_valid[2] =
			(iqentry_p_v[3'd2]
				|| (iqentry_p_s[3'd2]==alu0_sourceid && alu0_dataready)
				|| (iqentry_p_s[3'd2]==alu1_sourceid && alu1_dataready))
			&& (iqentry_a1_v[2] 
				|| (iqentry_a1_s[2] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a1_s[2] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a2_v[2] 
				|| (iqentry_mem[2] & ~iqentry_agen[2])
				|| (iqentry_a2_s[2] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a2_s[2] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a3_v[2] 
				|| (iqentry_mem[2] & ~iqentry_agen[2])
				|| (iqentry_a3_s[2] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a3_s[2] == alu1_sourceid && alu1_dataready));

assign args_valid[3] =
			(iqentry_p_v[3'd3]
				|| (iqentry_p_s[3'd3]==alu0_sourceid && alu0_dataready)
				|| (iqentry_p_s[3'd3]==alu1_sourceid && alu1_dataready))
			&& (iqentry_a1_v[3] 
				|| (iqentry_a1_s[3] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a1_s[3] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a2_v[3] 
				|| (iqentry_mem[3] & ~iqentry_agen[3])
				|| (iqentry_a2_s[3] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a2_s[3] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a3_v[3] 
				|| (iqentry_mem[3] & ~iqentry_agen[3])
				|| (iqentry_a3_s[3] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a3_s[3] == alu1_sourceid && alu1_dataready));

assign args_valid[4] =
			(iqentry_p_v[3'd4]
				|| (iqentry_p_s[3'd4]==alu0_sourceid && alu0_dataready)
				|| (iqentry_p_s[3'd4]==alu1_sourceid && alu1_dataready))
			&& (iqentry_a1_v[4] 
				|| (iqentry_a1_s[4] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a1_s[4] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a2_v[4] 
				|| (iqentry_mem[4] & ~iqentry_agen[4])
				|| (iqentry_a2_s[4] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a2_s[4] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a3_v[4] 
				|| (iqentry_mem[4] & ~iqentry_agen[4])
				|| (iqentry_a3_s[4] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a3_s[4] == alu1_sourceid && alu1_dataready));

assign args_valid[5] =
			(iqentry_p_v[3'd5]
				|| (iqentry_p_s[3'd5]==alu0_sourceid && alu0_dataready)
				|| (iqentry_p_s[3'd5]==alu1_sourceid && alu1_dataready))
			&& (iqentry_a1_v[5] 
				|| (iqentry_a1_s[5] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a1_s[5] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a2_v[5] 
				|| (iqentry_mem[5] & ~iqentry_agen[5])
				|| (iqentry_a2_s[5] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a2_s[5] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a3_v[5] 
				|| (iqentry_mem[5] & ~iqentry_agen[5])
				|| (iqentry_a3_s[5] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a3_s[5] == alu1_sourceid && alu1_dataready));

assign args_valid[6] =
			(iqentry_p_v[3'd6]
				|| (iqentry_p_s[3'd6]==alu0_sourceid && alu0_dataready)
				|| (iqentry_p_s[3'd6]==alu1_sourceid && alu1_dataready))
			&& (iqentry_a1_v[6] 
				|| (iqentry_a1_s[6] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a1_s[6] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a2_v[6] 
				|| (iqentry_mem[6] & ~iqentry_agen[6])
				|| (iqentry_a2_s[6] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a2_s[6] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a3_v[6] 
				|| (iqentry_mem[6] & ~iqentry_agen[6])
				|| (iqentry_a3_s[6] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a3_s[6] == alu1_sourceid && alu1_dataready));

assign args_valid[7] =
			(iqentry_p_v[3'd7]
				|| (iqentry_p_s[3'd7]==alu0_sourceid && alu0_dataready)
				|| (iqentry_p_s[3'd7]==alu1_sourceid && alu1_dataready))
			&& (iqentry_a1_v[7] 
				|| (iqentry_a1_s[7] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a1_s[7] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a2_v[7] 
				|| (iqentry_mem[7] & ~iqentry_agen[7])
				|| (iqentry_a2_s[7] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a2_s[7] == alu1_sourceid && alu1_dataready))
			&& (iqentry_a3_v[7] 
				|| (iqentry_mem[7] & ~iqentry_agen[7])
				|| (iqentry_a3_s[7] == alu0_sourceid && alu0_dataready)
				|| (iqentry_a3_s[7] == alu1_sourceid && alu1_dataready));

wire [7:0] could_issue;
assign could_issue[0] = iqentry_v[0] && !iqentry_out[0] && !iqentry_agen[0] && args_valid[0];
assign could_issue[1] = iqentry_v[1] && !iqentry_out[1] && !iqentry_agen[1] && args_valid[1];
assign could_issue[2] = iqentry_v[2] && !iqentry_out[2] && !iqentry_agen[2] && args_valid[2];
assign could_issue[3] = iqentry_v[3] && !iqentry_out[3] && !iqentry_agen[3] && args_valid[3];
assign could_issue[4] = iqentry_v[4] && !iqentry_out[4] && !iqentry_agen[4] && args_valid[4];
assign could_issue[5] = iqentry_v[5] && !iqentry_out[5] && !iqentry_agen[5] && args_valid[5];
assign could_issue[6] = iqentry_v[6] && !iqentry_out[6] && !iqentry_agen[6] && args_valid[6];
assign could_issue[7] = iqentry_v[7] && !iqentry_out[7] && !iqentry_agen[7] && args_valid[7];

wire any_msb =
	   (iqentry_v[head0] && iqentry_op[head0]==`MEMSB)
	|| (iqentry_v[head1] && iqentry_op[head1]==`MEMSB)
	|| (iqentry_v[head2] && iqentry_op[head2]==`MEMSB)
	|| (iqentry_v[head3] && iqentry_op[head3]==`MEMSB)
	|| (iqentry_v[head4] && iqentry_op[head4]==`MEMSB)
	|| (iqentry_v[head5] && iqentry_op[head5]==`MEMSB)
	|| (iqentry_v[head6] && iqentry_op[head6]==`MEMSB)
	;

reg [3:0] ispot;

always @(could_issue or head0 or head1 or head2 or head3 or head4 or head5 or head6 or head7)
begin
	iqentry_issue = 8'h00;
	iqentry_islot[0] = 2'b00;
	iqentry_islot[1] = 2'b00;
	iqentry_islot[2] = 2'b00;
	iqentry_islot[3] = 2'b00;
	iqentry_islot[4] = 2'b00;
	iqentry_islot[5] = 2'b00;
	iqentry_islot[6] = 2'b00;
	iqentry_islot[7] = 2'b00;
	ispot = head0;
	if (could_issue[head0] & !iqentry_fp[head0]) begin
		iqentry_issue[head0] = `TRUE;
		iqentry_islot[head0] = 2'b00;
		ispot = head0;
	end
	else if (could_issue[head1] & !iqentry_fp[head1]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMSB))
	begin
		iqentry_issue[head1] = `TRUE;
		iqentry_islot[head1] = 2'b00;
		ispot = head1;
	end
	else if (could_issue[head2] & !iqentry_fp[head2]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMSB)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`MEMSB)
	)
	begin
		iqentry_issue[head2] = `TRUE;
		iqentry_islot[head2] = 2'b00;
		ispot = head2;
	end
	else if (could_issue[head3] & !iqentry_fp[head3]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMSB)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`MEMSB)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`MEMSB)
	) begin
		iqentry_issue[head3] = `TRUE;
		iqentry_islot[head3] = 2'b00;
		ispot = head3;
	end
	else if (could_issue[head4] & !iqentry_fp[head4]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMSB)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`MEMSB)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`MEMSB)
	&& !(iqentry_v[head3] && iqentry_op[head3]==`MEMSB)
	) begin
		iqentry_issue[head4] = `TRUE;
		iqentry_islot[head4] = 2'b00;
		ispot = head4;
	end
	else if (could_issue[head5] & !iqentry_fp[head5]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMSB)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`MEMSB)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`MEMSB)
	&& !(iqentry_v[head3] && iqentry_op[head3]==`MEMSB)
	&& !(iqentry_v[head4] && iqentry_op[head4]==`MEMSB)
	) begin
		iqentry_issue[head5] = `TRUE;
		iqentry_islot[head5] = 2'b00;
		ispot = head5;
	end
	else if (could_issue[head6] & !iqentry_fp[head6]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMSB)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`MEMSB)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`MEMSB)
	&& !(iqentry_v[head3] && iqentry_op[head3]==`MEMSB)
	&& !(iqentry_v[head4] && iqentry_op[head4]==`MEMSB)
	&& !(iqentry_v[head5] && iqentry_op[head5]==`MEMSB)
	) begin
		iqentry_issue[head6] = `TRUE;
		iqentry_islot[head6] = 2'b00;
		ispot = head6;
	end
	else if (could_issue[head7] & !iqentry_fp[head7]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMSB)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`MEMSB)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`MEMSB)
	&& !(iqentry_v[head3] && iqentry_op[head3]==`MEMSB)
	&& !(iqentry_v[head4] && iqentry_op[head4]==`MEMSB)
	&& !(iqentry_v[head5] && iqentry_op[head5]==`MEMSB)
	&& !(iqentry_v[head6] && iqentry_op[head6]==`MEMSB)
	) begin
		iqentry_issue[head7] = `TRUE;
		iqentry_islot[head7] = 2'b00;
		ispot = head7;
	end
	else
		ispot = 4'd8;

	if (ispot != 4'd8 && !any_msb) begin
		if (could_issue[ispot+1] && !iqentry_issue[ispot+1] & !iqentry_fp[ispot+1]) begin
			iqentry_issue[ispot+1] = `TRUE;
			iqentry_islot[ispot+1] = 2'b01;
		end
		else if (could_issue[ispot+2] && !iqentry_issue[ispot+2] & !iqentry_fp[ispot+2]) begin
			iqentry_issue[ispot+2] = `TRUE;
			iqentry_islot[ispot+2] = 2'b01;
		end
		else if (could_issue[ispot+3] && !iqentry_issue[ispot+3] & !iqentry_fp[ispot+3]) begin
			iqentry_issue[ispot+3] = `TRUE;
			iqentry_islot[ispot+3] = 2'b01;
		end
		else if (could_issue[ispot+4] && !iqentry_issue[ispot+4] & !iqentry_fp[ispot+4]) begin
			iqentry_issue[ispot+4] = `TRUE;
			iqentry_islot[ispot+4] = 2'b01;
		end
		else if (could_issue[ispot+5] && !iqentry_issue[ispot+5] & !iqentry_fp[ispot+5]) begin
			iqentry_issue[ispot+5] = `TRUE;
			iqentry_islot[ispot+5] = 2'b01;
		end
		else if (could_issue[ispot+6] && !iqentry_issue[ispot+6] & !iqentry_fp[ispot+6]) begin
			iqentry_issue[ispot+6] = `TRUE;
			iqentry_islot[ispot+6] = 2'b01;
		end
		else if (could_issue[ispot+7] && !iqentry_issue[ispot+7] & !iqentry_fp[ispot+7]) begin
			iqentry_issue[ispot+7] = `TRUE;
			iqentry_islot[ispot+7] = 2'b01;
		end
	end
end

`ifdef FLOATING_POINT
reg [3:0] fpispot;
always @(could_issue or head0 or head1 or head2 or head3 or head4 or head5 or head6 or head7)
begin
	iqentry_fpissue = 8'h00;
	iqentry_fpislot[0] = 2'b00;
	iqentry_fpislot[1] = 2'b00;
	iqentry_fpislot[2] = 2'b00;
	iqentry_fpislot[3] = 2'b00;
	iqentry_fpislot[4] = 2'b00;
	iqentry_fpislot[5] = 2'b00;
	iqentry_fpislot[6] = 2'b00;
	iqentry_fpislot[7] = 2'b00;
	fpispot = head0;
	if (could_issue[head0] & iqentry_fp[head0]) begin
		iqentry_fpissue[head0] = `TRUE;
		iqentry_fpislot[head0] = 2'b00;
		fpispot = head0;
	end
	else if (could_issue[head1] & iqentry_fp[head1]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMSB))
	begin
		iqentry_fpissue[head1] = `TRUE;
		iqentry_fpislot[head1] = 2'b00;
		fpispot = head1;
	end
	else if (could_issue[head2] & iqentry_fp[head2]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMSB)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`MEMSB)
	)
	begin
		iqentry_fpissue[head2] = `TRUE;
		iqentry_fpislot[head2] = 2'b00;
		fpispot = head2;
	end
	else if (could_issue[head3] & iqentry_fp[head3]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMSB)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`MEMSB)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`MEMSB)
	) begin
		iqentry_fpissue[head3] = `TRUE;
		iqentry_fpislot[head3] = 2'b00;
		fpispot = head3;
	end
	else if (could_issue[head4] & iqentry_fp[head4]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMSB)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`MEMSB)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`MEMSB)
	&& !(iqentry_v[head3] && iqentry_op[head3]==`MEMSB)
	) begin
		iqentry_fpissue[head4] = `TRUE;
		iqentry_fpislot[head4] = 2'b00;
		fpispot = head4;
	end
	else if (could_issue[head5] & iqentry_fp[head5]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMSB)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`MEMSB)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`MEMSB)
	&& !(iqentry_v[head3] && iqentry_op[head3]==`MEMSB)
	&& !(iqentry_v[head4] && iqentry_op[head4]==`MEMSB)
	) begin
		iqentry_fpissue[head5] = `TRUE;
		iqentry_fpislot[head5] = 2'b00;
		fpispot = head5;
	end
	else if (could_issue[head6] & iqentry_fp[head6]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMSB)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`MEMSB)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`MEMSB)
	&& !(iqentry_v[head3] && iqentry_op[head3]==`MEMSB)
	&& !(iqentry_v[head4] && iqentry_op[head4]==`MEMSB)
	&& !(iqentry_v[head5] && iqentry_op[head5]==`MEMSB)
	) begin
		iqentry_fpissue[head6] = `TRUE;
		iqentry_fpislot[head6] = 2'b00;
		fpispot = head6;
	end
	else if (could_issue[head7] & iqentry_fp[head7]
	&& !(iqentry_v[head0] && iqentry_op[head0]==`MEMSB)
	&& !(iqentry_v[head1] && iqentry_op[head1]==`MEMSB)
	&& !(iqentry_v[head2] && iqentry_op[head2]==`MEMSB)
	&& !(iqentry_v[head3] && iqentry_op[head3]==`MEMSB)
	&& !(iqentry_v[head4] && iqentry_op[head4]==`MEMSB)
	&& !(iqentry_v[head5] && iqentry_op[head5]==`MEMSB)
	&& !(iqentry_v[head6] && iqentry_op[head6]==`MEMSB)
	) begin
		iqentry_fpissue[head7] = `TRUE;
		iqentry_fpislot[head7] = 2'b00;
		fpispot = head7;
	end
	else
		fpispot = 4'd8;

//	if (fpispot != 4'd8 && !any_msb) begin
//		if (could_issue[fpispot+1] && !iqentry_fpissue[fpispot+1] && iqentry_fp[fpispot+1]) begin
//			iqentry_fpissue[fpispot+1] = `TRUE;
//			iqentry_fpislot[fpispot+1] = 2'b01;
//		end
//		else if (could_issue[fpispot+2] && !iqentry_fpissue[fpispot+2] && iqentry_fp[fpispot+2]) begin
//			iqentry_fpissue[fpispot+2] = `TRUE;
//			iqentry_fpislot[fpispot+2] = 2'b01;
//		end
//		else if (could_issue[fpispot+3] && !iqentry_fpissue[fpispot+3] && iqentry_fp[fpispot+3]) begin
//			iqentry_fpissue[fpispot+3] = `TRUE;
//			iqentry_fpislot[fpispot+3] = 2'b01;
//		end
//		else if (could_issue[fpispot+4] && !iqentry_fpissue[fpispot+4] && iqentry_fp[fpispot+4]) begin
//			iqentry_fpissue[fpispot+4] = `TRUE;
//			iqentry_fpislot[fpispot+4] = 2'b01;
//		end
//		else if (could_issue[fpispot+5] && !iqentry_fpissue[fpispot+5] && iqentry_fp[fpispot+5]) begin
//			iqentry_fpissue[fpispot+5] = `TRUE;
//			iqentry_fpislot[fpispot+5] = 2'b01;
//		end
//		else if (could_issue[fpispot+6] && !iqentry_fpissue[fpispot+6] && iqentry_fp[fpispot+6]) begin
//			iqentry_fpissue[fpispot+6] = `TRUE;
//			iqentry_fpislot[fpispot+6] = 2'b01;
//		end
//		else if (could_issue[fpispot+7] && !iqentry_fpissue[fpispot+7] && iqentry_fp[fpispot+7]) begin
//			iqentry_fpissue[fpispot+7] = `TRUE;
//			iqentry_fpislot[fpispot+7] = 2'b01;
//		end
//	end
end
`endif

assign stomp_all = fnIsStoreString(iqentry_op[head0]) && int_pending;

// 
// additional logic for handling a branch miss (STOMP logic)
//
assign
	iqentry_stomp[0] = stomp_all || (branchmiss && iqentry_v[0] && head0 != 3'd0 && (missid == 3'd7 || iqentry_stomp[7])),
	iqentry_stomp[1] = stomp_all || (branchmiss && iqentry_v[1] && head0 != 3'd1 && (missid == 3'd0 || iqentry_stomp[0])),
	iqentry_stomp[2] = stomp_all || (branchmiss && iqentry_v[2] && head0 != 3'd2 && (missid == 3'd1 || iqentry_stomp[1])),
	iqentry_stomp[3] = stomp_all || (branchmiss && iqentry_v[3] && head0 != 3'd3 && (missid == 3'd2 || iqentry_stomp[2])),
	iqentry_stomp[4] = stomp_all || (branchmiss && iqentry_v[4] && head0 != 3'd4 && (missid == 3'd3 || iqentry_stomp[3])),
	iqentry_stomp[5] = stomp_all || (branchmiss && iqentry_v[5] && head0 != 3'd5 && (missid == 3'd4 || iqentry_stomp[4])),
	iqentry_stomp[6] = stomp_all || (branchmiss && iqentry_v[6] && head0 != 3'd6 && (missid == 3'd5 || iqentry_stomp[5])),
	iqentry_stomp[7] = stomp_all || (branchmiss && iqentry_v[7] && head0 != 3'd7 && (missid == 3'd6 || iqentry_stomp[6]));


assign alu0_issue = (!(iqentry_v[0] && iqentry_stomp[0]) && iqentry_issue[0] && iqentry_islot[0]==2'd0) ||
			(!(iqentry_v[1] && iqentry_stomp[1]) && iqentry_issue[1] && iqentry_islot[1]==2'd0) ||
			(!(iqentry_v[2] && iqentry_stomp[2]) && iqentry_issue[2] && iqentry_islot[2]==2'd0) ||
			(!(iqentry_v[3] && iqentry_stomp[3]) && iqentry_issue[3] && iqentry_islot[3]==2'd0) ||
			(!(iqentry_v[4] && iqentry_stomp[4]) && iqentry_issue[4] && iqentry_islot[4]==2'd0) ||
			(!(iqentry_v[5] && iqentry_stomp[5]) && iqentry_issue[5] && iqentry_islot[5]==2'd0) ||
			(!(iqentry_v[6] && iqentry_stomp[6]) && iqentry_issue[6] && iqentry_islot[6]==2'd0) ||
			(!(iqentry_v[7] && iqentry_stomp[7]) && iqentry_issue[7] && iqentry_islot[7]==2'd0)
			;

assign alu1_issue = (!(iqentry_v[0] && iqentry_stomp[0]) && iqentry_issue[0] && iqentry_islot[0]==2'd1) ||
			(!(iqentry_v[1] && iqentry_stomp[1]) && iqentry_issue[1] && iqentry_islot[1]==2'd1) ||
			(!(iqentry_v[2] && iqentry_stomp[2]) && iqentry_issue[2] && iqentry_islot[2]==2'd1) ||
			(!(iqentry_v[3] && iqentry_stomp[3]) && iqentry_issue[3] && iqentry_islot[3]==2'd1) ||
			(!(iqentry_v[4] && iqentry_stomp[4]) && iqentry_issue[4] && iqentry_islot[4]==2'd1) ||
			(!(iqentry_v[5] && iqentry_stomp[5]) && iqentry_issue[5] && iqentry_islot[5]==2'd1) ||
			(!(iqentry_v[6] && iqentry_stomp[6]) && iqentry_issue[6] && iqentry_islot[6]==2'd1) ||
			(!(iqentry_v[7] && iqentry_stomp[7]) && iqentry_issue[7] && iqentry_islot[7]==2'd1)
			;

`ifdef FLOATING_POINT
assign fp0_issue = (!(iqentry_v[0] && iqentry_stomp[0]) && iqentry_fpissue[0] && iqentry_islot[0]==2'd0) ||
			(!(iqentry_v[1] && iqentry_stomp[1]) && iqentry_fpissue[1] && iqentry_islot[1]==2'd0) ||
			(!(iqentry_v[2] && iqentry_stomp[2]) && iqentry_fpissue[2] && iqentry_islot[2]==2'd0) ||
			(!(iqentry_v[3] && iqentry_stomp[3]) && iqentry_fpissue[3] && iqentry_islot[3]==2'd0) ||
			(!(iqentry_v[4] && iqentry_stomp[4]) && iqentry_fpissue[4] && iqentry_islot[4]==2'd0) ||
			(!(iqentry_v[5] && iqentry_stomp[5]) && iqentry_fpissue[5] && iqentry_islot[5]==2'd0) ||
			(!(iqentry_v[6] && iqentry_stomp[6]) && iqentry_fpissue[6] && iqentry_islot[6]==2'd0) ||
			(!(iqentry_v[7] && iqentry_stomp[7]) && iqentry_fpissue[7] && iqentry_islot[7]==2'd0)
			;
`endif
