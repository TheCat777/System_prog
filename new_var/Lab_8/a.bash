FILE=2
fasm $FILE.asm $FILE.o
ld $FILE.o -lc -lm -dynamic-linker /lib64/ld-linux-x86-64.so.2 -o $FILE.out
./$FILE.out