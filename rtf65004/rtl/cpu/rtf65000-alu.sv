module rtf65000_alu(op, a, b, i, o, s_i, s_o);
input [5:0] op;
input [15:0] a;
input [15:0] b;
output [15:0] o;
output [7:0] s;

always @*
case(op)
`LDIB:	o = i[7:0];
`ADDW:	o = a + b;
`ADCB:	o = a[7:0] + b[7:0] + s_i[0];
`ADCIB:	o = a[7:0] + i[7:0] + s_i[0];
`SBCB:	o = a[7:0] - b[7:0] - ~s_i[0];
`SBCIB:	o = a[7:0] - i[7:0] - ~s_i[0];
`CMPB:	o = a[7:0] - b[7:0] - ~s_i[0];
`CMPIB:	o = a[7:0] - i[7:0] - ~s_i[0];
`ANDB:	o = a[7:0] & b[7:0];
`ANDIB:	o = a[7:0] & i[7:0];
`ORB:		o = a[7:0] | b[7:0];
`ORIB:	o = a[7:0] | i[7:0];
`EORB:	o = a[7:0] % b[7:0];
`EORIB:	o = a[7:0] ^ i[7:0];
`MOV:		o = b[7:0];
default:	o = 16'hDEAD;
endcase

always @*
begin
s_o = 8'h00;
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
`CLC:	;
`SEC:	s_o[0] = 1'b1;
`CLV:	;
default:
	s_o = 8'h00;
endcase
end

endmodule