# Tiny Basic

# Introduction
Tiny Basic is a BASIC interpreter that has found its way into numerous systems. The BASIC language is a great language for beginners to learn and is useful for some tasks.

# Operation
On startup Tiny Basic is in direct mode. Direct mode allows direct execution of commands based on user input. Direct mode has a handful more commands than run mode. 
Tiny Basic display a prompt consisting of the task id as a hexidecimal number followed by the '>' character. The task id is a convenience in the event that multiple copies of Tiny Basic are running.
The task id shows you which copy is currently running.

## Direct Mode Commands
From the command prompt the following commands are available in direct mode:
* RUN - begins execution of the program
* LIST - list the program text. This command has an optional line number to begin listing at.
* NEW - clear the variable area and program text area. This creates a blank slate.

## Entering in a Program
Programs may be written in Tiny Basic by preceding program text with a line number while in direct mode. Programs may also be loaded through the terminal using the LOAD command.

### Example
At the command prompt type:
10 PRINT "Hello World!"

PRINT - used to display output. Print can print strings bounded by quotation marks. Multiple items may be printed using the same PRINT command by separating items with a comma or semi-colon.
### Example
PRINT "The value of x is",x

GOTO - will transfer program execution to the line number specified as a command parameter. Note that the command parameter for the line number accepts any valid expression.
It's possible to goto a computed line number such as GOTO X.

GOSUB - will transfer program execution to the line number specified as a command parameter. Note that the command parameter for the line number accepts any valid expression.
In addition to transferring execution to a new line, the current line number is saved on the stack so that a return may be achieved using the RETURN statement.

RETURN - return from a subroutine that was called with the GOSUB statement.

IF (expr) - conditionally execute the next statement if the condition is true.

FOR - the FOR statement allows loops to be created when coupled with the NEXT statement.
FOR var = expr TO expr [STEP expr]

NEXT - the NEXT statement appears at the end of a FOR loop to indicate when to branch back for the next line of execution. The variable name used in the FOR statement must be specified.
NEXT var

#### Example
FOR X = 1 TO 10 : PRINT "Hello World!" : NEXT X

SLEEP - This command puts Tiny Basic to SLEEP suspending the execution of the interpreter for a time which is specified as a command parameter.
#### Example
SLEEP 10  - will suspend Tiny Basic execution for approximately 300 ms. The time increment is in terms of 30 ms intervals.

### Variables
This version of Tiny Basic allows variables names of any length, but variables are differentiated using only the first three characters of the varible name.
Variable names must begin with a letter or underscore and may contain numeric characters.
X = 10 assigns the value 10 to the variable X.

### Saving / Loading Programs
The easist way to save a Tiny Basic program is to switch the terminal to capture a file, then use the LIST statement to echo the program to the file.
To load a program into Tiny Basic use the file send capability of the terminal.
Tiny Basic also features LOAD and SAVE statement which will load or save a program. The format of the program is altered slightly by the LOAD and SAVE commands.
Line numbers are transferred as hexidecimal numbers converted to text.

### Interrupts
This version of Tiny Basic supports interrupt routines. Interrupt routines act like subroutines that are activated by an interrupt. A normal RETURN instruction is used to return fro the interrupt routine.
Interrupt routines are implemented using the 'ONIRQ' statement. This statement would be placed near the start of a program once ready for interrupts. It takes a line number as a parameter.
When an interrupt occurs Tiny Basic will automatically go to the line specified in the 'ONIRQ' statement after finishing processing of the current line.
To disable interrupt routines use 0 as the line number in an ONIRQ statement.

Also supported by this version of Tiny Basic is waiting for an IRQ routine to occur via the WAITIRQ command. The WAITIRQ command simply sits in a loop waiting until the IRQ flag is set.

## Internal Workings

### Program Line Format
Tiny basic stores text lines by storing a single byte line length first, then a four byte binary encoded line number, followed by the line text.
Storing a line length byte allows Tiny Basic to find the next line quickly.

|-------|--------|--------------|
| Line | Binary | Program Text |
| Length | Line | |
| Byte | Number | |

### Variables
Variables are stored in a variable storage area at the high end of memory available to Tiny Basic. Each variable is stored as a pair of 32-bit words. Variables are aligned on 4 byte addresses for performance.
The first word of a variable entry in the storage area contains the first three letters of the variable name followed by a charcter indicating the variable type.
The second word of a variable contains its value.

### Interrupts
How does Tiny Basic detect an interrupt? Tiny Basic can't place a wedge or hook onto an interrupt routine in the same manner as a compiled program would because it's a running interpreter not a binary executable program.
So, Tiny Basic relies on an interrupt flag to be set by the operating system. It polls this flag at the start of executing a line of basic program text to see if it should execute the interrupt subroutine.
If a line number has been specified by the 'ONIRQ' command and the interrupt flag is set, then Tiny Basic will execute a 'GOSBUB' to the interrupt routine instead of executing the current line of program text.

## Portability
This version of Tiny Basic is more difficult to port than usual. It contains calls to the operating system routines for some function such as interrupts. All the operating system calls are identified by the 'ecall' instruction.

## Limitations
Tiny Basic is limited in the following ways:
* line numbers must be six digits or less
* 800 variables max
* stack depth of 1kB

