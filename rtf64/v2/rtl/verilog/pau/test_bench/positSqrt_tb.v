`timescale 1ns / 1ps
module positSqrt_tb_v;

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
parameter es = 2;

reg [N-1:0] in;
reg clk;
reg [7:0] cnt;
reg start;
wire done;
reg done1;

wire [N-1:0] out, out2, out3;

reg [N-1:0] a1, a2;
wire [N-1:0] a, sqrt, sqr, sqr2;
wire i,z,d,i1,z1,d1;

// Instantiate the Unit Under Test (UUT)

//intToPosit #(.PSTWID(N), .es(es)) u1a (.i(a1), .o(a));
assign a = a1;
positSqrt #(.PSTWID(N), .es(es)) usqrt1 (.clk(clk), .ce(1'b1), .i(a), .o(sqrt), .start(start), .done(done), .zero(), .inf());
positMul #(.PSTWID(N), .es(es)) umul1 (sqrt,sqrt,sqr,z,i);
posit_mult #(.N(N), .es(es)) umul2 (sqrt,sqrt,1'b1,sqr2,i1,z1,d1);

	initial begin
	  start = 0;
	  a1 = $urandom(1);
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
  done1 = done;
  casez(cnt)
  8'b00000000:
    begin
      start = 1;
      a1 = 16;
      a2 = a;
      cnt = cnt + 1;
    end
  8'b???????0:
    begin
      start = 1;
      a2 = a;
      cnt = cnt + 1;
    end
  8'b???????1:
    begin
      start = 0;
      if (done) begin
        a1 = $urandom();
        cnt = cnt + 1;
      end
    end
  default:
    begin
      a1 = $urandom();
      cnt = cnt + 1;
    end
  endcase
end

integer outfile;
initial outfile = $fopen("d:/cores6/Thor2020/v3/rtl/fpu/test_bench/positSqrt_tvo32.txt", "wb");
  always @(negedge clk) begin
    if (done & !done1) begin
      if (a2!=sqr)
       $fwrite(outfile, "*%h\t%h\t%h\t%h\n",a2,sqr,sqr2,sqrt);
      else
       $fwrite(outfile, " %h\t%h\t%h\t%h\n",a2,sqr,sqr2,sqrt);
    end
  end

endmodule

