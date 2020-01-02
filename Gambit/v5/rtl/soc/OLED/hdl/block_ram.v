`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineer: Arthur Brown
// 
// Create Date: 08/30/2016
// Module Name: block_rom
// Project Name: OLED Demo
// Target Devices: Nexys Video
// Tool Versions: Vivado 2016.2
// Description: Infers a block RAM with read and write ports. If INIT_FROM_FILE, initially loaded with the contents of the file from FILENAME.
// 
// Revision 0.01 - File Created
//
//////////////////////////////////////////////////////////////////////////////////


module block_ram(
    input                 clk,
    input                 write_en,
    input      [ADDR_WIDTH-1:0] write_addr,
    input      [DATA_WIDTH-1:0] write_data,
    input      [ADDR_WIDTH-1:0] read_addr,
    output reg [DATA_WIDTH-1:0] read_data
    );
    parameter DATA_WIDTH=8,
              ADDR_WIDTH=8,
              INIT_FROM_FILE="false",
              INIT_FILENAME="foo.dat";
    
    reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];
    
    initial begin
        if (INIT_FROM_FILE == "true")
            $readmemh(INIT_FILENAME, mem);
    end
    always@(posedge clk) begin
        if (write_en)
            mem[write_addr] <= write_data;
        read_data <= mem[read_addr];
    end
endmodule
