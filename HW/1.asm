format elf64

public start
public add_num
public del_num
public count_prime
public count_first
public count_even
public close
public print_array

include 'func.asm'


input dq ?
output dq ?
max_count = 10000
count dq 0
ten = 10
one = 1

section '.text' executable
	
start:
	;; выполняем анонимное отображение в память
	mov rdi, 0    ;начальный адрес выберет сама ОС
	mov rsi, max_count ;задаем размер области памяти
	mov rdx, 0x3  ;совмещаем флаги PROT_READ | PROT_WRITE
	mov r10,0x22  ;задаем режим MAP_ANONYMOUS|MAP_PRIVATE
	mov r8, -1   ;указываем файловый дескриптор null
	mov r9, 0     ;задаем нулевое смещение
	mov rax, 9    ;номер системного вызова mmap
	syscall

	mov rsi, rax  ;Сохраняем адрес памяти анонимного отображения
	

    mov r15, rsi

    ret
	

add_num:
    mov rax, [count]
    mov [r15+8*rax], rdi
    inc [count]
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
    ret

    .plus:
        inc r12

        inc rbx
        cmp rbx, [count]
        jne .loop
        mov rax, r12
        ret

count_even:
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
    ret

    .plus:
        inc r12

        inc rbx
        cmp rbx, [count]
        jne .loop
        mov rax, r12
        ret

close:
    mov rdi, r15
	mov rsi, max_count
	mov rax, 11
	syscall

print_array:
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