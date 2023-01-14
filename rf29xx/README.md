# rf2901 bit-slice processing element
## Overview
This bit-slice processing element is modelled after the popular am2901 bit-slice processor.

## Differences from the am2901
- Separate q0,q3,ram0,and ram3 inputs and outputs with output enable decode. The output enable decode allows the inputs and outputs to be externally tri-stated if needed.
  am2901 uses tri-state lines used for both input and output.
- The y output does not have a tri-state driver.
- Increased the number of registers present to 64 from 16. High order register lines may be connected to zero to reduce the number of available registers.
- Independent selection of the target register. If the same behaviour as the am2901 is desired the Rt signal lines may be tied to the Rb signal lines.
  am2901 is setup for 2r connections. 3r connections work better with compilers.

Some of the differences are due to the availablility of more I/O pins. The am2901 was restricted to a 40 pin package.

