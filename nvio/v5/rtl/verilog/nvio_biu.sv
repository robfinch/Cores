// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	nvio_biu.v
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
module nvio_biu(clk,rdy,req_sz,rd_req,wr_req,ic_req,req_adr,ic_adr,rd_dat,wr_dat,
  drd_req,dwr_req,dreq_sz,dreq_adr,drd_dat,dwr_dat,
  ale,sel,ad,ird,ic_dat,ct,done,ctrl_wr,ctrl_dat,
  dram_cyc,dram_stb,dram_ack,dram_cs,dram_wr,dram_sel,dram_adr,dram_wdat,dram_rdat);
input clk;
input rdy;
input [2:0] req_sz;
input rd_req;               // read request
input wr_req;               // write request
input ic_req;               // instruction request
input [39:0] req_adr;
input [39:0] ic_adr;
output reg [63:0] rd_dat;
input [63:0] wr_dat;
output reg [255:0] ic_dat;

input drd_req;
input dwr_req;
input [2:0] dreq_sz;
input [39:0] dreq_adr;
output reg [63:0] drd_dat;
input [63:0] dwr_dat;

output reg ale;
output reg [3:0] sel;
inout [39:0] ad;
tri [39:0] ad;
output reg ird;
output reg [2:0] ct;
output reg done;
input ctrl_wr;
input [15:0] ctrl_dat;

output reg dram_cyc;
output reg dram_stb;
input dram_ack;
output reg dram_cs;
output reg dram_wr;
output reg [3:0] dram_sel;
output reg [27:0] dram_adr;
output reg [63:0] dram_wdat;
input [63:0] dram_rdat;

parameter SZ_UBYTE = 3'b000;
parameter SZ_UHALF = 3'b001;
parameter SZ_UWORD = 3'b010;
parameter SZ_DWORD = 3'b011;
parameter SZ_BYTE  = 3'b100;
parameter SZ_HALF  = 3'b101;
parameter SZ_WORD  = 3'b110;

parameter ST_IDLE = 6'd0;
parameter ST_READ_ALE1 = 6'd1;
parameter ST_READ_ALE2 = 6'd2;
parameter ST_READ_ALE3 = 6'd3;
parameter ST_READ1 = 6'd4;
parameter ST_READ2 = 6'd5;
parameter ST_READ3 = 6'd6;
parameter ST_WRITE_ALE1 = 6'd7;
parameter ST_WRITE_ALE2 = 6'd8;
parameter ST_WRITE_ALE3 = 6'd9;
parameter ST_WRITE1 = 6'd10;
parameter ST_WRITE2 = 6'd11;
parameter ST_WRITE3 = 6'd12;
parameter ST_IREAD_ALE1 = 6'd13;
parameter ST_IREAD1 = 6'd14;
parameter ST_DIREAD_ALE1 = 6'd15;
parameter ST_DIREAD1 = 6'd16;
parameter ST_DREAD_CYC1 = 6'd17;
parameter ST_DREAD_CYC2 = 6'd18;
parameter ST_DREAD1 = 6'd19;
parameter ST_DREAD2 = 6'd20;
parameter ST_DWRITE_CYC1 = 6'd21;
parameter ST_DWRITE_CYC2 = 6'd22;
parameter ST_DWRITE1 = 6'd23;
parameter ST_DWRITE2 = 6'd24;

parameter CT_IDLE = 3'd0;
parameter CT_READ = 3'd1;
parameter CT_WRITE = 3'd2;
parameter CT_SREAD = 3'd3;
parameter CT_SWRITE = 3'd4;
parameter CT_IOREAD = 3'd5;
parameter CT_IOWRITE = 3'd6;
parameter CT_IACK = 3'd7;

reg [5:0] state;
reg [3:0] cnt;
reg [3:0] acnt;
reg [2:0] icnt;   // instruction cache word counter
reg [39:0] xadr;  // external system bus address

reg [3:0] nIDS = 4'd5;
reg [3:0] tALE = 4'd2;
reg [3:0] tRD = 4'd4;
reg [3:0] tWR = 4'd4;

reg [11:0] sel321;
reg [15:0] sel321a;

reg [39:0] ado;
assign ad = ale ? ado : {ado[39:32],32'bz};

always @*
case (req_sz)
SZ_BYTE:  sel321 = 12'b00000001 << req_adr[1:0];
SZ_HALF:  sel321 = 12'b00000011 << req_adr[1:0];
SZ_WORD:  sel321 = 12'b00001111 << req_adr[1:0];
SZ_DWORD: sel321 = 12'b11111111 << req_adr[1:0];
default:  sel321 = 12'b11111111 << req_adr[1:0];
endcase

always @*
case (req_sz)
SZ_BYTE:  sel321a = 16'b00000001 << req_adr[2:0];
SZ_HALF:  sel321a = 16'b00000011 << req_adr[2:0];
SZ_WORD:  sel321a = 16'b00001111 << req_adr[2:0];
SZ_DWORD: sel321a = 16'b11111111 << req_adr[2:0];
default:  sel321a = 16'b11111111 << req_adr[2:0];
endcase

reg [95:0] dbo321;
reg [127:0] dbo321a;
always @*
  dbo321 = wr_dat << {req_adr[1:0],3'b0};
always @*
  dbo321a = wr_dat << {req_adr[2:0],3'b0};

wire [3:0] sel1 = sel321[3:0];
wire [3:0] sel2 = sel321[7:4];
wire [3:0] sel3 = sel321[11:8];
wire [7:0] sel1a = sel321a[7:0];
wire [7:0] sel2a = sel321a[15:8];
wire [31:0] dbo1 = dbo321[31:0];
wire [31:0] dbo2 = dbo321[63:32];
wire [31:0] dbo3 = dbo321[95:64];
wire [63:0] dbo1a = dbo321a[63:0];
wire [63:0] dbo2a = dbo321a[127:64];

always @(posedge clk)
begin
  done <= FALSE;
  if (cnt != 4'h0 && rdy)
    cnt <= cnt - 4'h1;
  if (acnt != 4'h0)
    acnt <= acnt - 4'h1;

if (ctrl_wr) begin
  nIDS <= ctrl_dat[3:0];
  tALE <= ctrl_dat[7:4];
  tRD <= ctrl_dat[11:8];
  tWR <= ctrl_dat[15:12];
end

case(state)
ST_IDLE:
  begin
    dram_cs <= LOW;
    ct <= CT_IDLE;
    begin
      if (dwr_req) begin
        acnt <= tALE;
        dram_adr <= dreq_adr[27:0];
        xadr <= dreq_adr;
        if (dreq_adr[39:28]==12'h0) begin
          dram_cs <= HIGH;
          state <= ST_DWRITE_CYC1;
        end
        else
          state <= ST_WRITE_ALE1;
      end
      else if (drd_req) begin
        acnt <= tALE;
        dram_adr <= dreq_adr[27:0];
        xadr <= dreq_adr;
        if (dreq_adr[39:28]==12'h0) begin
          dram_cs <= HIGH;
          state <= ST_DREAD_CYC1;
        end
        else
          state <= ST_READ_ALE1;
      end
      else if (wr_req) begin
        acnt <= tALE;
        dram_adr <= req_adr[27:0];
        xadr <= req_adr;
        if (req_adr[39:28]==12'h0) begin
          dram_cs <= HIGH;
          state <= ST_DWRITE_CYC1;
        end
        else
          state <= ST_WRITE_ALE1;
      end
      else if (rd_req) begin
        acnt <= tALE;
        state <= ST_READ_ALE1;
        dram_adr <= req_adr[27:0];
        xadr <= req_adr;
        if (req_adr[39:28]==12'h0) begin
          dram_cs <= HIGH;
          state <= ST_DREAD_CYC1;
        end
        else
          state <= ST_READ_ALE1;
      end
      else if (ic_req) begin
        icnt <= 3'd0;
        acnt <= tALE;
        dram_adr <= req_adr[27:0];
        xadr <= req_adr;
        if (ic_adr[39:28]==12'h0) begin
          dram_cs <= HIGH;
          state <= ST_DIREAD_CYC1;
        end
        else
          state <= ST_IREAD_ALE1;
      end
    end
  end

ST_IREAD_ALE1:
  begin
    ale <= HIGH;
    rd <= LOW;
    sel <= 4'hF;
    ado <= {xadr[39:2]+icnt,2'd0};
    if (acnt==4'h0) begin
      cnt <= tRD;
      ale <= LOW;
      state <= ST_IREAD1;
    end
  end
ST_IREAD1:
  if (cnt==4'h0 && rdy) begin
    case(icnt)
    3'd0: ic_dat[ 31:  0] <= ad[31:0];
    3'd1: ic_dat[ 63: 32] <= ad[31:0];
    3'd2: ic_dat[ 95: 64] <= ad[31:0];
    3'd3: ic_dat[127: 96] <= ad[31:0];
    3'd4: ic_dat[159:128] <= ad[31:0];
    3'd5: ic_dat[191:160] <= ad[31:0];
    3'd6: ic_dat[223:192] <= ad[31:0];
    3'd7: ic_dat[255:224] <= ad[31:0];
    endcase
    if (icnt==3'd7) begin
      done <= TRUE;
      state <= ST_IDLE;
    end
    else
      state <= ST_IREAD_ALE1;
    icnt <= icnt + 3'd1;
  end

ST_DIREAD_CYC1:
  begin
    dram_cyc <= HIGH;
    dram_stb <= HIGH;
    dram_sel <= 8'hFF;
    dram_adr <= {xadr[39:3]+icnt,3'd0};
    state <= ST_DIREAD1;
  end
ST_DIREAD1:
  if (dram_ack) begin
    dram_stb <= LOW;
    case(icnt)
    3'd0: ic_dat[ 63:  0] <= dram_rdat[63:0];
    3'd1: ic_dat[127: 64] <= dram_rdat[63:0];
    3'd2: ic_dat[191:128] <= dram_rdat[63:0];
    3'd3: ic_dat[255:192] <= dram_rdat[63:0];
    endcase
    if (icnt==3'd3) begin
      dram_cyc <= LOW;
      done <= TRUE;
      state <= ST_IDLE;
    end
    else
      state <= ST_DIREAD_CYC1;
    icnt <= icnt + 3'd1;
  end

ST_READ_ALE1:
  begin
    ale <= HIGH;
    rd <= LOW;
    sel <= sel1;
    ado <= xadr;
    if (acnt==4'h0) begin
      cnt <= tRD;
      ale <= LOW;
      state <= ST_READ1;
    end
  end
ST_READ1:
  if (cnt==4'h0 && rdy) begin
    rd_dat <= ad[31:0] >> {xadr[1:0],3'b0};
    case(sz)
    SZ_UBYTE,SZ_BYTE: rd_dat[63: 8] <= 56'd0;
    SZ_UHALF,SZ_HALF: rd_dat[63:16] <= 48'd0;
    SZ_UWORD,SZ_WORD: rd_dat[63:32] <= 32'd0;
    default:  ;
    endcase
    rd <= HIGH;
    if (sel2!=4'h0) begin
      rd <= LOW;
      acnt <= tALE;
      state <= ST_READ_ALE2;
    end
    else
      case(sz)
      SZ_UBYTE,SZ_UHALF,SZ_UWORD,SZ_DWORD:
        state <= ST_IDLE;
      default:
        state <= ST_SIGN_EXTEND;
      endcase
  end
ST_READ_ALE2:
  begin
    ale <= HIGH;
    rd <= LOW;
    sel <= sel2;
    ado <= {xadr[39:2]+38'd1,2'b00};
    if (acnt==4'h0) begin
      cnt <= tRD;
      ale <= LOW;
      state <= ST_READ2;
    end
  end
ST_READ2:
  if (cnt==4'h0 && rdy) begin
    rd <= HIGH;
    case(sz)
    SZ_UHALF,SZ_HALF:  rd_dat[15:8] <= ad[7:0];
    SZ_UWORD,SZ_WORD:
      case(xadr[1:0])
      2'b01:  rd_dat[31:24] <= ad[7 :0];
      2'b10:  rd_dat[31:16] <= ad[15:0];
      2'b11:  rd_dat[31: 8] <= ad[23:0];
      endcase
    SZ_DWORD:
      case(xadr[1:0])
      2'b01:  rd_dat[55:24] <= ad[31:0];
      2'b10:  rd_dat[47:16] <= ad[31:0];
      2'b11:  rd_dat[39: 8] <= ad[31:0];
      endcase
    endcase
    if (sel3!=4'h0) begin
      rd <= LOW;
      acnt <= tALE;
      state <= ST_READ_ALE3;
    end
    else
      case(sz)
      SZ_UBYTE,SZ_UHALF,SZ_UWORD,SZ_DWORD:
        state <= ST_IDLE;
      default:
        state <= ST_SIGN_EXTEND;
      endcase
  end
ST_READ_ALE3:
  begin
    ale <= HIGH;
    rd <= LOW;
    sel <= sel3;
    ado <= {xadr[39:2]+38'd2,2'b00};
    if (acnt==4'h0) begin
      cnt <= tRD;
      ale <= LOW;
      state <= ST_READ3;
    end
  end
ST_READ3:
  if (cnt==4'h0 && rdy) begin
    rd <= HIGH;
    case(sz)
    SZ_DWORD:
      case(xadr[1:0])
      2'b01:  rd_dat[63:56] <= ad[ 7:0];
      2'b10:  rd_dat[63:48] <= ad[15:0];
      2'b11:  rd_dat[63:40] <= ad[23:0];
      endcase
    endcase
    state <= ST_IDLE;
  end
ST_SIGN_EXTEND:
  begin
    case(sz)
    SZ_BYTE:  rd_dat[63: 8] <= {56{rd_dat[ 7]}};
    SZ_HALF:  rd_dat[63:16] <= {48{rd_dat[15]}};
    SZ_WORD:  rd_dat[63:32] <= {32{rd_dat[31]}};
    endcase
    state <= IDLE;
  end

ST_DREAD_CYC1:
  begin
    dram_cyc <= HIGH;
    dram_stb <= HIGH;
    dram_sel <= sel1a;
    dram_adr <= req_adr;
    state <= ST_DREAD1;
  end
ST_DREAD1:
  if (dram_ack) begin
    dram_stb <= LOW;
    rd_dat <= dram_rdat[63:0] >> {xadr[2:0],3'b0};
    case(sz)
    SZ_UBYTE,SZ_BYTE: rd_dat[63: 8] <= 56'd0;
    SZ_UHALF,SZ_HALF: rd_dat[63:16] <= 48'd0;
    SZ_UWORD,SZ_WORD: rd_dat[63:32] <= 32'd0;
    default:  ;
    endcase
    if (sel2a!=8'h00)
      state <= ST_DREAD_CYC2;
    else
      case(sz)
      SZ_UBYTE,SZ_UHALF,SZ_UWORD,SZ_DWORD:
        state <= ST_IDLE;
      default:
        state <= ST_SIGN_EXTEND;
      endcase
  end
ST_DREAD_CYC2:
  begin
    dram_cyc <= HIGH;
    dram_stb <= HIGH;
    dram_sel <= sel2a;
    dram_adr <= {xadr[39:3]+37'd1,3'b00};
    state <= ST_DREAD2;
  end
ST_DREAD2:
  if (dram_ack) begin
    dram_cyc <= LOW;
    dram_stb <= LOW;
    case(sz)
    SZ_UHALF,SZ_HALF:  rd_dat[15:8] <= dram_rdat[7:0];
    SZ_UWORD,SZ_WORD:
      case(xadr[2:0])
      3'b101:  rd_dat[31:24] <= dram_rdat[7 :0];
      3'b110:  rd_dat[31:16] <= dram_rdat[15:0];
      3'b111:  rd_dat[31: 8] <= dram_rdat[23:0];
      endcase
    SZ_DWORD:
      case(xadr[2:0])
      3'b001:  rd_dat[63:56] <= dram_rdat[ 7:0];
      3'b010:  rd_dat[63:48] <= dram_rdat[15:0];
      3'b011:  rd_dat[63:40] <= dram_rdat[23:0];
      3'b100:  rd_dat[63:32] <= dram_rdat[31:0];
      3'b101:  rd_dat[63:24] <= dram_rdat[39:0];
      3'b110:  rd_dat[63:16] <= dram_rdat[47:0];
      3'b111:  rd_dat[63: 8] <= dram_rdat[55:0];
      endcase
    endcase
    case(sz)
    SZ_UBYTE,SZ_UHALF,SZ_UWORD,SZ_DWORD:
      state <= ST_IDLE;
    default:
      state <= ST_SIGN_EXTEND;
    endcase
  end

ST_WRITE_ALE1:
  begin
    ale <= HIGH;
    wr <= LOW;
    sel <= sel1;
    ado <= xadr;
    if (acnt==4'h0) begin
      cnt <= tWR;
      ale <= LOW;
      ado <= {xadr[39:32],dbo1};
      state <= ST_WRITE1;
    end
  end
ST_WRITE1:
  if (cnt==4'h0 && rdy) begin
    wr <= HIGH;
    if (sel2!=4'h0) begin
      acnt <= tALE;
      state <= ST_WRITE_ALE2;
    end
    else
      state <= ST_IDLE;
  end
ST_WRITE_ALE2:
  begin
    ale <= HIGH;
    wr <= LOW;
    sel <= sel2;
    ado <= {xadr[39:2]+38'd1,2'b00};
    if (acnt==4'h0) begin
      cnt <= tWR;
      ale <= LOW;
      ado <= {xadr[39:32],dbo2};
      state <= ST_WRITE2;
    end
  end
ST_WRITE2:
  if (cnt==4'h0 && rdy) begin
    wr <= HIGH;
    if (sel3!=4'h0) begin
      acnt <= tALE;
      state <= ST_WRITE_ALE3;
    end
    else
      state <= ST_IDLE;
  end
ST_WRITE_ALE3:
  begin
    ale <= HIGH;
    wr <= LOW;
    sel <= sel3;
    ado <= {xadr[39:2]+38'd2,2'b00};
    if (acnt==4'h0) begin
      cnt <= tWR;
      ale <= LOW;
      ado <= {xadr[39:32],dbo3};
      state <= ST_WRITE3;
    end
  end
ST_WRITE3:
  if (cnt==4'h0 && rdy) begin
    wr <= HIGH;
    state <= ST_IDLE;
  end

ST_DWRITE_CYC1:
  begin
    dram_cyc <= HIGH;
    dram_stb <= HIGH;
    dram_wr <= HIGH;
    dram_sel <= sel1a;
    dram_wdat <= dbo1a;
    state <= ST_DWRITE1;
  end
ST_DWRITE1:
  if (dram_ack) begin
    dram_stb <= LOW;
    dram_wr <= LOW;
    if (sel2a!=8'h00)
      state <= ST_WRITE_CYC2;
    else
      state <= ST_IDLE;
  end
ST_DWRITE_CYC2:
  begin
    dram_stb <= HIGH;
    dram_wr <= HIGH;
    dram_sel <= sel2a;
    dram_adr <= {xadr[39:3]+37'd1,3'b00};
    dram_wdat <= dbo2a;
    state <= ST_DWRITE2;
  end
ST_DWRITE2:
  if (dram_ack) begin
    dram_cyc <= LOW;
    dram_stb <= LOW;
    dram_wr <= LOW;
    state <= ST_IDLE;
  end

endcase
end
endmodule
