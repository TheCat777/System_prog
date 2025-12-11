format ELF64

include 'func.asm'

public _start

section '.bss' writable
    buffer      rb 255
    input dq ?
    msg_yes     db "Yes", 0x0A
    msg_yes_len = $ - msg_yes
    msg_no      db "No", 0x0A
    msg_no_len = $ - msg_no


section '.text' executable
_start:
    call read
    
    ; Находим длину строки
    mov rdi, buffer
    xor rcx, rcx        ; счётчик длины
.find_length:
    cmp byte [rdi + rcx], 0x0A
    je .length_found
    inc rcx
    jmp .find_length

.length_found:
    cmp rcx, 1
    jle .output_yes     ; если длина <= 1, то порядок неубывающий

    mov rsi, buffer 
    mov rbx, rcx 
    dec rbx

    .check_loop:
        mov al, [rsi]       ; текущая цифра
        mov dl, [rsi + 1]   ; следующая цифра
        
        cmp al, dl
        jg .output_no       ; если текущая > следующей - порядок не неубывающий
        
        inc rsi
        dec rbx
        cmp rbx, 0
        jnz .check_loop

.output_yes:
    mov rax, 1
    mov rdi, 1 
    mov rsi, msg_yes
    mov rdx, msg_yes_len
    syscall
    call exit

.output_no:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_no
    mov rdx, msg_no_len
    syscall
    call exit

read:
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 255
    syscall
    ret