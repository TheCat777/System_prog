format ELF64

public _start

include 'func.asm'

section '.bss' writable
input dq ?
output dq ?
count dq 10

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
    mov r8, rax
    inc r8
    xor r9, r9
    inc r9

    ;два складываем два вычитаем
    .l1:
        cmp r9, [count]
        je .count_add

        xor rdx, rdx
        mov rax, r9
        mul r9
        mov r10, rax
        mov rcx, [count]
        div rcx

        cmp rdx, r9
        je .solve

        inc r9
        cmp r9, r8
        jl .l1

    mov rax, 0xA
    call print
    
    call exit

.solve:
    mov rax, r9
    call print_num
    mov rax, '-'
    call print
    mov rax, r10
    call print_num
    mov rax, ' '
    call print

    inc r9

    cmp r9, r8
    jl .l1

    mov rax, 0xA
    call print
    call exit

.count_add:
    mov rax, [count]
    mov r10, 10
    mul r10
    mov [count], rax

    cmp r9, r8
    jl .l1

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