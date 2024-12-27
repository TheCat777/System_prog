format ELF64

public _start

include 'func.asm'

section '.bss' writable
input dq ?
output dq ?

section '.text' executable
_start:
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 255
    syscall

    mov rax, input
    call len_str
    mov byte [input + rax], 0
    call str_number
    mov rsi, rax
    xor r8, r8

    ;два складываем два вычитаем
    .l1:
        mov rax, rsi
        mov rcx, 4
        div rcx
        cmp rdx, 0
        je .negat
        cmp rdx, 3
        je .negat
        add r8, rsi
        jmp .cont
        .negat:
            sub r8, rsi
        .cont:
            dec rsi
        cmp rsi, 0
        jg .l1

    mov rax, r8
    call print_num
    mov rax, 0xA
    call print
    call exit

print:
    push rcx
    mov [output], rax
    mov eax, 1
    mov edi, 1
    mov rsi, output
    mov edx, 1
    syscall
    pop rcx
    ret

print_num:
    xor rbx, rbx
    mov rcx, 10
    test rax, rax
    jns .loop
    push rax
    mov rax, '-'
    call print
    pop rax
    neg rax

.loop:
    xor rdx, rdx
    div rcx
    push rdx
    inc rbx
    cmp rax, 0
    jne .loop

.print_loop:
    pop rax
    add rax, 48
    call print
    dec rbx
    cmp rbx, 0
    jne .print_loop
    ret