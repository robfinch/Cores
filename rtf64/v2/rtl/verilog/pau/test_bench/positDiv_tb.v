`timescale 1ns / 1ps
module positDiv_tb_v;

function [31:0] log2;
input reg [31:0] value;
	begin
	value = value-1;
	for (log2=0; value>0; log2=log2+1)
        	value = value>>1;
      	end
endfunction

parameter N=64;
parameter E=8;
parameter Bs=log2(N);
parameter es = 3;

reg [N-1:0] in;
reg clk;
reg [31:0] cnt = 0;

wire [N-1:0] out, out2, out3;

reg [N-1:0] a1, b1;
wire [N-1:0] a, b;
wire [N-1:0] p, fsum, fb, ad, bd, psumd, out2d, p1, sum1;
wire i,z,d,i1,z1,d1,i2,z2,d2;
wire done;
reg start;

// Instantiate the Unit Under Test (UUT)

//intToPosit #(.PSTWID(N), .es(es)) u1a (.i(a1), .o(a));
//intToPosit #(.PSTWID(N), .es(es)) u1b (.i(b1), .o(b));
reg [63:0] fa;
wire [63:0] f2po;
fpToPosit #(.FPWID(64)) ufp1 (.i(fa), .o(f2po));

assign a = a1;
assign b = b1;
positDivide #(.PSTWID(N), .es(es)) udiv1 (clk, 1'b1, a, b, p, start, d, z, i);
posit_div #(.N(N),.es(es)) udiv2 (a, b, start, p1, i1, z1, d1);
posit_add #(.N(N),.es(es)) uadd2 (a, b, start, sum1, i2, z2, d2);

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
start <= 0;
  cnt = cnt + 1;
  case(cnt)
  0:  
    begin
    start <= 1;
      a1 = 0;
      b1 = 0;
    end
  1:
    begin
      a1 = 100;
      b1 = 10;
    end
  2:
    begin
      a1 = 100;
      b1 = 10;
    end
  10: 
    begin
      a1 = 100;
      b1 = 10;
      start <= 1;
    end
  14:
    begin
      a1 = 64'h63DB000000000000;
      b1 = 64'h63E8000000000000;
      fa = $realtobits(100.987);
    end
  15:
    begin
      a1 = 64'h63DB000000000000;
      b1 = 64'h63E8000000000000;
      fa = $realtobits(10.0);
    end
  16:
    begin
      a1 = 64'h63DB000000000000;
      b1 = 64'h63E8000000000000;
      fa = $realtobits(100.987);
    end
  17:
    begin
      a1 = 64'h5A40000000000000;
      b1 = 64'h3F87654321000000;
    end
  18:
    begin
      a1 = 64'h5A40000000000000;
      b1 = //64'h3F87654321000000;
        64'h3fe5604189374bc6;
    end
  default:
    begin
      if (d) begin
       start <= 1;
        cnt <= cnt + 1;
        a1 = $urandom();
        b1 = $urandom();
      end
      else
        cnt <= cnt;
    end
  endcase
end

integer outfile;
initial outfile = $fopen("d:/cores2020/rtf64/v2/rtl/verilog/cpu/pau/test_bench/positDiv_tvo64.txt", "wb");
  always @(negedge clk) begin
    if (p!=p1 && d)
     $fwrite(outfile, "*%h\t%h\t%h\t%h\n",a,b,p,p1);
    else if (d)
     $fwrite(outfile, " %h\t%h\t%h\t%h\n",a,b,p,p1);
  end

endmodule

