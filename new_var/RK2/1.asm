format ELF64

public _start

extrn initscr
extrn endwin
extrn clear
extrn refresh
extrn mvaddch
extrn addstr
extrn nodelay
extrn cbreak
extrn noecho
extrn curs_set
extrn keypad
extrn getch
extrn usleep
extrn sin
extrn stdscr

section '.data' writeable
    A dq 10.0 
    w dq 0.2
    x dq 0.0 
    step dq 0.15 
    
    key db 0
    
    star db '*'

    ; Константы
    two_pi dq 6.283185307179586
    min_A dq 1.0
    min_w dq 0.05

section '.bss' writeable
    rows resd 1
    cols resd 1
    
    temp resq 1

section '.text' executable

_start:
    call initscr
    call cbreak
    call noecho
    
    mov rdi, 0
    call curs_set
    
    mov rdi, 0
    mov rsi, 1
    call keypad
    
    mov rdi, 0
    mov rsi, 1
    call nodelay
    
    mov dword [rows], 24
    mov dword [cols], 80
    
    call main_loop
    
    call endwin
    
    mov rax, 60
    xor rdi, rdi
    syscall

main_loop:
    push rbp
    mov rbp, rsp
    
.main_loop:
    call clear
    
    call draw_sine
    
    call refresh
    
    call handle_input
    
    mov rdi, 50000      ; 50ms
    call usleep
    
    cmp byte [key], 27
    jne .main_loop
    
    pop rbp
    ret

draw_sine:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    movq xmm0, [x]
    mulsd xmm0, [w]
    
    ; Вызываем sin
    movq [rsp], xmm0
    mov rdi, [rsp]
    call sin
    movq xmm1, rax 
    
    mulsd xmm1, [A] 
    
    cvtsd2si rbx, xmm1 
    cvtsd2si rcx, [x] 
    
    mov eax, 12
    sub eax, ebx 
    
    mov edx, 40   
    add edx, ecx  
    
    ; Проверяем границы
    cmp eax, 2              ; пропускаем первые 2 строки
    jl .skip
    cmp eax, 24
    jge .skip
    cmp edx, 0
    jl .skip
    cmp edx, 80
    jge .skip
    
    ; Рисуем точку
    mov rdi, rax
    mov rsi, rdx
    call move_cursor
    mov rdi, star
    call addch
    
.skip:
    ; Увеличиваем x
    movq xmm0, [x]
    addsd xmm0, [step]
    movq [x], xmm0
    
    ; Сбрасываем при 2π
    comisd xmm0, [two_pi]
    jb .done
    pxor xmm0, xmm0
    movq [x], xmm0
    
.done:
    add rsp, 32
    pop rbp
    ret

; Обработка ввода
handle_input:
    push rbp
    mov rbp, rsp
    
    call getch
    mov [key], al
    
    cmp al, -1
    je .done
    
    cmp al, '+'
    je .inc_amp
    cmp al, '-'
    je .dec_amp
    cmp al, ']'
    je .inc_freq
    cmp al, '['
    je .dec_freq
    jmp .done

.inc_amp:
    movq xmm0, [A]
    addsd xmm0, 1.0
    movq [A], xmm0
    jmp .done

.dec_amp:
    movq xmm0, [A]
    subsd xmm0, 1.0
    comisd xmm0, [min_A]
    ja .store_amp
    movq xmm0, [min_A]
.store_amp:
    movq [A], xmm0
    jmp .done

.inc_freq:
    movq xmm0, [w]
    addsd xmm0, 0.05
    movq [w], xmm0
    jmp .done

.dec_freq:
    movq xmm0, [w]
    subsd xmm0, 0.05
    comisd xmm0, [min_w]
    ja .store_freq
    movq xmm0, [min_w]
.store_freq:
    movq [w], xmm0

.done:
    pop rbp
    ret

; Вспомогательная функция для перемещения курсора
move_cursor:
    ; rdi = y, rsi = x
    push rdi
    push rsi
    ; Используем ANSI escape codes для переносимости
    call move_cursor_ansi
    add rsp, 16
    ret

move_cursor_ansi:
    ; Выводим ANSI escape sequence: ESC [ y ; x H
    push rbp
    mov rbp, rsp
    
    ; Преобразуем координаты в строку
    sub rsp, 32
    mov byte [rsp], 0x1B    ; ESC
    mov byte [rsp+1], '['
    
    ; Преобразуем y в строку
    mov rax, rdi
    lea rcx, [rsp+2]
    call int_to_str
    
    ; Добавляем ;
    mov byte [rcx], ';'
    inc rcx
    
    ; Преобразуем x в строку
    mov rax, rsi
    call int_to_str
    
    ; Добавляем H
    mov byte [rcx], 'H'
    inc rcx
    mov byte [rcx], 0
    
    ; Выводим
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    lea rsi, [rsp]
    mov rdx, rcx
    sub rdx, rsp
    syscall
    
    add rsp, 32
    pop rbp
    ret

; Преобразование числа в строку (упрощенное)
int_to_str:
    ; rax = число, rcx = буфер
    push rbx
    mov rbx, 10
    push rcx
    
    ; Вычисляем длину
    mov r8, rax
    mov r9, 1
.len_loop:
    xor rdx, rdx
    div rbx
    test rax, rax
    jz .len_done
    inc r9
    jmp .len_loop
    
.len_done:
    mov rax, r8
    add rcx, r9
    mov byte [rcx], 0
    
.convert:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rcx
    mov [rcx], dl
    test rax, rax
    jnz .convert
    
    pop rax
    pop rbx
    mov rcx, rax
    add rcx, r9
    ret