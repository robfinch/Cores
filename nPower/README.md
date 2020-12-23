# Welcome to nPower!

## Overview
This is yet another project in the works.
The nPower core is a 32-bit PowerPC subset compatible core. It can run most common instructions but leaves out some of the features like segmentation and virtual memory.
The core is a superpipelined in-order dual issue superscalar core.

## Instructions Currently Supported
ADD   ADDI  ADDIS   ADDME   ADDZE   ADDC
AND   ANDI  ANDIS   ANDC
B     BC    BCCTR   BCLR
CMP   CMPI  CMPL    CMPLI
CNTLZW
CRAND CROR  CRXOR                      
CRNAND CRNOR CREQV                     
CRANDC  CRORC                          
DIVW  DIVWU
EQV   EXTB  EXTH
OR    ORC   ORI   ORIS 
LBZ   LBZU  LBZX  LBZUX
LHZ   LHZU  LHZX  LHZUX
LWZ   LWZU  LWZX  LWZUX   
MCRXR
MFCR  MFCTR MFLR  MFSPR MFXER
MTCRF MTCTR MTLR  MTSPR MTXER
MULLI MULLW
NAND  NEG   NOR           
RFI   RLWIMI RLWINM RLWNM
SC
SLW   SRW   SRAW  SRAWI 
STB   STBU  STBX  STBUX
STH   STHU  STHX  STHUX
STW   STWU  STWX  STWUX
SUBF  SUBFIC  SUBFME  SUBFZE  SUBFC
SYNC
TW    TWI
XOR   XORI  XORIS   

## Features
* Dual pipelines
* 8kB 4-way associative instruction cache
* perceptron branch prediction
* single channel to memory

## Reset
On reset the core vectors to $FFFC0000 which is where the system ROM is located, rather than to address $00000100.

## Memory

### Alignment
All access for instructions and data is little-endian. There are no alignment restrictions on data, the core will
run two bus cycles if necessary for unaligned data.

### Interface
The external data bus is 128-bit to facilitate cache loads. The core has a single bus to fetch and store instructions and data.

### Caches
The core has a 8kB 4-way associative instruction cache which can supply two instructions for every machine cycle.
There is currently no data cache.

## Status
Work began on this core about December 5th, 2020. It is still in its early stages and has many issues to fix.
