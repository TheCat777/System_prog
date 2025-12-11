format elf64

public _start

section '.bss' writable
    buffer rb 1024
    args rq 64
    tokens rb 2048

section '.text' executable

_start:
.loop:
    
    ; Чтение строки
    mov rsi, buffer
    call gets
    
    ; Пропускаем пустые строки
    cmp byte [buffer], 0
    je .loop
    
    ; Парсинг аргументов
    mov rdi, buffer
    call parse
    
    ; Запуск программы
    call execute
    
    jmp .loop

; Чтение строки
gets:
    push rbx
    mov rbx, rsi
    xor rcx, rcx
.read:
    mov rax, 0      ; read
    mov rdi, 0      ; stdin
    lea rsi, [rbx + rcx]
    mov rdx, 1
    syscall
    
    test rax, rax
    jle .done
    
    mov al, [rbx + rcx]
    cmp al, 10      ; newline
    je .end
    inc rcx
    cmp rcx, 1023
    jl .read
.end:
    mov byte [rbx + rcx], 0
.done:
    pop rbx
    ret

; Парсинг аргументов
parse:
    push rbx
    push r12
    push r13
    
    mov rbx, rdi        ; исходная строка
    lea r12, [tokens]   ; буфер токенов
    lea r13, [args]     ; массив указателей
    xor rcx, rcx        ; индекс аргументов
    xor rdx, rdx        ; позиция в строке
    
.skip:
    mov al, [rbx + rdx]
    test al, al
    jz .done
    cmp al, ' '
    jne .start
    inc rdx
    jmp .skip

.start:
    mov [r13 + rcx*8], r12
.copy:
    mov al, [rbx + rdx]
    test al, al
    jz .end
    cmp al, ' '
    je .end
    mov [r12], al
    inc r12
    inc rdx
    jmp .copy

.end:
    mov byte [r12], 0
    inc r12
    inc rcx
    mov al, [rbx + rdx]
    test al, al
    jz .done
    inc rdx
    jmp .skip

.done:
    mov qword [r13 + rcx*8], 0
    pop r13
    pop r12
    pop rbx
    ret

; Запуск программы
execute:
    ; Форк
    mov rax, 57
    syscall
    test rax, rax
    jz .child
    
    ; Родитель: ждем
    push rax
    mov rdi, rax
    xor rsi, rsi
    mov rax, 61
    syscall
    pop rax
    ret

.child:
    ; Дочерний: execve
    mov rdi, [args]
    lea rsi, [args]
    xor rdx, rdx
    mov rax, 59
    syscall
    
    ; Если execve не удался
    mov rax, 60
    mov rdi, 127
    syscall