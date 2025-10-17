fasm 2.asm 2.o
ld 2.o -lc -lncurses -dynamic-linker /lib64/ld-linux-x86-64.so.2 -o 2.out
./2.out 100 10