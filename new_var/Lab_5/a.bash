fasm 8.asm 8.o
ld 8.o -lc -lncurses -dynamic-linker /lib64/ld-linux-x86-64.so.2 -o 8.out
./8.out 1.txt 2.txt 3.txt