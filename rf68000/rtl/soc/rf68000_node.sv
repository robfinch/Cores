`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//                                                                          
// ============================================================================

import nic_pkg::*;

module rf68000_node(id, rst, clk, packet_i, packet_o, ipacket_i, ipacket_o);
input [4:0] id;
input rst;
input clk;
input packet_t packet_i;
output packet_t packet_o;
input ipacket_t ipacket_i;
output ipacket_t ipacket_o;

wire cyc1, stb1, ack1;
wire cyc2, stb2, ack2;
wire we1, we2;
wire [3:0] sel1, sel2;
wire [31:0] adr1, adr2;
wire [31:0] dati1, dati2;
wire [31:0] dato1, dato2;
wire ram1_en, ram2_en;
wire [3:0] ram1_we, ram2_we;
wire [31:0] ram1_adr, ram2_adr;
wire [31:0] ram1_dati, ram2_dati;
wire [31:0] ram1_dato, ram2_dato;
wire [31:0] ram1_dat, ram2_dat;
wire nic1_cyc, nic1_stb, nic1_ack, nic1_we;
wire nic2_cyc, nic2_stb, nic2_ack, nic2_we;
wire [31:0] nic1_dato, nic2_dato, nic1_dati, nic2_dati;
wire [3:0] nic1_sel, nic2_sel;
wire [31:0] nic1_adr, nic2_adr;
wire nic1_sack, nic2_sack;

packet_t packet_x;
ipacket_t ipacket_x;

assign ack1 = nic1_sack|ram1_ack;
assign ack2 = nic2_sack|ram2_ack;
assign dati1 = adr1[31:20]==12'h0 ? ram1_dat : nic1_dato;
assign dati2 = adr2[31:20]==12'h0 ? ram2_dat : nic2_dato;

rf68000_nic unic1
(
	.id({id,1'b0}),
	.rst_i(rst),
	.clk_i(clk),
	.s_cti_i(),
	.s_atag_o(),
	.s_cyc_i(cyc1),
	.s_stb_i(stb1),
	.s_ack_o(nic1_sack),
	.s_aack_o(),
	.s_rty_o(),
	.s_we_i(we1),
	.s_sel_i(sel1),
	.s_adr_i(adr1),
	.s_dat_i(dato1),
	.s_dat_o(nic1_dato),
	.m_cyc_o(nic1_cyc),
	.m_stb_o(nic1_stb),
	.m_ack_i(nic1_ack),
	.m_we_o(nic1_we),
	.m_sel_o(nic1_sel),
	.m_adr_o(nic1_adr),
	.m_dat_o(nic1_dato),
	.m_dat_i(nic1_dati),
	.packet_i(packet_i),
	.packet_o(packet_x),
	.ipacket_i(ipacket_i),
	.ipacket_o(ipacket_x),
	.rpacket_i(),
	.rpacket_o(),
	.irq_i(),
	.firq_i(),
	.cause_i(),
	.iserver_i(),
	.irq_o(),
	.firq_o(),
	.cause_o()
);

rf68000_nic unic2
(
	.id({id,1'b1}),
	.rst_i(rst),
	.clk_i(clk),
	.s_cti_i(),
	.s_atag_o(),
	.s_cyc_i(cyc2),
	.s_stb_i(stb2),
	.s_ack_o(nic2_sack),
	.s_aack_o(),
	.s_rty_o(),
	.s_we_i(we2),
	.s_sel_i(sel2),
	.s_adr_i(adr2),
	.s_dat_i(dato2),
	.s_dat_o(nic2_dato),
	.m_cyc_o(nic2_cyc),
	.m_stb_o(nic2_stb),
	.m_ack_i(nic2_ack),
	.m_we_o(nic2_we),
	.m_sel_o(nic2_sel),
	.m_adr_o(nic2_adr),
	.m_dat_o(nic2_dato),
	.m_dat_i(nic2_dati),
	.packet_i(packet_x),
	.packet_o(packet_o),
	.ipacket_i(ipacket_x),
	.ipacket_o(ipacket_o),
	.rpacket_i(),
	.rpacket_o(),
	.irq_i(),
	.firq_i(),
	.cause_i(),
	.iserver_i(),
	.irq_o(),
	.firq_o(),
	.cause_o()
);

rf68000_node_arbiter undarb1
(
	.id({id[2:0],1'b0}),
	.rst_i(rst),
	.clk_i(clk),
	.cpu_cyc(cyc1),
	.cpu_stb(stb1 && adr1[31:20]==12'h0),
	.cpu_ack(ram1_ack),
	.cpu_aack(ram1_aack),
	.cpu_we(we1),
	.cpu_sel(sel1),
	.cpu_adr(adr1),
	.cpu_dato(dato1),
	.cpu_dati(ram1_dat),
	.nic_cyc(nic1_cyc),
	.nic_stb(nic1_stb),
	.nic_ack(nic1_ack),
	.nic_we(nic1_we),
	.nic_sel(nic1_sel),
	.nic_adr(nic1_adr),
	.nic_dati(nic1_dati),
	.nic_dato(nic1_dato),
	.ram_en(ram1_en),
	.ram_we(ram1_we),
	.ram_adr(ram1_adr),
	.ram_dati(ram1_dati),
	.ram_dato(ram1_dato)
);

rf68000_node_arbiter undarb2
(
	.id({id[2:0],1'b1}),
	.rst_i(rst),
	.clk_i(clk),
	.cpu_cyc(cyc2),
	.cpu_stb(stb2 && adr2[31:20]==12'h0),
	.cpu_ack(ram2_ack),
	.cpu_aack(ram2_aack),
	.cpu_we(we2),
	.cpu_sel(sel2),
	.cpu_adr(adr2),
	.cpu_dato(dato2),
	.cpu_dati(ram2_dat),
	.nic_cyc(nic2_cyc),
	.nic_stb(nic2_stb),
	.nic_ack(nic2_ack),
	.nic_we(nic2_we),
	.nic_sel(nic2_sel),
	.nic_adr(nic2_adr),
	.nic_dati(nic2_dati),
	.nic_dato(nic2_dato),
	.ram_en(ram2_en),
	.ram_we(ram2_we),
	.ram_adr(ram2_adr),
	.ram_dati(ram2_dati),
	.ram_dato(ram2_dato)
);

rf68000 ucpu1
(
	.rst_i(rst),
	.rst_o(),
	.clk_i(clk),
	.nmi_i(),
	.ipl_i(),
	.lock_o(),
	.cyc_o(cyc1),
	.stb_o(stb1),
	.ack_i(ack1),
	.err_i(),
	.we_o(we1),
	.sel_o(sel1),
	.fc_o(),
	.adr_o(adr1),
	.dat_i(dati1),
	.dat_o(dato1)
);

rf68000 ucpu2
(
	.rst_i(rst),
	.rst_o(),
	.clk_i(clk),
	.nmi_i(),
	.ipl_i(),
	.lock_o(),
	.cyc_o(cyc2),
	.stb_o(stb2),
	.ack_i(ack2),
	.err_i(),
	.we_o(we2),
	.sel_o(sel2),
	.fc_o(),
	.adr_o(adr2),
	.dat_i(dati2),
	.dat_o(dato2)
);

// +---------------------------------------------------------------------------------------------------------------------+
// | MEMORY_INIT_FILE     | String             | Default value = none.                                                   |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specify "none" (including quotes) for no memory initialization, or specify the name of a memory initialization file-|
// | Enter only the name of the file with .mem extension, including quotes but without path (e.g. "my_file.mem").        |
// | File format must be ASCII and consist of only hexadecimal values organized into the specified depth by              |
// | narrowest data width generic value of the memory. Initialization of memory happens through the file name specified only when parameter|
// | MEMORY_INIT_PARAM value is equal to "". |                                                                           |
// | When using XPM_MEMORY in a project, add the specified file to the Vivado project as a design source.                |
// +---------------------------------------------------------------------------------------------------------------------+
// | MEMORY_INIT_PARAM    | String             | Default value = 0.                                                      |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specify "" or "0" (including quotes) for no memory initialization through parameter, or specify the string          |
// | containing the hex characters. Enter only hex characters with each location separated by delimiter (,).             |
// | Parameter format must be ASCII and consist of only hexadecimal values organized into the specified depth by         |
// | narrowest data width generic value of the memory.For example, if the narrowest data width is 8, and the depth of    |
// | memory is 8 locations, then the parameter value should be passed as shown below.                                    |
// | parameter MEMORY_INIT_PARAM = "AB,CD,EF,1,2,34,56,78"                                                               |
// | Where "AB" is the 0th location and "78" is the 7th location.                                                        |
// +---------------------------------------------------------------------------------------------------------------------+
// | USE_MEM_INIT         | Integer            | Range: 0 - 1. Default value = 1.                                        |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specify 1 to enable the generation of below message and 0 to disable generation of the following message completely.|
// | "INFO - MEMORY_INIT_FILE and MEMORY_INIT_PARAM together specifies no memory initialization.                         |
// | Initial memory contents will be all 0s."                                                                            |
// | NOTE: This message gets generated only when there is no Memory Initialization specified either through file or      |
// | Parameter.                                                                                                          |

   // xpm_memory_tdpram: True Dual Port RAM
   // Xilinx Parameterized Macro, version 2022.2

   xpm_memory_tdpram #(
      .ADDR_WIDTH_A(15),               // DECIMAL
      .ADDR_WIDTH_B(15),               // DECIMAL
      .AUTO_SLEEP_TIME(0),            // DECIMAL
      .BYTE_WRITE_WIDTH_A(8),        // DECIMAL
      .BYTE_WRITE_WIDTH_B(8),        // DECIMAL
      .CASCADE_HEIGHT(0),             // DECIMAL
      .CLOCKING_MODE("common_clock"), // String
      .ECC_MODE("no_ecc"),            // String
      .MEMORY_INIT_FILE("rom.mem"),      // String
      .MEMORY_INIT_PARAM("0"),        // String
      .MEMORY_OPTIMIZATION("true"),   // String
      .MEMORY_PRIMITIVE("block"),      // String
      .MEMORY_SIZE(131072*8),         // DECIMAL
      .MESSAGE_CONTROL(0),            // DECIMAL
      .READ_DATA_WIDTH_A(32),         // DECIMAL
      .READ_DATA_WIDTH_B(32),         // DECIMAL
      .READ_LATENCY_A(2),             // DECIMAL
      .READ_LATENCY_B(2),             // DECIMAL
      .READ_RESET_VALUE_A("0"),       // String
      .READ_RESET_VALUE_B("0"),       // String
      .RST_MODE_A("SYNC"),            // String
      .RST_MODE_B("SYNC"),            // String
      .SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
      .USE_MEM_INIT(1),               // DECIMAL
      .USE_MEM_INIT_MMI(0),           // DECIMAL
      .WAKEUP_TIME("disable_sleep"),  // String
      .WRITE_DATA_WIDTH_A(32),        // DECIMAL
      .WRITE_DATA_WIDTH_B(32),        // DECIMAL
      .WRITE_MODE_A("no_change"),     // String
      .WRITE_MODE_B("no_change"),     // String
      .WRITE_PROTECT(1)               // DECIMAL
   )
   xpm_memory_tdpram_inst (
      .dbiterra(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                       // on the data output of port A.

      .dbiterrb(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                       // on the data output of port A.

      .douta(ram1_dato),                   // READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
      .doutb(ram2_dato),                   // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
      .sbiterra(),				             // 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port A.

      .sbiterrb(),             				// 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port B.

      .addra(ram1_adr[16:2]),                   // ADDR_WIDTH_A-bit input: Address for port A write and read operations.
      .addrb(ram2_adr[16:2]),                   // ADDR_WIDTH_B-bit input: Address for port B write and read operations.
      .clka(clk),                     // 1-bit input: Clock signal for port A. Also clocks port B when
                                       // parameter CLOCKING_MODE is "common_clock".

      .clkb(clk),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                       // "independent_clock". Unused when parameter CLOCKING_MODE is
                                       // "common_clock".

      .dina(ram1_dati),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
      .dinb(ram2_dati),                     // WRITE_DATA_WIDTH_B-bit input: Data input for port B write operations.
      .ena(ram1_en),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                       // cycles when read or write operations are initiated. Pipelined
                                       // internally.

      .enb(ram2_en),                       // 1-bit input: Memory enable signal for port B. Must be high on clock
                                       // cycles when read or write operations are initiated. Pipelined
                                       // internally.

      .injectdbiterra(1'b0), 					// 1-bit input: Controls double bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectdbiterrb(1'b0), 					// 1-bit input: Controls double bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectsbiterra(1'b0), 					// 1-bit input: Controls single bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectsbiterrb(1'b0), 					// 1-bit input: Controls single bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .regcea(1'b1),                 // 1-bit input: Clock Enable for the last register stage on the output
                                       // data path.

      .regceb(1'b1),                 // 1-bit input: Clock Enable for the last register stage on the output
                                       // data path.

      .rsta(1'b0),                     // 1-bit input: Reset signal for the final port A output register stage.
                                       // Synchronously resets output port douta to the value specified by
                                       // parameter READ_RESET_VALUE_A.

      .rstb(1'b0),                     // 1-bit input: Reset signal for the final port B output register stage.
                                       // Synchronously resets output port doutb to the value specified by
                                       // parameter READ_RESET_VALUE_B.

      .sleep(1'b0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
      .wea(ram1_we),                       // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                       // for port A input data port dina. 1 bit wide when word-wide writes are
                                       // used. In byte-wide write configurations, each bit controls the
                                       // writing one byte of dina to address addra. For example, to
                                       // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                       // is 32, wea would be 4'b0010.

      .web(ram2_we)                        // WRITE_DATA_WIDTH_B/BYTE_WRITE_WIDTH_B-bit input: Write enable vector
                                       // for port B input data port dinb. 1 bit wide when word-wide writes are
                                       // used. In byte-wide write configurations, each bit controls the
                                       // writing one byte of dinb to address addrb. For example, to
                                       // synchronously write only bits [15-8] of dinb when WRITE_DATA_WIDTH_B
                                       // is 32, web would be 4'b0010.

   );

			
endmodule
