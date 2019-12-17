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
`include "rtf65004-config.sv"

module writeBuffer(rst_i, clk_i, bstate, cyc_pending, wb_has_bus, update_iq, uid, ruid, fault,
	wb_v, wb_addr, wb_en_i, cwr_o, csel_o, cadr_o, cdat_o,
	p0_id_i, p0_rid_i, p0_wr_i, p0_wrap_i, p0_ack_o, p0_sel_i, p0_adr_i, p0_dat_i, p0_hit,
	p1_id_i, p1_rid_i, p1_wr_i, p1_wrap_i, p1_ack_o, p1_sel_i, p1_adr_i, p1_dat_i, p1_hit,
	cyc_o, stb_o, ack_i, err_i, tlbmiss_i, wrv_i, we_o, sel_o, adr_o, dat_o, cr_o);
parameter WB_DEPTH = 7;
parameter IQ_ENTRIES = `IQ_ENTRIES;
parameter RENTRIES = `RENTRIES;
parameter INV = 1'b0;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter HIGH = 1'b1;
parameter LOW = 1'b0;
parameter AMSB = 63;
parameter BIDLE = 5'd0;
input rst_i;
input clk_i;
input [4:0] bstate;
input cyc_pending;
output reg wb_has_bus;
output reg update_iq;
output reg [7:0] fault;
output reg [IQ_ENTRIES-1:0] uid;
output reg [RENTRIES-1:0] ruid;
output reg [WB_DEPTH-1:0] wb_v;
output reg [63:0] wb_addr [0:WB_DEPTH-1];
input wb_en_i;

input [`QBITS] p0_id_i;
input [`RBITS] p0_rid_i;
input p0_wr_i;
input p0_wrap_i;
input [15:0] p0_sel_i;
input [63:0] p0_adr_i;
input [63:0] p0_dat_i;
output reg p0_ack_o;
output reg p0_hit;

input [`QBITS] p1_id_i;
input [`RBITS] p1_rid_i;
input p1_wr_i;
input p1_wrap_i;
input [15:0] p1_sel_i;
input [63:0] p1_adr_i;
input [63:0] p1_dat_i;
output reg p1_ack_o;
output reg p1_hit;

output reg cyc_o;
output reg stb_o;
input ack_i;
input err_i;
input tlbmiss_i;
input wrv_i;
output reg we_o;
output reg [15:0] sel_o;
output reg [AMSB:0] adr_o;
output reg [127:0] dat_o;
output reg cr_o;
output reg cwr_o;
output reg [15:0] csel_o;
output reg [AMSB:0] cadr_o;
output reg [63:0] cdat_o;

integer n, j;
reg wb_en;
reg [3:0] wb_ptr;
reg [22:0] wb_sel  [0:WB_DEPTH-1];
reg [63:0] wb_data [0:WB_DEPTH-1];
reg [IQ_ENTRIES-1:0] wb_id [0:WB_DEPTH-1];
reg [RENTRIES-1:0] wb_rid [0:WB_DEPTH-1];
reg [IQ_ENTRIES-1:0] wbo_id;
reg [RENTRIES-1:0] wbo_rid;
reg [WB_DEPTH-1:0] wb_wrap;
reg wrap_cycle;

wire writing_wb = /*(p0_wr_i && p1_wr_i && wb_ptr < WB_DEPTH-2) ||*/
									   (p0_wr_i && wb_ptr < WB_DEPTH-1)
									|| (p1_wr_i && wb_ptr < WB_DEPTH-1)
									;

parameter IDLE = 3'd0;
parameter StoreAck1 = 3'd1;
parameter Store2 = 3'd2;
parameter StoreAck2 = 3'd3;

// If the data is in the write buffer, give the buffer a chance to
// write out the data before trying to load from the cache.
always @*
begin
	p0_hit <= FALSE;
	p1_hit <= FALSE;
	for (n = 0; n < WB_DEPTH; n = n + 1) begin
		if (wb_v[n] && wb_addr[n][AMSB:4]==p0_adr_i[AMSB:4])
			p0_hit <= TRUE;
		if (wb_v[n] && wb_addr[n][AMSB:4]==p1_adr_i[AMSB:4])
			p1_hit <= TRUE;
	end
end

reg [22:0] sel_shift;
reg [143:0] dat_shift;

reg [2:0] state;
always @(posedge clk_i)
if (rst_i)
	state <= IDLE;
else begin
case(state)
IDLE:
	if (bstate==IDLE && (wb_v[0] & ~ack_i & ~cyc_o & ~cyc_pending))
		state <= StoreAck1;
StoreAck1:
	if (ack_i|err_i|tlbmiss_i|wrv_i) begin
		if (sel_shift[22:16]==7'h0 && !wrap_cycle)
			state <= IDLE;
		else
			state <= Store2;
	end
Store2:
	if (~ack_i)
		state <= StoreAck2;
StoreAck2:
	if (ack_i|err_i|tlbmiss_i|wrv_i)
		state <= IDLE;
default:
	state <= IDLE;
endcase
end

always @(posedge clk_i)
if (rst_i) begin
	cyc_o <= LOW;
	stb_o <= LOW;
	we_o <= LOW;
	sel_o <= 16'h0000;
	wb_has_bus <= FALSE;
	wb_v <= 1'b0;
	wb_ptr <= 1'd0;
	wb_en <= TRUE;
	wbo_id <= 1'd0;
	wbo_rid <= 1'd0;
	wb_wrap <= 1'd0;
	uid <= 1'd0;
	ruid <= 1'd0;
	update_iq <= FALSE;
	wrap_cycle <= FALSE;
	sel_shift <= 23'h0;
end
else begin
	if (wb_en_i)
		wb_en <= TRUE;
	cwr_o <= LOW;
	update_iq <= FALSE;
	p0_ack_o <= FALSE;
	p1_ack_o <= FALSE;
/*
	if ((p0_wr_i & ~p0_ack_o) & (p1_wr_i & ~p1_ack_o)) begin
		if (wb_ptr < WB_DEPTH-2) begin
			wb_v[wb_ptr-1] <= 1'b1;
			wb_ol[wb_ptr-1] <= p0_ol_i;
			wb_sel[wb_ptr-1] <= p0_sel_i;
			wb_addr[wb_ptr-1] <= p0_adr_i;
			wb_data[wb_ptr-1] <= p0_dat_i;
			wb_id[wb_ptr-1] <= 16'd1 << p0_id_i;
			wb_v[wb_ptr] <= 1'b1;
			wb_ol[wb_ptr] <= p1_ol_i;
			wb_sel[wb_ptr] <= p1_sel_i;
			wb_addr[wb_ptr] <= p1_adr_i;
			wb_data[wb_ptr] <= p1_dat_i;
			wb_id[wb_ptr] <= 16'd1 << p1_id_i;
			wb_ptr <= wb_ptr + 3'd2;
			p0_ack_o <= TRUE;
			p1_ack_o <= TRUE;
		end
		else if (wb_ptr < WB_DEPTH-1) begin
			wb_v[wb_ptr] <= 1'b1;
			wb_ol[wb_ptr] <= p0_ol_i;
			wb_sel[wb_ptr] <= p0_sel_i;
			wb_addr[wb_ptr] <= p0_adr_i;
			wb_data[wb_ptr] <= p0_dat_i;
			wb_id[wb_ptr] <= 16'd1 << p0_id_i;
			wb_ptr <= wb_ptr + 3'd1;
			p0_ack_o <= TRUE;
		end
	end
	else
*/
	if (p0_wr_i & ~p0_ack_o) begin
		if (wb_ptr < WB_DEPTH-1) begin
			wb_v[wb_ptr] <= 1'b1;
			wb_wrap[wb_ptr] <= p0_wrap_i;
			wb_sel[wb_ptr] <= p0_sel_i;
			wb_addr[wb_ptr] <= p0_adr_i;
			wb_data[wb_ptr] <= p0_dat_i;
			wb_id[wb_ptr] <= 16'd1 << p0_id_i;
			wb_rid[wb_ptr] <= 16'd1 << p0_rid_i;
			wb_ptr <= wb_ptr + 3'd1;
			p0_ack_o <= TRUE;
		end
	end
	else if (p1_wr_i & ~p1_ack_o) begin
		if (wb_ptr < WB_DEPTH-1) begin
			wb_v[wb_ptr] <= 1'b1;
			wb_wrap[wb_ptr] <= p1_wrap_i;
			wb_sel[wb_ptr] <= p1_sel_i;
			wb_addr[wb_ptr] <= p1_adr_i;
			wb_data[wb_ptr] <= p1_dat_i;
			wb_id[wb_ptr] <= 16'd1 << p1_id_i;
			wb_rid[wb_ptr] <= 16'd1 << p1_rid_i;
			wb_ptr <= wb_ptr + 3'd1;
			p1_ack_o <= TRUE;
		end
	end

case(state)
IDLE:
	if (bstate==BIDLE) begin
		if (wb_v[0] & ~ack_i & ~cyc_o & ~cyc_pending) begin
			cyc_o <= HIGH;
			stb_o <= HIGH;
			we_o <= HIGH;
			if (wb_wrap[0] && wb_addr[0][7:0]==8'hFF) begin
				sel_o <= 16'b01 << wb_addr[0][3:0];
				wrap_cycle <= TRUE;
			end
			else
				sel_o <= wb_sel[0] << wb_addr[0][3:0];
			adr_o <= {wb_addr[0][AMSB:4],4'h0};
			dat_o <= wb_data[0] << {wb_addr[0][3:0],3'h0};
			wbo_id <= wb_id[0];
			wbo_rid <= wb_rid[0];
			sel_shift <= {22'd0,wb_sel[0]} << wb_addr[0][3:0];
			dat_shift <= {120'd0,wb_data[0]} << {wb_addr[0][3:0],3'b0};
			wb_has_bus <= 1'b1;
		end
		if (wb_v[0]==INV && !writing_wb) begin
			for (j = 1; j <= WB_DEPTH-1; j = j + 1) begin
		   	wb_v[j-1] <= wb_v[j];
		   	wb_id[j-1] <= wb_id[j];
		   	wb_rid[j-1] <= wb_rid[j];
		   	wb_wrap[j-1] <= wb_wrap[j];
		   	wb_sel[j-1] <= wb_sel[j];
		   	wb_addr[j-1] <= wb_addr[j];
		   	wb_data[j-1] <= wb_data[j];
		   	if (wb_ptr > 1'd0)
		   		wb_ptr <= wb_ptr - 2'd1;
			end
			wb_v[WB_DEPTH-1] <= INV;
			wb_sel[WB_DEPTH-1] <= 1'd0;
		end
	end

// Terminal state for a store operation.
StoreAck1:
	if (ack_i|err_i|tlbmiss_i|wrv_i) begin
		stb_o <= LOW;
		if (sel_shift[22:16]==7'h0 && !wrap_cycle) begin
			cyc_o <= LOW;
			we_o <= LOW;
			sel_o <= 16'h0000;
			cr_o <= 1'b0;
    // This isn't a good way of doing things; the state should be propagated
    // to the commit stage, however since this is a store we know there will
    // be no change of program flow. So the reservation status bit is set
    // here. The author wanted to avoid the complexity of propagating the
    // input signal to the commit stage. It does mean that the SWC
    // instruction should be surrounded by SYNC's.
//    if (cr_o)
//			sema[0] <= rbi_i;
			wb_v[0] <= 1'b0;
			update_iq <= TRUE;
			uid <= wbo_id;
			ruid <= wbo_rid;
	    if (err_i|tlbmiss_i|wrv_i) begin	// should abort cycle
	    	wb_v <= 1'b0;			// Invalidate write buffer if there is a problem with the store
	    	wb_en <= FALSE;	// and disable write buffer
//				fault <= tlbmiss_i ? `FLT_TLB : wrv_i ? `FLT_DWF : err_i ? `FLT_DBE : `FLT_NONE;
	    end
    	cwr_o <= HIGH;
			csel_o <= wb_sel[0];
			cadr_o <= wb_addr[0];
			cdat_o <= wb_data[0];
	    wb_has_bus <= FALSE;
		end
		else begin
    	cwr_o <= HIGH;
			csel_o <= wrap_cycle ? 2'b01 : wb_sel[0];
			cadr_o <= wb_addr[0];
			cdat_o <= wb_data[0];
		end
	end
Store2:
	if (~ack_i) begin
		stb_o <= HIGH;
		sel_o <= {15'h0,1'b1};
		if (wrap_cycle)
			adr_o[AMSB:4] <= adr_o[AMSB:4] & 12'hFF0;
		else
			adr_o[AMSB:4] <= adr_o[AMSB:4] + 2'd1;
		adr_o[3:0] <= 4'b0;
		dat_o <= {120'd0,dat_shift[135:128]};
	end
StoreAck2:
	if (ack_i|err_i|tlbmiss_i|wrv_i) begin
		cyc_o <= LOW;
		stb_o <= LOW;
		we_o <= LOW;
		sel_o <= 16'h0000;
//    if (cr_o)
//			sema[0] <= rbi_i;
		wb_v[0] <= 1'b0;
		update_iq <= TRUE;
		uid <= wbo_id;
		ruid <= wbo_rid;
    if (err_i|tlbmiss_i|wrv_i) begin
    	wb_v <= 1'b0;			// Invalidate write buffer if there is a problem with the store
    	wb_en <= FALSE;	// and disable write buffer
//			fault <= tlbmiss_i ? `FLT_TLB : wrv_i ? `FLT_DWF : err_i ? `FLT_DBE : `FLT_NONE;
    end
  	cwr_o <= HIGH;
  	if (wrap_cycle) begin
			csel_o <= 2'b01;
			cadr_o <= (wb_addr[0] + 16'd1) & 16'hFF00;
			cdat_o <= {wb_data[0][15:8],wb_data[0][15:8]};
  	end
  	else begin
			csel_o <= wb_sel[0];
			cadr_o <= wb_addr[0];
			cdat_o <= wb_data[0];
  	end
    wb_has_bus <= FALSE;
	end
endcase

end

endmodule
