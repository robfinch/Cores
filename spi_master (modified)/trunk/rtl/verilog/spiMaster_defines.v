// ------------------------ spiMaster_defines.v ----------------------
// Version 0.0 - April 2008. Created
// Version 1.0 - 3rd June 2008. Fixed synchronisation issue between busClk and
//               spiSysClk. Fixed bug in bus accessible reset. Changed names of
//               fifo related modules to avoid conflict with other IP cores.
// Version 1.1 - 23rd August 2008. Modified reset synchronisation. Fixed bug
//               in wb_ack. Fixed file headers, and added description
// Version 1.2 - 25th October 2008. Modified readWriteSPIWireData to clock data
//               from the SPI bus on the rising edge of SCLK. This increases the
//               tsetup timing margin when reading SPI data. It turns out that the timing
//               was marginal for some SD cards when using a 24Mhz SPI clock.
//               Problem was exacerbated by the fact that the design prevents the 
//               final SPI interface Flipflops being pushed into the IO blocks.

`define SPI_MASTER_VERSION_NUM 8'h13
//`define SPI_SYS_CLK_48MHZ
//`define SPI_SYS_CLK_30MHZ
//`define SPI_SYS_CLK_25MHZ
`define SPI_SYS_CLK_100MHZ

//memoryMap
`define CTRL_STS_REG_BASE 8'h00
`define RX_FIFO_BASE 8'h10
`define TX_FIFO_BASE 8'h20
`define CMD_RESP_BASE 8'h30
`define ADDRESS_DECODE_MASK 8'hf0
`define SPI_MASTER_VERSION_REG 8'h00
`define SPI_MASTER_CONTROL_REG 8'h01
`define TRANS_TYPE_REG 8'h02
`define TRANS_CTRL_REG 8'h03
`define TRANS_STS_REG 8'h04
`define TRANS_ERROR_REG 8'h05
`define DIRECT_ACCESS_DATA_REG 8'h06
`define SD_SECT_7_0_REG 8'h07
`define SD_SECT_15_8_REG 8'h08
`define SD_SECT_23_16_REG 8'h09
`define SD_SECT_31_24_REG 8'h0a
`define SPI_CLK_DEL_REG 8'h0b


//FifoAddresses
`define FIFO_DATA_REG 3'b000
`define FIFO_STATUS_REG 3'b001
`define FIFO_DATA_COUNT_MSB 3'b010
`define FIFO_DATA_COUNT_LSB 3'b011
`define FIFO_CONTROL_REG 3'b100


`ifdef SIM_COMPILE
`define SLOW_SPI_CLK 8'h2
`define FAST_SPI_CLK 8'h00
`define TWO_MS 10'h001
`define TWO_FIFTY_MS 12'h001
`define ONE_HUNDRED_MS 12'h00c
`else //not SIM_COMPILE

`ifdef SPI_SYS_CLK_48MHZ

// --------------- spiSysClk = 48MHz
// if you change the clock frequency you will need to change these constants

// SLOW_SPI_CLK controls the SPI clock at start up.
// should be aiming for 400KHz
// SLOW_SPI_CLK = (spiSysClk / (400KHz * 2)) - 1
`define SLOW_SPI_CLK 8'h3b
// controls the SPI clock after init is complete.
// should be aiming for 24MHz ?
// controls the SPI clock after init is complete.
// should be aiming for 24MHz ?
// if spiSysClk >= 48MHz
// FAST_SPI_CLK = (spiSysClk / (24MHz * 2)) - 1
// else FAST_SPI_CLK = 0
`define FAST_SPI_CLK 8'h00
// TWO_MS = ((2mS * spiSysClk) / 256) - 1
`define TWO_MS 10'h177
// TWO_FIFTY_MS = ((250mS * spiSysClk) / 65536) - 1
`define TWO_FIFTY_MS 12'h0b6
// ONE_HUNDRED_MS = ((100mS * spiSysClk) / 65536) - 1
`define ONE_HUNDRED_MS 12'h048

`else //not SPI_SYS_CLK_48MHZ

`ifdef SPI_SYS_CLK_30MHZ
// --------------- spiSysClk = 30MHz
`define SLOW_SPI_CLK 8'h24
`define FAST_SPI_CLK 8'h00
`define TWO_MS 10'h0e9
`define TWO_FIFTY_MS 12'h071
`define ONE_HUNDRED_MS 12'h02c

`endif //SPI_SYS_CLK_30MHZ

`ifdef SPI_SYS_CLK_25MHZ
// --------------- spiSysClk = 25MHz
`define SLOW_SPI_CLK 8'h1e
`define FAST_SPI_CLK 8'h00
`define TWO_MS 10'h0c4
`define TWO_FIFTY_MS 12'h05e
`define ONE_HUNDRED_MS 12'h025
`endif

`ifdef SPI_SYS_CLK_100MHZ
// --------------- spiSysClk = 100MHz
`define SLOW_SPI_CLK 8'h124
`define FAST_SPI_CLK 8'd2
`define TWO_MS 10'd780
`define TWO_FIFTY_MS 12'd380
`define ONE_HUNDRED_MS 12'd152
`endif

`endif //SPI_SYS_CLK_48MHZ
`endif //SIM_COMPILE



`ifdef SIM_COMPILE
`define SD_INIT_START_SEQ_LEN 12'h03
`define MAX_8_BIT 8'h08
`else
`define SD_INIT_START_SEQ_LEN 12'ha0
`define MAX_8_BIT 8'hff
`endif


`define WR_RESP_TOUT 12'hf00

`define NO_BLOCK_REQ 2'b00
`define WRITE_SD_BLOCK 2'b01
`define READ_SD_BLOCK 2'b10

`define READ_NO_ERROR 2'b00
`define READ_CMD_ERROR 2'b01
`define READ_TOKEN_ERROR 2'b10

`define WRITE_NO_ERROR 2'b00
`define WRITE_CMD_ERROR 2'b01
`define WRITE_DATA_ERROR 2'b10
`define WRITE_BUSY_ERROR 2'b11


`define TRANS_NOT_BUSY 1'b0
`define TRANS_BUSY 1'b1

`define TRANS_START 1'b1
`define TRANS_STOP 1'b0

`define DIRECT_ACCESS 2'b00
`define INIT_SD 2'b01
`define RW_READ_SD_BLOCK 2'b10
`define RW_WRITE_SD_BLOCK 2'b11

`define INIT_NO_ERROR 2'b00
`define INIT_CMD0_ERROR 2'b01
`define INIT_CMD1_ERROR 2'b10

`define TX_FIFO_DEPTH 2048
`define TX_FIFO_ADDR_WIDTH 11
`define RX_FIFO_DEPTH 2048
`define RX_FIFO_ADDR_WIDTH 11

