
`define TRUE	1'b1
`define FALSE	1'b0

module OLED(rst, clk, adr, dat, SDIN, SCLK, DC, RES, VBAT, VDD);
input rst;
input clk;
input [31:0] adr;
input [15:0] dat;
output SDIN;
output SCLK;
output DC;
output RES;
output VBAT;
output VDD;

parameter IDLE = 4'd0;
parameter INIT = 4'd1;
parameter ACTIVE = 4'd2;
parameter WRITE = 4'd3;
parameter WRITEWAIT = 4'd4;
parameter UPDATEWAIT = 4'd5;
parameter DONE = 4'd6;

reg [3:0] state;
reg [127:0] Text0 = "N4V68kSys       ";
reg [127:0] Text1 = "ADDR: ????????  ";
reg [127:0] Text2 = "DATA:     ????  ";
reg [127:0] Text3 = "                ";
reg [127:0] Alphabet = "FEDCBA9876543210";

integer n;
reg [23:0] cnt;
wire write_ready,update_ready,disp_on_ready,disp_off_ready,toggle_disp_ready;
reg disp_on_start,disp_off_start;
reg write_start,update_start,update_clear;
reg [8:0] write_base_addr;
reg [7:0] write_ascii_data;

always @(posedge clk)
begin
    for (n = 16; n < 24; n = n + 1)
        Text1[n] <= Alphabet[{adr[3:0],3'b0}+(n-16)];
    for (n = 24; n < 32; n = n + 1)
    	Text1[n] <= Alphabet[{adr[7:4],3'b0}+(n-24)];
    for (n = 32; n < 40; n = n + 1)
    	Text1[n] <= Alphabet[{adr[11:8],3'b0}+(n-32)];
    for (n = 40; n < 48; n = n + 1)
    	Text1[n] <= Alphabet[{adr[15:12],3'b0}+(n-40)];
    for (n = 48; n < 56; n = n + 1)
    	Text1[n] <= Alphabet[{adr[19:16],3'b0}+(n-48)];
    for (n = 56; n < 64; n = n + 1)
    	Text1[n] <= Alphabet[{adr[23:20],3'b0}+(n-56)];
    for (n = 64; n < 72; n = n + 1)
    	Text1[n] <= Alphabet[{adr[27:24],3'b0}+(n-64)];
    for (n = 72; n < 80; n = n + 1)
    	Text1[n] <= Alphabet[{adr[31:28],3'b0}+(n-72)];
    for (n = 16; n < 24; n = n + 1)
    	Text2[n] <= Alphabet[{dat[3:0],3'b0}+(n-16)];
    for (n = 24; n < 32; n = n + 1)
    	Text2[n] <= Alphabet[{dat[7:4],3'b0}+(n-24)];
    for (n = 32; n < 40; n = n + 1)
    	Text2[n] <= Alphabet[{dat[11:8],3'b0}+(n-32)];
    for (n = 40; n < 48; n = n + 1)
    	Text2[n] <= Alphabet[{dat[15:12],3'b0}+(n-40)];
end

always @(posedge clk)
begin
	cnt <= cnt + 1;
	if (cnt==24'd5000000)
		cnt <= 24'd1;
end

always @(write_base_addr)
case(write_base_addr[8:7])
2'd0:	write_ascii_data <= {
			Text0[{~write_base_addr[6:3],3'd7}],
			Text0[{~write_base_addr[6:3],3'd6}],
			Text0[{~write_base_addr[6:3],3'd5}],
			Text0[{~write_base_addr[6:3],3'd4}],
			Text0[{~write_base_addr[6:3],3'd3}],
			Text0[{~write_base_addr[6:3],3'd2}],
			Text0[{~write_base_addr[6:3],3'd1}],
			Text0[{~write_base_addr[6:3],3'd0}]};
2'd1:	write_ascii_data <= {
			Text1[{~write_base_addr[6:3],3'd7}],
			Text1[{~write_base_addr[6:3],3'd6}],
			Text1[{~write_base_addr[6:3],3'd5}],
			Text1[{~write_base_addr[6:3],3'd4}],
			Text1[{~write_base_addr[6:3],3'd3}],
			Text1[{~write_base_addr[6:3],3'd2}],
			Text1[{~write_base_addr[6:3],3'd1}],
			Text1[{~write_base_addr[6:3],3'd0}]};
2'd2:	write_ascii_data <= {
			Text2[{~write_base_addr[6:3],3'd7}],
			Text2[{~write_base_addr[6:3],3'd6}],
			Text2[{~write_base_addr[6:3],3'd5}],
			Text2[{~write_base_addr[6:3],3'd4}],
			Text2[{~write_base_addr[6:3],3'd3}],
			Text2[{~write_base_addr[6:3],3'd2}],
			Text2[{~write_base_addr[6:3],3'd1}],
			Text2[{~write_base_addr[6:3],3'd0}]};
2'd3:	write_ascii_data <= {
			Text3[{~write_base_addr[6:3],3'd7}],
			Text3[{~write_base_addr[6:3],3'd6}],
			Text3[{~write_base_addr[6:3],3'd5}],
			Text3[{~write_base_addr[6:3],3'd4}],
			Text3[{~write_base_addr[6:3],3'd3}],
			Text3[{~write_base_addr[6:3],3'd2}],
			Text3[{~write_base_addr[6:3],3'd1}],
			Text3[{~write_base_addr[6:3],3'd0}]};
endcase

OLEDCtrl uolc1
(
	.clk(clk),
	
	.write_start(write_start),		//inserts an ascii character's bitmap into display memory at specified address
	.write_ascii_data(write_ascii_data),	//ascii value of character to add to memory
	.write_base_addr(write_base_addr),	//on screen address of character to add {y[1:0], x[3:0], 3'b0}
	.write_ready(write_ready),		//end of character bitmap write sequence
	.update_start(update_start),	//updates oled display with memory contents
    .update_clear(update_clear),
	.update_ready(update_ready),	//end of update sequence flag
	.disp_on_start(disp_on_start),	//starts initialization sequence
	.disp_on_ready(disp_on_ready),	//end of startup sequence flag
	.disp_off_start(disp_off_start),	//starts shutdown sequence
	.disp_off_ready(disp_off_ready),	//shutdown sequence available flag
	.toggle_disp_start(1'b0),
	.toggle_disp_ready(toggle_disp_ready),
	
	.SDIN(SDIN),	//OLED command pins
	.SCLK(SCLK),
	.DC(DC),
	.RES(RES),
	.VBAT(VBAT),
	.VDD(VDD)
);

wire init_done = disp_off_ready | toggle_disp_ready | write_ready | update_ready;//parse ready signals for clarity

always @(posedge clk)
case(state)
IDLE:
	if (rst & disp_on_ready) begin
		disp_on_start <= 1'b1;
		state <= INIT;
	end
INIT:
	begin
		disp_on_start <= 1'b0;
		if (rst==1'b0 && init_done==1'b1)
			state <= ACTIVE;
	end
ACTIVE:
	begin
		if (rst & disp_off_ready) begin
			disp_off_start <= `TRUE;
			state <= DONE;
		end
        else if (cnt == 1 && write_ready) begin
            write_start <= 1'b1;
            write_base_addr <= 'b0;
            state <= WRITEWAIT;
        end
	end
WRITE:
	begin
        write_start <= 1'b1;
        write_base_addr <= write_base_addr + 9'h8;
        state <= WRITEWAIT;
    end
WRITEWAIT:
	begin
	    write_start <= 1'b0;
	    if (write_ready == 1'b1)
	        if (write_base_addr == 9'h1f8) begin
	        	update_start <= 1'b1;
	        	update_clear <= 1'b0;
	            state <= UPDATEWAIT;
	        end
	        else
	            state <= WRITE;
	end
UPDATEWAIT:
	begin
        update_start <= 0;
        if (disp_on_ready == 1'b1)
            state <= ACTIVE;
    end
DONE:
	begin
        disp_off_start <= `FALSE;
        if (rst == 1'b0 && disp_on_ready == 1'b1)
            state <= IDLE;
    end
default:   state <= IDLE;
endcase

endmodule
