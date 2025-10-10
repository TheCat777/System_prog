format elf64

public _start

include 'func.asm'

section '.bss' writable
    buffer rb 200
    pid rq 1
    status rd 1
    args rq 5

    input db "1.txt", 0
    input2 db "2.txt", 0
    output db "3.txt", 0
	
section '.text' executable
_start:	
main_loop:
    mov rsi, buffer
    call input_keyboard
    mov rax, 57
    syscall
    cmp rax, 0
    jne wait_up
    mov [args], buffer
    mov [args+8], input
    mov [args+16], input2 
    mov [args+24], output
    mov [args+32], 0
    mov rsi, args
    mov rdi, buffer
    mov rax, 59
    syscall
    call exit

wait_up:
    mov rdi, -1
    mov rsi, status
    mov rdx, 0
    mov r10, 0
    mov rax, 61
    syscall
    jmp main_loop