`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DigilentInc
// Engineer: Arthur Brown
// 
// Create Date: 10/08/2016 02:05:52 PM
// Module Name: debouncer
// Project Name: OLED Demo
// Description: Debounces an input signal. When input transitions, only transition output if input is stable for COUNT_MAX clock cycles.
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module debouncer(
    input clk,
    input A,
    output B
    );
    parameter COUNT_MAX=15, COUNT_WIDTH=4;
    reg [COUNT_WIDTH-1:0] count;
    reg [1:0] state=0;
    wire cen;
    assign B = state[1];
    assign cen = state[0];
    localparam Idle=2'b00,
               Tran=2'b01,
               Off=2'b00,
               On=2'b10;
    always@(posedge clk)
        case (state)
        Off|Idle:
            if (A == 1'b1)
                state <= Off|Tran;
        Off|Tran:
            if (A == 0)
                state <= Off|Idle;
            else if (count == COUNT_MAX)
                state <= On|Idle;
        On|Tran:
            if (A == 1)
                state <= On|Idle;
            else if (count == COUNT_MAX)
                state <= Off|Idle;
        On|Idle:
            if (A == 0)
                state <= On|Tran;
        endcase
    always@(posedge clk)
        if (cen == 1'b0)
            count <= 'b0;
        else
            count <= count + 1'b1;
endmodule
