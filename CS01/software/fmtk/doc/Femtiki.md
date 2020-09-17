# "Femtiki" Finitron Multi-Tasking Kernel

## Overview
Femtiki is a modern operating system kernel.
All FMTK functions return a status in $a0 which is normally E_Ok if the function performed successfully or one of the error codes if the function failed. A second return value is return in $a1 for some functions.
Arguments to Femtiki functions are passed in $a1 to $a6. The function call number is specified in $a0. The Femtiki OS dispatch function will copy user argument registers to machine mode registers for use by the OS.
Function call numbers in the range $000 to $3FF are reserved for the Femtiki OS.
Femtiki function calls are performed by loading the function number into $a0 and function arguments into registers $a1 to $a6, then issuing an environment call (ecall) instruction.

## System Functions

### Initialization - Function 0
Invoking the initialization function will completely reset Femtiki.

#### Parameters:
  none

### Starting a Task - Function 1
This function starts a task running at a normal priority level with a small 1kB stack.
#### Parameters:
* $a1 = memory required (task's local memory)
* $a2 = starting address

### Exiting a Task - Function 2
There are two ways a task may end. One is by invoking the ExitTask function the other via KillTask.
Exit task exits the currently running task. Memory associated with the task is added to the garbage collection list.
#### Parameters:
* none

### Killing a Task - function 3
There are two ways a task may end. One is by invoking the ExitTask function the other via KillTask.
KillTask causes a specified task to end. Internal to the operating system ExitTask falls through into the KillTask function after determining the task id.
Note that the system task is immortal, it may not be killed.
#### Parameters:
* $a1 = task id of task to kill

### Setting Task Priority - function 4
This function call sets the task's priority. There are five priority levels supported by the OS (0 to 4). Each level has it's own queue for tasks.
Tasks start at a normal priority level of 2. Level 0 is the highest priority while level 4 is the lowest. High priority tasks are given more time slices than low ones.
Femtiki varies which queue it looks at from time to time to avoid starving low priority tasks.
#### Parameters:
* $a1 = new task priority (0 to 4)

### Sleeping - function 5
The sleep function puts a task to sleep placing it on a timeout list for the specified number of time slices (30 ms intervals). The sleep function may be invoked with an argument of zero to yield the current task without placing it on a timeout list.
The operating system keeps track of how long the task has been running. 
#### Parameters:
* $a1 = length of time to sleep in 30 ms intervals (must be >= 0)

### Allocate a Mailbox - function 6
The mailbox allocate function does just that. Mailboxes are associated with applications and are used as a holding spot for either messages or tasks.
Tasks queue at mailboxes while waiting for messages to arrive. Messages queue at mailboxes if there are no waiting tasks.
#### Parameters:
* $a1 = app id of owning app
#### Returns:
* $a0 = E_Ok if successful
* $a1 = mailbox handle

### Free Mailbox = function 7
This function causes waiting tasks to be dequeued from the mailbox and waiting messages to be dequeued as well. The mailbox is then returned to the pool of available mailboxes.
Tasks waiting for messages at the mailbox will recieve a 'E_NoMsg' returned from the WaitMsg call.
#### Parameters:
* $a1 = mailbox handle

### Send Message - function 9
This function sends a message to a mailbox. The message will be broadcast to any waiting tasks. Waiting tasks will then be moved to the ready queue. If there are no waiting tasks then the message is queued at the mailbox.
Messages consist of three words of information. The exact meaning of the words is application dependent.
#### Parameters:
*	$a1 = mailbox handle
* $a2 = message d1
* $a3 = message d2
* $a4 = message d3

### Wait Message - function 10
Invoking WaitMsg will cause the task to be queued at the mailbox and a task switch to occur if there are no messages at the mailbox.
Task may queue for a specified length of time after which they will be dequeued and receive an 'E_NoMsg' return code.
The message pointers may be null pointers if that portion of the message isn't required.
#### Parameters:
* $a1 = mailbox handle
* $a2 = pointer where to put message D1
* $a3 = pointer where to put message D2
* $a4 = pointer where to put message D3
* $a5 = time limit

### Peek Message - function 11
Peek message checks for a message at a mailbox without queueing the task if no message is available.
If a message is available it may optionally be removed from the message queue.
The message pointers may be null pointers if that portion of the message isn't required.
#### Parameters:
* $a1 = mailbox handle
* $a2 = pointer where to put message D1
* $a3 = pointer where to put message D2
* $a4 = pointer where to put message D3
* $a5 = 1 = remove from queue

### Start App - Function 12
This function starts an application. Memory is allocated for code and data and the root task is started.
#### Parameters:
* $a1 = pointer to application startup record

### Scheduler IRQ - Function 13
This function runs the FMTK scheduler. The scheduler is normally run from a time-slice interrupt routine.
#### Parameters:
* none
#### Returns:
* none

### Get Current Task ID - Function 14
This function returns the task id of the currently running task.
#### Parameters:
* none
#### Returns:
* $v0 = E_Ok  (always)
* $v1 = task id

### Has IO Focus - Function 20
This function returns the a status indicating whether or not the current app has the I/O focus.
#### Parameters:
* none
#### Returns:
* $v0 = E_Ok  (always)
* $v1 = 1 if focus is present, 0 otherwise

### Switch IO Focus - Function 21
This function switches the I/O focus to the next task in the list. The virtual screen and keyboard buffers are swapped with real ones.
#### Parameters:
* none
#### Returns:
* $v0 = E_Ok  (always)

### Release IO Focus - Function 22
This function removes the current application from the I/O focus list.
#### Parameters:
* none
#### Returns:
* $v0 = E_Ok  (always)

### Force Release IO Focus - Function 23
This function removes the specified application from the I/O focus list.
#### Parameters:
* $a1 = application id
#### Returns:
* $v0 = E_Ok  (always)

### Release IO Focus - Function 24
This function adds the current application to the I/O focus list.
#### Parameters:
* none
#### Returns:
* $v0 = E_Ok  (always)

### IO - Function 26
This function is an entry point for access to I/O device routines. There are a number of sub-functions available through this entry point.
#### Parameters:
* $a1 = sub-function number to invoke
* $a2 to $a6 parameters as needed for sub-function.

## System Objects

### Application Control Block (ACB)
The application control block stores information associated with an application, it's quite large (4kB) so in a small system only a few apps are allowed.
Information stored includes the command line used to start the app, user name, pointers to application code, data and heap, information for garbage collection, and virtual video screen and keyboard buffers.

#### Application Startup Record (ASR)
The application startup record contains information neccesary to start an app. This includes pointers to code and data, priority and processor affinity.

### Task Control Block (TCB)
The task is like a heavy-weight thread. Each task has a 1kB task control block associated with it. The TCB stores state associated with the task. This includes processor registers, time accounting fields, fields to support messaging and others.
Every app has at least one task associated with it, although there may be more than one.

### Threads
Threads are light-weight objects storing state on the stack. Femtiki does not itself support threads other than tasks. Instead thread management is left up applications.

### Device Control Block (DCB)
Each device in the system has a control block associated with it.

## Inner Workings
### Task Id
The task id is a hash of the task control block address. The hash is defined to be able to find the TCB in operating system memory in a fast and efficient manner.
Since TCB's are 1kB aligned the lower 10 bits of the address are always zero. The upper 13 bits of the address are also zero as there's only 512k ram in the system.
That means a simple right shift of the address by 10 bits gives a 9-bit value which is probably adequate for a task id.

### Mailboxes
Mailboxes are allocated in groups of 48 with a group header which fit nicely into a 1kB block of memory.
#### Mailbox handle hash
Mailbox handles are a hash code that allows a quick means for the OS to identify where in memory the mailbox is located.
Since mailboxes are located in 1kB blocks of memory and are at least word aligned, the lower 10 bits of the address shifted right twice forms the low byte of the mailbox handle hash. The OS keeps a small list of mailbox groups, the list contains the addresses of each 1kB group of mailboxes. The index into this list is used for the higher order bits of the mailbox handle hash.

