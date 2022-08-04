# uart6551

uart6551 is a 6551 register compatible uart core.
uart6551 is a 32-bit peripheral device which may also be used as an eight-bit peripheral.
The uart contains just four 32-bit registers. The low order eight bits of the register set are 6551 compatible.
The upper 24-bits of registers represent an extension to the 6551 register set.
An additional baud-rate selector bit is present which allows the selection of a few more higher baud-rates.
There are also 16 entry transmit and recieve fifos.

## Status

The core has been tried in an FPGA at 9,600 and 115,200 baud and appears to work.

