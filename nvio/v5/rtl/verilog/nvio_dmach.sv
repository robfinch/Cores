// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	nvio_dma.v
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
module nvio_dma(rst,clk64,cs_i,we_i,sel_i,adr_i,dat_i,dat_o,xrq,xack,drd_req,dwr_req,dreq_sz,dreq_adr,drd_dat,dwr_dat,drw_done)
parameter NCH = 8;    // number of channels
input rst;
input clk64;
input cs_i;
input we_i;
input [7:0] sel_i;
input [8:0] adr_i;
input [63:0] dat_i;
output [63:0] dat_o;
input [NCH-1:0] xrq;
output reg [NCH-1:0] xack;
output reg drd_req;
output reg dwr_req;
output reg [2:0] dreq_sz;
output reg [39:0] dreq_adr;
input [63:0] drd_dat;
output [63:0] dwr_dat;
input drw_done;
parameter tCYC = 10;  // number of clocks per bus cycle

reg [63:0] tmp;
reg [39:0] src_base_adr [0:NCH-1];
reg [39:0] src_curr_adr [0:NCH-1];
reg [39:0] dst_base_adr [0:NCH-1];
reg [39:0] dst_curr_adr [0:NCH-1];
reg [39:0] base_cnt [0:NCH-1];
reg [39:0] curr_cnt [0:NCH-1];
reg [63:0] fill_dat [0:NCH-1];
reg [1:0] mode [0:NCH-1];           // DMA mode, 00=one,01=block,10=demand
reg [1:0] rwop [0:NCH-1];           // read/write op: 11 = read then write,01 = read only,10 = write only
reg [NCH-1:0] en;                   // enabled
reg [NCH-1:0] xen;                  // external request enable
reg [ 3:0] xfer_sz [0:NCH-1];
reg [NCH-1:0] autorl;               // automatic reload
reg [NCH-1:0] trig;                 // software trigger
reg [1:0] src_incdec [0:NCH-1];
reg [1:0] dst_incdec [0:NCH-1];
reg [4:0] chs;                      // channel selected

always @(posedge clk64)
if (rst) begin
  for (n = 0; n < NCH; n = n + 1) begin
    mode[n] <= 2'b00;
    rwop[n] <= 2'b11;
    en[n] <= 1'b0;
    xen[n] <= 1'b0;
    trig[n] <= 1'b0;
    src_incdec[n] <= 2'b01;
    dst_incdec[n] <= 2'b01;
  end
end
else begin
  if (wcnt != 4'd0)
    wcnt <= wcnt - 4'd1;

  if (cs_i & we_i) begin
    casez(adr_i[8:3])
    6'b???000:  src_base_adr[adr_i[8:6]] <= dat_i[39:0];
    6'b???001:  ;
    6'b???010:  dst_base_adr[adr_i[8:6]] <= dat_i[39:0];
    6'b???011:  ;
    6'b???100:  base_cnt[adr_i[8:6]] <= dat_i[39:0];
    6'b???101:  ;
    6'b???110:  fill_dat[adr_i[8:6]] <= dat_i;  
    6'b???111:
      begin
        if (sel_i[0]) begin
          mode[adr_i[8:6]] <= dat_i[1:0];
          rwop[adr_i[8:6]] <= dat_i[3:2];
          en[adr_i[8:6]] <= dat_i[4];
          xen[adr_i[8:6]] <= dat_i[5];
          autorl[adr_i[8:6]] <= dat_i[6];
        end
        if (sel_i[1])
          xfer_sz[adr_i[8:6]] <= dat_i[10:8];
        if (sel_i[2]) begin
          src_incdec[adr_i[8:6]] <= dat_i[17:16];
          dst_incdec[adr_i[8:6]] <= dat_i[19:18];
        end
        if (sel_i[3])
          trig[adr_i[8:6]] <= dat_i[31];
      end
    endcase
  end
  begin
    casez(adr_i[8:3])
    6'b???000:  dat_o <= src_base_adr[adr_i[8:6]];
    6'b???001:  dat_o <= src_curr_adr[adr_i[8:6]];
    6'b???010:  dat_o <= dst_base_adr[adr_i[8:6]];
    6'b???011:  dat_o <= dst_curr_adr[adr_i[8:6]];
    6'b???100:  dat_o <= base_cnt[adr_i[8:6]];
    6'b???101:  dat_o <= curr_cnt[adr_i[8:6]];
    6'b???110:  dat_o <= fill_dat[adr_i[6:8]];
    6'b???111:
      begin
        dat_o[1:0] <= mode[adr_i[8:6]];
        dat_o[3:2] <= rwop[adr_i[8:6]];
        dat_o[4] <= en[adr_i[8:6]];
        dat_o[5] <= xen[adr_i[8:6]];
        dat_o[6] <= autorl[adr_i[8:6]];
        dat_o[10:8] <= xfer_sz[adr_i[8:6]];
        dat_o[17:16] <= src_incdec[adr_i[8:6]];
        dat_o[19:18] <= dst_incdec[adr_i[8:6]];
        dat_o[31] <= trig[adr_i[8:6]];
      end
    endcase
  end

case(state)
ST_IDLE:
  begin
    chs <= NCH;
    for (n = NCH-1; n >= 0; n = n - 1) begin
      if (en[n] && curr_cnt[n] < base_cnt[n]) begin
        if (xen[n] & xrq[n]) begin
          chs <= n;
          tmp <= fill_dat[n];
          state <= (rwop[n][0]==1'b1) ? ST_RXFER : (rwop[n][1]==1'b1) ? ST_WXFER : ST_IDLE;
        end
        else if (trig[n]) begin
          trig[n] <= 1'b0;
          chs <= n;
          tmp <= fill_dat[n];
          state <= (rwop[n][0]==1'b1) ? ST_RXFER : (rwop[n][1]==1'b1) ? ST_WXFER : ST_IDLE;
        end
      end
    end
  end

ST_RXFER:
  begin
    xack[chs] <= HIGH;
    drd_req <= HIGH;
    dreq_sz <= xfer_sz[chs];
    dreq_adr <= src_curr_adr[chs];
    state <= ST_RXFER2;
  end
ST_RXFER2:
  if (drw_done) begin
    drd_req <= LOW;
    tmp <= drd_dat;
    if (rwop[chs][1]==1'b0) begin
      xack[chs] <= LOW;
      case(mode)
      2'b00,2'b11:
        begin
          case(src_incdec[chs])
          2'b00:  ;
          2'b01:  src_curr_adr[chs] <= src_curr_adr[chs] + xfer_sz[chs];
          2'b10:  src_curr_adr[chs] <= src_curr_adr[chs] - xfer_sz[chs];
          2'b11:  ;
          endcase        
          curr_cnt[chs] <= curr_cnt[chs] + 40'd1;
          if (curr_cnt[chs] >= base_cnt[chs] && autorl[chs]) begin
            src_curr_adr[chs] <= src_base_adr[chs];
            curr_cnt[chs] <= 40'd0;
          end
          wcnt <= tCYC;
          state <= ST_WAITCYC;
        end
      2'b01,2'b10:
        begin
          if ((mode==2'b10 && xrq[chs] && (curr_cnt[chs] < base_cnt[chs]))
          || (mode==2'b01 && (curr_cnt[chs] < base_cnt[chs]))) begin
            case(src_incdec[chs])
            2'b00:  ;
            2'b01:  src_curr_adr[chs] <= src_curr_adr[chs] + xfer_sz[chs];
            2'b10:  src_curr_adr[chs] <= src_curr_adr[chs] - xfer_sz[chs];
            2'b11:  ;
            endcase        
            curr_cnt[chs] <= curr_cnt[chs] + 40'd1;
            state <= ST_RXFER;
          end
          else begin
            wcnt <= tCYC;
            state <= ST_WAITCYC;
          end
        end
      endcase
    end
    else
      state <= ST_WXFER;
  end

ST_WXFER:
  begin
    xack[chs] <= HIGH;
    dwr_req <= HIGH;
    dreq_sz <= xfer_sz[chs];
    dreq_adr <= src_dst_adr[chs];
    dreq_wdat <= tmp;
    state <= ST_WXFER2;
  end
ST_WXFER2:
  if (drw_done) begin
    xack[chs] <= LOW;
    dwr_req <= LOW;
    case(mode)
    2'b00,2'b11:
      begin
        case(src_incdec[chs])
        2'b00:  ;
        2'b01:  src_curr_adr[chs] <= src_curr_adr[chs] + xfer_sz[chs];
        2'b10:  src_curr_adr[chs] <= src_curr_adr[chs] - xfer_sz[chs];
        2'b11:  ;
        endcase        
        case(dst_incdec)
        2'b00:  ;
        2'b01:  dst_curr_adr[chs] <= dst_curr_adr[chs] + xfer_sz[chs];
        2'b10:  dst_curr_adr[chs] <= dst_curr_adr[chs] - xfer_sz[chs];
        2'b11:  ;
        endcase
        curr_cnt[chs] <= curr_cnt[chs] + 40'd1;
        if (curr_cnt[chs] >= base_cnt[chs] && autorl[chs]) begin
          src_curr_adr[chs] <= src_base_adr[chs];
          dst_curr_adr[chs] <= dst_base_adr[chs];
          curr_cnt[chs] <= 40'd0;
        end
        wcnt <= tCYC;
        state <= ST_WAITCYC;
      end
    2'b01,2'b10:
      begin
        if ((mode==2'b10 && xrq[chs] && (curr_cnt[chs] < base_cnt[chs]))
        || (mode==2'b01 && (curr_cnt[chs] < base_cnt[chs]))) begin
          case(src_incdec[chs])
          2'b00:  ;
          2'b01:  src_curr_adr[chs] <= src_curr_adr[chs] + xfer_sz[chs];
          2'b10:  src_curr_adr[chs] <= src_curr_adr[chs] - xfer_sz[chs];
          2'b11:  ;
          endcase        
          case(dst_incdec)
          2'b00:  ;
          2'b01:  dst_curr_adr[chs] <= dst_curr_adr[chs] + xfer_sz[chs];
          2'b10:  dst_curr_adr[chs] <= dst_curr_adr[chs] - xfer_sz[chs];
          2'b11:  ;
          endcase
          curr_cnt[chs] <= curr_cnt[chs] + 40'd1;
          wcnt <= tCYC;
          state <= (rwop[chs][0]==1'b1) ? ST_RXFER : (rwop[chs][1]==1'b1) ? ST_WXFER : ST_WAITCYC;
        end
        else begin
          if (curr_cnt[chs] >= base_cnt[chs] && autorl[chs]) begin
            src_curr_adr[chs] <= src_base_adr[chs];
            dst_curr_adr[chs] <= dst_base_adr[chs];
            curr_cnt[chs] <= 40'd0;
          end
          if (curr_cnt[chs] >= base_cnt[chs]) begin
            wcnt <= tCYC;
            state <= ST_WAITCYC;
          end
        end
      end
    endcase
  end

ST_WAITCYC:
  if (wcnt==4'd0)
    state <= ST_IDLE;
endcase
end

endmodule
