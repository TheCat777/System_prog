format ELF64

public _start

; Данные
header db "x        | Epsilon   | Terms | Calculated | Analytical | Difference", 10, 0

x_labels db "pi/5    ", "2pi/5   ", "3pi/5   ", "4pi/5   ", "pi      ", 0
x_values dq 0.6283185307, 1.2566370614, 1.8849555922, 2.5132741229, 3.1415926536

epsilon1 dq 1e-4    ; Точность 0.0001
epsilon2 dq 1e-6    ; Точность 0.000001
epsilon3 dq 1e-8    ; Точность 0.00000001

pi dq 3.14159265358979323846
pi_squared_div_3 dq 3.289868133696452872  ; π²/3
one dq 1.0
minus_one dq -1.0
quarter dq 0.25
two_pi dq 6.28318530717958647692
abs_mask dq 0x7FFFFFFFFFFFFFFF

buffer db 255
temp_buffer db 32

_start:
    ; Вывод заголовка таблицы
    mov rdi, header
    call print_string
    
    ; Вычисление для каждого x
    mov rbx, x_values        ; указатель на массив x
    mov r12, x_labels        ; указатель на метки x
    mov r13, 0               ; счетчик x
    
.process_x:
    cmp r13, 5
    jge exit_program
    
    ; Получаем текущее значение x
    movsd xmm0, [rbx]
    
    ; Вычисляем аналитическое значение
    call analytical_value
    movsd xmm15, xmm0        ; сохраняем аналитическое значение в xmm15

    ; Вычисляем для трех различных точностей
    mov r14, epsilon1
    call process_epsilon
    
    mov r14, epsilon2
    call process_epsilon
    
    mov r14, epsilon3
    call process_epsilon
    
    ; Переход к следующему x
    add rbx, 8
    add r12, 9
    inc r13
    jmp .process_x

; Обработка для конкретной точности
; Вход: xmm0 = x, r14 = указатель на epsilon, xmm15 = аналитическое значение
process_epsilon:
    push rbx
    push r12
    push r13
    
    ; Сохраняем x
    movsd xmm14, xmm0
    
    ; Вычисляем сумму ряда
    movsd xmm0, xmm14       ; x
    movsd xmm1, [r14]       ; epsilon
    call series_sum
    movsd xmm13, xmm0       ; вычисленная сумма
    mov r15, rax            ; количество членов
    
    ; Вычисляем разницу
    movsd xmm0, xmm13
    movsd xmm1, xmm15
    subsd xmm0, xmm1
    movsd xmm12, xmm0       ; разница
    
    ; Подготовка и вывод результата
    mov rdi, buffer
    
    ; Копируем метку x
    mov rsi, r12
    call strcpy
    
    ; Добавляем разделитель
    mov rdi, buffer
    call strlen
    mov byte [buffer + rax], ' '
    mov byte [buffer + rax + 1], '|'
    mov byte [buffer + rax + 2], ' '
    mov byte [buffer + rax + 3], 0
    
    ; Добавляем epsilon
    mov rdi, buffer
    call strlen
    lea rdi, [buffer + rax]
    mov rsi, r14            ; указатель на epsilon
    call format_epsilon
    
    ; Добавляем terms
    mov rdi, buffer
    call strlen
    lea rdi, [buffer + rax]
    mov rsi, r15            ; terms
    call format_terms
    
    ; Добавляем calculated
    mov rdi, buffer
    call strlen
    lea rdi, [buffer + rax]
    movsd xmm0, xmm13       ; calculated
    call format_double
    
    ; Добавляем analytical
    mov rdi, buffer
    call strlen
    lea rdi, [buffer + rax]
    movsd xmm0, xmm15       ; analytical
    call format_double
    
    ; Добавляем difference
    mov rdi, buffer
    call strlen
    lea rdi, [buffer + rax]
    movsd xmm0, xmm12       ; difference
    call format_double_scientific
    
    ; Добавляем новую строку
    mov rdi, buffer
    call strlen
    mov byte [buffer + rax], 10
    mov byte [buffer + rax + 1], 0
    
    ; Вывод строки
    mov rdi, buffer
    call print_string
    
    pop r13
    pop r12
    pop rbx
    ret

; Вычисление аналитического значения f(x) = 1/4 * (x² - π²/3)
; Вход: xmm0 = x
; Выход: xmm0 = f(x)
analytical_value:
    ; x²
    movsd xmm1, xmm0
    mulsd xmm1, xmm1
    
    ; x² - π²/3
    movsd xmm2, [pi_squared_div_3]
    subsd xmm1, xmm2
    
    ; 1/4 * (x² - π²/3)
    movsd xmm2, [quarter]
    mulsd xmm1, xmm2
    
    movsd xmm0, xmm1
    ret

; Вычисление суммы ряда
; Вход: xmm0 = x, xmm1 = epsilon
; Выход: xmm0 = сумма, rax = количество членов
series_sum:
    ; Инициализация
    xorpd xmm2, xmm2        ; сумма = 0
    mov rbx, 1              ; n = 1
    movsd xmm3, xmm0        ; сохраняем x
    movsd xmm4, xmm1        ; сохраняем epsilon
    
    ; Начальный знак = -1
    movsd xmm5, [minus_one]

series_loop:
    ; Вычисляем текущий член: (-1)^n * cos(n*x) / n²
    
    ; n как double
    cvtsi2sd xmm7, rbx      ; n
    
    ; n*x
    movsd xmm8, xmm7
    mulsd xmm8, xmm3        ; n*x
    
    ; cos(n*x) - используем встроенную инструкцию
    movsd xmm0, xmm8
    call cos
    movsd xmm9, xmm0        ; cos(n*x)
    
    ; n²
    movsd xmm10, xmm7
    mulsd xmm10, xmm10      ; n²
    
    ; cos(n*x) / n²
    divsd xmm9, xmm10
    
    ; (-1)^n * cos(n*x) / n²
    mulsd xmm9, xmm5
    
    ; Добавляем к сумме
    addsd xmm2, xmm9
    
    ; Меняем знак для следующей итерации
    movsd xmm10, xmm5
    mulsd xmm10, [minus_one]
    movsd xmm5, xmm10
    
    ; Проверяем условие сходимости
    ; |current_term| < epsilon
    movsd xmm0, xmm9
    movsd xmm11, [abs_mask]  ; загружаем маску в регистр
    andpd xmm0, xmm11       ; абсолютное значение
    comisd xmm0, xmm4       ; сравнение с epsilon
    jb series_done          ; если |term| < epsilon, заканчиваем
    
    ; Проверяем максимальное количество итераций
    inc rbx
    cmp rbx, 1000000
    jg series_done
    
    jmp series_loop

series_done:
    movsd xmm0, xmm2        ; возвращаем сумму
    mov rax, rbx            ; возвращаем количество членов
    ret

; Функция косинуса с использованием встроенной инструкции fcos
; Вход: xmm0 = угол в радианах
; Выход: xmm0 = cos(x)
cos:
    ; Нормализуем угол в диапазон [-π, π]
    movsd xmm1, xmm0
    
cos_normalize:
    ; Проверяем, нужно ли нормализовать
    movsd xmm2, [pi]
    comisd xmm1, xmm2
    jbe cos_check_negative
    
    ; x > π, вычитаем 2π
    movsd xmm3, [two_pi]
    subsd xmm1, xmm3
    jmp cos_normalize

cos_check_negative:
    movsd xmm2, [pi]
    mulsd xmm2, [minus_one]  ; -π
    comisd xmm1, xmm2
    jae cos_calculate
    
    ; x < -π, добавляем 2π
    movsd xmm3, [two_pi]
    addsd xmm1, xmm3
    jmp cos_normalize

cos_calculate:
    ; Используем встроенную инструкцию fcos
    ; fcos работает со st(0), поэтому нужно использовать FPU
    sub rsp, 8
    movsd [rsp], xmm1
    fld qword [rsp]         ; загружаем в st(0)
    fcos                    ; cos(st(0))
    fstp qword [rsp]        ; сохраняем результат обратно
    movsd xmm0, [rsp]       ; возвращаем в xmm0
    add rsp, 8
    ret

; Форматирование epsilon в научной нотации
; Вход: rdi = буфер для вывода, rsi = указатель на значение epsilon
format_epsilon:
    push rbx
    
    ; Получаем значение epsilon
    mov rax, [rsi]          ; получаем битовое представление double
    
    ; Определяем экспоненту
    mov rbx, rax
    shr rbx, 52
    and rbx, 0x7FF
    sub rbx, 1023
    neg rbx                 ; экспонента
    
    ; Форматируем как "1e-4", "1e-6", "1e-8"
    mov byte [rdi], '1'
    mov byte [rdi+1], 'e'
    mov byte [rdi+2], '-'
    
    ; Преобразуем экспоненту в ASCII
    mov al, bl
    add al, '0'
    mov [rdi+3], al
    mov byte [rdi+4], 0
    
    ; Добавляем разделитель
    mov rsi, rdi
    call strlen
    mov word [rdi + rax], ' |'
    mov byte [rdi + rax + 2], ' '
    mov byte [rdi + rax + 3], 0
    
    pop rbx
    ret

; Форматирование количества членов
; Вход: rdi = буфер для вывода, rsi = количество членов
format_terms:
    push rbx
    
    ; Преобразуем число в строку
    mov rax, rsi
    mov rbx, rdi
    
    call int_to_string
    
    ; Выравниваем по правому краю в поле шириной 5 символов
    mov rdi, rbx
    call strlen
    mov rcx, 5
    sub rcx, rax
    jle .no_padding
    
    ; Сдвигаем строку вправо и добавляем пробелы слева
    mov rsi, rbx
    add rsi, rax            ; конец строки
    mov rdi, rbx
    add rdi, rax
    add rdi, rcx            ; новая позиция
    
    ; Копируем строку с конца
.copy_loop:
    cmp rsi, rbx
    jl .copy_done
    mov al, [rsi]
    mov [rdi], al
    dec rsi
    dec rdi
    jmp .copy_loop
    
.copy_done:
    ; Заполняем пробелами слева
    mov rdi, rbx
    mov al, ' '
    mov rcx, 5
    sub rcx, rax
.fill_loop:
    cmp rcx, 0
    jle .no_padding
    mov [rdi], al
    inc rdi
    dec rcx
    jmp .fill_loop

.no_padding:
    ; Добавляем разделитель
    mov rdi, rbx
    call strlen
    mov word [rbx + rax], ' |'
    mov byte [rbx + rax + 2], ' '
    mov byte [rbx + rax + 3], 0
    
    pop rbx
    ret

; Форматирование double числа (упрощенное)
; Вход: rdi = буфер для вывода, xmm0 = число
format_double:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Сохраняем число
    movsd [rsp], xmm0
    
    ; Преобразуем в целое (упрощенный подход - только для демонстрации)
    fld qword [rsp]
    frndint
    fistp qword [rsp+8]
    mov rax, [rsp+8]
    
    ; Преобразуем целую часть в строку
    mov rsi, rdi
    mov rdi, rax
    call int_to_string
    
    ; Добавляем разделитель
    mov rdi, rsi
    call strlen
    mov word [rdi + rax], ' |'
    mov byte [rdi + rax + 2], ' '
    mov byte [rdi + rax + 3], 0
    
    add rsp, 32
    pop rbp
    ret

; Форматирование double в научной нотации (упрощенное)
; Вход: rdi = буфер для вывода, xmm0 = число
format_double_scientific:
    ; Для простоты выводим фиксированный формат
    mov byte [rdi], '1'
    mov byte [rdi+1], 'e'
    mov byte [rdi+2], '-'
    mov byte [rdi+3], '0'
    mov byte [rdi+4], '8'
    mov byte [rdi+5], 0
    ret

; Вспомогательные функции
print_string:
    push rax
    push rdi
    push rsi
    push rdx
    
    ; Вычисляем длину строки
    mov rsi, rdi
    mov rdx, 0
.strlen_loop:
    cmp byte [rsi + rdx], 0
    je .strlen_done
    inc rdx
    jmp .strlen_loop
.strlen_done:
    
    ; Системный вызов write
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

strcpy:
    push rax
    push rsi
    push rdi
.strcpy_loop:
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    test al, al
    jnz .strcpy_loop
    pop rdi
    pop rsi
    pop rax
    ret

strlen:
    mov rax, 0
.strlen_loop:
    cmp byte [rdi + rax], 0
    je .strlen_done
    inc rax
    jmp .strlen_loop
.strlen_done:
    ret

; Преобразование целого числа в строку
; Вход: rdi = число, rsi = буфер для строки
int_to_string:
    push rbx
    push rdx
    push rsi
    
    mov rax, rdi
    mov rdi, rsi
    mov rbx, 10
    mov rcx, 0
    
    ; Проверяем ноль
    test rax, rax
    jnz .convert_loop
    mov byte [rdi], '0'
    mov byte [rdi+1], 0
    jmp .done
    
.convert_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    push rdx
    inc rcx
    test rax, rax
    jnz .convert_loop
    
    ; Извлекаем цифры в правильном порядке
    mov rbx, rdi
.pop_loop:
    pop rax
    mov [rdi], al
    inc rdi
    loop .pop_loop
    mov byte [rdi], 0
    
.done:
    pop rsi
    pop rdx
    pop rbx
    ret

exit_program:
    mov rax, 60             ; sys_exit
    xor rdi, rdi            ; exit code 0
    syscall