`timescale 1ns / 1ps
module positMultiply_tb_v;

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
reg [25:0] cnt = 0;

wire [N-1:0] out, out2, out3;

reg [N-1:0] a1, b1;
wire [N-1:0] a, b;
wire [N-1:0] p, fsum, fa, fb, ad, bd, psumd, out2d, p1;
wire i,z,d,i1,z1,d1;

// Instantiate the Unit Under Test (UUT)

intToPosit #(.PSTWID(N), .es(es)) u1a (.i(a1), .o(a));
intToPosit #(.PSTWID(N), .es(es)) u1b (.i(b1), .o(b));

wire [N-1:0] a2 = cnt[11] ? a1 : a;
wire [N-1:0] b2 = cnt[11] ? b1 : b;
wire [N-1:0] p2, a3, b3;

positMultiply #(.PSTWID(N), .es(es)) umul1 (clk,1'b1,a2,b2,p,z,i);
posit_mult #(.N(N),.es(es)) umul3 (a2, b2, 1'b1, p2, i1, z1, d1);
delay #(.WID(N), .DEP(13)) udly1 (.clk(clk), .ce(1'b1), .i(p2), .o(p1));
delay #(.WID(N), .DEP(13)) udly2 (.clk(clk), .ce(1'b1), .i(a2), .o(a3));
delay #(.WID(N), .DEP(13)) udly3 (.clk(clk), .ce(1'b1), .i(b2), .o(b3));

delay2 #(N) ud1 (.i(a), .o(ad));
delay2 #(N) ud2 (.i(a), .o(bd));
delay2 #(N) ud3 (.i(psum), .o(psumd));
delay2 #(N) ud4 (.i(out2), .o(out2d));

	initial begin
	  a1 = $urandom(1);
	  b1 = $urandom(2);
	  cnt = 0;
		// Initialize Inputs
		clk = 1;
		// Wait 100 ns for global reset to finish
		#101 in = 32'h0080ffff;
		#700000 
		$fclose(outfile);
		$finish;
	end
	
always #5 clk=~clk;
always @(posedge clk) begin
  cnt <= cnt + 1;
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
      if (cnt[0]) begin
        a1 = $urandom();
        b1 = $urandom();
      end
    end
  endcase
end

integer outfile;
initial outfile = $fopen("d:/cores2020/rtf64/v2/rtl/verilog/cpu/pau/test_bench/positMultiply_tvo32.txt", "wb");
  always @(posedge clk) begin
    if (cnt[11:0]==12'h001)
      $fwrite(outfile, "--------------integers-------------\n");
    if (cnt[11:0]==12'h800)
      $fwrite(outfile, "---------------reals---------------\n");
    if (cnt[0]) begin
      if (p!=p1)
        $fwrite(outfile, "*%h\t%h\t%h\t%h\n",a3,b3,p,p1);
      else
        $fwrite(outfile, " %h\t%h\t%h\t%h\n",a3,b3,p,p1);
    end
  end

endmodule

