# FAL6567

This set of cores makes up a 6567 VIC-II compatible circuit. The core would be implmented in an FPGA or other PLD and would need additional logic for level translations to substitute into a 6567 socket.

## Features
HDMI output
16 sprites
80 column text mode

## Output
Most modern TV's and monitors support HDMI inputs.

## Sprites
By making use of fast paged mode, FPM, of the dynamic RAM, FAL6567 may support up to 16 sprites.
The additional sprites reuse the existing registers. There is a switch in register 32h which selects which sprite registers are visible.
Register 32h may be used to select legacy sprite operation and the set of sprite registers visible.
When 80 column text mode is active sprites may be positioned at only every other X pixel location. This is a design choice because there are 1040 horizontal positions in 80 column mode requiring 10 bits to represent, but the VIC-II register set has room for only a nine-bit coordinate.

## 80 Column Text
A modern display can easily display 80 columns of text in a crisp clean fashion without blurring or fuzziness.
Because the displayed image is rendered to an internal buffer to convert the image to DVI/HDMI output an 80 column mode is possible without needing to increase the frequency of memory access.
Twice as much memory is scanned for character data, this results in longer badlines.

