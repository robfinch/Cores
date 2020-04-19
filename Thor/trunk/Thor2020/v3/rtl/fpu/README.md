# Posit Arithmetic Code
## Overview
The posit number format is a relatively new number format (2013) developed by John L. Gustafson.
It can act as a substitute for IEEE floating-point number format and offers better accuracy.
More information on this can be found at: posithub.org

## History / Origins
This code was begun in April 2020.
While much of the code is orignal, some of this code (heavily modified) originated from:
  https://github.com/manish-kj/Posit-HDL-Arithmetic
  and the PACoGEN project

## Operation
This code performs all operations in one long clock cycle, relying on toolsets to retime the
logic across multiple clock cycles if needed for performance. In order to get retiming it
will be neccessary to add some registers in the output paths.
