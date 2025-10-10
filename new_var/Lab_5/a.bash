fasm 11.asm 11.o
ld 11.o -lc -lncurses -dynamic-linker /lib64/ld-linux-x86-64.so.2 -o 11.out
./11.out