
module TokenDetect(a, b, shamt);
input [9:0] a;
input [9:0] b;
output reg [4:0] shamt;
parameter kCtlTkn0 = 10'b1101010100;
parameter kCtlTkn1 = 10'b0010101011;
parameter kCtlTln2 = 10'b0101010100;
parameter kCtlTkn3 = 10'b1010101011;
integer nn;
genvar g;

wire [19:0] ab = {a,b};

generate begin : gTest
begin
  shamt <= 5'd31;
  for (g = 19; g <= 10; g = g - 1)
    if (ab[g:g-9]==kCtlTkn0)
      shamt <= 19-g;
    else if (ab[g:g-9]==kCtlTkn1)
      shamt <= 19-g;
    else if (ab[g:g-9]==kCtlTkn2)
      shamt <= 19-g;
    else if (ab[g:g-9]==kCtlTkn3)
      shamt <= 19-g;
end
endgenerate

endmodule
