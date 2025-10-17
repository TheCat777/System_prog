fasm 3.asm 3.o
ld 3.o -lc -lncurses -dynamic-linker /lib64/ld-linux-x86-64.so.2 -o 3.out
./3.out aboba