`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
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
//
//	Verilog 1995
//
// ============================================================================
//
`define HIGH    1'b1
`define LOW     1'b0

`define MSG_DST     127:120
`define MSG_X       127:124
`define MSG_Y       123:120
`define MSG_Z       63:60
`define MSG_SRC     119:112
`define MSG_ROUT    111:80
`define MSG_CTRL    79
`define MSG_TTL     77:72
`define MSG_TYPE    71:64
`define MSG_GDST    63:60
`define MSG_GSRC    59:56

module BMCRouterTop(X, Y, Z, rst_i, clk_i, sclk, cs_i, cyc_i, stb_i, ack_o, we_i, adr_i, dat_i, dat_o, rxdX, rxdY, rxdZ, txdX, txdY, txdZ);
parameter HAS_ZROUTE = 0;
parameter ZROUTE_COL = 4'd4;
parameter ENABLE_ZROUTE = 1'b0;
input [3:0] X;      // router address
input [3:0] Y;      // router address
input [3:0] Z;
input rst_i;
input clk_i;
input sclk;
input cs_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [7:0] adr_i;
input [135:0] dat_i;
output reg [135:0] dat_o;
input [3:0] rxdX;
input [3:0] rxdY;
input [4-HAS_ZROUTE:0] rxdZ; 
output [3:0] txdX;
output [3:0] txdY;
output [4-HAS_ZROUTE:0] txdZ;

reg rxCycX, rxStbX, rxWeX, rxCsX;
reg rxCycY, rxStbY, rxWeY, rxCsY;
reg rxCycZ, rxStbZ, rxWeZ, rxCsZ;
reg txCycX, txStbX, txWeX, txCsX;
reg txCycY, txStbY, txWeY, txCsY;
reg txCycZ, txStbZ, txWeZ, txCsZ;
wire dpX,dpY,dpZ;
wire rxAckX,rxAckY,rxAckZ,txAckX,txAckY,txAckZ;
wire txEmptyX,txEmptyY,txEmptyZ;
wire [127:0] rxDatoX,rxDatoY,rxDatoZ;
reg [127:0] txDatiX, txDatiY, txDatiZ;
reg [127:0] rxBuf, txBuf, txBuf2, fifoDati;
wire [127:0] fifoDato;
wire [5:0] fifocnt;
wire fifofull;
wire empty;
wire [5:0] rxFifoCntX,rxFifoCntY,rxFifoCntZ;
wire rxFifoFullX,rxFifoFullY,rxFifoFullZ;
reg snoop;

wire cs = cs_i & cyc_i & stb_i;
reg rdy1;
always @(posedge clk_i)
    rdy1 <= cs;
assign ack_o = cs ? (we_i ? 1'b1 : rdy1) : 1'b0;

wire rdf;
reg wf, dpTx;
reg [3:0] state;
parameter IDLE  = 4'd0;
parameter ACKRXX = 4'd1;
parameter CHK_MATCHX = 4'd2;
parameter NACKTXX = 4'd3;
parameter NACKTXY = 4'd4;
parameter CHK_MATCHY = 4'd5;
parameter ACKRXY = 4'd6;
parameter CHK_MATCHT = 4'd7;
parameter TXGBL = 4'd8;
parameter NACKTXXG = 4'd9;
parameter TXGBLY = 4'd10;
parameter ACKRXZ = 4'd11;
parameter CHK_MATCHZ = 4'd12;
parameter NACKTXZG = 4'd13;
parameter TXGBLZ = 4'd14;
parameter NACKTXZ = 4'd15;

routerRxBs u1 (
	// WISHBONE SoC bus interface
	.rst_i(rst_i),			// reset
	.clk_i(clk_i),			// clock
	.cyc_i(rxCycX),			// cycle is valid
	.stb_i(rxStbX),			// strobe
	.ack_o(rxAckX),			// data is ready
	.we_i(rxWeX),				// write (this signal is used to qualify reads)
	.dat_o(rxDatoX),		// data out
	//------------------------
	.cs_i(rxCsX),				// chip select
	.sclk(sclk),
	.clear(),			// clear reciever
	.rxd(rxdX),				// external serial input
	.frame_err(),		// framing error
	.overrun(),			// receiver overrun
	.fifocnt(rxFifoCntX),
	.fifofull(rxFifoFullX)
);

routerTxBs u3 (
	// WISHBONE SoC bus interface
	.rst_i(rst_i),		// reset
	.clk_i(clk_i),		// clock
	.cyc_i(txCycX),		// cycle valid
	.stb_i(txStbX),		// strobe
	.ack_o(txAckX),		// transfer done
	.we_i(txWeX),		// write transmitter
	.dat_i(txDatiX),   // data in
	//--------------------
	.cs_i(txCsX),			// chip select
	.sclk(sclk),
	.cts(1'b1),			// clear to send
	.txd(txdX),		// external serial output
	.empty(txEmptyX)	    // buffer is empty
);

routerRxBs u5 (
	// WISHBONE SoC bus interface
	.rst_i(rst_i),			// reset
	.clk_i(clk_i),			// clock
	.cyc_i(rxCycY),			// cycle is valid
	.stb_i(rxStbY),			// strobe
	.ack_o(rxAckY),			// data is ready
	.we_i(rxWeY),				// write (this signal is used to qualify reads)
	.dat_o(rxDatoY),		// data out
	//------------------------
	.cs_i(rxCsY),				// chip select
	.sclk(sclk),
	.clear(),			// clear reciever
	.rxd(rxdY),				// external serial input
	.frame_err(),		// framing error
	.overrun(),			// receiver overrun
	.fifocnt(rxFifoCntY),
	.fifofull(rxFifoFullY)
);

routerTxBs u7 (
	// WISHBONE SoC bus interface
	.rst_i(rst_i),		// reset
	.clk_i(clk_i),		// clock
	.cyc_i(txCycY),		// cycle valid
	.stb_i(txStbY),		// strobe
	.ack_o(txAckY),		// transfer done
	.we_i(txWeY),		// write transmitter
	.dat_i(txDatiY),   // data in
	//--------------------
	.cs_i(txCsY),			// chip select
	.sclk(sclk),
	.cts(1'b1),		// clear to send
	.txd(txdY),		// external serial output
	.empty(txEmptyY)	    // buffer is empty
);

generate begin
if (HAS_ZROUTE==1) begin
routerRxBs u10 (
	// WISHBONE SoC bus interface
	.rst_i(rst_i),			// reset
	.clk_i(clk_i),			// clock
	.cyc_i(rxCycZ),			// cycle is valid
	.stb_i(rxStbZ),			// strobe
	.ack_o(rxAckZ),			// data is ready
	.we_i(rxWeZ),				// write (this signal is used to qualify reads)
	.dat_o(rxDatoZ),		// data out
	//------------------------
	.cs_i(rxCsZ),				// chip select
	.sclk(sclk),
	.clear(),			// clear reciever
	.rxd(rxdZ),				// external serial input
	.frame_err(),		// framing error
	.overrun(),			// receiver overrun
	.fifocnt(rxFifoCntZ),
	.fifofull(rxFifoFullZ)
);

routerTxBs u11 (
	// WISHBONE SoC bus interface
	.rst_i(rst_i),		// reset
	.clk_i(clk_i),		// clock
	.cyc_i(txCycZ),		// cycle valid
	.stb_i(txStbZ),		// strobe
	.ack_o(txAckZ),		// transfer done
	.we_i(txWeZ),		// write transmitter
	.dat_i(txDatiZ),   // data in
	//--------------------
	.cs_i(txCsZ),			// chip select
	.sclk(sclk),
	.cts(1'b1),		// clear to send
	.txd(txdZ),		// external serial output
	.empty(txEmptyZ)    // buffer is empty
);
end
else if (HAS_ZROUTE==2) begin
routerRxBsZ u6 (
	// WISHBONE SoC bus interface
	.rst_i(rst_i),			// reset
	.clk_i(clk_i),			// clock
	.cyc_i(rxCycZ),			// cycle is valid
	.stb_i(rxStbZ),			// strobe
	.ack_o(rxAckZ),			// data is ready
	.we_i(rxWeZ),				// write (this signal is used to qualify reads)
	.dat_o(rxDatoZ),		// data out
	//------------------------
	.cs_i(rxCsZ),				// chip select
	.sclk(sclk),
	.clear(),			// clear reciever
	.rxd(rxdZ),				// external serial input
	.frame_err(),		// framing error
	.overrun(),			// receiver overrun
	.fifocnt(rxFifoCntZ),
	.fifofull(rxFifoFullZ)
);

routerTxBsZ u8 (
	// WISHBONE SoC bus interface
	.rst_i(rst_i),		// reset
	.clk_i(clk_i),		// clock
	.cyc_i(txCycZ),		// cycle valid
	.stb_i(txStbZ),		// strobe
	.ack_o(txAckZ),		// transfer done
	.we_i(txWeZ),		// write transmitter
	.dat_i(txDatiZ),   // data in
	//--------------------
	.cs_i(txCsZ),			// chip select
	.sclk(sclk),
	.cts(1'b1),		// clear to send
	.txd(txdZ),		// external serial output
	.empty(txEmptyZ)	    // buffer is empty
);
end
else begin
assign rxFifoFullZ = 1'b0;
assign rxFifoCntZ = 6'h00;
assign txdZ = 4'h0;
assign txEmptyZ = 1'b1;
end
end
endgenerate

routerFifo3 u9
(
  .clk(clk_i),              // input wire clk
  .rst(rst_i),              // input wire srst
  .din(fifoDati),                // input wire [127 : 0] din
  .wr_en(wf),            // input wire wr_en
  .rd_en(rdf),            // input wire rd_en
  .dout(fifoDato),              // output wire [127 : 0] dout
  .full(fifofull),             // output wire full
  .empty(),            // output wire empty
  .data_count(fifocnt)  // output wire [4 : 0] data_count
);
/*
routerFifo ufifo
(
  .wclk(clk_i),
  .wrst(rst_i),
  .di(fifoDati),
  .wr(wf),
  .rclk(clk_i),
  .rrst(rst_i),
  .rd(rdf),
  .dout(fifoDato),
  .cnt(fifocnt)
);
*/
always @(posedge clk_i)
    casex(adr_i[4:0])
    5'h00:  dat_o <= {fifofull,1'b0,fifocnt,fifoDato};
    5'h11:  dat_o <= {snoop,7'h0};
    5'h12:  dat_o <= dpTx;
    endcase

edge_det(.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(cs && !we_i && adr_i[4:0]==5'h0), .pe(rdf), .ne(), .ee() );

always @(posedge clk_i)
if (rst_i) begin
    wf <= 1'b0;
    rdf <= 1'b0;
    dpTx <= 1'b0;
    state <= IDLE;
    rxCycX <= `LOW;
    rxStbX <= `LOW;
    rxWeX <= `LOW;
    rxCsX <= `LOW;
    rxCycY <= `LOW;
    rxStbY <= `LOW;
    rxWeY <= `LOW;
    rxCsY <= `LOW;
    rxCycZ <= `LOW;
    rxStbZ <= `LOW;
    rxWeZ <= `LOW;
    rxCsZ <= `LOW;
    txCycX <= `LOW;
    txStbX <= `LOW;
    txWeX <= `LOW;
    txCsX <= `LOW;
    txCycY <= `LOW;
    txStbY <= `LOW;
    txWeY <= `LOW;
    txCsY <= `LOW;
    txCycZ <= `LOW;
    txStbZ <= `LOW;
    txWeZ <= `LOW;
    txCsZ <= `LOW;
end
else begin
wf <= 1'b0;
rdf <= 1'b0;
    if (cs & ~we_i) begin
        case(adr_i[4:0])
        5'h0:   rdf <= 1'b1;
        endcase
    end
    if (cs & we_i) begin
        case(adr_i[4:0])
        5'h0:   txBuf <= dat_i[127:0];
        5'h11:  begin
                snoop <= dat_i[7];
                rdf <= dat_i[6];
                end
        5'h12:  dpTx <= 1'b1;
        endcase
    end
case(state)
IDLE:
    if ({rxFifoFullX,rxFifoCntX} != 6'd0) begin
        rxCycX <= `HIGH;
        rxStbX <= `HIGH;
        rxWeX <= `LOW;
        rxCsX <= `HIGH;
        state <= ACKRXX;
    end
    else if ({rxFifoFullY,rxFifoCntY} != 6'd0) begin
        rxCycY <= `HIGH;
        rxStbY <= `HIGH;
        rxWeY <= `LOW;
        rxCsY <= `HIGH;
        state <= ACKRXY;
    end
    else if ({rxFifoFullZ,rxFifoCntZ} != 6'd0) begin
        rxCycZ <= `HIGH;
        rxStbZ <= `HIGH;
        rxWeZ <= `LOW;
        rxCsZ <= `HIGH;
        state <= ACKRXZ;
    end
    else if (dpTx) begin
        state <= CHK_MATCHT;
    end
ACKRXX:
if (rxAckX) begin
    rxCycX <= `LOW;
    rxStbX <= `LOW;
    rxWeX <= `LOW;
    rxCsX <= `LOW;
    rxBuf <= rxDatoX;
    state <= CHK_MATCHX;
end
CHK_MATCHX:
    chk_match(rxBuf,0);
NACKTXX:
    if (txAckX) begin
        txCycX <= `LOW;
        txStbX <= `LOW;
        txWeX <= `LOW;
        txCsX <= `LOW;
        state <= IDLE;        
    end
NACKTXY:
    if (txAckY) begin
        txCycY <= `LOW;
        txStbY <= `LOW;
        txWeY <= `LOW;
        txCsY <= `LOW;
        state <= IDLE;        
    end
NACKTXZ:
    if (txAckZ) begin
        txCycZ <= `LOW;
        txStbZ <= `LOW;
        txWeZ <= `LOW;
        txCsZ <= `LOW;
        state <= IDLE;        
    end
ACKRXY:
    if (rxAckY) begin
        rxCycY <= `LOW;
        rxStbY <= `LOW;
        rxWeY <= `LOW;
        rxCsY <= `LOW;
        rxBuf <= rxDatoY;
        state <= CHK_MATCHY;
    end
ACKRXZ:
    if (rxAckZ) begin
        rxCycZ <= `LOW;
        rxStbZ <= `LOW;
        rxWeZ <= `LOW;
        rxCsZ <= `LOW;
        rxBuf <= rxDatoZ;
        state <= CHK_MATCHZ;
    end
CHK_MATCHY:
    chk_match(rxBuf,0);
CHK_MATCHZ:
    chk_match(rxBuf,0);
CHK_MATCHT:
    chk_match(txBuf,1);
TXGBL:
    if (txEmptyX) begin
        txCycX <= `HIGH;
        txStbX <= `HIGH;
        txWeX <= `HIGH;
        txCsX <= `HIGH;
        txDatiX <= txBuf2;
        //txDatiX[`MSG_ROUT] <= {txBuf[`MSG_ROUT],2'b01};
        state <= NACKTXXG;
    end
NACKTXXG:
    begin
        if (txAckX) begin
            txCycX <= `LOW;
            txStbX <= `LOW;
            txWeX <= `LOW;
            txCsX <= `LOW;
            state <= TXGBLY;
        end
    end
TXGBLY:
    begin
        if (txEmptyY) begin
            txCycY <= `HIGH;
            txStbY <= `HIGH;
            txWeY <= `HIGH;
            txCsY <= `HIGH;
            txDatiY <= txBuf2;
            //txDatiY[`MSG_ROUT] <= {txBuf[`MSG_ROUT],2'b10};
            state <= HAS_ZROUTE ? NACKTXZG : NACKTXY;
        end
    end
NACKTXZG:
    begin
        if (txAckY) begin
            txCycY <= `LOW;
            txStbY <= `LOW;
            txWeY <= `LOW;
            txCsY <= `LOW;
            state <= TXGBLZ;
        end
    end
TXGBLZ:
    if (txEmptyZ) begin
        txCycZ <= `HIGH;
        txStbZ <= `HIGH;
        txWeZ <= `HIGH;
        txCsZ <= `HIGH;
        txDatiZ <= txBuf2;
        //txDatiY[`MSG_ROUT] <= {txBuf[`MSG_ROUT],2'b10};
        state <= NACKTXZ;
    end

endcase
end

task chk_match;
input [127:0] buff;
input rsttx;            // option to reset transmit busy indicator
begin
    if (buff[`MSG_TTL]==6'h00)
        state <= IDLE;
    else
    case(buff[`MSG_CTRL])
    // Normal routing
    default:
        if (buff[`MSG_DST]==8'hFF) begin
            txBuf2 <= buff;
            txBuf2[`MSG_TTL] <= buff[`MSG_TTL] - 6'd1;
            wf <= 1'b1;
            fifoDati <= buff;
            state <= TXGBL;
            if (rsttx)
                dpTx <= 1'b0;
        end
        // Check for illegal message destination - ignore message
        else if (buff[`MSG_X]<4'h1 || buff[`MSG_X] > 4'h8 || buff[`MSG_Y]<4'h1 || buff[`MSG_Y] > 4'h7) begin
            state <= IDLE;
            if (rsttx)
                dpTx <= 1'b0;
        end
        else if (buff[`MSG_Z]!=Z && ENABLE_ZROUTE) begin
            if (HAS_ZROUTE) begin
                if (txEmptyZ) begin
                    if (snoop) begin
                        wf <= 1'b1;
                        fifoDati <= buff;
                    end
                    txCycZ <= `HIGH;
                    txStbZ <= `HIGH;
                    txWeZ <= `HIGH;
                    txCsZ <= `HIGH;
                    txDatiZ <= buff;
                    txDatiZ[`MSG_TTL] <= buff[`MSG_TTL] - 6'd1;
                    //txDatiX[`MSG_ROUT] <= {buff[`MSG_ROUT],2'b01};
                    state <= NACKTXZ;
                    if (rsttx)
                        dpTx <= 1'b0;
                end
            end
            else begin
                if (buff[`MSG_X]!=ZROUTE_COL)
                    txX(buff,rsttx);
                else
                    txY(buff,rsttx);
            end
        end
        else if (buff[`MSG_X]!=X)
            txX(buff,rsttx);
        else if (buff[`MSG_Y]!=Y)
            txY(buff,rsttx);
        else begin
            wf <= 1'b1;
            fifoDati <= buff;
            state <= IDLE;
            if (rsttx)
                dpTx <= 1'b0;
        end
    // Forced routing: route according to MSG_ROUT
    /* Makes the router too big.
    1'b1:
        if (buff[`MSG_DST]==8'hFF) begin
            txBuf <= buff;
            wf <= 1'b1;
            fifoDati <= buff;
            state <= TXGBL;
        end
        else begin
            if (snoop) begin
                wf <= 1'b1;
                fifoDati <= buff;
            end
            case(buff[111:110])
            2'b01:  // rout in X direction
                if (txEmptyX) begin
                    txCycX <= `HIGH;
                    txStbX <= `HIGH;
                    txWeX <= `HIGH;
                    txCsX <= `HIGH;
                    txDatiX <= buff;
                    // Eat up the message route bits
                    txDatiX[`MSG_ROUT] <= {buff[109:80],2'b00};
                    state <= NACKTXX;
                end
            2'b10:  // rout in Y direction
                if (txEmptyY) begin
                    txCycY <= `HIGH;
                    txStbY <= `HIGH;
                    txWeY <= `HIGH;
                    txCsY <= `HIGH;
                    txDatiY <= buff;
                    // Eat up the message route bits
                    txDatiY[`MSG_ROUT] <= {buff[109:80],2'b00};
                    state <= NACKTXY;
                end
            default:    // no more routing info
                begin
                    wf <= 1'b1;
                    fifoDati <= buff;
                    state <= IDLE;
                end
            endcase
        end
        */
    endcase
end
endtask

task txX;
input [127:0] buff;
input rsttx;
begin
    if (txEmptyX) begin
        if (snoop) begin
            wf <= 1'b1;
            fifoDati <= buff;
        end
        txCycX <= `HIGH;
        txStbX <= `HIGH;
        txWeX <= `HIGH;
        txCsX <= `HIGH;
        txDatiX <= buff;
        txDatiX[`MSG_TTL] <= buff[`MSG_TTL] - 6'd1;
        //txDatiX[`MSG_ROUT] <= {buff[`MSG_ROUT],2'b01};
        state <= NACKTXX;
        if (rsttx)
            dpTx <= 1'b0;
    end
end
endtask

task txY;
input [127:0] buff;
input rsttx;
begin
    if (txEmptyY) begin
        if (snoop) begin
            wf <= 1'b1;
            fifoDati <= buff;
        end
        txCycY <= `HIGH;
        txStbY <= `HIGH;
        txWeY <= `HIGH;
        txCsY <= `HIGH;
        txDatiY <= buff;
        txDatiY[`MSG_TTL] <= buff[`MSG_TTL] - 6'd1;
        //txDatiY[`MSG_ROUT] <= {buff[`MSG_ROUT],2'b10};
        state <= NACKTXY;
        if (rsttx)
            dpTx <= 1'b0;
    end
end
endtask

endmodule
