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
// Memory combinational logic
//
// ============================================================================
//
//
// additional DRAM-enqueue logic

Thor_TLB #(DBW) utlb1
(
	.rst(rst_i),
	.clk(clk),
	.km(km),
	.pc(spc),
	.ea(dram0_addr),
	.ppc(ppc),
	.pea(pea),
	.iuncached(iuncached),
	.uncached(uncached),
	.m1IsStore(we_o),
	.ASID(asid),
	.op(tlb_op),
	.state(tlb_state),
	.regno(tlb_regno),
	.dati(tlb_data),
	.dato(tlb_dato),
	.ITLBMiss(ITLBMiss),
	.DTLBMiss(DTLBMiss),
	.HTLBVirtPageo()
);
	
assign dram_avail = (dram0 == `DRAMSLOT_AVAIL || dram1 == `DRAMSLOT_AVAIL || dram2 == `DRAMSLOT_AVAIL);

assign  iqentry_memopsvalid[0] = (iqentry_mem[0] & iqentry_a2_v[0] & iqentry_agen[0]),
	iqentry_memopsvalid[1] = (iqentry_mem[1] & iqentry_a2_v[1] & iqentry_agen[1]),
	iqentry_memopsvalid[2] = (iqentry_mem[2] & iqentry_a2_v[2] & iqentry_agen[2]),
	iqentry_memopsvalid[3] = (iqentry_mem[3] & iqentry_a2_v[3] & iqentry_agen[3]),
	iqentry_memopsvalid[4] = (iqentry_mem[4] & iqentry_a2_v[4] & iqentry_agen[4]),
	iqentry_memopsvalid[5] = (iqentry_mem[5] & iqentry_a2_v[5] & iqentry_agen[5]),
	iqentry_memopsvalid[6] = (iqentry_mem[6] & iqentry_a2_v[6] & iqentry_agen[6]),
	iqentry_memopsvalid[7] = (iqentry_mem[7] & iqentry_a2_v[7] & iqentry_agen[7]);

assign  iqentry_memready[0] = (iqentry_v[0] & iqentry_memopsvalid[0] & ~iqentry_memissue[0] & ~iqentry_done[0] & ~iqentry_out[0] & ~iqentry_stomp[0]),
	iqentry_memready[1] = (iqentry_v[1] & iqentry_memopsvalid[1] & ~iqentry_memissue[1] & ~iqentry_done[1] & ~iqentry_out[1] & ~iqentry_stomp[1]),
	iqentry_memready[2] = (iqentry_v[2] & iqentry_memopsvalid[2] & ~iqentry_memissue[2] & ~iqentry_done[2] & ~iqentry_out[2] & ~iqentry_stomp[2]),
	iqentry_memready[3] = (iqentry_v[3] & iqentry_memopsvalid[3] & ~iqentry_memissue[3] & ~iqentry_done[3] & ~iqentry_out[3] & ~iqentry_stomp[3]),
	iqentry_memready[4] = (iqentry_v[4] & iqentry_memopsvalid[4] & ~iqentry_memissue[4] & ~iqentry_done[4] & ~iqentry_out[4] & ~iqentry_stomp[4]),
	iqentry_memready[5] = (iqentry_v[5] & iqentry_memopsvalid[5] & ~iqentry_memissue[5] & ~iqentry_done[5] & ~iqentry_out[5] & ~iqentry_stomp[5]),
	iqentry_memready[6] = (iqentry_v[6] & iqentry_memopsvalid[6] & ~iqentry_memissue[6] & ~iqentry_done[6] & ~iqentry_out[6] & ~iqentry_stomp[6]),
	iqentry_memready[7] = (iqentry_v[7] & iqentry_memopsvalid[7] & ~iqentry_memissue[7] & ~iqentry_done[7] & ~iqentry_out[7] & ~iqentry_stomp[7]);

assign outstanding_stores = (dram0 && fnIsStore(dram0_op)) || (dram1 && fnIsStore(dram1_op)) || (dram2 && fnIsStore(dram2_op));

// This signal needed to stave off an instruction cache access.
assign mem_will_issue =
	(
	(~iqentry_stomp[0] && iqentry_memissue[0] && iqentry_agen[0] && ~iqentry_out[0] && iqentry_cmt[0] && ihit) ||
	(~iqentry_stomp[1] && iqentry_memissue[1] && iqentry_agen[1] && ~iqentry_out[1] && iqentry_cmt[1] && ihit) ||
	(~iqentry_stomp[2] && iqentry_memissue[2] && iqentry_agen[2] && ~iqentry_out[2] && iqentry_cmt[2] && ihit) ||
	(~iqentry_stomp[3] && iqentry_memissue[3] && iqentry_agen[3] && ~iqentry_out[3] && iqentry_cmt[3] && ihit) ||
	(~iqentry_stomp[4] && iqentry_memissue[4] && iqentry_agen[4] && ~iqentry_out[4] && iqentry_cmt[4] && ihit) ||
	(~iqentry_stomp[5] && iqentry_memissue[5] && iqentry_agen[5] && ~iqentry_out[5] && iqentry_cmt[5] && ihit) ||
	(~iqentry_stomp[6] && iqentry_memissue[6] && iqentry_agen[6] && ~iqentry_out[6] && iqentry_cmt[6] && ihit) ||
	(~iqentry_stomp[7] && iqentry_memissue[7] && iqentry_agen[7] && ~iqentry_out[7] && iqentry_cmt[7] && ihit))
	&& (dram0 == 3'd0 || dram1==3'd0 || dram2==3'd0)
	;

