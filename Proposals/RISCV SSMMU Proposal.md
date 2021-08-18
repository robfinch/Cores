# RISCV - Simplified System Memory Management Unit (SSMMU) Proposal
RISCV HW specification. Working draft, subject to change.

<strong>Contributors:</strong> Robert T. Finch

## Introduction
Many systems can benefit from the provision of virtual memory management. Virtual memory may be used to protect the address space of one app from another, enhancing the reliability and security of a system.
The simplified system MMU provides minimalistic base and bound and paging capabilities for a small to mid size system. Base bound and paging are applied in all modes of operation. Base address generation is applied to virtual addresses first to generate a linear address which is then mapped using a paged mapping system. Access rights are governed by the base register since all pages based on the same address are likely to require the same access. Support for access rights is optional if it’s desired to reduce the hardware cost.

## Proposal
We Propose:
*	an MMU system containing 16 base/bound registers, and a small page mapping memory
*	a custom instruction ‘mvmap’ to access the page mapping memory
*	a custom instruction ‘mvseg’ to access the base/bound registers
* the page mapping system does not fault if pages are not present

## Rationale
The goal here is to provide a memory management option that sits between basic base and bound memory management and a full-blown paging system in complexity.
The RISCV standard provides several excellent choices for memory management. However, a paged system which must manage a TLB and multi-level page tables may be overly complex for a smaller system while at the same time managing memory using a base and bound system isn’t sufficient.
The use of a custom instruction to access the page mapping memory is motivated by the number of registers contained in the page mapping memory. There are too many registers required to be able to use the CSR register set.
While it's conceivable that several CSR's could be used to manage the table in an indirect fasion it complicates software and obsures meaning.
The ‘mvmap’ instruction works in manner similar to the CSR instruction. It atomically swaps the current value and new value for a mapping register.
Keeping the page mapping table internal to core means no external memory access is required. It can be accessed at high speed.

## Base Registers
It is assumed for a smaller system that upper address bits are not used for addressing memory and are available to select a base/bound register. The SSMMU includes 16 base/bound registers. The base/bound register in use is selected by the upper nybble of the virtual address. In the case of the program address, base/bound register #15 is always used. If an address has all ones in bits 26 to 31 then base/bounds addressing is bypassed. This provides a shared program area containing the BIOS and OS code. Suggested usage of base/bound registers are shown in the table below.

| Base Regno |  Usage   |  Selected By                         |
|------------|----------|--------------------------------------|
|   0 to 7   |   data   | bits 28 to 31 of the virtual address |
|    8,9     | reserved | bits 28 to 31 of the virtual address |
|     10     |  stack   | bits 28 to 31 of the virtual address |
|     11     |   I/O    | bits 28 to 31 of the virtual address |
|     13     |  rodata  | bits 28 to 31 of the virtual address |
|     14     |   code   | storage for return base/bound        |
|     15     |   code   | always for program counter           |

## Base Register Format
| Base Address 28 bits |  RWX  |

The low order four bits of the base register are reserved for access rights bits. Supporting memory access rights is optional.
* R: 1 = segment readable
* W: 1 = segment writeable
* X: 1 = segment executable

## Bound Register Format
| Bounding Address 18 bits |

The bound register contains only 18 bits which when shifted left by 10 bits provides a 28-bit bound address. Note virtual address cannot exceed 28 bits due to the presence of the base/bound selection in the upper four bits. The ten low order bits of a bounding address are filled with ones.

## Linear Address Generation
The base address value contained in the upper 28 bits of a base register is shifted left 10 bits before being added to the virtual address. This gives potentially a 38-bit address space. Note however that the page mapping table limits the physical address space to 26 bits.
The address shift of 10 bits is determined to be the same size as a mapped page.

## Exceptions / Faults
The base/bound system may generate faults if the access rights are violated or if the bounding address is exceeded. When a fault occurs the cause code is set corresponding to the type of fault and the bad address register loaded with the faulting address. One code from the designated custom use faults is used for a bounding address exceeded fault.

|Cause Code|Standard      | Event                                                |
|----------|--------------|------------------------------------------------------|
|    24    |              | Bounding address exceeded                            |
|     5    | read fault   | Attempt to read from un-reabled address range        |
|     7    | write fault  | Attempt to write to un-writable address range        |
|     1    | instr. fault | Attempt to execute from non-executable address range |

## Reset
On reset the code base register is set to zero, and the code bounds register set to all ones. No other base/bound registers are initialized.

## The Page Map
The page directly maps virtual address pages to physical ones. The page map is a dedicated memory internal to the processing core accessible with the custom ‘mvmap’ instruction. It is similar in operation to a TLB but is much simpler. TLB’s cache address translations and create TLB miss exceptions. Page walks of mapping tables are required to update the TLB on a miss. There are no exceptions associated with the page mapping table. 
In addition to based addresses, memory is divided up into 1kB pages which are mapped. There are 16 memory maps available. A memory map represents an address space; a four-bit address space identifier is in use. Address spaces will need to be shared if more than 16 apps are running in the system. The desire is to keep the mapping tables small so they may fit into a small number of standard memory blocks. For instance for the sample system there are 512 pages required to map the 512kB address space and it fits into two block rams. The virtual page number is used to lookup the physical page in the page mapping table. Addresses with the top eight bits set are not mapped to allow access to the system ROM.
The page mapping table is indexed by the ASID and the virtual page number to determine the physical page. The ‘mvmap’ instruction uses Rs1 to contain a mapping table index. Bits 16 to 19 of Rs1 are the ASID, bits 0 to 15 of Rs1 are used for the virtual page number. It is expected that the virtual page number is a small number. Rs2 contains the new value of the physical page. The current value of the physical page is placed in Rd when the instruction executes.

| ASID 4   |  Virtual Page   |  Physical Page   |
|----------|-----------------|------------------|
|    0     |       0         |        10        |
|    0     |       1         |        11        |
|    0     |      ...        |       ...        |
|    0     |      510        |        18        |
|    0     |      511        |        19        |
|    1     |       0         |        21        |
|    1     |      ...        |       ...        |
|    1     |      510        |       ...        |
|    1     |      511        |       ...        |
| 14 more  |      ...        |       ...        |

## The 1kB Page
Many memory systems use a 4kB page size or larger. That size was not chosen here as the available memory is assumed to be small and a 4kB page size would result in too few pages of memory to support multiple tasks. A smaller page size results in less wasted space which is important with a small memory system. It’s a careful balance, an even smaller page size would waste less memory but would require a much larger page mapping ram.

## Physical Page Zero (PPN=0)
To avoid the necessity of an additional bit in the page mapping table to indicate active entries, a physical page number of zero shall indicate that the entry is available to be mapped. This means that physical memory page zero is not accessible. Note that a virtual address of zero remains accessible.

## Exceptions
Unused page map entries should point to an unimplemented area of memory so that an access exception will be generated. It is assumed that an exception (generated by the system, not the mmu) is generated for unimplemented regions of the address space.
Alternately, one page of the memory space could be reserved as a general crash area if exceptions are not supported.
Exceptions may be generated if the access rights specified in a base register don't match the type of access attempted.
Since the mapping mechanism prevents access to unmapped memory areas an app may crash without affecting other apps.

## MVSEG
mvseg atomically swaps the current value to Rd for a new value in Rs1 of the base/bound register identified by Rs2. Values 0 to 15 in Rs2 identify a base register. Values 16 to 31 in Rs2 identify a bounds register.
If Rs1 is x0 then only the current value is returned, no update of the base/bound register takes place.

### Instruction Format
|  0  | Rs2 | Rs1 | 0 |  Rd  |    13   |

## MVMAP
mvmap atomically swaps the current value of the physical page number to Rd for a new value in Rs1 for the page map register identified by Rs2.
If Rs1 is x0 then only the current value is returned, no update of the map register takes place.

### Instruction Format
|  1  | Rs2 | Rs1 | 0 |  Rd  |    13   |

Rs1 Value
| Unused - should be zero 12 bits | ASID 4 bits  |  Virtual Page Number 16 bits max  |
Rs2 Value
| Unused - should be zero 16 bits |  Physical Page Number 16 bits max  |

## Memory Fence
Both the MVSEG and MVMAP instructions may require a memory fence be inserted before-hand to ensure that all memory, instruction fetch, and I/O operations are complete before the MVSEG or MVMAP instruction is executed. Changing the mapping table or base/bound registers should be done in a manner that does not cause the processor to lose its stream of execution. Updates may be done when the top six bits of a program address are all ones in which case base/bound and mapping will not be applied.

## CSR Usage
The SSMMU is specified in the satp register - CSR $180. Mode=bare=0 and ASID[8:7]=3. The low order bits 0 to 6 of the ASID are used to indicate the ASID. Since the mapping table in an internal resource accessed by the 'mvmap' instruction it does not require a base address. So, bits 0 to 21 of the satp register are used to indicate the size of the mapping table. Bit 0 to 15 indicate the number of map entries per map. Bits 16 to 21 indicate the number of maps in the table.

## Examples

## Example Test System

The CS01 files may be found at: https://github.com/robfinch/Cores/tree/master/CS01
