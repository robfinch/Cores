`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2007-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// PSGEnvelopeGenerator.v
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
//=============================================================================

module PSGEnvelopeGenerator(rst, srst, clk, gate, attack, decay, sustain, relese, o, envState);
input rst;					// reset
input srst;
input clk;					// core clock
input gate;
input [28:0] attack;
input [23:0] decay;
input [7:0] sustain;        // sustain level
input [23:0] relese;
output [7:0] o;
output [2:0] envState;

// envelope generator states
parameter ENV_IDLE = 3'd0;
parameter ENV_ATTACK = 3'd1;
parameter ENV_DECAY = 3'd2;
parameter ENV_SUSTAIN = 3'd3;
parameter ENV_RELEASE = 3'd4;

// Per channel count storage
reg [7:0] envCtr;
reg [7:0] envCtr2;
reg [7:0] iv;           // interval value for decay/release
reg [2:0] icnt;         // interval count
reg [28:0] envDvn;
reg [2:0] envState;

reg [2:0] envStateNxt;
reg [28:0] envStepPeriod;	// determines the length of one step of the envelope generator

integer n;

wire attack_next = envState==ENV_IDLE && gate;
wire decay_next = envState==ENV_ATTACK && envCtr==8'hFE && sustain != 8'hFF;
wire release_next = envState==ENV_SUSTAIN && !gate; 

// Envelope generate state machine
// Determine the next envelope state
always @*
begin
envStateNxt <= envState;    // default to hold state
case (envState)
ENV_IDLE:
    if (gate)
        envStateNxt <= ENV_ATTACK;
ENV_ATTACK:
    if (envCtr==8'hFE) begin
        if (sustain==8'hFF)
            envStateNxt <= ENV_SUSTAIN;
        else
            envStateNxt <= ENV_DECAY;
    end
ENV_DECAY:
    if (envCtr==sustain)
        envStateNxt <= ENV_SUSTAIN;
ENV_SUSTAIN:
    if (~gate)
        envStateNxt <= ENV_RELEASE;
ENV_RELEASE:
    if (envCtr==8'h00)
        envStateNxt <= ENV_IDLE;
    else if (gate)
        envStateNxt <= ENV_SUSTAIN;
// In case of hardware problem
default:
    envStateNxt <= ENV_IDLE;
endcase
end

always @(posedge clk)
if (rst|srst)
    envState <= ENV_IDLE;
else
    envState <= envStateNxt;


// Handle envelope counter
always @(posedge clk)
if (rst) begin
    envCtr <= 0;
    envCtr2 <= 0;
    icnt <= 0;
    iv <= 0;
end
else begin
case (envState)
ENV_IDLE:
    begin
    envCtr <= 0;
    envCtr2 <= 0;
    icnt <= 0;
    iv <= 0;
    end
ENV_SUSTAIN:
    begin
    envCtr2 <= 0;
    icnt <= 0;
    iv <= sustain >> 3;
    end
ENV_ATTACK:
    begin
    icnt <= 0;
    iv <= (8'hff - sustain) >> 3;
    if (envDvn==29'h0) begin
        envCtr2 <= 0;
        envCtr <= envCtr + 1;
    end
    end
ENV_DECAY,
ENV_RELEASE:
    if (envDvn==29'h0) begin
        envCtr <= envCtr - 1;
        if (envCtr2==iv) begin
            envCtr2 <= 0;
            if (icnt < 3'd7)
                icnt <= icnt + 1;
        end
        else
            envCtr2 <= envCtr2 + 1;
    end
endcase
end

// Determine envelope divider adjustment source
always @*
begin
case(envState)
ENV_ATTACK:	    envStepPeriod <= attack;
ENV_DECAY:		envStepPeriod <= decay;
ENV_RELEASE:	envStepPeriod <= relese;
default:		envStepPeriod <= 24'h0;
endcase
end


// double the delay at appropriate points
// for exponential modelling
wire [28:0] envStepPeriod1 = {4'b0,envStepPeriod} << icnt;


// handle the clock divider
// loadable down counter
// This sets the period of each step of the envelope
always @(posedge clk)
if (rst)
    envDvn <= 0;
else begin
    casex({attack_next,decay_next,release_next})
    3'b1xx: envDvn <= {4'h0,attack};
    3'b01x: envDvn <= {4'h0,decay};
    3'b001: envDvn <= {4'h0,relese};
    default:
        if (envDvn==29'h0)
            envDvn <= envStepPeriod1;
        else
            envDvn <= envDvn - 1;
    endcase
end

assign o = envCtr;

endmodule

