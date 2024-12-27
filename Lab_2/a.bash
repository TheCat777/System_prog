fasm aboba.asm
ld aboba.o -lc -lncurses -dynamic-linker /lib64/ld-linux-x86-64.so.2 -o aboba.out
./aboba.out 123