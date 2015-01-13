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
	iqentry_imm[7] = fnHasConst(iqentry_op[7]),
	iqentry_imm[8] = fnHasConst(iqentry_op[8]),
	iqentry_imm[9] = fnHasConst(iqentry_op[9]),
	iqentry_imm[10] = fnHasConst(iqentry_op[10]),
	iqentry_imm[11] = fnHasConst(iqentry_op[11]),
	iqentry_imm[12] = fnHasConst(iqentry_op[12]),
	iqentry_imm[13] = fnHasConst(iqentry_op[13]),
	iqentry_imm[14] = fnHasConst(iqentry_op[14]),
	iqentry_imm[15] = fnHasConst(iqentry_op[15]);

//
// additional logic for ISSUE
//
// for the moment, we look at ALU-input buffers to allow back-to-back issue of 
// dependent instructions ... we do not, however, look ahead for DRAM requests 
// that will become valid in the next cycle.  instead, these have to propagate
// their results into the IQ entry directly, at which point it becomes issue-able
//

wire args_valid[0:15];
assign args_valid[0] =
			(iqentry_av[0] 
				|| (iqentry_as[0] == alu0_sourceid && alu0_dataready)
				|| (iqentry_as[0] == alu1_sourceid && alu1_dataready))
			&& (iqentry_bv[0] 
				|| (iqentry_mem[0] & ~iqentry_agen[0])
				|| (iqentry_bs[0] == alu0_sourceid && alu0_dataready)
				|| (iqentry_bs[0] == alu1_sourceid && alu1_dataready))
			&& (iqentry_cv[0] 
				|| (iqentry_mem[0] & ~iqentry_agen[0])
				|| (iqentry_cs[0] == alu0_sourceid && alu0_dataready)
				|| (iqentry_cs[0] == alu1_sourceid && alu1_dataready));

assign args_valid[1] =
			(iqentry_av[1] 
				|| (iqentry_as[1] == alu0_sourceid && alu0_dataready)
				|| (iqentry_as[1] == alu1_sourceid && alu1_dataready))
			&& (iqentry_bv[1] 
				|| (iqentry_mem[1] & ~iqentry_agen[1])
				|| (iqentry_bs[1] == alu0_sourceid && alu0_dataready)
				|| (iqentry_bs[1] == alu1_sourceid && alu1_dataready))
			&& (iqentry_cv[1] 
				|| (iqentry_mem[1] & ~iqentry_agen[1])
				|| (iqentry_cs[1] == alu0_sourceid && alu0_dataready)
				|| (iqentry_cs[1] == alu1_sourceid && alu1_dataready));

assign args_valid[2] =
			(iqentry_av[2] 
				|| (iqentry_as[2] == alu0_sourceid && alu0_dataready)
				|| (iqentry_as[2] == alu1_sourceid && alu1_dataready))
			&& (iqentry_bv[2] 
				|| (iqentry_mem[2] & ~iqentry_agen[2])
				|| (iqentry_bs[2] == alu0_sourceid && alu0_dataready)
				|| (iqentry_bs[2] == alu1_sourceid && alu1_dataready))
			&& (iqentry_cv[2] 
				|| (iqentry_mem[2] & ~iqentry_agen[2])
				|| (iqentry_cs[2] == alu0_sourceid && alu0_dataready)
				|| (iqentry_cs[2] == alu1_sourceid && alu1_dataready));

assign args_valid[3] =
			(iqentry_av[3] 
				|| (iqentry_as[3] == alu0_sourceid && alu0_dataready)
				|| (iqentry_as[3] == alu1_sourceid && alu1_dataready))
			&& (iqentry_bv[3] 
				|| (iqentry_mem[3] & ~iqentry_agen[3])
				|| (iqentry_bs[3] == alu0_sourceid && alu0_dataready)
				|| (iqentry_bs[3] == alu1_sourceid && alu1_dataready))
			&& (iqentry_cv[3] 
				|| (iqentry_mem[3] & ~iqentry_agen[3])
				|| (iqentry_cs[3] == alu0_sourceid && alu0_dataready)
				|| (iqentry_cs[3] == alu1_sourceid && alu1_dataready));

assign args_valid[4] =
			(iqentry_av[4] 
				|| (iqentry_as[4] == alu0_sourceid && alu0_dataready)
				|| (iqentry_as[4] == alu1_sourceid && alu1_dataready))
			&& (iqentry_bv[4] 
				|| (iqentry_mem[4] & ~iqentry_agen[4])
				|| (iqentry_bs[4] == alu0_sourceid && alu0_dataready)
				|| (iqentry_bs[4] == alu1_sourceid && alu1_dataready))
			&& (iqentry_cv[4] 
				|| (iqentry_mem[4] & ~iqentry_agen[4])
				|| (iqentry_cs[4] == alu0_sourceid && alu0_dataready)
				|| (iqentry_cs[4] == alu1_sourceid && alu1_dataready));

assign args_valid[5] =
			(iqentry_av[5] 
				|| (iqentry_as[5] == alu0_sourceid && alu0_dataready)
				|| (iqentry_as[5] == alu1_sourceid && alu1_dataready))
			&& (iqentry_bv[5] 
				|| (iqentry_mem[5] & ~iqentry_agen[5])
				|| (iqentry_bs[5] == alu0_sourceid && alu0_dataready)
				|| (iqentry_bs[5] == alu1_sourceid && alu1_dataready))
			&& (iqentry_cv[5] 
				|| (iqentry_mem[5] & ~iqentry_agen[5])
				|| (iqentry_cs[5] == alu0_sourceid && alu0_dataready)
				|| (iqentry_cs[5] == alu1_sourceid && alu1_dataready));

assign args_valid[6] =
			(iqentry_av[6] 
				|| (iqentry_as[6] == alu0_sourceid && alu0_dataready)
				|| (iqentry_as[6] == alu1_sourceid && alu1_dataready))
			&& (iqentry_bv[6] 
				|| (iqentry_mem[6] & ~iqentry_agen[6])
				|| (iqentry_bs[6] == alu0_sourceid && alu0_dataready)
				|| (iqentry_bs[6] == alu1_sourceid && alu1_dataready))
			&& (iqentry_cv[6] 
				|| (iqentry_mem[6] & ~iqentry_agen[6])
				|| (iqentry_cs[6] == alu0_sourceid && alu0_dataready)
				|| (iqentry_cs[6] == alu1_sourceid && alu1_dataready));

assign args_valid[7] =
			(iqentry_av[7] 
				|| (iqentry_as[7] == alu0_sourceid && alu0_dataready)
				|| (iqentry_as[7] == alu1_sourceid && alu1_dataready))
			&& (iqentry_bv[7] 
				|| (iqentry_mem[7] & ~iqentry_agen[7])
				|| (iqentry_bs[7] == alu0_sourceid && alu0_dataready)
				|| (iqentry_bs[7] == alu1_sourceid && alu1_dataready))
			&& (iqentry_cv[7] 
				|| (iqentry_mem[7] & ~iqentry_agen[7])
				|| (iqentry_cs[7] == alu0_sourceid && alu0_dataready)
				|| (iqentry_cs[7] == alu1_sourceid && alu1_dataready));

assign args_valid[8] =
			(iqentry_av[8] 
				|| (iqentry_as[8] == alu0_sourceid && alu0_dataready)
				|| (iqentry_as[8] == alu1_sourceid && alu1_dataready))
			&& (iqentry_bv[8] 
				|| (iqentry_mem[8] & ~iqentry_agen[8])
				|| (iqentry_bs[8] == alu0_sourceid && alu0_dataready)
				|| (iqentry_bs[8] == alu1_sourceid && alu1_dataready))
			&& (iqentry_cv[8] 
				|| (iqentry_mem[8] & ~iqentry_agen[8])
				|| (iqentry_cs[8] == alu0_sourceid && alu0_dataready)
				|| (iqentry_cs[8] == alu1_sourceid && alu1_dataready));

assign args_valid[9] =
			(iqentry_av[9] 
				|| (iqentry_as[9] == alu0_sourceid && alu0_dataready)
				|| (iqentry_as[9] == alu1_sourceid && alu1_dataready))
			&& (iqentry_bv[9] 
				|| (iqentry_mem[9] & ~iqentry_agen[9])
				|| (iqentry_bs[9] == alu0_sourceid && alu0_dataready)
				|| (iqentry_bs[9] == alu1_sourceid && alu1_dataready))
			&& (iqentry_cv[9] 
				|| (iqentry_mem[9] & ~iqentry_agen[9])
				|| (iqentry_cs[9] == alu0_sourceid && alu0_dataready)
				|| (iqentry_cs[9] == alu1_sourceid && alu1_dataready));

assign args_valid[10] =
			(iqentry_av[10] 
				|| (iqentry_as[10] == alu0_sourceid && alu0_dataready)
				|| (iqentry_as[10] == alu1_sourceid && alu1_dataready))
			&& (iqentry_bv[10] 
				|| (iqentry_mem[10] & ~iqentry_agen[10])
				|| (iqentry_bs[10] == alu0_sourceid && alu0_dataready)
				|| (iqentry_bs[10] == alu1_sourceid && alu1_dataready))
			&& (iqentry_cv[10] 
				|| (iqentry_mem[10] & ~iqentry_agen[10])
				|| (iqentry_cs[10] == alu0_sourceid && alu0_dataready)
				|| (iqentry_cs[10] == alu1_sourceid && alu1_dataready));

assign args_valid[11] =
			(iqentry_av[11] 
				|| (iqentry_as[11] == alu0_sourceid && alu0_dataready)
				|| (iqentry_as[11] == alu1_sourceid && alu1_dataready))
			&& (iqentry_bv[11] 
				|| (iqentry_mem[11] & ~iqentry_agen[11])
				|| (iqentry_bs[11] == alu0_sourceid && alu0_dataready)
				|| (iqentry_bs[11] == alu1_sourceid && alu1_dataready))
			&& (iqentry_cv[11] 
				|| (iqentry_mem[11] & ~iqentry_agen[11])
				|| (iqentry_cs[11] == alu0_sourceid && alu0_dataready)
				|| (iqentry_cs[11] == alu1_sourceid && alu1_dataready));

assign args_valid[12] =
			(iqentry_av[12] 
				|| (iqentry_as[12] == alu0_sourceid && alu0_dataready)
				|| (iqentry_as[12] == alu1_sourceid && alu1_dataready))
			&& (iqentry_bv[12] 
				|| (iqentry_mem[12] & ~iqentry_agen[12])
				|| (iqentry_bs[12] == alu0_sourceid && alu0_dataready)
				|| (iqentry_bs[12] == alu1_sourceid && alu1_dataready))
			&& (iqentry_cv[12] 
				|| (iqentry_mem[12] & ~iqentry_agen[12])
				|| (iqentry_cs[12] == alu0_sourceid && alu0_dataready)
				|| (iqentry_cs[12] == alu1_sourceid && alu1_dataready));

assign args_valid[13] =
			(iqentry_av[13] 
				|| (iqentry_as[13] == alu0_sourceid && alu0_dataready)
				|| (iqentry_as[13] == alu1_sourceid && alu1_dataready))
			&& (iqentry_bv[13] 
				|| (iqentry_mem[13] & ~iqentry_agen[13])
				|| (iqentry_bs[13] == alu0_sourceid && alu0_dataready)
				|| (iqentry_bs[13] == alu1_sourceid && alu1_dataready))
			&& (iqentry_cv[13] 
				|| (iqentry_mem[13] & ~iqentry_agen[13])
				|| (iqentry_cs[13] == alu0_sourceid && alu0_dataready)
				|| (iqentry_cs[13] == alu1_sourceid && alu1_dataready));

assign args_valid[14] =
			(iqentry_av[14] 
				|| (iqentry_as[14] == alu0_sourceid && alu0_dataready)
				|| (iqentry_as[14] == alu1_sourceid && alu1_dataready))
			&& (iqentry_bv[14] 
				|| (iqentry_mem[14] & ~iqentry_agen[14])
				|| (iqentry_bs[14] == alu0_sourceid && alu0_dataready)
				|| (iqentry_bs[14] == alu1_sourceid && alu1_dataready))
			&& (iqentry_cv[14] 
				|| (iqentry_mem[14] & ~iqentry_agen[14])
				|| (iqentry_cs[14] == alu0_sourceid && alu0_dataready)
				|| (iqentry_cs[14] == alu1_sourceid && alu1_dataready));

assign args_valid[15] =
			(iqentry_av[15] 
				|| (iqentry_as[15] == alu0_sourceid && alu0_dataready)
				|| (iqentry_as[15] == alu1_sourceid && alu1_dataready))
			&& (iqentry_bv[15] 
				|| (iqentry_mem[15] & ~iqentry_agen[15])
				|| (iqentry_bs[15] == alu0_sourceid && alu0_dataready)
				|| (iqentry_bs[15] == alu1_sourceid && alu1_dataready))
			&& (iqentry_cv[15] 
				|| (iqentry_mem[15] & ~iqentry_agen[15])
				|| (iqentry_cs[15] == alu0_sourceid && alu0_dataready)
				|| (iqentry_cs[15] == alu1_sourceid && alu1_dataready));

wire [15:0] could_issue;
assign could_issue[0] = iqentry_v[0] && !iqentry_out[0] && !iqentry_agen[0] && args_valid[0];
assign could_issue[1] = iqentry_v[1] && !iqentry_out[1] && !iqentry_agen[1] && args_valid[1];
assign could_issue[2] = iqentry_v[2] && !iqentry_out[2] && !iqentry_agen[2] && args_valid[2];
assign could_issue[3] = iqentry_v[3] && !iqentry_out[3] && !iqentry_agen[3] && args_valid[3];
assign could_issue[4] = iqentry_v[4] && !iqentry_out[4] && !iqentry_agen[4] && args_valid[4];
assign could_issue[5] = iqentry_v[5] && !iqentry_out[5] && !iqentry_agen[5] && args_valid[5];
assign could_issue[6] = iqentry_v[6] && !iqentry_out[6] && !iqentry_agen[6] && args_valid[6];
assign could_issue[7] = iqentry_v[7] && !iqentry_out[7] && !iqentry_agen[7] && args_valid[7];
assign could_issue[8] = iqentry_v[8] && !iqentry_out[8] && !iqentry_agen[8] && args_valid[8];
assign could_issue[9] = iqentry_v[9] && !iqentry_out[9] && !iqentry_agen[9] && args_valid[9];
assign could_issue[10] = iqentry_v[10] && !iqentry_out[10] && !iqentry_agen[10] && args_valid[10];
assign could_issue[11] = iqentry_v[11] && !iqentry_out[11] && !iqentry_agen[11] && args_valid[11];
assign could_issue[12] = iqentry_v[12] && !iqentry_out[12] && !iqentry_agen[12] && args_valid[12];
assign could_issue[13] = iqentry_v[13] && !iqentry_out[13] && !iqentry_agen[13] && args_valid[13];
assign could_issue[14] = iqentry_v[14] && !iqentry_out[14] && !iqentry_agen[14] && args_valid[14];
assign could_issue[15] = iqentry_v[15] && !iqentry_out[15] && !iqentry_agen[15] && args_valid[15];

wire any_msb =
	   (iqentry_v[head0] && iqentry_op[head0]==`MEMSB)
	|| (iqentry_v[head1] && iqentry_op[head1]==`MEMSB)
	|| (iqentry_v[head2] && iqentry_op[head2]==`MEMSB)
	|| (iqentry_v[head3] && iqentry_op[head3]==`MEMSB)
	|| (iqentry_v[head4] && iqentry_op[head4]==`MEMSB)
	|| (iqentry_v[head5] && iqentry_op[head5]==`MEMSB)
	|| (iqentry_v[head6] && iqentry_op[head6]==`MEMSB)
	|| (iqentry_v[head7] && iqentry_op[head7]==`MEMSB)
	|| (iqentry_v[head8] && iqentry_op[head8]==`MEMSB)
	|| (iqentry_v[head9] && iqentry_op[head9]==`MEMSB)
	|| (iqentry_v[head10] && iqentry_op[head10]==`MEMSB)
	|| (iqentry_v[head11] && iqentry_op[head11]==`MEMSB)
	|| (iqentry_v[head12] && iqentry_op[head12]==`MEMSB)
	|| (iqentry_v[head13] && iqentry_op[head13]==`MEMSB)
	|| (iqentry_v[head14] && iqentry_op[head14]==`MEMSB)
	;

assign iqentry_issue[0] = (iqentry_v[0] && !iqentry_out[0] && !iqentry_agen[0]
			&& (head0 == 4'd0 || ~|iqentry_islot[15] || (iqentry_islot[15] == 2'b01 && ~iqentry_issue[15]))
			&& args_valid[0];
assign iqentry_islot[0] = (head0 == 4'd0) ? 2'b00
			: (iqentry_islot[15][1]) ? 2'b11
			: (iqentry_islot[15] + {1'b0, iqentry_issue[15]});

assign iqentry_issue[1] = (iqentry_v[1] && !iqentry_out[1] && !iqentry_agen[1]
			&& (head0 == 4'd1 || ~|iqentry_islot[0] || (iqentry_islot[0] == 2'b01 && ~iqentry_issue[0]))
			&& args_valid[1];
assign iqentry_islot[1] = (head0 == 4'd1) ? 2'b00
			: (iqentry_islot[0][1]) ? 2'b11
			: (iqentry_islot[0] + {1'b0, iqentry_issue[0]});

assign iqentry_issue[2] = (iqentry_v[2] && !iqentry_out[2] && !iqentry_agen[2]
			&& (head0 == 4'd2 || ~|iqentry_islot[1] || (iqentry_islot[1] == 2'b01 && ~iqentry_issue[1]))
			&& args_valid[2];
assign iqentry_islot[2] = (head0 == 4'd2) ? 2'b00
			: (iqentry_islot[1][1]) ? 2'b11
			: (iqentry_islot[1] + {1'b0, iqentry_issue[1]});

assign iqentry_issue[3] = (iqentry_v[3] && !iqentry_out[3] && !iqentry_agen[3]
			&& (head0 == 4'd3 || ~|iqentry_islot[2] || (iqentry_islot[2] == 2'b01 && ~iqentry_issue[2]))
			&& args_valid[3];
assign iqentry_islot[3] = (head0 == 4'd3) ? 2'b00
			: (iqentry_islot[2][1]) ? 2'b11
			: (iqentry_islot[2] + {1'b0, iqentry_issue[2]});

assign iqentry_issue[4] = (iqentry_v[4] && !iqentry_out[4] && !iqentry_agen[4]
			&& (head0 == 4'd4 || ~|iqentry_islot[3] || (iqentry_islot[3] == 2'b01 && ~iqentry_issue[3]))
			&& args_valid[4];
assign iqentry_islot[4] = (head0 == 4'd4) ? 2'b00
			: (iqentry_islot[3][1]) ? 2'b11
			: (iqentry_islot[3] + {1'b0, iqentry_issue[3]});

assign iqentry_issue[5] = (iqentry_v[5] && !iqentry_out[5] && !iqentry_agen[5]
			&& (head0 == 4'd5 || ~|iqentry_islot[4] || (iqentry_islot[4] == 2'b01 && ~iqentry_issue[4]))
			&& args_valid[5];
assign iqentry_islot[5] = (head0 == 4'd5) ? 2'b00
			: (iqentry_islot[4][1]) ? 2'b11
			: (iqentry_islot[4] + {1'b0, iqentry_issue[4]});

assign iqentry_issue[6] = (iqentry_v[6] && !iqentry_out[6] && !iqentry_agen[6]
			&& (head0 == 4'd6 || ~|iqentry_islot[5] || (iqentry_islot[5] == 2'b01 && ~iqentry_issue[5]))
			&& args_valid[6];
assign iqentry_islot[6] = (head0 == 4'd6) ? 2'b00
			: (iqentry_islot[5][1]) ? 2'b11
			: (iqentry_islot[5] + {1'b0, iqentry_issue[5]});

assign iqentry_issue[7] = (iqentry_v[7] && !iqentry_out[7] && !iqentry_agen[7]
			&& (head0 == 4'd7 || ~|iqentry_islot[6] || (iqentry_islot[6] == 2'b01 && ~iqentry_issue[6]))
			&& args_valid[7];
assign iqentry_islot[7] = (head0 == 4'd7) ? 2'b00
			: (iqentry_islot[6][1]) ? 2'b11
			: (iqentry_islot[6] + {1'b0, iqentry_issue[6]});

assign iqentry_issue[8] = (iqentry_v[8] && !iqentry_out[8] && !iqentry_agen[8]
			&& (head0 == 4'd8 || ~|iqentry_islot[7] || (iqentry_islot[7] == 2'b01 && ~iqentry_issue[7]))
			&& args_valid[8];
assign iqentry_islot[8] = (head0 == 4'd8) ? 2'b00
			: (iqentry_islot[7][1]) ? 2'b11
			: (iqentry_islot[7] + {1'b0, iqentry_issue[7]});

assign iqentry_issue[9] = (iqentry_v[9] && !iqentry_out[9] && !iqentry_agen[9]
			&& (head0 == 4'd9 || ~|iqentry_islot[8] || (iqentry_islot[8] == 2'b01 && ~iqentry_issue[8]))
			&& args_valid[9];
assign iqentry_islot[9] = (head0 == 4'd9) ? 2'b00
			: (iqentry_islot[8][1]) ? 2'b11
			: (iqentry_islot[8] + {1'b0, iqentry_issue[8]});

assign iqentry_issue[10] = (iqentry_v[10] && !iqentry_out[10] && !iqentry_agen[10]
			&& (head0 == 4'd10 || ~|iqentry_islot[9] || (iqentry_islot[9] == 2'b01 && ~iqentry_issue[9]))
			&& args_valid[10];
assign iqentry_islot[10] = (head0 == 4'd10) ? 2'b00
			: (iqentry_islot[9][1]) ? 2'b11
			: (iqentry_islot[9] + {1'b0, iqentry_issue[9]});

assign iqentry_issue[11] = (iqentry_v[11] && !iqentry_out[11] && !iqentry_agen[11]
			&& (head0 == 4'd11 || ~|iqentry_islot[10] || (iqentry_islot[10] == 2'b01 && ~iqentry_issue[10]))
			&& args_valid[11];
assign iqentry_islot[11] = (head0 == 4'd11) ? 2'b00
			: (iqentry_islot[10][1]) ? 2'b11
			: (iqentry_islot[10] + {1'b0, iqentry_issue[10]});

assign iqentry_issue[12] = (iqentry_v[12] && !iqentry_out[12] && !iqentry_agen[12]
			&& (head0 == 4'd12 || ~|iqentry_islot[11] || (iqentry_islot[11] == 2'b01 && ~iqentry_issue[11]))
			&& args_valid[12];
assign iqentry_islot[12] = (head0 == 4'd12) ? 2'b00
			: (iqentry_islot[11][1]) ? 2'b11
			: (iqentry_islot[11] + {1'b0, iqentry_issue[11]});

assign iqentry_issue[13] = (iqentry_v[13] && !iqentry_out[13] && !iqentry_agen[13]
			&& (head0 == 4'd13 || ~|iqentry_islot[12] || (iqentry_islot[12] == 2'b01 && ~iqentry_issue[12]))
			&& args_valid[13];
assign iqentry_islot[13] = (head0 == 4'd13) ? 2'b00
			: (iqentry_islot[12][1]) ? 2'b11
			: (iqentry_islot[12] + {1'b0, iqentry_issue[12]});

assign iqentry_issue[14] = (iqentry_v[14] && !iqentry_out[14] && !iqentry_agen[14]
			&& (head0 == 4'd14 || ~|iqentry_islot[13] || (iqentry_islot[13] == 2'b01 && ~iqentry_issue[13]))
			&& args_valid[14];
assign iqentry_islot[14] = (head0 == 4'd14) ? 2'b00
			: (iqentry_islot[13][1]) ? 2'b11
			: (iqentry_islot[13] + {1'b0, iqentry_issue[13]});

assign iqentry_issue[15] = (iqentry_v[15] && !iqentry_out[15] && !iqentry_agen[15]
			&& (head0 == 4'd15 || ~|iqentry_islot[14] || (iqentry_islot[14] == 2'b01 && ~iqentry_issue[14]))
			&& args_valid[15];
assign iqentry_islot[15] = (head0 == 4'd15) ? 2'b00
			: (iqentry_islot[14][1]) ? 2'b11
			: (iqentry_islot[14] + {1'b0, iqentry_issue[14]});


assign iqentry_LdIssue[0] = (iqentry_LdReady[0]
			&& (head0 == 4'd0 || ~|iqentry_Ldislot[15] || (iqentry_Ldislot[15] == 2'b01 && ~iqentry_LdIssue[15]));
assign iqentry_Ldislot[0] = (head0 == 4'd0) ? 2'b00
			: (iqentry_Ldislot[15][1]) ? 2'b11
			: (iqentry_LDislot[15] + {1'b0, iqentry_LdIssue[15]});

assign iqentry_LdIssue[1] = (iqentry_LdReady[1]
			&& (head0 == 4'd1 || ~|iqentry_Ldislot[0] || (iqentry_Ldislot[0] == 2'b01 && ~iqentry_LdIssue[0]));
assign iqentry_Ldislot[1] = (head0 == 4'd1) ? 2'b00
			: (iqentry_Ldislot[0][1]) ? 2'b11
			: (iqentry_LDislot[0] + {1'b0, iqentry_LdIssue[0]});

assign iqentry_LdIssue[2] = (iqentry_LdReady[2]
			&& (head0 == 4'd2 || ~|iqentry_Ldislot[1] || (iqentry_Ldislot[1] == 2'b01 && ~iqentry_LdIssue[1]));
assign iqentry_Ldislot[2] = (head0 == 4'd2) ? 2'b00
			: (iqentry_Ldislot[1][1]) ? 2'b11
			: (iqentry_LDislot[1] + {1'b0, iqentry_LdIssue[1]});

assign iqentry_LdIssue[3] = (iqentry_LdReady[3]
			&& (head0 == 4'd3 || ~|iqentry_Ldislot[2] || (iqentry_Ldislot[2] == 2'b01 && ~iqentry_LdIssue[2]));
assign iqentry_Ldislot[3] = (head0 == 4'd3) ? 2'b00
			: (iqentry_Ldislot[2][1]) ? 2'b11
			: (iqentry_LDislot[2] + {1'b0, iqentry_LdIssue[2]});

assign iqentry_LdIssue[4] = (iqentry_LdReady[4]
			&& (head0 == 4'd4 || ~|iqentry_Ldislot[3] || (iqentry_Ldislot[3] == 2'b01 && ~iqentry_LdIssue[3]));
assign iqentry_Ldislot[4] = (head0 == 4'd4) ? 2'b00
			: (iqentry_Ldislot[3][1]) ? 2'b11
			: (iqentry_LDislot[3] + {1'b0, iqentry_LdIssue[3]});

assign iqentry_LdIssue[5] = (iqentry_LdReady[5]
			&& (head0 == 4'd5 || ~|iqentry_Ldislot[4] || (iqentry_Ldislot[4] == 2'b01 && ~iqentry_LdIssue[4]));
assign iqentry_Ldislot[5] = (head0 == 4'd5) ? 2'b00
			: (iqentry_Ldislot[4][1]) ? 2'b11
			: (iqentry_LDislot[4] + {1'b0, iqentry_LdIssue[4]});

assign iqentry_LdIssue[6] = (iqentry_LdReady[6]
			&& (head0 == 4'd6 || ~|iqentry_Ldislot[5] || (iqentry_Ldislot[5] == 2'b01 && ~iqentry_LdIssue[5]));
assign iqentry_Ldislot[6] = (head0 == 4'd6) ? 2'b00
			: (iqentry_Ldislot[5][1]) ? 2'b11
			: (iqentry_LDislot[5] + {1'b0, iqentry_LdIssue[5]});

assign iqentry_LdIssue[7] = (iqentry_LdReady[7]
			&& (head0 == 4'd7 || ~|iqentry_Ldislot[6] || (iqentry_Ldislot[6] == 2'b01 && ~iqentry_LdIssue[6]));
assign iqentry_Ldislot[7] = (head0 == 4'd7) ? 2'b00
			: (iqentry_Ldislot[6][1]) ? 2'b11
			: (iqentry_LDislot[6] + {1'b0, iqentry_LdIssue[6]});

assign iqentry_LdIssue[8] = (iqentry_LdReady[8]
			&& (head0 == 4'd8 || ~|iqentry_Ldislot[7] || (iqentry_Ldislot[7] == 2'b01 && ~iqentry_LdIssue[7]));
assign iqentry_Ldislot[8] = (head0 == 4'd8) ? 2'b00
			: (iqentry_Ldislot[7][1]) ? 2'b11
			: (iqentry_LDislot[7] + {1'b0, iqentry_LdIssue[7]});

assign iqentry_LdIssue[9] = (iqentry_LdReady[9]
			&& (head0 == 4'd9 || ~|iqentry_Ldislot[8] || (iqentry_Ldislot[8] == 2'b01 && ~iqentry_LdIssue[8]));
assign iqentry_Ldislot[9] = (head0 == 4'd9) ? 2'b00
			: (iqentry_Ldislot[8][1]) ? 2'b11
			: (iqentry_LDislot[8] + {1'b0, iqentry_LdIssue[8]});

assign iqentry_LdIssue[10] = (iqentry_LdReady[10]
			&& (head0 == 4'd10 || ~|iqentry_Ldislot[9] || (iqentry_Ldislot[9] == 2'b01 && ~iqentry_LdIssue[9]));
assign iqentry_Ldislot[10] = (head0 == 4'd10) ? 2'b00
			: (iqentry_Ldislot[9][1]) ? 2'b11
			: (iqentry_LDislot[9] + {1'b0, iqentry_LdIssue[9]});

assign iqentry_LdIssue[11] = (iqentry_LdReady[11]
			&& (head0 == 4'd11 || ~|iqentry_Ldislot[10] || (iqentry_Ldislot[10] == 2'b01 && ~iqentry_LdIssue[10]));
assign iqentry_Ldislot[11] = (head0 == 4'd11) ? 2'b00
			: (iqentry_Ldislot[10][1]) ? 2'b11
			: (iqentry_LDislot[10] + {1'b0, iqentry_LdIssue[10]});

assign iqentry_LdIssue[12] = (iqentry_LdReady[12]
			&& (head0 == 4'd12 || ~|iqentry_Ldislot[11] || (iqentry_Ldislot[11] == 2'b01 && ~iqentry_LdIssue[11]));
assign iqentry_Ldislot[12] = (head0 == 4'd12) ? 2'b00
			: (iqentry_Ldislot[11][1]) ? 2'b11
			: (iqentry_LDislot[11] + {1'b0, iqentry_LdIssue[11]});

assign iqentry_LdIssue[13] = (iqentry_LdReady[13]
			&& (head0 == 4'd13 || ~|iqentry_Ldislot[12] || (iqentry_Ldislot[12] == 2'b01 && ~iqentry_LdIssue[12]));
assign iqentry_Ldislot[13] = (head0 == 4'd13) ? 2'b00
			: (iqentry_Ldislot[12][1]) ? 2'b11
			: (iqentry_LDislot[12] + {1'b0, iqentry_LdIssue[12]});

assign iqentry_LdIssue[14] = (iqentry_LdReady[14]
			&& (head0 == 4'd14 || ~|iqentry_Ldislot[13] || (iqentry_Ldislot[13] == 2'b01 && ~iqentry_LdIssue[13]));
assign iqentry_Ldislot[14] = (head0 == 4'd14) ? 2'b00
			: (iqentry_Ldislot[13][1]) ? 2'b11
			: (iqentry_LDislot[13] + {1'b0, iqentry_LdIssue[13]});

assign iqentry_LdIssue[15] = (iqentry_LdReady[15]
			&& (head0 == 4'd15 || ~|iqentry_Ldislot[14] || (iqentry_Ldislot[14] == 2'b01 && ~iqentry_LdIssue[14]));
assign iqentry_Ldislot[15] = (head0 == 4'd15) ? 2'b00
			: (iqentry_Ldislot[14][1]) ? 2'b11
			: (iqentry_LDislot[14] + {1'b0, iqentry_LdIssue[14]});

/*
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
*/

assign stomp_all = fnIsStoreString(iqentry_op[head0]) && int_pending;

// 
// additional logic for handling a branch miss (STOMP logic)
//
assign
	iqentry_stomp[0] = stomp_all || (branchmiss && iqentry_v[0] && head0 != 4'd0 && (missid == 4'd15 || iqentry_stomp[15])),
	iqentry_stomp[1] = stomp_all || (branchmiss && iqentry_v[1] && head0 != 4'd1 && (missid == 4'd0 || iqentry_stomp[0])),
	iqentry_stomp[2] = stomp_all || (branchmiss && iqentry_v[2] && head0 != 4'd2 && (missid == 4'd1 || iqentry_stomp[1])),
	iqentry_stomp[3] = stomp_all || (branchmiss && iqentry_v[3] && head0 != 4'd3 && (missid == 4'd2 || iqentry_stomp[2])),
	iqentry_stomp[4] = stomp_all || (branchmiss && iqentry_v[4] && head0 != 4'd4 && (missid == 4'd3 || iqentry_stomp[3])),
	iqentry_stomp[5] = stomp_all || (branchmiss && iqentry_v[5] && head0 != 4'd5 && (missid == 4'd4 || iqentry_stomp[4])),
	iqentry_stomp[6] = stomp_all || (branchmiss && iqentry_v[6] && head0 != 4'd6 && (missid == 4'd5 || iqentry_stomp[5])),
	iqentry_stomp[7] = stomp_all || (branchmiss && iqentry_v[7] && head0 != 4'd7 && (missid == 4'd6 || iqentry_stomp[6])),
	iqentry_stomp[8] = stomp_all || (branchmiss && iqentry_v[8] && head0 != 4'd8 && (missid == 4'd7 || iqentry_stomp[7])),
	iqentry_stomp[9] = stomp_all || (branchmiss && iqentry_v[9] && head0 != 4'd9 && (missid == 4'd8 || iqentry_stomp[8])),
	iqentry_stomp[10] = stomp_all || (branchmiss && iqentry_v[10] && head0 != 4'd10 && (missid == 4'd9 || iqentry_stomp[9])),
	iqentry_stomp[11] = stomp_all || (branchmiss && iqentry_v[11] && head0 != 4'd11 && (missid == 4'd10 || iqentry_stomp[10])),
	iqentry_stomp[12] = stomp_all || (branchmiss && iqentry_v[12] && head0 != 4'd12 && (missid == 4'd11 || iqentry_stomp[11])),
	iqentry_stomp[13] = stomp_all || (branchmiss && iqentry_v[13] && head0 != 4'd13 && (missid == 4'd12 || iqentry_stomp[12])),
	iqentry_stomp[14] = stomp_all || (branchmiss && iqentry_v[14] && head0 != 4'd14 && (missid == 4'd13 || iqentry_stomp[13])),
	iqentry_stomp[15] = stomp_all || (branchmiss && iqentry_v[15] && head0 != 4'd15 && (missid == 4'd14 || iqentry_stomp[14]));

assign alu0_issue =
			(!(iqentry_v[0] && iqentry_stomp[0]) && iqentry_issue[0] && iqentry_islot[0]==2'd0) ||
			(!(iqentry_v[1] && iqentry_stomp[1]) && iqentry_issue[1] && iqentry_islot[1]==2'd0) ||
			(!(iqentry_v[2] && iqentry_stomp[2]) && iqentry_issue[2] && iqentry_islot[2]==2'd0) ||
			(!(iqentry_v[3] && iqentry_stomp[3]) && iqentry_issue[3] && iqentry_islot[3]==2'd0) ||
			(!(iqentry_v[4] && iqentry_stomp[4]) && iqentry_issue[4] && iqentry_islot[4]==2'd0) ||
			(!(iqentry_v[5] && iqentry_stomp[5]) && iqentry_issue[5] && iqentry_islot[5]==2'd0) ||
			(!(iqentry_v[6] && iqentry_stomp[6]) && iqentry_issue[6] && iqentry_islot[6]==2'd0) ||
			(!(iqentry_v[7] && iqentry_stomp[7]) && iqentry_issue[7] && iqentry_islot[7]==2'd0) ||
			(!(iqentry_v[8] && iqentry_stomp[8]) && iqentry_issue[8] && iqentry_islot[8]==2'd0) ||
			(!(iqentry_v[9] && iqentry_stomp[9]) && iqentry_issue[9] && iqentry_islot[9]==2'd0) ||
			(!(iqentry_v[10] && iqentry_stomp[10]) && iqentry_issue[10] && iqentry_islot[10]==2'd0) ||
			(!(iqentry_v[11] && iqentry_stomp[11]) && iqentry_issue[11] && iqentry_islot[11]==2'd0) ||
			(!(iqentry_v[12] && iqentry_stomp[12]) && iqentry_issue[12] && iqentry_islot[12]==2'd0) ||
			(!(iqentry_v[13] && iqentry_stomp[13]) && iqentry_issue[13] && iqentry_islot[13]==2'd0) ||
			(!(iqentry_v[14] && iqentry_stomp[14]) && iqentry_issue[14] && iqentry_islot[14]==2'd0) ||
			(!(iqentry_v[15] && iqentry_stomp[15]) && iqentry_issue[15] && iqentry_islot[15]==2'd0)
			;

assign alu1_issue = 
			(!(iqentry_v[0] && iqentry_stomp[0]) && iqentry_issue[0] && iqentry_islot[0]==2'd1) ||
			(!(iqentry_v[1] && iqentry_stomp[1]) && iqentry_issue[1] && iqentry_islot[1]==2'd1) ||
			(!(iqentry_v[2] && iqentry_stomp[2]) && iqentry_issue[2] && iqentry_islot[2]==2'd1) ||
			(!(iqentry_v[3] && iqentry_stomp[3]) && iqentry_issue[3] && iqentry_islot[3]==2'd1) ||
			(!(iqentry_v[4] && iqentry_stomp[4]) && iqentry_issue[4] && iqentry_islot[4]==2'd1) ||
			(!(iqentry_v[5] && iqentry_stomp[5]) && iqentry_issue[5] && iqentry_islot[5]==2'd1) ||
			(!(iqentry_v[6] && iqentry_stomp[6]) && iqentry_issue[6] && iqentry_islot[6]==2'd1) ||
			(!(iqentry_v[7] && iqentry_stomp[7]) && iqentry_issue[7] && iqentry_islot[7]==2'd1) ||
			(!(iqentry_v[8] && iqentry_stomp[8]) && iqentry_issue[8] && iqentry_islot[8]==2'd1) ||
			(!(iqentry_v[9] && iqentry_stomp[9]) && iqentry_issue[9] && iqentry_islot[9]==2'd1) ||
			(!(iqentry_v[10] && iqentry_stomp[10]) && iqentry_issue[10] && iqentry_islot[10]==2'd1) ||
			(!(iqentry_v[11] && iqentry_stomp[11]) && iqentry_issue[11] && iqentry_islot[11]==2'd1) ||
			(!(iqentry_v[12] && iqentry_stomp[12]) && iqentry_issue[12] && iqentry_islot[12]==2'd1) ||
			(!(iqentry_v[13] && iqentry_stomp[13]) && iqentry_issue[13] && iqentry_islot[13]==2'd1) ||
			(!(iqentry_v[14] && iqentry_stomp[14]) && iqentry_issue[14] && iqentry_islot[14]==2'd1) ||
			(!(iqentry_v[15] && iqentry_stomp[15]) && iqentry_issue[15] && iqentry_islot[15]==2'd1)
			;

`ifdef FLOATING_POINT
assign fp0_issue =
			(!(iqentry_v[0] && iqentry_stomp[0]) && iqentry_fpissue[0] && iqentry_islot[0]==2'd0) ||
			(!(iqentry_v[1] && iqentry_stomp[1]) && iqentry_fpissue[1] && iqentry_islot[1]==2'd0) ||
			(!(iqentry_v[2] && iqentry_stomp[2]) && iqentry_fpissue[2] && iqentry_islot[2]==2'd0) ||
			(!(iqentry_v[3] && iqentry_stomp[3]) && iqentry_fpissue[3] && iqentry_islot[3]==2'd0) ||
			(!(iqentry_v[4] && iqentry_stomp[4]) && iqentry_fpissue[4] && iqentry_islot[4]==2'd0) ||
			(!(iqentry_v[5] && iqentry_stomp[5]) && iqentry_fpissue[5] && iqentry_islot[5]==2'd0) ||
			(!(iqentry_v[6] && iqentry_stomp[6]) && iqentry_fpissue[6] && iqentry_islot[6]==2'd0) ||
			(!(iqentry_v[7] && iqentry_stomp[7]) && iqentry_fpissue[7] && iqentry_islot[7]==2'd0) ||
			(!(iqentry_v[8] && iqentry_stomp[8]) && iqentry_fpissue[8] && iqentry_islot[8]==2'd0) ||
			(!(iqentry_v[9] && iqentry_stomp[9]) && iqentry_fpissue[9] && iqentry_islot[9]==2'd0) ||
			(!(iqentry_v[10] && iqentry_stomp[10]) && iqentry_fpissue[10] && iqentry_islot[10]==2'd0) ||
			(!(iqentry_v[11] && iqentry_stomp[11]) && iqentry_fpissue[11] && iqentry_islot[11]==2'd0) ||
			(!(iqentry_v[12] && iqentry_stomp[12]) && iqentry_fpissue[12] && iqentry_islot[12]==2'd0) ||
			(!(iqentry_v[13] && iqentry_stomp[13]) && iqentry_fpissue[13] && iqentry_islot[13]==2'd0) ||
			(!(iqentry_v[14] && iqentry_stomp[14]) && iqentry_fpissue[14] && iqentry_islot[14]==2'd0) ||
			(!(iqentry_v[15] && iqentry_stomp[15]) && iqentry_fpissue[15] && iqentry_islot[15]==2'd0)
			;
`endif

assign ld0_issue =
			(!(iqentry_v[0] && iqentry_stomp[0]) && iqentry_LdIssue[0] && iqentry_Ldislot[0]==2'd0) ||
			(!(iqentry_v[1] && iqentry_stomp[1]) && iqentry_LdIssue[1] && iqentry_Ldislot[1]==2'd0) ||
			(!(iqentry_v[2] && iqentry_stomp[2]) && iqentry_LdIssue[2] && iqentry_Ldislot[2]==2'd0) ||
			(!(iqentry_v[3] && iqentry_stomp[3]) && iqentry_LdIssue[3] && iqentry_Ldislot[3]==2'd0) ||
			(!(iqentry_v[4] && iqentry_stomp[4]) && iqentry_LdIssue[4] && iqentry_Ldislot[4]==2'd0) ||
			(!(iqentry_v[5] && iqentry_stomp[5]) && iqentry_LdIssue[5] && iqentry_Ldislot[5]==2'd0) ||
			(!(iqentry_v[6] && iqentry_stomp[6]) && iqentry_LdIssue[6] && iqentry_Ldislot[6]==2'd0) ||
			(!(iqentry_v[7] && iqentry_stomp[7]) && iqentry_LdIssue[7] && iqentry_Ldislot[7]==2'd0) ||
			(!(iqentry_v[8] && iqentry_stomp[8]) && iqentry_LdIssue[8] && iqentry_Ldislot[8]==2'd0) ||
			(!(iqentry_v[9] && iqentry_stomp[9]) && iqentry_LdIssue[9] && iqentry_Ldislot[9]==2'd0) ||
			(!(iqentry_v[10] && iqentry_stomp[10]) && iqentry_LdIssue[10] && iqentry_Ldislot[10]==2'd0) ||
			(!(iqentry_v[11] && iqentry_stomp[11]) && iqentry_LdIssue[11] && iqentry_Ldislot[11]==2'd0) ||
			(!(iqentry_v[12] && iqentry_stomp[12]) && iqentry_LdIssue[12] && iqentry_Ldislot[12]==2'd0) ||
			(!(iqentry_v[13] && iqentry_stomp[13]) && iqentry_LdIssue[13] && iqentry_Ldislot[13]==2'd0) ||
			(!(iqentry_v[14] && iqentry_stomp[14]) && iqentry_LdIssue[14] && iqentry_Ldislot[14]==2'd0) ||
			(!(iqentry_v[15] && iqentry_stomp[15]) && iqentry_LdIssue[15] && iqentry_Ldislot[15]==2'd0)
			;
assign ld1_issue =
			(!(iqentry_v[0] && iqentry_stomp[0]) && iqentry_LdIssue[0] && iqentry_Ldislot[0]==2'd1) ||
			(!(iqentry_v[1] && iqentry_stomp[1]) && iqentry_LdIssue[1] && iqentry_Ldislot[1]==2'd1) ||
			(!(iqentry_v[2] && iqentry_stomp[2]) && iqentry_LdIssue[2] && iqentry_Ldislot[2]==2'd1) ||
			(!(iqentry_v[3] && iqentry_stomp[3]) && iqentry_LdIssue[3] && iqentry_Ldislot[3]==2'd1) ||
			(!(iqentry_v[4] && iqentry_stomp[4]) && iqentry_LdIssue[4] && iqentry_Ldislot[4]==2'd1) ||
			(!(iqentry_v[5] && iqentry_stomp[5]) && iqentry_LdIssue[5] && iqentry_Ldislot[5]==2'd1) ||
			(!(iqentry_v[6] && iqentry_stomp[6]) && iqentry_LdIssue[6] && iqentry_Ldislot[6]==2'd1) ||
			(!(iqentry_v[7] && iqentry_stomp[7]) && iqentry_LdIssue[7] && iqentry_Ldislot[7]==2'd1) ||
			(!(iqentry_v[8] && iqentry_stomp[8]) && iqentry_LdIssue[8] && iqentry_Ldislot[8]==2'd1) ||
			(!(iqentry_v[9] && iqentry_stomp[9]) && iqentry_LdIssue[9] && iqentry_Ldislot[9]==2'd1) ||
			(!(iqentry_v[10] && iqentry_stomp[10]) && iqentry_LdIssue[10] && iqentry_Ldislot[10]==2'd1) ||
			(!(iqentry_v[11] && iqentry_stomp[11]) && iqentry_LdIssue[11] && iqentry_Ldislot[11]==2'd1) ||
			(!(iqentry_v[12] && iqentry_stomp[12]) && iqentry_LdIssue[12] && iqentry_Ldislot[12]==2'd1) ||
			(!(iqentry_v[13] && iqentry_stomp[13]) && iqentry_LdIssue[13] && iqentry_Ldislot[13]==2'd1) ||
			(!(iqentry_v[14] && iqentry_stomp[14]) && iqentry_LdIssue[14] && iqentry_Ldislot[14]==2'd1) ||
			(!(iqentry_v[15] && iqentry_stomp[15]) && iqentry_LdIssue[15] && iqentry_Ldislot[15]==2'd1)
			;

