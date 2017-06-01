// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// timeout_list.v
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
`define TOL_NOP     4'd0
`define TOL_DEC     4'd1
`define TOL_INS     4'd2
`define TOL_RMV     4'd3

module timeout_list(rst, clk, rdy, cs, vda, rw, ad, i, o);
input rst;
input clk;
output rdy;
input cs;
input vda;
input rw;
input [3:0] ad;
input [7:0] i;
output reg [7:0] o;

parameter TRUE  = 1'b1;
parameter FALSE = 1'b0;

parameter IDLE  = 5'd0;
parameter DEC1  = 5'd1;
parameter DEC2 = 5'd2;
parameter INS1 = 5'd3;
parameter INS2 = 5'd4;
parameter INS3 = 5'd5;
parameter INS_BEFORE = 5'd6;
parameter INS11 = 5'd7;
parameter INS12 = 5'd8;
parameter INS_CHK_END = 5'd9;
parameter INS_AT_END = 5'd10;
parameter INS_EMPTY_TOL = 5'd11;
parameter RMV1 = 5'd12;
parameter RMV2 = 5'd13;
parameter RMV3 = 5'd14;
parameter RMV4 = 5'd15;
parameter RMV5 = 5'd16;

reg [4:0] state;
reg [3:0] cmd;
reg [9:0] req_task;
reg [31:0] req_timeout;

reg [9:0] TimeoutList;          // head of timeout list
reg [9:0] nextptr [0:511];      // next pointers
reg [31:0] timeout [0:511];     // timeout amount
reg [15:0] timed_out;           // latest task that timed out
reg [31:0] res;                 // temporary result bus
reg [31:0] to;                  // temporary time out
reg busy;                       // busy status flag

reg [9:0] ndx,prv,ndx2;
wire [8:0] ndx9 = ndx[8:0];
wire [8:0] prv9 = prv[8:0];

assign rdy = 1'b1;

always @*
case(ad)
4'd0:   o <= {busy,7'd0};
4'd2:   o <= timed_out[7:0];
4'd3:   o <= timed_out[15:8];
default:    o <= 8'h00;
endcase

always @(posedge clk)
if (rst) begin
    state <= IDLE;
    TimeoutList <= 10'h3ff;
    timed_out <= 16'hFFFF;
end
else begin
    if (cs && vda && ~rw) begin
        case(ad)
        4'd0:   cmd <= i[3:0];
        4'd2:   req_task[7:0] <= i;
        4'd3:   req_task[8] <= i[0];
        4'd4:   req_timeout[7:0] <= i;
        4'd5:   req_timeout[15:8] <= i;
        4'd6:   req_timeout[23:16] <= i;
        4'd7:   req_timeout[31:24] <= i;
        default:    ;
        endcase   
    end

case(state)
IDLE:
    case(cmd)
    `TOL_DEC:
        begin
            cmd <= `TOL_NOP;
            ndx <= TimeoutList;
            if (TimeoutList[9])
                timed_out <= 16'hFFFF;
            else
                state <= DEC1;
            busy <= FALSE;
        end
    `TOL_INS:
        begin
            cmd <= `TOL_NOP;
            busy <= TRUE;
            state <= INS1;
        end
    `TOL_RMV:
        begin
            cmd <= `TOL_NOP;
            if (~TimeoutList[9]) begin
                busy <= TRUE;
                state <= RMV1;
            end
        end
    default:
        busy <= FALSE;
    endcase
DEC1:
    // Decrement the timeout for the task at the head of the timeout list.
    begin
        state <= IDLE;
        if (timeout[ndx9] != 32'd0) begin
            res <= timeout[ndx9] - 32'd1;
            timed_out <= 16'hFFFF;
            state <= DEC2;
        end
        else begin
            timed_out <= ndx9;
            TimeoutList <= nextptr[ndx9];
            nextptr[ndx9] <= 10'h3FF;
        end
    end
DEC2:
    begin
        timeout[ndx9] <= res;
        state <= IDLE;
    end

INS1:
    if (TimeoutList[9]) begin
        TimeoutList <= req_task;
        res <= req_timeout;
        ndx <= req_task;
        state <= INS_EMPTY_TOL;
    end
    else begin
        ndx <= TimeoutList;
        state <= INS2;
    end

INS2:
    begin
        to <= timeout[ndx9];
        state <= INS3;
    end
INS3:
    if (to < req_timeout) begin
        req_timeout <= req_timeout - to;
        prv <= ndx;
        ndx <= nextptr[ndx9];
        state <= INS_CHK_END;
    end
    else begin
        res <= to - req_timeout;
        state <= INS_BEFORE;
    end

INS_BEFORE:
    begin
        timeout[ndx9] <= res;
        nxt2 <= ndx;
        ndx <= prv;
        state <= INS11;
    end
INS11:
    begin
        nexptr[ndx9] <= req_task;
        ndx <= req_task;
        state <= INS12;
    end
INS12:
    begin
        nexptr[ndx9] <= ndx2;
        timeout[ndx9] <= req_timeout;
        state <= IDLE; 
    end

INS_CHK_END:
    if (ndx[9]) begin
        ndx <= prv;
        res <= req_timeout;
        state <= INS_AT_END;
    end
    else begin
        state <= INS2;
    end
INS_AT_END:
    begin
        nextptr[ndx9] <= req_task;
        ndx <= req_task;
        state <= INS_EMPTY_TOL; 
    end
INS_EMPTY_TOL:
    begin
        timeout[ndx9] <= res;
        nextptr[ndx9] <= 10'h3FF;
        state <= IDLE;
    end

RMV1:
    begin
        ndx <= TimeoutList;
        prv <= 10'h3FF;
    end
RMV2:
    begin
        if (req_task!=ndx9) begin
            prv <= ndx;
            ndx <= nextptr[ndx9];
        end
        else begin
            if (prv[9]) begin
                TimeoutList <= nextptr[ndx9];
                nextptr[ndx9] <= 10'h3ff;
                timeout[ndx9] <= 32'd0;
                state <= IDLE;
            end
            else begin
                ndx <= nextptr[ndx9];
                to <= timeout[ndx9];
                state <= RMV3;
            end
        end
    end
    // update the timeout of the next task on the list
    // add the time remaining of the task to be removed
RMV3:
    begin
        if (!ndx[9])
            res <= timeout[ndx9] + to;
        state <= RMV4;
    end
RMV4:
    begin
        if (!ndx[9])
            timeout[ndx9] <= res;
        ndx2 <= ndx;
        ndx <= prv;
        state <= RMV5;
    end
    // prev->next = task->next
RMV5:
    begin
        nextptr[ndx9] <= ndx2;
        state <= IDLE;
    end
default:
    state <= IDLE;
endcase

end

endmodule
