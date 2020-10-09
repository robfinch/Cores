
// Given the byte opcode, the instruction length is determined.
module rtf64_InsLength(i, o);
input [7:0] i;
output reg [3:0] o;

always @*
casez(i)
8'h00:  o = 4'd3;
8'h0F:  o = 4'd5;
8'h17:  o = 4'd6;
8'h1B:  o = 4'd5;
8'h30:  o = 4'd3;
8'h31:  o = 4'd3;
8'h32:  o = 4'd3;
8'h33:  o = 4'd3;
8'h34:  o = 4'd3;
8'h35:  o = 4'd3;
8'h36:  o = 4'd2;
8'h37:  o = 4'd4;
8'h38:  o = 4'd8;
8'h39:  o = 4'd8;
8'h3A:  o = 4'd8;
8'h3B:  o = 4'd8;
8'h3C:  o = 4'd8;
8'h3D:  o = 4'd8;
8'h3E:  o = 4'd8;
8'h3F:  o = 4'd8;
8'h40:  o = 4'd4;
8'h41:  o = 4'd5;
8'h42:  o = 4'd5;
8'h44:  o = 4'd2;
8'h45:  o = 4'd3;
8'h46:  o = 4'd3;
8'h47:  o = 4'd3;
8'h48:  o = 4'd3;
8'h49:  o = 4'd3;
8'h4A:  o = 4'd3;
8'h4B:  o = 4'd3;
8'h4C:  o = 4'd3;
8'h4D:  o = 4'd3;
8'h4E:  o = 4'd3;
8'h4F:  o = 4'd3;
8'h50:  o = 4'd3;
8'h51:  o = 4'd3;
8'h52:  o = 4'd3;
8'h53:  o = 4'd4;
8'h54:  o = 4'd3;
8'h55:  o = 4'd3;
8'h56:  o = 4'd3;
8'h57:  o = 4'd3;
8'h5E:  o = 4'd3;
8'h5F:  o = 4'd2;
8'h6?:  o = 4'd2;
8'h80:  o = 4'd3;
8'h81:  o = 4'd3;
8'h82:  o = 4'd3;
8'h83:  o = 4'd3;
8'h84:  o = 4'd3;
8'h85:  o = 4'd3;
8'h86:  o = 4'd3;
8'h87:  o = 4'd3;
8'h88:  o = 4'd3;
8'h89:  o = 4'd3;
8'h8A:  o = 4'd2;
8'h8B:  o = 4'd3;
8'h8E:  o = 4'd3;
8'h90:  o = 4'd3;
8'h97:  o = 4'd6;
8'hA0:  o = 4'd3;
8'hA1:  o = 4'd3;
8'hA2:  o = 4'd3;
8'hA3:  o = 4'd3;
8'hA4:  o = 4'd3;
8'hA5:  o = 4'd3;
8'hA6:  o = 4'd3;
8'hAA:  o = 4'd2;
8'hAB:  o = 4'd3;
8'hAC:  o = 4'd3;
8'hB0:  o = 4'd3;
8'hB7:  o = 4'd6;
8'hE1:  o = 4'd3;
8'hEA:  o = 4'd1;
8'hF1:  o = 4'd3;
default:  o = 4'd4;
endcase

endmodule
