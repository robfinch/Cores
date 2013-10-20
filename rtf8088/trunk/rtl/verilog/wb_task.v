`define INITIATE_CODE_READ		cyc_type <= `CT_CODE; cyc_o <= 1'b1; stb_o <= 1'b1; we_o <= 1'b0; adr_o <= csip;
`define TERMINATE_CYCLE			cyc_type <= `CT_PASSIVE; cyc_o <= 1'b0; stb_o <= 1'b0; we_o <= 1'b0;
`define TERMINATE_CODE_READ		cyc_type <= `CT_PASSIVE; cyc_o <= 1'b0; stb_o <= 1'b0; we_o <= 1'b0; ip <= ip_inc;
`define PAUSE_CODE_READ			cyc_type <= `CT_PASSIVE; stb_o <= 1'b0; ip <= ip_inc;
`define CONTINUE_CODE_READ		cyc_type <= `CT_CODE; stb_o <= 1'b1; adr_o <= csip;
`define INITIATE_STACK_WRITE	cyc_type <= `CT_WRMEM; cyc_o <= 1'b1; stb_o <= 1'b1; we_o <= 1'b1; adr_o <= sssp;
`define PAUSE_STACK_WRITE		cyc_type <= `CT_PASSIVE; sp <= sp_dec; stb_o <= 1'b0; we_o <= 1'b0;

`define INITIATE_STACK_POP		cyc_type <= `CT_RDMEM; lock_o <= 1'b1; cyc_o <= 1'b1; stb_o <= 1'b1; adr_o <= sssp;
`define COMPLETE_STACK_POP		cyc_type <= `CT_PASSIVE; lock_o <= bus_locked; cyc_o <= 1'b0; stb_o <= 1'b0; sp <= sp_inc;
`define PAUSE_STACK_POP			cyc_type <= `CT_PASSIVE; stb_o <= 1'b0; sp <= sp_inc;
`define CONTINUE_STACK_POP		cyc_type <= `CT_RDMEM; stb_o <= 1'b1; adr_o <= sssp;

task wb_read;
input [2:0] ct;
input [19:0] ad;
begin
	cyc_type <= ct;
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b0;
	adr_o <= ad;
end
endtask

task wb_pause_read;
begin
	cyc_type <= `CT_PASSIVE;
	stb_o <= 1'b0;
end
endtask

task wb_write;
input [2:0] ct;
input [19:0] ad;
input [7:0] dat;
begin
	cyc_type <= ct;
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b1;
	adr_o <= ad;
	dat_o <= dat;
end
endtask

task wb_nack;
begin
	cyc_type <= `CT_PASSIVE;
	cyc_o <= 1'b0;
	stb_o <= 1'b0;
	we_o <= 1'b0;
	adr_o <= 20'd0;
	dat_o <= 8'd0;
end
endtask

task wb_nack_ir;
begin
	wb_nack();
	ir <= dat_i;
	ip <= ip_inc;
end
endtask

task wb_nack_ir2;
begin
	wb_nack();
	ir2 <= dat_i;
	ip <= ip_inc;
end
endtask

task wb_pause_code_read;
begin
	cyc_type <= `CT_PASSIVE;
	stb_o <= 1'b0;
	ip <= ip_inc;
end
endtask

task wb_stack_push;
begin
	cyc_type <= `CT_WRMEM;
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b1;
	adr_o <= sssp;
end
endtask

task wb_pause_stack_push;
begin
	cyc_type <= `CT_PASSIVE;
	sp <= sp_dec;
	stb_o <= 1'b0;
	we_o <= 1'b0;
end
endtask

task wb_stack_pop;
begin
	cyc_type <= `CT_RDMEM;
	lock_o <= 1'b1;
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	adr_o <= sssp;
end
endtask

task wb_pause_stack_pop;
begin
	cyc_type <= `CT_PASSIVE;
	stb_o <= 1'b0;
	sp <= sp_inc;
end
endtask

task wb_continue_stack_pop;
begin
	cyc_type <= `CT_RDMEM;
	stb_o <= 1'b1;
	adr_o <= sssp;
end
endtask

task wb_stack_pop_nack;
begin
	lock_o <= bus_locked;
	sp <= sp_inc;
	wb_nack();
end
endtask

