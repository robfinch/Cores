// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	MinimigGrid.v
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//
// ============================================================================
//
module MinimigGrid(cpu_resetn, xclk, led, btnu, btnd, btnl, btnr, btnc,
    kd, kclk,
    TMDS_OUT_clk_p, TMDS_OUT_clk_n, TMDS_OUT_data_p, TMDS_OUT_data_n,
    ddr3_ck_p,ddr3_ck_n,ddr3_cke,ddr3_reset_n,ddr3_ras_n,ddr3_cas_n,ddr3_we_n,
    ddr3_ba,ddr3_addr,ddr3_dq,ddr3_dqs_p,ddr3_dqs_n,ddr3_dm,ddr3_odt
);
input cpu_resetn;
input xclk;
output [7:0] led;
input btnu;
input btnd;
input btnl;
input btnr;
input btnc;
inout tri kd;
inout tri kclk;
output TMDS_OUT_clk_p;
output TMDS_OUT_clk_n;
output [2:0] TMDS_OUT_data_p;
output [2:0] TMDS_OUT_data_n;

output [0:0] ddr3_ck_p;
output [0:0] ddr3_ck_n;
output [0:0] ddr3_cke;
output ddr3_reset_n;
output ddr3_ras_n;
output ddr3_cas_n;
output ddr3_we_n;
output [2:0] ddr3_ba;
output [14:0] ddr3_addr;
inout [15:0] ddr3_dq;
inout [1:0] ddr3_dqs_p;
inout [1:0] ddr3_dqs_n;
output [1:0] ddr3_dm;
output [0:0] ddr3_odt;

parameter SIM = 1'b0;

wire clk200,clk40;
wire locked;
wire cpu_clk;
wire _cpu_reset;
wire rst = ~locked;
wire [2:0] _cpu_ipl;
wire _cpu_dtack;
wire cpu_dd;
wire [31:0] cpu_addr;
wire [15:0] cpu_data_o;
wire [15:0] cpu_data =  cpu_r_w ? 16'bz : cpu_data_o; //cpu_dd ? cpu_data_o : 16'bz;
wire [15:0] cpu_data_i = cpu_data;
wire _cpu_as;
wire _cpu_lds;
wire _cpu_uds;
wire cpu_r_w;
//assign _cpu_reset = locked ? 1'b1 : 1'b0;

wire eol, eof;
wire hSync, vSync;
wire hSync_n = ~hSync;
wire vSync_n = ~vSync;
wire [7:0] red;
wire [7:0] green;
wire [7:0] blue;
wire blank;

wire _ram_bhe,_ram_ble;
wire _ram_we,_ram_oe;
wire _ram_ce;
wire [15:0] ram_data;
wire [15:0] ram_data_i = ram_data;
wire [15:0] ram_data_o;
assign ram_data = _ram_we ? (&_ram_ce ? 16'd0000 : ram_data_o) : 16'bz;
wire [31:1] ram_addr,ram_addr1;
wire [15:0] chip_ram_dat_o;

wire sel_boot;

wire btnuo, btndd, btnld, btnrd, btncd;
BtnDebounce ubdb1 (clk40, btnu, btnud);
BtnDebounce ubdb2 (clk40, btnd, btndd);
BtnDebounce ubdb3 (clk40, btnl, btnld);
BtnDebounce ubdb4 (clk40, btnr, btnrd);
BtnDebounce ubdb5 (clk40, btnc, btncd);

VGASyncGen800x600_60Hz u4
(
	.rst(rst),
	.clk(clk40),
	.hSync(hSync),
	.vSync(vSync),
	.eol(eol),
	.eof(eof),
	.blank(blank),
	.border(border)
);


// The following core supplied by Digilent as part of the NexysVideo examples.
rgb2dvi #(
    .kGenerateSerialClk(1'b0),
    .kClkPrimitive("MMCM"),
    .kClkRange(3),
    .kRstActiveHigh(1'b1)
)
ur2d1 
(
    .TMDS_Clk_p(TMDS_OUT_clk_p),
    .TMDS_Clk_n(TMDS_OUT_clk_n),
    .TMDS_Data_p(TMDS_OUT_data_p),
    .TMDS_Data_n(TMDS_OUT_data_n),
    .aRst(rst),
    .aRst_n(~rst),
    .vid_pData({red,blue,green}),
    .vid_pVDE(~blank),
    .vid_pHSync(hSync),
    .vid_pVSync(vSync),
    .PixelClk(clk40),
    .SerialClk(clk200)
);
/*
TG68KdotC_Kernel utg68kk
(
    .clk(cpu_clk),
    .nReset(_cpu_reset),
    .clkena_in(1'b1),
    .data_in(cpu_data_i),
	.IPL(_cpu_ipl),
	.IPL_autovector(1'b0),
    .CPU(2'b00),//             	: in std_logic_vector(1 downto 0):="00";  -- 00->68000  01->68010  11->68020(only some parts - yet)
    .addr(cpu_addr),
    .data_write(cpu_data_o),
	.nWr(cpu_r_w),
	.nUDS(_cpu_uds),
	.nLDS(_cpu_lds),
	.busstate(),   //	  	  	: out std_logic_vector(1 downto 0);	-- 00-> fetch code 10->read data 11->write data 01->no memaccess
    .nResetOut(),
    .FC(),   //              	: out std_logic_vector(2 downto 0);
    .dtack(_cpu_dtack)
);
*/

TG68 utg68k
(        
	.clk(cpu_clk),
	.reset(_cpu_reset),
    .clkena_in(1'b1),
    .data_in(cpu_data_i),
    .IPL(_cpu_ipl),
    .dtack(_cpu_dtack),
    .addr(cpu_addr),
    .data_out(cpu_data_o),
    .as(_cpu_as),
    .uds(_cpu_uds),
    .lds(_cpu_lds),
    .rw(cpu_r_w),
    .drive_data(cpu_dd)
);

/*
TG68K utg68k1
(
    .clk(cpu_clk),
    .reset(_cpu_reset),
    .clkena_in(1'b1),
    .IPL(_cpu_ipl),
    .dtack(_cpu_dtack),
    .vpa(1'b1),
    .ein(1'b1),
    .addr(cpu_addr),
    .data_read(cpu_data_i),
    .data_write(cpu_data_o),
    .as(_cpu_as),
    .uds(_cpu_uds),
    .lds(_cpu_lds),
    .rw(cpu_r_w),
    .e(),
    .vma(),   

    .wrd(), //           : out std_logic;
    .ena7RDreg(1'b1),   //      : in std_logic:='1';
    .ena7WRreg(1'b1),   //      : in std_logic:='1';
    .enaWRreg(1'b1),    //      : in std_logic:='1';
        
    .fromram(),         //    	  : in std_logic_vector(15 downto 0);
    .ramready(1'b0),    //      : in std_logic:='0';
    .cpu(2'b00),         // 00->68000  01->68010  11->68020(only same parts - yet)
//--        fastkick      : in std_logic:='0';
    .memcfg(6'h00),     //    : in std_logic_vector(5 downto 0);
    .ramaddr(),         // 	  : out std_logic_vector(31 downto 0);
    .cpustate(),        //    : out std_logic_vector(5 downto 0);
    .nResetOut(),       //	  : out std_logic;
    //skipFetch     : out std_logic; debugging
    .cpuDMA(),        // : buffer std_logic;
    .ramlds(),        // : out std_logic;
    .ramuds(),        //: out std_logic;
    .VBR_out()
);
*/
Manni umni1 (ram_addr1, ram_addr);

generate begin : gram
if (SIM) begin
chipram chipram1
(
	.clka(clk200),    // input wire clka
	.ena(1'b0),      // input wire ena
	.wea({2{~cpu_r_w & 1'b0}} & ~{_cpu_uds,_cpu_lds}),      // input wire [1 : 0] wea
	.addra(cpu_addr[19:1]),  // input wire [18 : 0] addra
	.dina(cpu_data_o),    // input wire [15 : 0] dina
	.douta(chip_ram_dat_o),  // output wire [15 : 0] douta
	.clkb(clk200),    // input wire clkb
	.enb(~_ram_ce),      // input wire enb
	.web({2{~_ram_we & ~_ram_ce}} & ~{_ram_bhe,_ram_ble}),      // input wire [1 : 0] web
	.addrb(ram_addr[19:1]),  // input wire [18 : 0] addrb
	.dinb(ram_data_i),    // input wire [15 : 0] dinb
	.doutb(ram_data_o)  // output wire [15 : 0] doutb
);
end
else begin
DDRcontrol DDRCtrl1
(
	// Common
	.clk_200MHz_i(clk200),	// 200 MHz system clock
	.rst_i(rst),              // active high system reset

	// RAM interface
	.ram_a({ram_addr[28:1],1'b0}),
	.ram_dq_i(ram_data_i),
	.ram_dq_o(ram_data_o),
	.ram_cen(_ram_ce),
	.ram_oen(_ram_oe),
	.ram_wen(_ram_we),
	.ram_bhe(_ram_bhe),
	.ram_ble(_ram_ble),
	.data_valid(),
      
	// DDR3 interface
	.ddr3_dq(ddr3_dq),
	.ddr3_dqs_n(ddr3_dqs_n),
	.ddr3_dqs_p(ddr3_dqs_p),
	.ddr3_addr(ddr3_addr),
	.ddr3_ba(ddr3_ba),
	.ddr3_ras_n(ddr3_ras_n),
	.ddr3_cas_n(ddr3_cas_n),
	.ddr3_we_n(ddr3_we_n),
	.ddr3_ck_p(ddr3_ck_p),
	.ddr3_ck_n(ddr3_ck_n),
	.ddr3_cke(ddr3_cke),
	.ddr3_reset_n(ddr3_reset_n),
	.ddr3_dm(ddr3_dm),
	.ddr3_odt(ddr3_odt)
);
end
end
endgenerate

Minimig1 #(.SIM(SIM)) umm1
(
	// m68k pins
	.cpu_data(cpu_data),	  // m68k data bus
	.cpu_address(cpu_addr[31:1]),	// m68k address bus
	._cpu_ipl(_cpu_ipl),		// m68k interrupt request
	._cpu_as(_cpu_as),			// m68k address strobe
	._cpu_uds(_cpu_uds),		// m68k upper data strobe
	._cpu_lds(_cpu_lds),		// m68k lower data strobe
	.cpu_r_w(cpu_r_w),			// m68k read / write
	._cpu_dtack(_cpu_dtack),	// m68k data acknowledge
	._cpu_reset(_cpu_reset),	// m68k reset
	.cpu_clk(cpu_clk),			// m68k clock
	// sram pins
	.ram_data(ram_data),	    // sram data bus
	.ram_address(ram_addr1),	   // sram address bus
	._ram_ce(_ram_ce),     		// sram chip enable
	._ram_bhe(_ram_bhe),		// sram upper byte select
	._ram_ble(_ram_ble),		// sram lower byte select
	._ram_we(_ram_we),			// sram write enable
	._ram_oe(_ram_oe),			// sram output enable
	// system	pins
	.mreset(~cpu_resetn),
	.mclk(xclk),				// master system clock (100MHz)
	.locked(locked),
	// rs232 pins
	.rxd(1'b0),				// rs232 receive
	.txd(),				// rs232 send
	.cts(1'b1),				// rs232 clear to send
	.rts(),				// rs232 request to send
	// I/O
	._joy1(),			// joystick 1 [fire2,fire,up,down,left,right] (default mouse port)
	._joy2(),			// joystick 2 [fire2,fire,up,down,left,right] (default joystick port)
	._15khz(1'b1),				// scandoubler disable
	.pwrled(),		// power led
	.msdat(),				// PS2 mouse data
	.msclk(),				// PS2 mouse clk
	.kbddat(kd),				// PS2 keyboard data
	.kbdclk(kclk),				// PS2 keyboard clk
	// host controller interface (SPI)
	._scs(),			// SPI chip select
	.sdi(),				// SPI data input
	.sdo(),				// SPI data output
	.sck(),				// SPI clock
	// video
	.eol(eol),
	.eof(eof),
	._hsync(hSync_n),        // hSync active low
	._vsync(vSync_n),
	.red(red[7:4]),			// red
	.green(green[7:4]),		// green
	.blue(blue[7:4]),			// blue
	//.blank(blank),
	// audio
	.left(),				// audio bitstream left
	.right(),				// audio bitstream right
	// user i/o
	.gpio(),
	.leds(),
	// unused pins
	.init_b(),				// vertical sync for MCU (sync OSD update)
    .sel_boot(sel_boot),
	.clk200(clk200),
	.clk40(clk40)
);

assign led = btndd ? cpu_addr[23:16] : btnrd ? cpu_addr[15:8] : cpu_addr[7:0];
//assign led[1] = sel_boot;
//assign led[0] = vSync;
//assign led[1] = locked;
/*
assign led[1:0] = 2'h0;
assign led[6] = locked;
assign led[5] = cpu_clk;
assign led[4] = ~cpu_resetn;
assign led[3] = vSync;
assign led[2] = hSync;
*/
assign red[3:0] = 4'h0;
assign green[3:0] = 4'h0;
assign blue[3:0] = 4'h0;

endmodule
