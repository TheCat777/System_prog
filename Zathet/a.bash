fasm 1.asm
ld 1.o -lc -lncurses -dynamic-linker /lib64/ld-linux-x86-64.so.2 -o 1.out
./1.out input.txt