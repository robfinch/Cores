`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2007-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// PSG32.v
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
//	Registers
//  00      -------- ffffffff ffffffff ffffffff     freq [23:0]
//  04      -------- -------- pppppppp pppppppp     pulse width
//	08	    -------- -------- trsg-efo vvvvvv-- 	test, ringmod, sync, gate, filter, output, voice type
//  0C      -------- aaaaaaaa aaaaaaaa aaaaaaaa     attack
//  10      -------- dddddddd dddddddd dddddddd     decay
//  14      -------- -------- -------- ssssssss     sustain
//  18      -------- rrrrrrrr rrrrrrrr rrrrrrrr     release
//  1C      -------- -------- --aaaaaa aaaaaaa-     wave table base address
//											vvvvv
//											wnpst
//  20-3C   Voice #2
//  40-5C   Voice #3
//  60-7C   Voice #4
//
//	...
//	B0      -------- -------- -------- ----vvvv   volume (0-15)
//	B4      nnnnnnnn nnnnnnnn nnnnnnnn nnnnnnnn   osc3 oscillator 3
//	B8      -------- -------- -------- nnnnnnnn   env3 envelope 3
//  BC      -------- -------- -sss-sss -sss-sss   env state
//
//  C0-DC   -------- -------- s---kkkk kkkkkkkk   filter coefficients
//  E0-FC   -------- -------- -------- --------   reserved for more filter coefficients
//
//=============================================================================

module PSG32(rst_i, clk_i, cs_i, cyc_i, stb_i, ack_o, we_i, adr_i, dat_i, dat_o,
	m_adr_o, m_dat_i, o
);
// WISHBONE SYSCON
input rst_i;
input clk_i;			// system clock
// NON-WISHBONE
input cs_i;             // circuit select
// WISHBONE SLAVE
input cyc_i;			// cycle valid
input stb_i;			// circuit select
output ack_o;
input we_i;				// write
input [7:0] adr_i;		// address input
input [31:0] dat_i;		// data input
output [31:0] dat_o;	// data output

// NON-WISHBONE MASTER
output [13:0] m_adr_o;	// wave table address
input  [11:0] m_dat_i;	// wave table data input

output [17:0] o;

// I/O registers
reg [31:0] dat_o;
reg [13:0] m_adr_o;

reg [3:0] test;				// test (enable note generator)
reg [5:0] vt [3:0];			// voice type
reg [23:0] freq0, freq1, freq2, freq3;	// frequency control
reg [15:0] pw0, pw1, pw2, pw3;			// pulse width control
reg [3:0] gate;
reg [23:0] attack0, attack1, attack2, attack3;
reg [23:0] decay0, decay1, decay2, decay3;
reg [7:0] sustain0, sustain1, sustain2, sustain3;
reg [23:0] relese0, relese1, relese2, relese3;
reg [13:0] wtadr0, wtadr1, wtadr2, wtadr3;
reg [3:0] sync;
reg [3:0] ringmod;
reg [3:0] fm;
reg [3:0] outctrl;
reg [3:0] filt;                 // 1 = output goes to filter
reg [3:0] eg;                   // 1 = output goes through envelope generator
wire [31:0] acc0, acc1, acc2, acc3;
reg [3:0] volume;	// master volume
wire [11:0] tg1_o,tg2_o,tg3_o,tg4_o;    // tone generator output
wire [7:0] env;		// envelope generator output
wire [7:0] env0, env1, env2, env3;
wire [19:0] out0,out1,out2,out3;
wire [2:0] es0,es1,es2,es3;
wire [29:0] out4;
reg [21:0] sum,fsum;
reg [21:0] sum2;
wire [21:0] filtin1;	// FIR filter input
wire [37:0] filt_o;		// FIR filter output
reg [3:0] cnt;          // 4 bits needed for FIR
reg [3:0] cnt1,cnt2,cnt3;

// channel select signal
wire [1:0] sel = cnt[1:0];

and(cs, cyc_i, stb_i, cs_i);
reg ack1,ack2;
always @(posedge clk_i)
	ack1 <= cs;
always @(posedge clk_i)
    ack2 <= ack1 & cs;
assign ack_o = cs ? (we_i ? 1'b1 : ack2) : 1'b0;

// Register shadow ram for register readback
reg [31:0] reg_shadow [63:0];
reg [8:0] radr;
always @(posedge clk_i)
    if (cs & we_i)  reg_shadow[adr_i[7:2]] <= dat_i;
always @(posedge clk_i)
    radr <= adr_i[7:2];
wire [31:0] reg_shadow_o = reg_shadow[radr];

// write to registers
always @(posedge clk_i)
begin
	if (rst_i) begin
		freq0 <= 0;
		freq1 <= 0;
		freq2 <= 0;
		freq3 <= 0;
		pw0 <= 0;
		pw1 <= 0;
		pw2 <= 0;
		pw3 <= 0;
		test <= 0;
		vt[0] <= 0;
		vt[1] <= 0;
		vt[2] <= 0;
		vt[3] <= 0;
		gate <= 0;
		outctrl <= 0;
		filt <= 0;
		attack0 <= 0;
		attack1 <= 0;
		attack2 <= 0;
		attack3 <= 0;
		decay0 <= 0;
		sustain0 <= 0;
		relese0 <= 0;
		decay1 <= 0;
		sustain1 <= 0;
		relese1 <= 0;
		decay2 <= 0;
		sustain2 <= 0;
		relese2 <= 0;
		decay3 <= 0;
		sustain3 <= 0;
		relese3 <= 0;
		sync <= 0;
		ringmod <= 0;
		fm <= 0;
		volume <= 0;
	end
	else begin
		if (cs & we_i) begin
			case(adr_i[7:2])
			//---------------------------------------------------------
			6'd00:	freq0 <= dat_i[23:0];
			6'd01:	pw0 <= dat_i[15:0];
			6'd02:	begin
						vt[0] <= dat_i[7:2];
						outctrl[0] <= dat_i[8];
						filt[0] <= dat_i[9];
						eg[0] <= dat_i[10];
						fm[0] <= dat_i[11];
						gate[0] <= dat_i[12];
						sync[0] <= dat_i[13];
						ringmod[0] <= dat_i[14]; 
						test[0] <= dat_i[15];
					end
			6'd03:	attack0 <= dat_i[23:0];
			6'd04:  decay0 <= dat_i[23:0];
		    6'd05:  sustain0 <= dat_i[7:0];
			6'd06:  relese0 <= dat_i[23:0];
            6'd07:  wtadr0 <= {dat_i[13:1],1'b0};
               
			//---------------------------------------------------------
			6'd08:	freq1 <= dat_i[23:0];
			6'd09:	pw1 <= dat_i[15:0];
			6'd10:	begin
						vt[1] <= dat_i[7:2];
						outctrl[1] <= dat_i[8];
						filt[1] <= dat_i[9];
						eg[1] <= dat_i[10];
						fm[1] <= dat_i[11];
						gate[1] <= dat_i[12];
						sync[1] <= dat_i[13];
						ringmod[1] <= dat_i[14]; 
						test[1] <= dat_i[15];
					end
			6'd11:	attack1 <= dat_i[23:0];
            6'd12:  decay1 <= dat_i[23:0];
            6'd13:  sustain1 <= dat_i[7:0];
            6'd14:  relese1 <= dat_i[23:0];
            6'd15:  wtadr1 <= {dat_i[13:1],1'b0};

			//---------------------------------------------------------
			6'd16:	freq2 <= dat_i[23:0];
			6'd17:	pw2 <= dat_i[15:0];
			6'd18:	begin
						vt[2] <= dat_i[7:2];
						outctrl[2] <= dat_i[8];
						filt[2] <= dat_i[9];
						eg[2] <= dat_i[10];
						fm[2] <= dat_i[11];
						gate[2] <= dat_i[12];
						sync[2] <= dat_i[5];
						outctrl[0] <= dat_i[13];
						ringmod[2] <= dat_i[14]; 
						test[2] <= dat_i[15];
					end
			6'd19:	attack2 <= dat_i[23:0];
            6'd20:  decay2 <= dat_i[23:0];
            6'd21:  sustain2 <= dat_i[7:0];
            6'd22:  relese2 <= dat_i[23:0];
            6'd23:  wtadr2 <= {dat_i[13:1],1'b0};

			//---------------------------------------------------------
			6'd24:	freq3 <= dat_i[23:0];
			6'd25:	pw3 <= dat_i[15:0];
			6'd26:	begin
						vt[3] <= dat_i[7:2];
						outctrl[3] <= dat_i[8];
						filt[3] <= dat_i[9];
						eg[3] <= dat_i[10];
						fm[3] <= dat_i[11];
						gate[3] <= dat_i[12];
						sync[3] <= dat_i[13];
						ringmod[3] <= dat_i[14]; 
						test[3] <= dat_i[15];
					end
			6'd27:	attack3 <= dat_i[23:0];
            6'd28:  decay3 <= dat_i[23:0];
            6'd29:  sustain3 <= dat_i[7:0];
            6'd30:  relese3 <= dat_i[23:0];
            6'd31:  wtadr3 <= {dat_i[13:1],1'b0};

			//---------------------------------------------------------
			6'd44:	volume <= dat_i[3:0];

			default:	;
			endcase
		end
	end
end


always @(posedge clk_i)
    case(adr_i[7:2])
    6'd45:	begin
            dat_o <= acc3;
            end
    6'd46:	begin
            dat_o <= {24'h0,env3};
            end
    6'd47:  dat_o <= {17'h0,es3,1'b0,es2,1'b0,es1,1'b0,es0};
    default: begin
            dat_o <= reg_shadow_o;
            end
    endcase

wire [13:0] madr;
mux4to1 #(12) u11
(
	.e(1'b1),
	.s(cnt),
	.i0(wtadr0 + {acc0[27:17],1'b0}),
	.i1(wtadr1 + {acc1[27:17],1'b0}),
	.i2(wtadr2 + {acc2[27:17],1'b0}),
	.i3(wtadr3 + {acc3[27:17],1'b0}),
	.z(madr)
);
always @(posedge clk_i)
    m_adr_o <= madr;
wire [11:0] wave_i = m_dat_i;

// This counter controls channel multiplexing for the wave table
// And controls filtering
always @(posedge clk_i)
if (rst_i)
    cnt <= 4'd0;
else
    cnt <= cnt + 4'd1;

// note generator - multi-channel
PSGToneGenerator u1a
(
    .rst(rst_i),
    .clk(clk_i),
    .ack(sel==2'b11),
    .test(test[0]),
    .vt(vt[0]),
    .freq(freq0),
    .pw(pw0),
    .acc(acc0),
    .pch_i(tg4_o),
    .prev_acc(acc3),
    .wave(wave_i),
    .sync(sync[0]),
    .ringmod(ringmod[0]),
    .fm_i(fm[0]),
    .o(tg1_o)
);

PSGToneGenerator u1b
(
    .rst(rst_i),
    .clk(clk_i),
    .ack(sel==2'b00),
    .test(test[1]),
    .vt(vt[1]),
    .freq(freq1),
    .pw(pw1),
    .acc(acc1),
    .pch_i(tg1_o),
    .prev_acc(acc0),
    .wave(wave_i),
    .sync(sync[1]),
    .ringmod(ringmod[1]),
    .fm_i(fm[1]),
    .o(tg2_o)
);

PSGToneGenerator u1c
(
    .rst(rst_i),
    .clk(clk_i),
    .ack(sel==2'b01),
    .test(test[2]),
    .vt(vt[2]),
    .freq(freq2),
    .pw(pw2),
    .acc(acc2),
    .pch_i(tg2_o),
    .prev_acc(acc1),
    .wave(wave_i),
    .sync(sync[2]),
    .ringmod(ringmod[2]),
    .fm_i(fm[2]),
    .o(tg3_o)
);

PSGToneGenerator u1d
(
    .rst(rst_i),
    .clk(clk_i),
    .ack(sel==2'b10),
    .test(test[3]),
    .vt(vt[3]),
    .freq(freq3),
    .pw(pw3),
    .acc(acc3),
    .pch_i(tg3_o),
    .prev_acc(acc2),
    .wave(wave_i),
    .sync(sync[3]),
    .ringmod(ringmod[3]),
    .fm_i(fm[3]),
    .o(tg4_o)
);

PSGEnvelopeGenerator u2a
(
    .rst(rst_i),
    .clk(clk_i),
    .gate(gate[0]),
    .attack(attack0),
    .decay(decay0),
    .sustain(sustain0),
    .relese(relese0),
    .o(env0),
    .envState(es0)
);

PSGEnvelopeGenerator u2b
(
    .rst(rst_i),
    .clk(clk_i),
    .gate(gate[1]),
    .attack(attack1),
    .decay(decay1),
    .sustain(sustain1),
    .relese(relese1),
    .o(env1),
    .envState(es1)
);

PSGEnvelopeGenerator u2c
(
    .rst(rst_i),
    .clk(clk_i),
    .gate(gate[2]),
    .attack(attack2),
    .decay(decay2),
    .sustain(sustain2),
    .relese(relese2),
    .o(env2),
    .envState(es2)
);

PSGEnvelopeGenerator u2d
(
    .rst(rst_i),
    .clk(clk_i),
    .gate(gate[3]),
    .attack(attack3),
    .decay(decay3),
    .sustain(sustain3),
    .relese(relese3),
    .o(env3),
    .envState(es3)
);

// shape output according to envelope
PSGShaper u5a
(
	.clk_i(clk_i),
	.ce(1'b1),
	.tgi(tg1_o),
	.env(eg[0] ? env0 : 8'hFF),
	.o(out0)
);

PSGShaper u5b
(
	.clk_i(clk_i),
	.ce(1'b1),
	.tgi(tg2_o),
	.env(eg[1] ? env1 : 8'hFF),
	.o(out1)
);

PSGShaper u5c
(
	.clk_i(clk_i),
	.ce(1'b1),
	.tgi(tg3_o),
	.env(eg[2] ? env2 : 8'hFF),
	.o(out2)
);

PSGShaper u5d
(
	.clk_i(clk_i),
	.ce(1'b1),
	.tgi(tg4_o),
	.env(eg[3] ? env3 : 8'hFF),
	.o(out3)
);

always @(posedge clk_i)
	cnt1 <= cnt;
always @(posedge clk_i)
	cnt2 <= cnt1;
always @(posedge clk_i)
	cnt3 <= cnt2;

// Sum the channels not going to the filter
always @(posedge clk_i)
sum <= 
    {2'd0,(out0 & {20{outctrl[0]}})} +
    {2'd0,(out1 & {20{outctrl[1]}})} +
    {2'd0,(out2 & {20{outctrl[2]}})} +
    {2'd0,(out3 & {20{outctrl[3]}})};

// Sum the channels going to the filter
always @(posedge clk_i)
fsum <= 
    {2'd0,(out0 & {20{filt[0]}})} +
    {2'd0,(out1 & {20{filt[1]}})} +
    {2'd0,(out2 & {20{filt[2]}})} +
    {2'd0,(out3 & {20{filt[3]}})};

// The FIR filter
PSGFilter2 u8
(
	.rst(rst_i),
	.clk(clk_i),
	.cnt(cnt2),
	.wr(we_i && stb_i && adr_i[7:6]==3'b11),
    .adr(adr_i[5:2]),
    .din({dat_i[15],dat_i[11:0]}),
    .i(fsum),
    .o(filt_o)
);

// Sum the filtered and unfiltered output
always @(posedge clk_i)
	sum2 <= sum + filt_o[37:16];

// Last stage:
// Adjust output according to master volume
PSGVolumeControl u10
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.i(sum2),
	.volume(volume),
	.o(out4)
);

assign o = out4[29:12];

endmodule
