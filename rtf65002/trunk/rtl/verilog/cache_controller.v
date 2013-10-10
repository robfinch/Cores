// ============================================================================
//        __
//   \\__/ o\    (C) 2013  Robert Finch, Stratford
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
// Cache controller
// Also takes care of loading the instruction buffer for non-cached access
//

//IDLE:
//	begin
//		if (!cyc_o) begin
//`ifdef SUPPORT_DCACHE
//			// A write to a cacheable address does not cause a cache load
//			if (dmiss) begin
//				isDataCacheLoad <= `TRUE;
//				if (isRMW)
//					lock_o <= 1'b1;
//				cti_o <= 3'b001;
//				bl_o <= 6'd3;
//				cyc_o <= 1'b1;
//				stb_o <= 1'b1;
//				sel_o <= 4'hF;
//				adr_o <= {radr[31:2],4'h0};
//				cstate <= LOAD_DCACHE;
//			end
//			else
//`endif
//`ifdef SUPPORT_ICACHE
//			if (!unCachedInsn && imiss && !hit0) begin
//				isInsnCacheLoad <= `TRUE;
//				bte_o <= 2'b00;
//				cti_o <= 3'd001;
//				bl_o <= 6'd3;
//				cyc_o <= 1'b1;
//				stb_o <= 1'b1;
//				sel_o <= 4'hF;
//				adr_o <= {pc[31:4],4'h0};
//				cstate <= LOAD_ICACHE;
//			end
//			else if (!unCachedInsn && imiss && !hit1) begin
//				isInsnCacheLoad <= `TRUE;
//				bte_o <= 2'b00;
//				cti_o <= 3'd001;
//				bl_o <= 6'd3;
//				cyc_o <= 1'b1;
//				stb_o <= 1'b1;
//				sel_o <= 4'hF;
//				adr_o <= {pcp8[31:4],4'h0};
//				cstate <= LOAD_ICACHE;
//			end
//			else 
//`endif
//			if (unCachedInsn && imiss) begin
//				bte_o <= 2'b00;
//				cti_o <= 3'b001;
//				bl_o <= 6'd2;
//				cyc_o <= 1'b1;
//				stb_o <= 1'b1;
//				sel_o <= 4'hf;
//				adr_o <= {pc[31:2],2'b00};
//				cstate <= LOAD_IBUF1;
//			end
//		end
//	end


`ifdef SUPPORT_DCACHE
DCACHE1:
	begin
		isDataCacheLoad <= `TRUE;
		if (isRMW)
			lock_o <= 1'b1;
		cti_o <= 3'b001;
		bl_o <= 6'd3;
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 4'hF;
		adr_o <= {radr[31:2],4'h0};
		state <= LOAD_DCACHE;
	end
LOAD_DCACHE:
	if (ack_i) begin
		if (adr_o[3:2]==2'b11) begin
			dmiss <= `FALSE;
			isDataCacheLoad <= `FALSE;
			cti_o <= 3'b000;
			bl_o <= 6'd0;
			cyc_o <= 1'b0;
			stb_o <= 1'b0;
			sel_o <= 4'h0;
			adr_o <= 34'h0;
			state <= retstate;
		end
		adr_o[3:2] <= adr_o[3:2] + 2'd1;
	end
`ifdef SUPPORT_BERR
	else if (err_i) begin
		if (adr_o[3:2]==2'b11) begin
			dmiss <= `FALSE;
			isDataCacheLoad <= `FALSE;
			cti_o <= 3'b000;
			bl_o <= 6'd0;
			cyc_o <= 1'b0;
			stb_o <= 1'b0;
			sel_o <= 4'h0;
			adr_o <= 34'h0;
			// The state machine will be waiting for a dhit.
			// Override the next state and send the processor to the bus error state.
			state <= BUS_ERROR;
		end
		adr_o[3:2] <= adr_o[3:2] + 2'd1;
	end
`endif
`endif
`ifdef SUPPORT_ICACHE
ICACHE1:
	if (!hit0) begin
		isInsnCacheLoad <= `TRUE;
		bte_o <= 2'b00;
		cti_o <= 3'b001;
		bl_o <= 6'd3;
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 4'hF;
		adr_o <= {pc[31:4],4'h0};
		state <= LOAD_ICACHE;
	end
	else if (!hit1) begin
		isInsnCacheLoad <= `TRUE;
		bte_o <= 2'b00;
		cti_o <= 3'b001;
		bl_o <= 6'd3;
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 4'hF;
		adr_o <= {pcp8[31:4],4'h0};
		state <= LOAD_ICACHE;
	end
	else
		state <= em ? BYTE_IFETCH : IFETCH;
LOAD_ICACHE:
	if (ack_i) begin
		if (adr_o[3:2]==2'b11) begin
			isInsnCacheLoad <= `FALSE;
			cti_o <= 3'b000;
			bl_o <= 6'd0;
			cyc_o <= 1'b0;
			stb_o <= 1'b0;
			sel_o <= 4'h0;
			adr_o <= 34'd0;
`ifdef ICACHE_2WAY
			clfsr <= {clfsr,clfsr_fb};
`endif
			state <= ICACHE1;
		end
		adr_o[3:2] <= adr_o[3:2] + 2'd1;
	end
`ifdef SUPPORT_BERR
	else if (err_i) begin
		if (adr_o[3:2]==2'b11) begin
			isInsnCacheLoad <= `FALSE;
			cti_o <= 3'b000;
			bl_o <= 6'd0;
			cyc_o <= 1'b0;
			stb_o <= 1'b0;
			sel_o <= 4'h0;
			adr_o <= 34'd0;
			state <= INSN_BUS_ERROR;
`ifdef ICACHE_2WAY
			clfsr <= {clfsr,clfsr_fb};
`endif
		end
		adr_o[3:2] <= adr_o[3:2] + 2'd1;
	end
`endif
`endif
//IBUF1:
//	begin
//		bte_o <= 2'b00;
//		cti_o <= 3'b001;
//		bl_o <= 6'd2;
//		cyc_o <= 1'b1;
//		stb_o <= 1'b1;
//		sel_o <= 4'hf;
//		adr_o <= {pc[31:2],2'b00};
//		state <= LOAD_IBUF1;
//	end
LOAD_IBUF1:
	if (!cyc_o) begin
		bte_o <= 2'b00;
		cti_o <= 3'b001;
		bl_o <= 6'd2;
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 4'hF;
		adr_o <= {pc[31:2],2'b00};
	end
	else if (ack_i|err_i) begin
		case(pc[1:0])
		2'd0:	ibuf <= dat_i;
		2'd1:	ibuf <= dat_i[31:8];
		2'd2:	ibuf <= dat_i[31:16];
		2'd3:	ibuf <= dat_i[31:24];
		endcase
		state <= LOAD_IBUF2;
		adr_o <= adr_o + 34'd4;
	end
LOAD_IBUF2:
	if (ack_i|err_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 4'h0;
		case(pc[1:0])
		2'd0:	ibuf[55:32] <= dat_i[23:0];
		2'd1:	ibuf[55:24] <= dat_i;
		2'd2:	ibuf[47:16] <= dat_i;
		2'd3:	ibuf[39:8] <= dat_i;
		endcase
		state <= LOAD_IBUF3;
		adr_o <= adr_o + 34'd4;
	end
LOAD_IBUF3:
	if (ack_i) begin
		cti_o <= 3'b000;
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 4'h0;
		case(pc[1:0])
		2'd0:	;
		2'd1:	;
		2'd2:	ibuf[55:48] <= dat_i[7:0];
		2'd3:	ibuf[55:40] <= dat_i[15:0];
		endcase
		adr_o <= 34'd0;
		state <= IFETCH;
		bufadr <= pc;	// clears the miss
	end
`ifdef SUPPORT_BERR
	else if (err_i) begin
		case(pc[1:0])
		2'd0:	;
		2'd1:	;
		2'd2:	ibuf[55:48] <= dat_i[7:0];
		2'd3:	ibuf[55:40] <= dat_i[15:0];
		endcase
		cti_o <= 3'b000;
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 4'h0;
		adr_o <= 34'd0;
		state <= INSN_BUS_ERROR;
		bufadr <= pc;	// clears the miss
	end
`endif
