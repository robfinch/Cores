module mpmc_tb();
reg rst;
reg clk200MHz;
reg busclk;
wire mem_ui_clk;
reg cpu_cyc;
reg cpu_stb;
wire cpu_ack;
reg cpu_we;
reg [3:0] cpu_sel;
reg [31:0] cpu_adr;
reg [31:0] cpu_dato;
reg [7:0] state;
reg bm_cyc;
wire bm_ack;
reg [31:0] bm_adr;
wire bm_stb = bm_cyc;
wire [127:0] bm_dat;

wire [15:0] ddr2_dq;
wire [1:0] ddr2_dqs_p;
wire [1:0] ddr2_dqs_n;
wire [12:0] ddr2_addr;
wire [2:0] ddr2_ba;
wire ddr2_ras_n;
wire ddr2_cas_n;
wire ddr2_we_n;
wire ddr2_ck_p;
wire ddr2_ck_n;
wire ddr2_cke;
wire ddr2_cs_n;
wire [1:0] ddr2_dm;
wire ddr2_odt;

initial begin

  #0 rst = 1'b0;
  #0 busclk = 1'b0;
  #0 clk200MHz = 1'b0;
  #100 rst = 1'b1;
  #1000 rst = 1'b0;

end
always #2.5 clk200MHz = ~clk200MHz;
always #20.0 busclk = ~busclk;

always @(posedge busclk)
if (rst) begin
  state <= 8'd0;
end
else begin
  case (state)
  8'd64:
    begin
      cpu_cyc <= 1'b1;
      cpu_stb <= 1'b1;
      cpu_we <= 1'b1;
      cpu_sel <= 4'hF;
      cpu_adr <= 32'h01C00000;
      cpu_dato <= 32'h12345678;
      state <= state + 1;
    end
  8'd65:
    if (cpu_ack) begin
      cpu_cyc <= 1'b0;
      cpu_stb <= 1'b0;
      cpu_we <= 1'b0;
      cpu_sel <= 4'h0;
      cpu_adr <= 32'hFFC00000;
      cpu_dato <= 32'h0;
      state <= state + 1;
    end
  8'd66:
      begin
        cpu_cyc <= 1'b1;
        cpu_stb <= 1'b1;
        cpu_we <= 1'b1;
        cpu_sel <= 4'hF;
        cpu_adr <= 32'h01C00010;
        cpu_dato <= 32'h99999999;
        state <= state + 1;
      end
  8'd67:
    if (cpu_ack) begin
      cpu_cyc <= 1'b0;
      cpu_stb <= 1'b0;
      cpu_we <= 1'b0;
      cpu_sel <= 4'h0;
      cpu_adr <= 32'hFFC00000;
      cpu_dato <= 32'h0;
      state <= state + 1;
    end
  8'd68:
    begin
      bm_cyc <= 1'b1;
      bm_adr <= 32'h04C00000;
      state <= state + 1;
    end
  8'd69:
    if (bm_ack) begin
      bm_cyc <= 1'b0;
      state <= state + 1;
    end
  default:  state <= state + 1;
  endcase
end

mpmc2 #(.SIM("TRUE"), .SIM_BYPASS_INIT_CAL("FAST")) umpmc1
(
.rst_i(rst),
.clk200MHz(clk200MHz),
.fpga_temp(12'h000),
.mem_ui_clk(mem_ui_clk),

.cyc0(bm_cyc),
.stb0(bm_stb),
.ack0(bm_ack),
.we0(1'b0),
.adr0(bm_adr),
.dato0(bm_dat),

.cyc1(1'b0),
.stb1(1'b0),
.we1(1'b0),
.sel1(4'h0),
.adr1(32'h0),

.cyc2(1'b0),
.stb2(1'b0),
.we2(1'b0),
.sel2(4'h0),
.adr2(32'h0),

.cyc3(1'b0),
.stb3(1'b0),
.we3(1'b0),
.sel3(4'h0),
.adr3(32'h0),

.cyc4(1'b0),
.stb4(1'b0),
.we4(1'b0),
.adr4(32'h0),

.cyc5(1'b0),
.stb5(1'b0),
.adr5(32'h0),

.cyc6(1'b0),
.stb6(1'b0),
.we6(1'b0),
.sel6(4'h0),
.adr6(32'h0),

.cyc7(cpu_cyc),
.stb7(cpu_stb),
.ack7(cpu_ack),
.we7(cpu_we),
.sel7(cpu_sel),
.adr7(cpu_adr),
.dati7(cpu_dato),
.dato7(),
.sr7(1'b0),
.cr7(1'b0),
.rb7(),

.ddr2_dq(ddr2_dq),
.ddr2_dqs_n(ddr2_dqs_n),
.ddr2_dqs_p(ddr2_dqs_p),
.ddr2_addr(ddr2_addr),
.ddr2_ba(ddr2_ba),
.ddr2_ras_n(ddr2_ras_n),
.ddr2_cas_n(ddr2_cas_n),
.ddr2_we_n(ddr2_we_n),
.ddr2_ck_p(ddr2_ck_p),
.ddr2_ck_n(ddr2_ck_n),
.ddr2_cke(ddr2_cke),
.ddr2_cs_n(ddr2_cs_n),
.ddr2_dm(ddr2_dm),
.ddr2_odt(ddr2_odt)
);

ddr2a uddr1 (
    .ck(ddr2_ck_p),
    .ck_n(ddr2_ck_n),
    .cke(ddr2_cke),//ddr2_cke),
    .cs_n(ddr2_cs_n),
    .ras_n(ddr2_ras_n),
    .cas_n(ddr2_cas_n),
    .we_n(ddr2_we_n),
    .dm_rdqs(ddr2_dm),
    .ba(ddr2_ba),
    .addr(ddr2_addr),
    .dq(ddr2_dq),
    .dqs(ddr2_dqs_p),
    .dqs_n(ddr2_dqs_n),
    .rdqs_n(ddr2_dm),
    .odt(ddr2_odt)
);

endmodule

