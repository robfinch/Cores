`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineer: Arthur Brown
// 
// Create Date: 08/16/2016 01:31:44 PM
// Module Name: block_rom
// Project Name: OLED Demo
// Target Devices: Nexys Video
// Tool Versions: Vivado 2016.2
// Description: Infers a single port block ROM loaded with the contents of the file from FILENAME
// 
// Revision 0.01 - File Created
//
//////////////////////////////////////////////////////////////////////////////////


module block_rom(
    input clk,
    input [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] dout
);
    parameter DATA_WIDTH=8, ADDR_WIDTH=8, FILENAME="charLib.dat";
    localparam LENGTH=2**ADDR_WIDTH;
    reg [DATA_WIDTH-1:0] mem [LENGTH-1:0];
    initial $readmemh(FILENAME, mem);
    always@(posedge clk)
        dout <= mem[addr];
endmodule
