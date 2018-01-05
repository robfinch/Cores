# CC64

This is a C compiler for a 68000 compatible cpu core.
The compiler is currently "in the works" and guarenteed not to be fully working at the moment.
It can compile some really simple code correctly, but mostly doesn't compile correctly yet.

In particular there is not yet proper support for temporaries.
Also the compiler sometimes mistakenly updates a register that it shouldn't that it uses later in code.
There are many bugs in it at the moment. 

