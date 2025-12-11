fasm 1.asm 1.o
ld 1.o -lc -lncurses -lm -dynamic-linker /lib64/ld-linux-x86-64.so.2 -o 1.out
./1.out