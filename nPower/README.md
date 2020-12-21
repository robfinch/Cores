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
MULLI MULLW
NAND  NEG   NOR           
SUBF  SUBFIC  SUBFME  SUBFZE  SUBFC
RFI   RLWIMI RLWINM RLWNM
SLW   SRW  
SRAW  SRAWI
XOR   XORI  XORIS   

LBZ   LBZU  LBZX  LBZUX   MFCR    MTCRF
LHZ   LHZU  LHZX  LHZUX   MFSPR   MTSPR
LWZ   LWZU  LWZX  LWZUX   MFLR    MTLR 
STB   STBU  STBX  STBUX   MFCTR   MTCTR
STH   STHU  STHX  STHUX   MFXER   MTXER
STW   STWU  STWX  STWUX   MCRXR        

## Features
* Dual pipelines
* 8kB 4-way associative instruction cache
* perceptron branch prediction
* single channel to memory

## Status
Work began on this core about December 5th, 2020. It is still in its early stages and has many issues to fix.
