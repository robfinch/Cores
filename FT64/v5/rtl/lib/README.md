# LIB
-----

This directory contains an assortment of generic library cores.

## ack_gen.v
This core generates a acknowledge signal from input select and write signals. The ack signal is generated after a specified number of clock cycles. The specification is via a core parameter. The ack delay may be set independently for read and write cycles. Ack goes away within one clock cycle of the select signal becoming inactive. The primary use of this core is to generate acknowledge signals for the WISHBONE bus or other types of busses. The level of the ack when inactive is specifiable with a core parameter so this core may be used as a ready signal generator as well.

## BCDMath.v
This file contains a set of cores performing basic BCD operations (add, subtract and multiply). The BCD multiplier uses a simple lookup table to multiply two two-digit BCD numbers.

## cntlz.v - Leading Zeros Counting
This set of cores count the leading zeros in a value by using an efficient combination of lookup tables and adders. The cores are small and fast. These cores replace code that looks like a chain of adders with a more efficient form.

## cntpop.v
This set of cores perform a population count (count of the number of set bits) of a value once again using an efficient combination of lookup tables and adders.

## delay.v
This is a set of cores (delay1, delay2, delay3...) which can delay a signal or a signal bus by a number of clock cycles. The cores are useful in pipelined systems to synchronize signals. There are examples of usage in the floating-point cores.

## DivGoldschmidt.v - Goldschmidt Divider
This is a core implementing a parameterized GoldSchmidt divider. The divider typically completes a divide within six clock cycles or less. The divider consumes a fair number of resources as it uses two double-width multipliers which must be single cycle in order to maintain divider performance. Counting the leading zeros in the divider could be made more efficient by using one of the leading zeros counting cores (cntlz__),
however that may require hard-coding and removing some of the divider parameters.
Shifting the numerator and denomintor right or left using a barrel or funnel shifter is what gives Goldschmidt a lot of it's performance. Most of the divide is being performed by shifting which takes place in a single cycle.
For most floating point numbers shifting left isn't required as the number is always between 1.0 and 2.0. Instead typically only a single shift to the right is required. For fixed point numbers however, we probably want to be able to shift left, hence the LEFT parameter.
With no left shifting the only impact is for denormal numbers which take longer for the divide to converge.

## edge_det.v - detect edges
This core detects an edge on a signal. The leading edge, trailing edge, or both edges may be detected.

## ffo.v
This core finds the first bit set to one searching from the left side of a value to the right. 

## ffz.v
Similar to ffo.v this core finds the first zero instead of the first one.

## lfsr.v
This core is a parameterized version of a linear feedback shift register (LFSR). The core supports a parameterized width up to 31 bits. LFSR's are often used to obtain what appears to be random sequences of numbers.

## redor__.v
This set of cores performs a reduction or operation on the input values. The 'a' input choose the number of bits to perform the reduction on. This core is used by some floating-point cores.

## round_robin.v - Round Robin Arbitrator
This core arbitrates between different masters in a round-robin fashion. It is parameterized to accept a different number of masters. The currently selected master may be locked by applying a lock signal. 

## vtdl.v - Variable Tap Delay Line
This core is a delay line with a variable tap position. The tap position is controllable at run time. It may be used as a simple fifo. The width of the delay line is parameterized.


