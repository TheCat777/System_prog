format ELF64

public _start

include 'func.asm'

section '.bss' writable
    buffer      rb 12
    input dq ?
    msg_yes     db "Принято", 0x0A
    msg_yes_len = $ - msg_yes
    msg_no      db "Отклонено", 0x0A
    msg_no_len = $ - msg_no


section '.text' executable
_start:
    ; Читаем число N
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 255
    syscall

    mov rax, input
    call len_str
    mov byte [input + rax], 0
    call str_number
    mov rbx, rax

    xor r12, r12        ; r12 = счётчик единиц
    xor r13, r13        ; r13 = счётчик нулей
    
    ; Читаем N строк
.read_loop:
    cmp rbx, 0      ; проверяем, остались ли строки
    jz .compare
    
    ; Читаем одну строку
    mov rax, 0
    mov rdi, 0
    mov rsi, buffer
    mov rdx, 12
    syscall
    
    ; Анализируем символ
    mov al, [buffer]
    cmp al, '1'
    je .count_one
    cmp al, '0'
    je .count_zero
    jmp .next_line
    
.count_one:
    inc r12
    jmp .next_line
    
.count_zero:
    inc r13
    
.next_line:
    dec rbx
    jmp .read_loop

.compare:     ; Сравниваем количество единиц и нулей
    cmp r12, r13
    jg .output_yes
    
.output_no:
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, msg_no
    mov rdx, msg_no_len
    syscall
    jmp exit
    
.output_yes:
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, msg_yes
    mov rdx, msg_yes_len
    syscall
    call exit