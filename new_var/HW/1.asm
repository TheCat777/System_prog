format elf64

public start
public add_num
public add_random
public del_num
public count_prime
public count_first
public count_even
public print_array

include 'func.asm'

section '.bss' writeable
    input dq ?
    output dq ?
    max_count = 10000
    count dq 0
    ten = 10
    one = 1
    dev_urandom db '/dev/urandom',0

section '.text' executable
	
start:
	 ; Выделяем память в куче с помощью brk
    mov rax, 12         ; номер системного вызова brk
    mov rdi, 0          ; получить текущее значение brk
    syscall
    
    mov rdi, rax        ; сохраняем текущий brk
    add rdi, max_count  ; увеличиваем на нужный размер
    mov rax, 12         ; номер системного вызова brk
    syscall

	mov rsi, rax  ;Сохраняем адрес памяти кучи
	

    mov r15, rsi

    mov [count], 0

    ret

add_num:
    mov rax, [count]
    mov [r15+8*rax], rdi
    inc [count]
    ret
	

add_random:
    cmp rdi, 0
    je .f
    mov r13, rdi
    .loop3:
        call Rand
        
        mov rdi, rax
        call add_num
        dec r13

        cmp r13, 0
        jne .loop3
    .f:
        ret


del_num:
    dec [count]
    xor rax, rax
    .loop:
        mov rbx, [r15+8*rax+8]
        mov [r15+8*rax], rbx

        inc rax
        cmp rax, [count]
        jl .loop
    ret


count_prime:
    mov rdx, [count]
    cmp rdx, 0
    je .f4

    xor r12, r12
    xor rbx, rbx
    .loop1:
        cmp rbx, [count]
        je .e
        mov rax, [r15+8*rbx]
        cmp rax, 10
        jl .primt_first_check

        mov rcx, 2
        mov r11, [r15+8*rbx]
        .loop2:
            xor rdx, rdx
            mov rax, [r15+8*rbx]
            div rcx
            cmp rdx, 0
            je .not_prime
        

            inc rcx
            cmp rcx, r11
            jb .loop2
        inc rbx
        inc r12
        cmp rbx, [count]
        jne .loop1
    .e:
    mov rax, r12
    .f4:
        ret

.not_prime:
    inc rbx
    jmp .loop1

.primt_first_check:
    inc rbx 

    cmp rax, 2
    je .is_prime
    cmp rax, 3
    je .is_prime
    cmp rax, 5
    je .is_prime
    cmp rax, 7
    je .is_prime
    
    jmp .loop1


.is_prime:
    inc r12
    jmp .loop1



count_first:
    mov rdx, [count]
    cmp rdx, 0
    je .f3

    xor rbx, rbx
    xor rdx, rdx
    xor r12, r12
    mov r8, ten
    mov r9, one
    .loop:
        xor rdx, rdx
        mov rax, [r15+8*rbx]
        div r8
        cmp rdx, r9
        je .plus
        
        inc rbx
        cmp rbx, [count]
        jne .loop
    mov rax, r12
    .f3:
        ret

    .plus:
        inc r12

        inc rbx
        cmp rbx, [count]
        jne .loop
        mov rax, r12
        ret

count_even:
    mov rdx, [count]
    cmp rdx, 0
    je .f2

    xor rbx, rbx
    xor rdx, rdx
    xor r12, r12
    mov r8, 2
    mov r9, 0
    .loop:
        xor rdx, rdx
        mov rax, [r15+8*rbx]
        div r8
        cmp rdx, r9
        je .plus
        
        inc rbx
        cmp rbx, [count]
        jne .loop
    mov rax, r12
    .f2:
        ret

    .plus:
        inc r12

        inc rbx
        cmp rbx, [count]
        jne .loop
        mov rax, r12
        ret


print_array:
    mov rdx, [count]
    cmp rdx, 0
    je .f1

    xor rdx, rdx
    xor r12, r12
    .loop:
        xor rdx, rdx
        mov rax, [r15+8*r12]
        call print_num
        call new_line
        
        inc r12
        cmp r12, [count]
        jne .loop
    .f1:
        ret



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

Rand:
    push rdi
    push rsi
    push rdx
    push rcx
    push rbx
    
    ; Открываем /dev/urandom
    mov rax, 2
    mov rdi, dev_urandom
    mov rsi, 0
    mov rdx, 0
    syscall
    
    test rax, rax
    js .dev_error
    
    mov rbx, rax 
    
    sub rsp, 8
    mov rdi, rbx
    mov rsi, rsp 
    mov rdx, 2          ; количество байт
    mov rax, 0 
    syscall
    
    mov rdi, rbx
    mov rax, 3
    syscall
    
    mov rax, [rsp]
    add rsp, 8
    
.dev_cleanup:
    pop rbx
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    ret

.dev_error:
    ; Если не удалось открыть /dev/urandom, используем rdrand (криптографически устойчивый, но требующий энтропию)
    rdrand rax
    jnc .dev_error
    jmp .dev_cleanup