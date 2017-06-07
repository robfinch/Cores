
module Butterfly_tb();
reg rst;
reg clk;

initial begin
    #0 rst = 0;
    #0 clk = 0;
    #10 rst = 1;
    #50 rst = 0;
end

always
    #5 clk = ~clk;

endmodule
