format ELF64
include 'func.asm'

public _start

THREAD_FLAGS = 2147585792
ARRLEN = 731

section '.bss' writable
    array rb ARRLEN
    digits rq 10
    buffer rb 10
    f db "/dev/random", 0
    stack1 rq 4096
    msg1 db "Третье число после максимального:", 0xA, 0
    msg2 db "Медиана:", 0xA, 0
    msg3 db "Наиболее часто встречающаяся цифра:", 0xA, 0
    msg4 db "0.75 Квантиль:", 0xA, 0
    space db " ", 0

section '.text' executable
_start:
    mov rax, 2
    mov rdi, f
    mov rsi, 0
    syscall
    mov r8, rax

    mov rax, 0
    mov rdi, r8
    mov rsi, array
    mov rdx, ARRLEN
    syscall

    ; Фильтрация данных
    .filter_loop:
        call filter
        cmp rax, 0
        jne .filter_loop

    mov rcx, ARRLEN
    .print:
        dec rcx
        xor rax, rax
        mov al, [array + rcx]
        ;mov rsi, buffer
        ;call number_str
        ;call print_str
        ;mov rsi, space
        ;call print_str
        inc rcx
    loop .print

    call new_line

    ; Первый форк для квантиля
    mov rax, 57
    syscall

    cmp rax, 0
    je .quantil

    mov rax, 61
    mov rdi, -1
    mov rdx, 0
    mov r10, 0
    syscall
    
    ; Второй форк для наиболее часто встречающейся цифры
    mov rax, 57
    syscall

    cmp rax, 0
    je .most_frequent_digit

    mov rax, 61
    mov rdi, -1
    mov rdx, 0
    mov r10, 0
    syscall

    ; Третий форк для пятого числа после минимального
    mov rax, 57
    syscall

    cmp rax, 0
    je .3th_max

    mov rax, 61
    mov rdi, -1
    mov rdx, 0
    mov r10, 0
    syscall

    ; Четвёртый форк для медианы
    mov rax, 57
    syscall

    cmp rax, 0
    je .mediana

    mov rax, 61
    mov rdi, -1
    mov rdx, 0
    mov r10, 0
    syscall

    

    call exit

.3th_max:
    mov rsi, msg1
    call print_str

    xor rax, rax
    mov al, [array + ARRLEN - 3]
    mov rsi, buffer
    call number_str
    call print_str
    call new_line
    call exit

.quantil:
    mov rsi, msg4
    call print_str

    xor rdx, rdx
    xor rax, rax

    mov rax, ARRLEN
    mov r8, 4
    div r8
    mov r8, rax

    mov rax, ARRLEN
    sub rax, r8

    mov al, [array + rax]
    movzx r8, al

    xor rax, rax
    mov rax, r8
    mov rsi, buffer
    call number_str
    call print_str
    call new_line
    call exit

.mediana:
    mov rsi, msg2
    call print_str

    xor rdx, rdx
    xor rax, rax

    mov rax, ARRLEN
    mov r8, 2
    div r8


    mov al, [array + rax]
    movzx r8, al

    mov rax, r8
    mov rsi, buffer
    call number_str
    call print_str
    call new_line
    call exit

.most_frequent_digit:
    mov rsi, msg3
    call print_str

    mov rsi, array
    add rsi, ARRLEN
    dec rsi
    xor rbx, rbx
    mov rbx, 10
    .loop1:
        cmp rsi, array
        jl .next1

        xor rax, rax
        mov al, byte [rsi]
        .decomp_loop:
            xor rdx, rdx
            div rbx
            push rax
            mov rax, 8
            mul rdx
            mov rdx, rax
            pop rax
            mov r10, [digits + rdx]
            inc r10
            mov [digits + rdx], r10
            cmp rax, 0
            je @f
            jmp .decomp_loop

        @@:
        dec rsi
        jmp .loop1

    .next1:
    mov rax, 9999999
    xor rbx, rbx
    xor rcx, rcx
    .comp_loop:
        cmp rcx, 10
        je .next2

        push rax
        mov rax, 8
        mul rcx
        mov rdx, rax
        pop rax

        cmp rax, [digits + rdx]
        jl @f
        mov rax, [digits + rdx]
        mov rbx, rcx

        @@:
        inc rcx
        jmp .comp_loop

    .next2:
    mov rax, rbx
    mov rsi, buffer
    call number_str
    call print_str
    call new_line
    call exit
filter:
    xor rax, rax
    mov rsi, array
    mov rcx, ARRLEN
    dec rcx
    .check:
        mov dl, [rsi]
        mov dh, [rsi+1]
        cmp dl, dh
        jbe .ok

        mov [rsi], dh
        mov [rsi+1], dl
        inc rax

        .ok:
        inc rsi
    loop .check
    ret