module regfile(wclk, wa0, wa1, wa2, i0, i1, i2,
	ra0, ra1, ra2, ra3, ra4, ra5, ra6, ra7, ra8,
	o0, o1, o2, o3, o4, o5, o6, o7, o8);
input wclk;
input [5:0] wa0;
input [5:0] wa1;
input [5:0] wa2;
input [63:0] i0;
input [63:0] i1;
input [63:0] i2;
input [5:0] ra0;
input [5:0] ra1;
input [5:0] ra2;
input [5:0] ra3;
input [5:0] ra4;
input [5:0] ra5;
input [5:0] ra6;
input [5:0] ra7;
input [5:0] ra8;
output [63:0] o0;
output [63:0] o1;
output [63:0] o2;
output [63:0] o3;
output [63:0] o4;
output [63:0] o5;
output [63:0] o6;
output [63:0] o7;
output [63:0] o8;

reg [63:0] regs0 [63:0];
reg [63:0] regs1 [63:0];
reg [63:0] regs2 [63:0];
reg [1:0] whreg [63:0];

always @(posedge wclk)
begin
	regs0[wa0] <= i0;
	regs1[wa1] <= i1;
	regs2[wa2] <= i2;
	case({wa0==wa1,wa0==wa2,wa1==wa2})
	3'b000:
		begin
			whreg[wa0] <= 2'd0;
			whreg[wa1] <= 2'd1;
		end
	3'b001:
		begin
			whreg[wa0] <= 2'd0;
		end
	3'b010:
		begin
			whreg[wa1] <= 2'd1;
		end
	3'b100:
		begin
			whreg[wa1] <= 2'd1;
		end
	3'b011,3'b101,3'b110,	// hardware errors
	3'b111:	; // whreg[wa2] <= 2'd2;
	endcase
	whreg[wa2] <= 2'd2;
end

assign o0 = ra0 == 6'd0 ? 64'd0 : ra0==wa2 ? i2 : ra0==wa1 ? i1 : ra0==wa0 ? i0 : 
			whreg[ra0]==2'd0 ? regs0[ra0] : whreg[ra0]==2'd1 ? regs1[ra0] : regs2[ra0];
assign o1 = ra1 == 6'd0 ? 64'd0 : ra1==wa2 ? i2 : ra1==wa1 ? i1 : ra1==wa0 ? i0 : 
			whreg[ra1]==2'd0 ? regs0[ra1] : whreg[ra1]==2'd1 ? regs1[ra1] : regs2[ra1];
assign o2 = ra2 == 6'd0 ? 64'd0 : ra2==wa2 ? i2 : ra2==wa1 ? i1 : ra2==wa0 ? i0 : 
			whreg[ra2]==2'd0 ? regs0[ra2] : whreg[ra2]==2'd1 ? regs1[ra2] : regs2[ra2];
assign o3 = ra3 == 6'd0 ? 64'd0 : ra3==wa2 ? i2 : ra3==wa1 ? i1 : ra3==wa0 ? i0 : 
			whreg[ra3]==2'd0 ? regs0[ra3] : whreg[ra3]==2'd1 ? regs1[ra3] : regs2[ra3];
assign o4 = ra4 == 6'd0 ? 64'd0 : ra4==wa2 ? i2 : ra4==wa1 ? i1 : ra4==wa0 ? i0 : 
			whreg[ra4]==2'd0 ? regs0[ra4] : whreg[ra4]==2'd1 ? regs1[ra4] : regs2[ra4];
assign o5 = ra5 == 6'd0 ? 64'd0 : ra5==wa2 ? i2 : ra5==wa1 ? i1 : ra5==wa0 ? i0 : 
			whreg[ra5]==2'd0 ? regs0[ra5] : whreg[ra5]==2'd1 ? regs1[ra5] : regs2[ra5];
assign o6 = ra6 == 6'd0 ? 64'd0 : ra6==wa2 ? i2 : ra6==wa1 ? i1 : ra6==wa0 ? i0 : 
			whreg[ra6]==2'd0 ? regs0[ra6] : whreg[ra6]==2'd1 ? regs1[ra6] : regs2[ra6];
assign o7 = ra7 == 6'd0 ? 64'd0 : ra7==wa2 ? i2 : ra7==wa1 ? i1 : ra7==wa0 ? i0 : 
			whreg[ra7]==2'd0 ? regs0[ra7] : whreg[ra7]==2'd1 ? regs1[ra7] : regs2[ra7];
assign o8 = ra8 == 6'd0 ? 64'd0 : ra8==wa2 ? i2 : ra8==wa1 ? i1 : ra8==wa0 ? i0 : 
			whreg[ra8]==2'd0 ? regs0[ra8] : whreg[ra8]==2'd1 ? regs1[ra8] : regs2[ra8];

endmodule
