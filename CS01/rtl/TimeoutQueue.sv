
module TimeoutQueue(rst_i, clk_i, dec_i, cs_i, cyc_i, stb_i, ack_o, we_i, adr_i, dat_i, dat_o);
input rst_i;
input clk_i;
input dec_i;
input cs_i;
input cyc_i;
input stb_i;
output reg ack_o;
input we_i;
input [8:0] adr_i;
input [31:0] dat_i;
output reg [31:0] dat_o;

reg [3:0] state;
parameter RESET = 4'd0;
parameter IDLE = 4'd1;
parameter READTO = 4'd2;
parameter WAITNACK = 4'd3;
parameter DEC1 = 4'd4;
parameter DEC2 = 4'd5;
parameter DEC3 = 4'd6;

reg cs;
reg cyc;
reg stb;
reg we;
reg [8:0] adr;
reg [31:0] dati;
reg dec;

// Register inputs
always_ff @(posedge clk_i)
	cs <= cs_i;
always_ff @(posedge clk_i)
	cyc <= cyc_i;
always_ff @(posedge clk_i)
	stb <= stb_i;
always_ff @(posedge clk_i)
	we <= we_i;
always_ff @(posedge clk_i)
	adr <= adr_i;
always_ff @(posedge clk_i)
	dati <= dat_i;

wire csi = cs & cyc & stb;

reg [32:0] timeout;
reg [5:0] tndx;
reg wrto, dodec;
reg [63:0] tol;
(* ram_style="distributed" *)
reg [32:0] timeouts [0:63];

always_ff @(posedge clk_i)
	if (wrto)
		timeouts[tndx] <= timeout;
wire [32:0] tmo = timeouts[tndx];

always_ff @(posedge clk_i)
if (rst_i)
	state <= RESET;
else begin
case(state)
RESET:	state <= IDLE;
IDLE:
	if (dec_i & ~dec)
		state <= DEC1;
	else if (csi && (we || adr[8]))	// Write TO registers or access TOL
		state <= WAITNACK;
	else if (csi && !we)	// Read TO registers
		state <= READTO;
READTO:	state <= WAITNACK;
WAITNACK:	if (!csi) state <= dodec ? DEC1 : IDLE;
DEC1:	state <= DEC2;
DEC2:	state <= DEC3;
DEC3:	state <= (tndx==6'd63) ? IDLE : DEC1;
default:
	state <= RESET;
endcase
end

always_ff @(posedge clk_i)
if (rst_i) begin
	tol <= 64'h0;
	wrto <= 1'b0;
	dec <= 1'b0;
	dodec <= 1'b0;
	dat_o <= 32'h0;
end
else begin
	wrto <= 1'b0;

case(state)
RESET:
	begin
		tol <= 64'h0;
		dat_o <= 32'h0;
	end
IDLE:
	begin
		dat_o <= 32'h0;
		dec <= dec_i;
		if (csi) begin
			if (we)
				casez(adr)
				9'b0??????00:
					begin
						tndx <= adr[7:2];
						timeout <= dati;
						wrto <= 1'b1;
						ack_o <= 1'b1;
					end
				9'b1000000??:
					tol[31:0] <= dati;
				9'b1000001??:
					tol[63:32] <= dati;
				9'b111111???:
					begin
						dodec <= 1'b1;
						ack_o <= 1'b1;
					end
				endcase
			else
				casez(adr)
				9'b0??????00:
					tndx <= adr[7:2];
				9'b1000000??:
					dat_o <= tol[31:0];
				9'b1000001??:
					dat_o <= tol[63:32];
				default:	;
				endcase
		end
	end
READTO:
	begin
		dat_o <= tmo;
		ack_o <= 1'b1;
	end
WAITNACK:
	if (!csi) begin
		ack_o <= 1'b0;
		dodec <= 1'b0;
		dat_o <= 32'h0;
	end
DEC1:
	timeout <= tmo;
DEC2:
	timeout <= timeout - 2'd1;
DEC3:
	begin
		if (timeout[32]) begin
			tol[tndx] <= 1'b1;
			timeout <= 32'hFFFFFFFF;
		end
		wrto <= 1'b1;
		tndx <= tndx + 2'd1;
	end
endcase

end

endmodule
