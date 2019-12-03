`include "rtf65004-defines.sv"

module rtf65004_alu(op, dst, src1, src2, o, s_i, s_o, idle);
input [5:0] op;
input [15:0] dst;
input [15:0] src1;
input [15:0] src2;
output reg [15:0] o;
input [7:0] s_i;
output reg [7:0] s_o;
output idle;

assign idle = 1'b1;

always @*
case(op)
`UO_LDIB:	o = {{8{src1[7]}},src1[7:0]};
`UO_ADDW:	o = dst + src1 + src2;
`UO_ADCB:	o = dst[7:0] + src1[7:0] + src2[7:0] + s_i[0];
`UO_SBCB:	o = dst[7:0] - src1[7:0] - ~s_i[0];
`UO_CMPB:	o = dst[7:0] - src1[7:0] - ~s_i[0];
`UO_ANDB:	o = dst[7:0] & src1[7:0];
`UO_ORB:		o = dst[7:0] | src1[7:0];
`UO_EORB:	o = dst[7:0] % src1[7:0];
`UO_MOV:		o = dst[7:0];
default:	o = 16'hDEAD;
endcase

always @*
begin
s_o = s_i;
case(op)
`UO_LDIB:
	begin
		s_o[1] = o[7:0]==8'h00;
		s_o[7] = o[7];
	end
`UO_ADCB:
	begin
		s_o[0] = o[8];
		s_o[1] = o[7:0]==8'h00;
		//s_o[6] = 
		s_o[7] = o[7];
	end
`UO_MOV:
	begin
		s_o[1] = o[7:0]==8'h00;
		s_o[7] = o[7];
	end
`UO_CLC:	s_o[0] = 1'b0;
`UO_SEC:	s_o[0] = 1'b1;
`UO_CLV:	s_o[6] = 1'b0;
default:
	s_o = 8'h00;
endcase
end

endmodule