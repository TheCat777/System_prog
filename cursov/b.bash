fasm main.asm
ld main.o -lc -lncurses -dynamic-linker /lib64/ld-linux-x86-64.so.2 -o main.out
./main.out