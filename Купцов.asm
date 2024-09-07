format ELF
public _start
msg db "Cuptsov", 0xA, "Sviatoslav", 0xA, "Romanovich", 0xA, 0

_start:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg
    mov edx, 28
    int 0x80
    
    mov eax, 1
    mov ebx, 0
    int 0x80