# DSD9 System On a Chip

DSD9 SoC is the latest incarnation of the system built to test various components. And mainly for fun.
Most of the system is continuously "in the works". 

# Status
DSD9 SoC isn't completely working yet. Currently it boots to simple button based menu selection which
allows testing system RAM or testing FP. Testing FP doesn't work yet. 

The reset button must be pressed and released to start the system. Next the down button must be pressed several times which steps through some system tests before arriving at the main menu.

The SoC includes a number of different devices including:
	- 2 text controllers,
	- bitmap controller,
	- sprite controller,
	- sound generator,
	- keyboard interface,
	- leds and switches interface,
	- seven segment eight character display
	- button interface
	- DSD9 80 bit cpu with floating point

## System Memory Map

|Address Range| Device|
|:--- |:---|
|$0000xxxx| scratchpad ram (only 16kB)|
|$0xxxxxxx| main memory (128 MB)|
|$FFDC000x|	keyboard|
|$FFDC008x| seven segment display|
|$FFDC009x| buttons|
|$FFDC060x| leds and switches|
|$FFDC5xxx| bitmap controller|
|$FFD0xxxx| text controller #1|
|$FFD1xxxx| text controller #2|
|$FFD300xx| life game|
|$FFD500xx|	sound generator|
|$FFD8xxxx| sprite image ram|
|$FFDADxxx| sprite controller|
|$FFFCxxxx| boot rom|
|$FFFDxxxx| boot rom|

## Brief Desciption of I/O Devices

### Seven Segment Display

The seven segment display may be updated simply by storing a value to $FFDC0080.
Each digit is "on" for approximately 500 us. There is a 10us inter-digit blanking interval.
The entire display is driven at approximately 250kHz.
The decimal points are wired up to act as additional LEDS for system display
|Point|Function|
|:---:|:---|
|7|Uart Tx status|
|6|Uart Rx status|
|3|irq indicator|
|2|memory reservation request active|
|1|memory reservation cleared|
|0|memory reservation status|

### Buttons

Buttons may be read using a simple load instruction from $FFDC0090. Buttons are debounced with a hardware debounce circuit.

### LEDS and Switches

LEDS may be updated by storing to $FFDC0600. Switches may be read by loading from $FFDC0600.
|Switch|Function|
|:---:|:---|
|0|Turns the bitmap controller on or off|
|1|Enables text controller #1 output|
|2|Enables bitmap controller output|
|3|Enables Game of Life output|
|4|Enables sprite controller output|
|13|Enables audio output|
|14|Selects a continuous 800Hz tone to test audio output|

### Bitmap Controller

The bitmap controller is capable of a wide variety of display and color resolutions.
The video timing generator generates signals for a 1366x768 widescreen display.
The default mode for the bitmap controller is 340x256x16bpp. Higher resolutions are possible.
Note the Nexys4ddr board has 12 bit VGA output.
Some experimentation may be requried to determine the maximum video mode that works reliably.

## Locating Source Code

The files for the system on a chip are spread out in several directories under the *Cores* repository. They are really projects and mini-projects in their own right.
Files specific to only DSD9 will be found under the DSD9 directory.

Hopefully they are relatively easy to find. Most of them are placed in directories that correspond to supported devices.
Keyboard code is found under the keyboard directory.
Video code (text controllers, bitmap controllers) are found under the video directory.
Sound generator files (PSG) can be found under the audio folder.

It may be necessary to search a bit to find all the files.
Some files are not present because they are vendor proprietary. In particular some of the block memory components were generated with vendor tools.

## Hierarchy

The top file for the system on chip is DSD9Soc_Nexys4ddr.v
There are dozens of files (80+) that make up the system. The system is broken up into components that can be reused for other projects.

|File| Location|Comment|
|----|:---|:---|
|DSD9Soc_Nexys4ddr|Cores\DSD\DSD9\trunk\soc\rtl\verilog|Top level file|
|....clkgen1366x768_Nexys4ddr|Cores\DSD\DSD9\trunk\soc\rtl\verilog||
|....WXGASyncGen1366x768_60Hz|Cores\video\trunk\rtl\verilog||
|........counter|Cores\lib\trunk\rtl\verilog||
|....BtnDebounce|Cores\lib\trunk\rtl\verilog||
|....seven_seg8|Cores\lib\trunk\rtl\verilog||
|........down_counter|Cores\lib\trunk\rtl\verilog||
|....Ps2Keyboard|Cores\keyboard\trunk\rtl\verilog||
|........Ps2Interface||This file is part of the Nexys4ddr demo project by Digilent.com|
|....IOBridge|Cores\DSD\DSD9\trunk\soc\rtl\verilog||
|....lifegame|Cores\DSD\DSD9\trunk\rtl\verilog\life||
|........edge_det|Cores\lib\trunk\rtl\verilog||
|....DSD9_TextController|Cores\video\trunk\rtl\verilog||
|........regReadbackMem|Cores\memory\trunk\rtl\verilog||
|........syncRam4kx9_1rw1r|Cores\memory\trunk\rtl\verilog||
|........HVCounter|Cores\video\trunk\rtl\verilog||
|............VT163|Cores\lib\trunk\rtl\verilog||
|............change_det|Cores\lib\trunk\rtl\verilog||
|........VT151|Cores\lib\trunk\rtl\verilog||
|........ParallelToSerial|Cores\lib\trunk\rtl\verilog||
|....DSD9_BitmapController|Cores\video\trunk\rtl\verilog||
|........syncRam512x32_1rw1r|Cores\memory\trunk\rtl\verilog||
|........gfx_calcAddress|Cores\video\trunk\rtl\verilog\gfx_calcAddress4.v||
|........rtfVideoFifo3|Cores\video\trunk\rtl\verilog||
|....DSD9_SpriteController|Cores\video\trunk\rtl\verilog||
|....PSG32|Cores\audio\trunk\rtl\verilog\PSG||
|........mux4to1|Cores\audio\trunk\rtl\verilog\PSG||
|........PSGToneGenerator|Cores\audio\trunk\rtl\verilog\PSG||
|........PSGHarmonicSynthesizer|Cores\audio\trunk\rtl\verilog\PSG||
|........PSGNoteOutMux|Cores\audio\trunk\rtl\verilog\PSG||
|........PSGEnvelopeGenerator|Cores\audio\trunk\rtl\verilog\PSG||
|........PSGShaper|Cores\audio\trunk\rtl\verilog\PSG||
|........PSGFilter2|Cores\audio\trunk\rtl\verilog\PSG||
|........PSGVolumeControl|Cores\audio\trunk\rtl\verilog\PSG||
|....PSGPWMDac|Cores\audio\trunk\rtl\verilog\PSG||
|....FPGAMonitor||This file is part of the Nexys4ddr demo project by Digilent.com|
|....mpmc2|Cores\memory\trunk\rtl\verilog||
|.......ddr2||These files are part of the Nexys4ddr demo project by Digilent.com|
|....scratchram|Cores\memory\trunk\rtl\verilog|This file contains a generated memory|
|....bootrom|Cores\DSD\DSD9\trunk\soc\rtl\verilog||
|....BusError|||
|....DSD9_mpu|Cores\DSD\DSD9\trunk\rtl\verilog||
|........DSD9|Cores\DSD\DSD9\trunk\rtl\verilog\DSD9a.v||
|............DSD9_multiplier|Cores\DSD\DSD9\trunk\rtl\verilog||
|............DSD9_divider|Cores\DSD\DSD9\trunk\rtl\verilog||
|............DSD9_logic|Cores\DSD\DSD9\trunk\rtl\verilog||
|............DSD9_shift|Cores\DSD\DSD9\trunk\rtl\verilog||
|............DSD9_bitfield|Cores\DSD\DSD9\trunk\rtl\verilog||
|............DSD9_SetEval|Cores\DSD\DSD9\trunk\rtl\verilog||
|............fpunit|Cores\DSD\DSD9\trunk\rtl\verilog\fpUnit||
|................fpZLUnit|Cores\DSD\DSD9\trunk\rtl\verilog\fpUnit||
|....................fp_cmp_unit|Cores\DSD\DSD9\trunk\rtl\verilog\fpUnit||
|........................fp_decomp|Cores\DSD\DSD9\trunk\rtl\verilog\fpUnit||
|................fpLOOUnit|Cores\DSD\DSD9\trunk\rtl\verilog\fpUnit||
|....................delay1|Cores\lib\trunk\rtl\verilog\delay.v||
|....................delay2|Cores\lib\trunk\rtl\verilog\delay.v||
|....................delay4|Cores\lib\trunk\rtl\verilog\delay.v||
|....................delay5|Cores\lib\trunk\rtl\verilog\delay.v||
|....................itof|Cores\DSD\DSD9\trunk\rtl\verilog\fpUnit||
|........................cntlz128Reg|Cores\lib\trunk\rtl\verilog\cntlz.v||
|........................cntlz96Reg|Cores\lib\trunk\rtl\verilog\cntlz.v||
|........................cntlz80Reg|Cores\lib\trunk\rtl\verilog\cntlz.v||
|........................cntlz64Reg|Cores\lib\trunk\rtl\verilog\cntlz.v||
|........................cntlz32Reg|Cores\lib\trunk\rtl\verilog\cntlz.v||
|....................ftoi|Cores\DSD\DSD9\trunk\rtl\verilog\fpUnit||
|................fpAddsub|Cores\DSD\DSD9\trunk\rtl\verilog\fpUnit||
|....................fpDecomp|Cores\DSD\DSD9\trunk\rtl\verilog\fpUnit||
|....................redor128|Cores\lib\trunk\rtl\verilog||
|....................redor96|Cores\lib\trunk\rtl\verilog||
|....................redor80|Cores\lib\trunk\rtl\verilog||
|....................redor64|Cores\lib\trunk\rtl\verilog||
|....................redor32|Cores\lib\trunk\rtl\verilog||
|................fpDiv|Cores\DSD\DSD9\trunk\rtl\verilog\fpUnit||
|....................fpdivr8|Cores\DSD\DSD9\trunk\rtl\verilog\fpUnit||
|....................specialCaseDivider|Cores\lib\trunk\rtl\verilog||
|................fpMul|Cores\DSD\DSD9\trunk\rtl\verilog\fpUnit||
|................fpNormalize|Cores\DSD\DSD9\trunk\rtl\verilog\fpUnit||
|................fpRoundReg|Cores\DSD\DSD9\trunk\rtl\verilog\fpUnit\fpRound.v||
|....................fpRound|Cores\DSD\DSD9\trunk\rtl\verilog\fpUnit\fpRound.v||
|............DSD9_BranchEval|Cores\DSD\DSD9\trunk\rtl\verilog||
|............DSD9_BranchHistory|Cores\DSD\DSD9\trunk\rtl\verilog||
|............DSD9_L2_icache|Cores\DSD\DSD9\trunk\rtl\verilog\DSD9a.v||
|............DSD9_L1_icache|Cores\DSD\DSD9\trunk\rtl\verilog\DSD9a.v||
|............vtdl|Cores\lib\trunk\rtl\verilog||
|............DSD9_dache|Cores\DSD\DSD9\trunk\rtl\verilog\DSD9a.v||
|............DSD9_mmu|Cores\DSD\DSD9\trunk\rtl\verilog||
|........DSD9_pic|Cores\DSD\DSD9\trunk\rtl\verilog||
|........DSD_30Hz|Cores\DSD\DSD9\trunk\rtl\verilog||



