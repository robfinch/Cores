# Welcome to the NVIO2 core

The nvio2 core is a 128-bit core. Since there's little chance of a superscalar core fitting in a low-cost FPGA nvio2 is currently implemented as a simple non-overlapped pipelined design. The ISA is somewhat different than v1. Templates are gone and a fixed 40-bit size instruction is used.
