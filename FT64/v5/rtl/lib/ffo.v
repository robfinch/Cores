
// Find first one
module ffo6(i, o);
input [5:0] i;
output reg [2:0] o;
always @*
casex(i)
6'b1xxxxx:  o <= 3'd5;
6'b01xxxx:  o <= 3'd4;
6'b001xxx:  o <= 3'd3;
6'b0001xx:  o <= 3'd2;
6'b00001x:  o <= 3'd1;
6'b000001:  o <= 3'd0;
default:    o <= 3'd7;
endcase
endmodule

module ffo12(i, o);
input [11:0] i;
output reg [3:0] o;

wire [2:0] o1,o2;
ffo6 u1 (i[11:6],o1);
ffo6 u2 (i[5:0],o2);
always @*
if (o1==3'd7 && o2==3'd7)
    o <= 4'd15;
else if (o1==3'd7)
    o <= o2;
else
    o <= 3'd6 + o1;

endmodule

module ffo24(i, o);
input [23:0] i;
output reg [4:0] o;

wire [3:0] o1,o2;
ffo12 u1 (i[23:12],o1);
ffo12 u2 (i[11:0],o2);
always @*
if (o1==4'd15 && o2==4'd15)
    o <= 5'd31;
else if (o1==4'd15)
    o <= o2;
else
    o <= 4'd12 + o1;

endmodule

module ffo48(i, o);
input [47:0] i;
output reg [5:0] o;

wire [4:0] o1,o2;
ffo24 u1 (i[47:24],o1);
ffo24 u2 (i[23:0],o2);
always @*
if (o1==5'd31 && o2==5'd31)
    o <= 6'd63;
else if (o1==5'd31)
    o <= o2;
else
    o <= 5'd24 + o1;

endmodule

module ffo96(i, o);
input [95:0] i;
output reg [6:0] o;

wire [5:0] o1,o2;
ffo48 u1 (i[95:48],o1);
ffo48 u2 (i[47:0],o2);
always @*
if (o1==6'd63 && o2==6'd63)
    o <= 7'd127;
else if (o1==6'd63)
    o <= o2;
else
    o <= 6'd48 + o1;

endmodule

