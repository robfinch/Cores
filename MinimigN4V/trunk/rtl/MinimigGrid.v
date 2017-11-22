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
module MinimigGrid(cpu_resetn, xclk, led,
    kd, kclk,
    TMDS_OUT_clk_p, TMDS_OUT_clk_n, TMDS_OUT_data_p, TMDS_OUT_data_n
);
input cpu_resetn;
input xclk;
output [7:0] led;
inout tri kd;
inout tri kclk;
output TMDS_OUT_clk_p;
output TMDS_OUT_clk_n;
output [2:0] TMDS_OUT_data_p;
output [2:0] TMDS_OUT_data_n;

wire clk400,clk80;
wire locked;
wire cpu_clk;
wire _cpu_reset;
wire rst = ~locked;
wire [2:0] _cpu_ipl;
wire _cpu_dtack;
wire cpu_dd;
wire [31:0] cpu_addr;
wire [15:0] cpu_data_o;
wire [15:0] cpu_data =  cpu_dd ? cpu_data_o : 16'bz;
wire [15:0] cpu_data_i = cpu_data;
wire _cpu_as;
wire _cpu_lds;
wire _cpu_uds;
wire cpu_r_w;
//assign _cpu_reset = locked ? 1'b1 : 1'b0;

wire hSync, vSync;
wire [7:0] red;
wire [7:0] green;
wire [7:0] blue;
wire blank;

wire _ram_bhe,_ram_ble;
wire _ram_we,_ram_oe;
wire [3:0] _ram_ce;
wire _ram_ce1 = &_ram_ce;
wire [15:0] ram_data, ram_data_o;
assign ram_data = _ram_we ? (&_ram_ce ? 16'd0000 : ram_data_o) : 16'bz;
wire [21:0] ram_addr;
assign ram_addr[21] = ~_ram_ce[3] | ~_ram_ce[2];
assign ram_addr[20] = ~_ram_ce[3] | ~_ram_ce[1];
assign ram_addr[0] = 1'b0;
wire [15:0] chip_ram_dat_o;

WXGASyncGen1280x768_60Hz u4
(
	.rst(rst),
	.clk(clk80),
	.hSync(hSync),
	.vSync(vSync),
	.blank(blank),
	.border(border)
);


// The following core supplied by Digilent as part of the NexysVideo examples.
rgb2dvi #(
    .kGenerateSerialClk(1'b0),
    .kClkPrimitive("MMCM"),
    .kClkRange(2),
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
    .vid_pHSync(~hSync),
    .vid_pVSync(vSync),
    .PixelClk(clk80),
    .SerialClk(clk400)
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
    .data_out(cpu_dat_o),
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
chipram chipram1 (
  .clka(clk80),    // input wire clka
  .ena(1'b0),      // input wire ena
  .wea({2{~cpu_r_w & 1'b0}} & ~{_cpu_uds,_cpu_lds}),      // input wire [1 : 0] wea
  .addra(cpu_addr[19:1]),  // input wire [18 : 0] addra
  .dina(cpu_data_o),    // input wire [15 : 0] dina
  .douta(chip_ram_dat_o),  // output wire [15 : 0] douta
  .clkb(clk80),    // input wire clkb
  .enb(~_ram_ce[0]),      // input wire enb
  .web({2{~_ram_we & ~_ram_ce[0]}} & {~{_ram_bhe,_ram_ble}}),      // input wire [1 : 0] web
  .addrb(ram_addr[19:1]),  // input wire [18 : 0] addrb
  .dinb(ram_data),    // input wire [15 : 0] dinb
  .doutb(ram_data_o)  // output wire [15 : 0] doutb
);

Minimig1 umm1
(
	// m68k pins
	.cpu_data(cpu_data),	  // m68k data bus
	.cpu_address(cpu_addr[23:1]),	// m68k address bus
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
	.ram_address(ram_addr[19:1]),	// sram address bus
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
	.pwrled(led[7]),		// power led
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
	._hsync(~hSync),
	._vsync(~vSync),
//	._hsync(_hsync),			// horizontal sync
//	._vsync(_vsync),			// vertical sync
	.red(red[7:4]),			// red
	.green(green[7:4]),		// green
	.blue(blue[7:4]),			// blue
	//.blank(blank),
	// audio
	.left(),				// audio bitstream left
	.right(),				// audio bitstream right
	// user i/o
	.gpio(),
	// unused pins
	.init_b(),				// vertical sync for MCU (sync OSD update)

	.clk400(clk400),
	.clk80(clk80)
);

assign led = cpu_addr[8:1];
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
