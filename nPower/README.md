# Welcome to nPower!

## Overview
This is yet another project in the works.
The nPower core is a 32-bit PowerPC subset compatible core. It can run most common instructions but leaves out some of the features like segmentation and virtual memory.
The core is a superpipelined in-order dual issue superscalar core.

## Instructions Currently Supported
ADD   ADDI  ADDIS   LBZ   LBZU  LBZX  LBZUX   MFCR    MTCRF
SUBF                LHZ   LHZU  LHZX  LHZUX   MFSPR   MTSPR
CMP   CMPI  EXTB    LWZ   LWZU  LWZX  LWZUX   MFLR    MTLR
CMPL  CMPLI EXTH    STB   STBU  STBX  STBUX   MFCTR   MTCTR
AND   ANDI  ANDIS   STH   STHU  STHX  STHUX   MFXER   MTXER
OR    ORI   ORIS    STW   STWU  STWX  STWUX   MCRXR
XOR   XORI  XORIS   B     BC    BCCTR BCLR
ANDC  ORC           CRAND CROR  CRXOR
NAND  NOR           CRNAND CRNOR CREQV
EQV                 CRANDC  CRORC
MULLI MULLW RLWIMI
SLW   NEG   RLWINM
SRW         RLWNM
SRAW  SRAWI

## Features
* Dual pipelines
* 8kB instruction cache
* single channel to memory

## Status
Work began on this core about December 5th, 2020. It is still in its early stages and has many issues to fix.
