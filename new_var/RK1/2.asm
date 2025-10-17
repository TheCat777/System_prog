format ELF64

public _start

section '.bss' writeable
    output rb 1
    buffer rb 32

section '.text' executable

_start:
    mov rax, [rsp]
    cmp rax, 3
    jne exit
    
    mov rsi, [rsp + 16]
    call str_number
    mov r12, rax   ; n in r12
    
    mov rsi, [rsp + 24]
    call str_number
    cmp rax, -1
    je exit
    mov r13, rax    ; k in r13
    
    cmp r12, 0
    jle exit
    cmp r13, 0
    jl exit
    
    xor r14, r14
    mov r15, 1
    
.main_loop:
    cmp r15, r12
    jg .loop_end
    
    mov rax, r15
    call sum_of_digits
    
    cmp rax, r13
    jne .next_number
    
    add r14, r15
    
.next_number:
    inc r15
    jmp .main_loop
    
.loop_end:
    mov rax, r14
    call print_num
    
    mov al, 10
    call print
    
    call exit


sum_of_digits:
    push rbx
    push rcx
    push rdx
    
    xor rbx, rbx
    mov rcx, 10
    
.digit_loop:
    xor rdx, rdx
    div rcx
    add rbx, rdx
    test rax, rax
    jnz .digit_loop
    
    mov rax, rbx
    
    pop rdx
    pop rcx
    pop rbx
    ret

str_number:
    push rcx
    push rbx
    push rdx

    xor rax, rax
    xor rcx, rcx
    xor rbx, rbx
    
.loop:
    mov bl, byte [rsi+rcx]
    test bl, bl
    jz .finished
    cmp bl, '0'
    jl .finished
    cmp bl, '9'
    jg .finished

    sub bl, '0'
    imul rax, 10
    add rax, rbx
    inc rcx
    jmp .loop

.finished:
    pop rdx
    pop rbx
    pop rcx
    ret

print:
    push rax
    push rdi
    push rsi
    push rdx
    
    mov [output], al
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, output
    mov rdx, 1          ; длина 1 символ
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

; Функция вывода числа
; Вход: RAX = число для вывода
print_num:
    push rbx
    push rcx
    push rdx
    push rsi
    
    mov rcx, 10
    xor rbx, rbx        ; счетчик цифр
    
    test rax, rax
    jnz .loop
    
    ; Если число 0
    mov al, '0'
    call print
    jmp .done
    
.loop:
    xor rdx, rdx
    div rcx
    push rdx
    inc rbx
    test rax, rax
    jnz .loop

.print_loop:
    pop rax
    add al, '0'
    call print
    dec rbx
    jnz .print_loop
    
.done:
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

exit:
    mov rax,1
    mov rbx,0
    int 0x80
