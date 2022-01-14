cd a09\a09\debug
a09 -Lboot_rom.lst -Vboot_rom.ver boot_rom.asm
a09 -Lboot_rom.lst -bboot_rom.bin boot_rom.asm
cd ..\..\..
cd forth
a09 -Lforth.lst -Vforth.ver forth.asm
a09 -Lforth.lst -bforth.bin forth.asm
cd ..
cd ExBasROM
REM a09 -LExBasROM.lst -VExBasROM.ver -bExBasROM.bin ExBasROM.asm
cd ..

