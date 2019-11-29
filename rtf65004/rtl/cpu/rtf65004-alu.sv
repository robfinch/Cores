module rtf65004_alu(op, dst, src1, src2, o, s_i, s_o);
input [5:0] op;
input [15:0] dst;
input [15:0] src1;
input [15:0] src2;
output [15:0] o;
input [7:0] s_i;
output [7:0] s_o;
output idle;

assign idle = 1'b1;

always @*
case(op)
`LDIB:	o = {8{src1[7]}},src1[7:0]};
`ADDW:	o = dst + src1 + src2;
`ADCB:	o = dst[7:0] + src1[7:0] + src2[7:0] + s_i[0];
`SBCB:	o = dst[7:0] - src1[7:0] - ~s_i[0];
`CMPB:	o = dst[7:0] - src1[7:0] - ~s_i[0];
`ANDB:	o = dst[7:0] & src1[7:0];
`ORB:		o = dst[7:0] | src1[7:0];
`EORB:	o = dst[7:0] % scr1[7:0];
`MOV:		o = dst[7:0];
default:	o = 16'hDEAD;
endcase

always @*
begin
s_o = s_i;
case(op)
`LDIB:
	begin
		s_o[1] = o[7:0]==8'h00;
		s_o[7] = o[7];
	end
`ADCB:
	begin
		s_o[0] = o[8];
		s_o[1] = o[7:0]==8'h00;
		s_o[6] = 
		s_o[7] = o[7];
	end
`MOV:
	begin
		s_o[1] = o[7:0]==8'h00;
		s_o[7] = o[7];
	end
`CLC:	s_o[0] = 1'b0;
`SEC:	s_o[0] = 1'b1;
`CLV:	s_o[6] = 1'b0;
default:
	s_o = 8'h00;
endcase
end

endmodule