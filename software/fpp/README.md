# FPP64 - Finitron Pre-Processor

## Overview

This is a standard "C" language preprocessor written as a standlone app.
It may be used for other pre-processing requirements.
The latest version has a syntax option (/Sastd) for pre-processing assembly language file.
It can support recursive macro definitions.

## Operation

The pre-processor operates by reading a bit into a text buffer and performing macro substitutions on the text in the buffer.
Substitutions can result in more substitutions being required. The substituter will loop a maximum number of times.
The text buffer grows as substitutions are made and more text is read from input files.
The result is stored in memory and written to the output file once the end of the input file is detected and all
substitutions are finished.

## Status

The most recent update allows default arguments to be specified for macro arguments.
The argument is followed by an '=' sign, then the default value.
The most recent version 3.xx is passing most of the test suite without issues.

## Supported Directives

The standard "C" language directives are supported.
This is just a pre-processor so it does not support all the directives found in assembly language.
It only supports those used by pre-processing. The list of supported assembly language directives includes:

* "define"
* "set"
* "equ"
* "err"
* "abort"
* "include"
* "else"
* "ifdef"
* "ifndef"
* "ifeq"
* "ifne"
* "ifgt"
* "ifge"
* "iflt"
* "ifle"
* "ifb"
* "ifnb"
* "if"
* "incdir"
* "endif"
* "undef"
* "macro"
* "endm"
* "irp"
* "rept"
* "endr"
