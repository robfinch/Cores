// ============================================================================
//        __
//   \\__/ o\    (C) 2013,2015  Robert Finch, Stratford
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
// This core simulates a serial transmitter by outputing a text stream.
// ============================================================================
//
module rtfSerialSim(rst,baud16,txd);
input rst;
input baud16;
output txd;

reg [9:0] buff;
reg [9:0] buf2;
reg [5:0] cnt;
reg [3:0]  bitcnt;
reg [7:0] msg [0:7];
reg [7:0] msgndx;

assign txd = buff[9];

always @(posedge baud16)
if (rst) begin
    cnt <= 6'd0;
    buff <= 10'h3FF;
    buf2 <= 10'h3ff;
    msg[0] = "H";
    msg[1] = "i";
    msg[2] = "T";
    msg[3] = "h";
    msg[4] = "e";
    msg[5] = "r";
    msg[6] = "e";
    msg[7] = " ";
    msgndx <= 4'd0; 
end
else begin
    cnt <= cnt + 6'd1;
    if (cnt==6'd15) begin
        cnt <= 6'd0;
        bitcnt <= bitcnt + 4'd1;
        if (bitcnt==4'd9) begin
            bitcnt <= 4'd0;
            buff <= buf2;
            msgndx <= msgndx + 8'd1;
            buf2 <= {1'b0,msg[msgndx],^msg[msgndx]};
        end
        else
            buff <= {buff[8:0],1'b1};
    end
end

endmodule
