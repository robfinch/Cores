`timescale 1ns / 1ps
module intToPosit_tb_v;

function [31:0] log2;
input reg [31:0] value;
	begin
	value = value-1;
	for (log2=0; value>0; log2=log2+1)
        	value = value>>1;
      	end
endfunction

parameter N=32;
parameter E=8;
parameter Bs=log2(N);
parameter es = 4;

reg clk;
reg [5:0] cnt;

wire [N-1:0] out;

reg [N-1:0] a;

// Instantiate the Unit Under Test (UUT)
intToPosit #(.PSTWID(N), .es(es)) u2 (.i(a), .o(out));

//FP_to_posit #(.N(32), .E(8), .es(es)) u3 (in, out3);
//Posit_to_FP #(.N(32), .E(8), .es(es)) u5 (out, out3);


	initial begin
	  a = $urandom(1);
		// Initialize Inputs
		clk = 1;
		cnt = 0;
		// Wait 100 ns for global reset to finish
		#325150 
		$fclose(outfile);
		$finish;
	end
	
always #5 clk=~clk;
always @(posedge clk) begin
  a = $urandom();
  cnt = cnt + 1;
  case (cnt)
  1:  a = 8192;
  2:  a = 10;
  3:  a = -1;
  4:  a = -10;
  default:   a = $urandom();
  endcase
end

integer outfile;
initial outfile = $fopen("d:/cores5/Gambit/v5/rtl/cpu/fpu/test_bench/intToPosit_tvo32.txt", "wb");
  always @(negedge clk) begin
     $fwrite(outfile, "%d\t%h\n",a,out);
  end

endmodule

