
module rfx32_cmp(a, b, o);
input value_t a;
input value_t b;
output value_t o;

always_comb
begin
	o = 'd0;
	o[0] = a == b;
	o[1] = a != b;
	o[2] = $signed(a) < $signed(b);
	o[3] = $signed(a) <= $signed(b);
	o[4] = $signed(a) >= $signed(b);
	o[5] = $signed(a) > $signed(b);
	o[6] = ~a[b[4:0]];
	o[7] =  a[b[4:0]];
	o[10] = a < b;
	o[11] = a <= b;
	o[12] = a >= b;
	o[13] = a > b;
end

endmodule
