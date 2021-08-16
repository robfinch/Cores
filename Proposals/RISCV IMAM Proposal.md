# RISCV - Indexed Memory Access Modes (IMAM) Proposal
RISCV HW specification. Working draft, subject to change.

<strong>Contributors:</strong> Robert T. Finch

## Introduction
Indexed address modes of the form using a base and an index register are commonly supported in many architectures. This is sometimes called double-indexed addressing to disambiguate the mode from register indirect addressing which is also sometimes called indexed addressing. Described here indexed addressing refers to a mode using two registers in the effective address calculation. It is a feature that the RISCV architecture lacks due to its Spartan mindset. It has been author's experience that somewhere between 1% and 2% of all instructions use the indexed address mode when present in the processor. Clearly this with this small a percentage of usage and the capacity to construct the equivalent addressing from existing instructions it makes sense that indexed addressing is not supported by the base architecture. However, there is some justification for the support of indexed addressing in the extended architecture even if only as custom instructions. a) Portability, as many architectures support indexed addressing it may be easier to port existing software if it were also supported in RISCV. b) Contructing a target address without using indexed addressing often requires more instructions and more registers to be used. This decreases code density and increases register pressure. RISCV can in some cases construct indexed addressing using only two compressed instructions, giving it almost the same performance characteristics as indexed addressing.

## Proposal
We Propose:
*	adding scaled indexed loads and stores as custom instructions.

## Rationale
Scaled indexed addressing does not consume as much opcode space as register indirect addressing and may be implemented within a subset of a custom instruction range. The same quantities can be loaded as for register indirect addressing. Scaling of the index register allows loops to be formed which count in terms of a primitive type size rather than in bytes. There is sometimes a savings in cases where the indexing register is same register containing the loop count.
Care has been taken that Rs2 is the register stored for store instructions, and a consistent register Rs3 is used for indexing.

## Instruction Format
### Scaled Indexed Load Instructions

| Rs3 | Sc | 0 | F3L | Rs1 | 1 | Rd | 13 |

Rs3 is the index register which is scaled
Sc  is the scaling amount code
F3L is a three bit load size specification using the same values as the three bit load specification for register indirect addressing.
Rs1 is the base register
Rd  is the target register of the load operation

### Scaled Indexed Store Instructions

| Rs3 | Sc | Rs2 | Rs1 | 2 | 0 | F3S | 13 |

Rs3 is the index register which is scaled
Sc  is the scaling amount code
Rs2 is the source register to store to memory
F3S is a three bit store size specification using the same values as the three bit store specification for register indirect addressing.

## Address Generation
The target effective address is generated as the sum of Rs1 plus Rs3 scaled by a scaling constant.

## Scale
Two bits of the instruction are dedicated to indicate a scaling value applied to Rs3 during address formation. Rs3 is shifted left by the scale code which is the same as being multiplied by the amount. The two bits represent scaling as outlined in the table below.
| Sc | Amount |
|----|--------|
|  0 |    1   |
|  1 |    2   |
|  2 |    4   |
|  3 |    8   |

## Exceptions / Faults
Scaled indexed addressing is subject to same set of exceptions or faults as register indirect addressing.

## Examples

## Example Test System

The CS01 files may be found at: https://github.com/robfinch/Cores/tree/master/CS01
