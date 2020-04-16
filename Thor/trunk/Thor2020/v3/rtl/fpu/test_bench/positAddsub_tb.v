`timescale 1ns / 1ps
module positAddsub_tb_v;

function [31:0] log2;
input reg [31:0] value;
	begin
	value = value-1;
	for (log2=0; value>0; log2=log2+1)
        	value = value>>1;
      	end
endfunction

parameter N=52;
parameter E=8;
parameter Bs=log2(N);
parameter es = 4;

reg [N-1:0] in;
reg clk;
reg [5:0] cnt;

wire [N-1:0] out, out2, out3;

reg [N-1:0] a1, b1;
wire [N-1:0] a, b;
wire [N-1:0] psum, fsum, fa, fb, ad, bd, psumd, out2d, psum1;

// Instantiate the Unit Under Test (UUT)

intToPosit #(.PSTWID(N), .es(es)) u1a (.i(a1), .o(a));
intToPosit #(.PSTWID(N), .es(es)) u1b (.i(b1), .o(b));
positToFp #(.FPWID(N), .PSTWID(N), .es(es)) u2
(
  .i(a), 
	.o(fa)
);

positToFp #(.FPWID(N), .PSTWID(N), .es(es)) u3
(
  .i(b), 
	.o(fb)
);

positAddsub #(.PSTWID(N), .es(es)) uadd1 (1'b0,a,b,psum);
fpAddsub #(.FPWID(N)) uadd2 (clk,1'b1,3'd0,1'b0,fa,fb,fsum);
posit_add #(.N(N),.es(es)) uadd3 (a, b, 1'b1, psum1);

positToFp #(.FPWID(N), .PSTWID(N), .es(es)) u4
(
  .i(psum), 
	.o(out2)
);


delay2 #(N) ud1 (.i(a), .o(ad));
delay2 #(N) ud2 (.i(a), .o(bd));
delay2 #(N) ud3 (.i(psum), .o(psumd));
delay2 #(N) ud4 (.i(out2), .o(out2d));


//FP_to_posit #(.N(32), .E(8), .es(es)) u3 (in, out3);
//Posit_to_FP #(.N(32), .E(8), .es(es)) u5 (out, out3);


	initial begin
	  a1 = $urandom(1);
	  b1 = $urandom(2);
	  cnt = 0;
		// Initialize Inputs
		clk = 1;
		// Wait 100 ns for global reset to finish
		#101 in = 32'h0080ffff;
		#325150 
		$fclose(outfile);
		$finish;
	end
	
always #5 clk=~clk;
always @(posedge clk) begin
  cnt = cnt + 1;
  case(cnt)
  0:  
    begin
      a1 = 0;
      b1 = 0;
    end
  1:
    begin
      a1 = 0;
      b1 = 10;
    end
  2:
    begin
      a1 = 10;
      b1 = 10;
    end
   
  default:
    begin
      a1 = $urandom();
      b1 = $urandom();
    end
  endcase
end

integer outfile;
initial outfile = $fopen("d:/cores5/Gambit/v5/rtl/cpu/fpu/test_bench/positAddsub_tvo32.txt", "wb");
  always @(negedge clk) begin
     $fwrite(outfile, "%h\t%h\t%h\t%h\n",a,b,psum,psum1);
  end

endmodule

