/*
** Filename: USBHostHIDKbd_iomux.c
**
** Automatically created by Application Wizard 1.4.2
**
** Part of solution USBHostHIDKbd in project USBHostHIDKbd
**
** Comments:
**
** Important: Sections between markers "FTDI:S*" and "FTDI:E*" will be overwritten by
** the Application Wizard
*/
#include "vos.h"

void iomux_setup(void)
{
	/* FTDI:SIO IOMux Functions */
	unsigned char packageType;
	
	packageType = vos_get_package_type();
	if (packageType == VINCULUM_II_32_PIN)
	{
		// Debugger to pin 11 as Bi-Directional.
		vos_iomux_define_bidi(199, IOMUX_IN_DEBUGGER, IOMUX_OUT_DEBUGGER);
		// GPIO_Port_A_1 to pin 12 as Input.
		vos_iomux_define_input(12, IOMUX_IN_GPIO_PORT_A_1);
		// GPIO_Port_A_2 to pin 14 as Input.
		vos_iomux_define_input(14, IOMUX_IN_GPIO_PORT_A_2);
		// GPIO_Port_A_3 to pin 15 as Input.
		vos_iomux_define_input(15, IOMUX_IN_GPIO_PORT_A_3);
		// UART_TXD to pin 23 as Output.
		vos_iomux_define_output(23, IOMUX_OUT_UART_TXD);
		// UART_RXD to pin 24 as Input.
		vos_iomux_define_input(24, IOMUX_IN_UART_RXD);
		// UART_RTS_N to pin 25 as Output.
		vos_iomux_define_output(25, IOMUX_OUT_UART_RTS_N);
		// UART_CTS_N to pin 26 as Input.
		vos_iomux_define_input(26, IOMUX_IN_UART_CTS_N);
		// SPI_Slave_0_CLK to pin 29 as Input.
		vos_iomux_define_input(29, IOMUX_IN_SPI_SLAVE_0_CLK);
		// SPI_Slave_0_MOSI to pin 30 as Input.
		vos_iomux_define_input(30, IOMUX_IN_SPI_SLAVE_0_MOSI);
		// SPI_Slave_0_MISO to pin 31 as Output.
		vos_iomux_define_output(31, IOMUX_OUT_SPI_SLAVE_0_MISO);
		// SPI_Slave_0_CS to pin 32 as Input.
		vos_iomux_define_input(32, IOMUX_IN_SPI_SLAVE_0_CS);
	
	}
	if (packageType == VINCULUM_II_48_PIN)
	{
		// Debugger to pin 11 as Bi-Directional.
		vos_iomux_define_bidi(199, IOMUX_IN_DEBUGGER, IOMUX_OUT_DEBUGGER);
		// PWM_1 to pin 12 as Output.
		vos_iomux_define_output(12, IOMUX_OUT_PWM_1);
		// PWM_2 to pin 13 as Output.
		vos_iomux_define_output(13, IOMUX_OUT_PWM_2);
		// PWM_3 to pin 14 as Output.
		vos_iomux_define_output(14, IOMUX_OUT_PWM_3);
		// GPIO_Port_A_1 to pin 46 as Input.
		vos_iomux_define_input(46, IOMUX_IN_GPIO_PORT_A_1);
		// GPIO_Port_A_0 to pin 45 as Input.
		vos_iomux_define_input(45, IOMUX_IN_GPIO_PORT_A_0);
		// GPIO_Port_A_3 to pin 48 as Input.
		vos_iomux_define_input(48, IOMUX_IN_GPIO_PORT_A_3);
		// UART_TXD to pin 31 as Output.
		vos_iomux_define_output(31, IOMUX_OUT_UART_TXD);
		// UART_RXD to pin 32 as Input.
		vos_iomux_define_input(32, IOMUX_IN_UART_RXD);
		// UART_RTS_N to pin 33 as Output.
		vos_iomux_define_output(33, IOMUX_OUT_UART_RTS_N);
		// UART_CTS_N to pin 34 as Input.
		vos_iomux_define_input(34, IOMUX_IN_UART_CTS_N);
		// UART_DTR_N to pin 35 as Output.
		vos_iomux_define_output(35, IOMUX_OUT_UART_DTR_N);
		// UART_DSR_N to pin 36 as Input.
		vos_iomux_define_input(36, IOMUX_IN_UART_DSR_N);
		// UART_DCD to pin 37 as Input.
		vos_iomux_define_input(37, IOMUX_IN_UART_DCD);
		// UART_RI to pin 38 as Input.
		vos_iomux_define_input(38, IOMUX_IN_UART_RI);
		// UART_TX_Active to pin 41 as Output.
		vos_iomux_define_output(41, IOMUX_OUT_UART_TX_ACTIVE);
		// GPIO_Port_A_5 to pin 42 as Input.
		vos_iomux_define_input(42, IOMUX_IN_GPIO_PORT_A_5);
		// GPIO_Port_A_6 to pin 43 as Input.
		vos_iomux_define_input(43, IOMUX_IN_GPIO_PORT_A_6);
		// GPIO_Port_A_7 to pin 44 as Input.
		vos_iomux_define_input(44, IOMUX_IN_GPIO_PORT_A_7);
		// SPI_Slave_0_CLK to pin 15 as Input.
		vos_iomux_define_input(15, IOMUX_IN_SPI_SLAVE_0_CLK);
		// SPI_Slave_0_MOSI to pin 16 as Input.
		vos_iomux_define_input(16, IOMUX_IN_SPI_SLAVE_0_MOSI);
		// SPI_Slave_0_MISO to pin 18 as Output.
		vos_iomux_define_output(18, IOMUX_OUT_SPI_SLAVE_0_MISO);
		// SPI_Slave_0_CS to pin 19 as Input.
		vos_iomux_define_input(19, IOMUX_IN_SPI_SLAVE_0_CS);
		// SPI_Master_CLK to pin 20 as Output.
		vos_iomux_define_output(20, IOMUX_OUT_SPI_MASTER_CLK);
		// SPI_Master_MOSI to pin 21 as Output.
		vos_iomux_define_output(21, IOMUX_OUT_SPI_MASTER_MOSI);
		// SPI_Master_MISO to pin 22 as Input.
		vos_iomux_define_input(22, IOMUX_IN_SPI_MASTER_MISO);
		// SPI_Master_CS_0 to pin 23 as Output.
		vos_iomux_define_output(23, IOMUX_OUT_SPI_MASTER_CS_0);
	
	}
	if (packageType == VINCULUM_II_64_PIN)
	{
		// Debugger to pin 11 as Bi-Directional.
		vos_iomux_define_bidi(199, IOMUX_IN_DEBUGGER, IOMUX_OUT_DEBUGGER);
		// FIFO_Data_0 to pin 15 as Bi-Directional.
		vos_iomux_define_bidi(15, IOMUX_IN_FIFO_DATA_0, IOMUX_OUT_FIFO_DATA_0);
		// FIFO_Data_1 to pin 16 as Bi-Directional.
		vos_iomux_define_bidi(16, IOMUX_IN_FIFO_DATA_1, IOMUX_OUT_FIFO_DATA_1);
		// FIFO_Data_2 to pin 17 as Bi-Directional.
		vos_iomux_define_bidi(17, IOMUX_IN_FIFO_DATA_2, IOMUX_OUT_FIFO_DATA_2);
		// FIFO_Data_3 to pin 18 as Bi-Directional.
		vos_iomux_define_bidi(18, IOMUX_IN_FIFO_DATA_3, IOMUX_OUT_FIFO_DATA_3);
		// FIFO_Data_4 to pin 19 as Bi-Directional.
		vos_iomux_define_bidi(19, IOMUX_IN_FIFO_DATA_4, IOMUX_OUT_FIFO_DATA_4);
		// FIFO_Data_5 to pin 20 as Bi-Directional.
		vos_iomux_define_bidi(20, IOMUX_IN_FIFO_DATA_5, IOMUX_OUT_FIFO_DATA_5);
		// FIFO_Data_6 to pin 22 as Bi-Directional.
		vos_iomux_define_bidi(22, IOMUX_IN_FIFO_DATA_6, IOMUX_OUT_FIFO_DATA_6);
		// FIFO_Data_7 to pin 23 as Bi-Directional.
		vos_iomux_define_bidi(23, IOMUX_IN_FIFO_DATA_7, IOMUX_OUT_FIFO_DATA_7);
		// FIFO_RXF_N to pin 24 as Output.
		vos_iomux_define_output(24, IOMUX_OUT_FIFO_RXF_N);
		// FIFO_TXE_N to pin 25 as Output.
		vos_iomux_define_output(25, IOMUX_OUT_FIFO_TXE_N);
		// FIFO_RD_N to pin 26 as Input.
		vos_iomux_define_input(26, IOMUX_IN_FIFO_RD_N);
		// FIFO_WR_N to pin 27 as Input.
		vos_iomux_define_input(27, IOMUX_IN_FIFO_WR_N);
		// FIFO_OE_N to pin 28 as Input.
		vos_iomux_define_input(28, IOMUX_IN_FIFO_OE_N);
		// UART_DSR_N to pin 29 as Input.
		vos_iomux_define_input(29, IOMUX_IN_UART_DSR_N);
		// UART_DCD to pin 31 as Input.
		vos_iomux_define_input(31, IOMUX_IN_UART_DCD);
		// UART_RI to pin 32 as Input.
		vos_iomux_define_input(32, IOMUX_IN_UART_RI);
		// UART_TXD to pin 39 as Output.
		vos_iomux_define_output(39, IOMUX_OUT_UART_TXD);
		// UART_RXD to pin 40 as Input.
		vos_iomux_define_input(40, IOMUX_IN_UART_RXD);
		// UART_RTS_N to pin 41 as Output.
		vos_iomux_define_output(41, IOMUX_OUT_UART_RTS_N);
		// UART_CTS_N to pin 42 as Input.
		vos_iomux_define_input(42, IOMUX_IN_UART_CTS_N);
		// UART_DTR_N to pin 43 as Output.
		vos_iomux_define_output(43, IOMUX_OUT_UART_DTR_N);
		// UART_DSR_N to pin 44 as Input.
		vos_iomux_define_input(44, IOMUX_IN_UART_DSR_N);
		// UART_DCD to pin 45 as Input.
		vos_iomux_define_input(45, IOMUX_IN_UART_DCD);
		// UART_RI to pin 46 as Input.
		vos_iomux_define_input(46, IOMUX_IN_UART_RI);
		// UART_TX_Active to pin 47 as Output.
		vos_iomux_define_output(47, IOMUX_OUT_UART_TX_ACTIVE);
		// SPI_Slave_0_CLK to pin 51 as Input.
		vos_iomux_define_input(51, IOMUX_IN_SPI_SLAVE_0_CLK);
		// SPI_Slave_0_MOSI to pin 52 as Input.
		vos_iomux_define_input(52, IOMUX_IN_SPI_SLAVE_0_MOSI);
		// SPI_Slave_0_MISO to pin 55 as Output.
		vos_iomux_define_output(55, IOMUX_OUT_SPI_SLAVE_0_MISO);
		// SPI_Slave_0_CS to pin 56 as Input.
		vos_iomux_define_input(56, IOMUX_IN_SPI_SLAVE_0_CS);
		// SPI_Slave_1_CLK to pin 57 as Input.
		vos_iomux_define_input(57, IOMUX_IN_SPI_SLAVE_1_CLK);
		// SPI_Slave_1_MOSI to pin 58 as Input.
		vos_iomux_define_input(58, IOMUX_IN_SPI_SLAVE_1_MOSI);
		// SPI_Slave_1_MISO to pin 59 as Output.
		vos_iomux_define_output(59, IOMUX_OUT_SPI_SLAVE_1_MISO);
		// SPI_Slave_1_CS to pin 60 as Input.
		vos_iomux_define_input(60, IOMUX_IN_SPI_SLAVE_1_CS);
		// SPI_Master_CLK to pin 61 as Output.
		vos_iomux_define_output(61, IOMUX_OUT_SPI_MASTER_CLK);
		// SPI_Master_MOSI to pin 62 as Output.
		vos_iomux_define_output(62, IOMUX_OUT_SPI_MASTER_MOSI);
		// SPI_Master_MISO to pin 63 as Input.
		vos_iomux_define_input(63, IOMUX_IN_SPI_MASTER_MISO);
		// SPI_Master_CS_0 to pin 64 as Output.
		vos_iomux_define_output(64, IOMUX_OUT_SPI_MASTER_CS_0);
	
	}
	
	/* FTDI:EIO */

}
