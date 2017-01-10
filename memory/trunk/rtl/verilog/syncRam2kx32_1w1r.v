module syncRam2kx32_1w1r (wclk, wce, wr, wa, wd, rclk, rce, ra, o);
input wclk;
input wce;
input [3:0] wr;
input [10:0] wa;
input [31:0] wd;
input rclk;
input rce;
input [10:0] ra;
output [31:0] o;

syncRam2kx8_1rw1r um0 (
    .wclk(wclk),
    .wce(wce),
    .wr(wr[0]),
    .wa(wa),
    .wd(wd[7:0]),
    .rclk(rclk),
    .rce(1'b1),
    .ra(ra),
    .o(o[7:0])
);
syncRam2kx8_1rw1r um1 (
    .wclk(wclk),
    .wce(wce),
    .wr(wr[1]),
    .wa(wa),
    .wd(wd[15:8]),
    .rclk(rclk),
    .rce(1'b1),
    .ra(ra),
    .o(o[15:8])
);
syncRam2kx8_1rw1r um2 (
    .wclk(wclk),
    .wce(wce),
    .wr(wr[2]),
    .wa(wa),
    .wd(wd[23:16]),
    .rclk(rclk),
    .rce(1'b1),
    .ra(ra),
    .o(o[23:16])
);
syncRam2kx8_1rw1r um3 (
    .wclk(wclk),
    .wce(wce),
    .wr(wr[3]),
    .wa(wa),
    .wd(wd[31:24]),
    .rclk(rclk),
    .rce(1'b1),
    .ra(ra),
    .o(o[31:24])
);

endmodule
