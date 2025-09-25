format ELF64
include 'func.asm'

; Объявление внешних функций
extrn initscr
extrn endwin
extrn curs_set
extrn start_color
extrn init_pair
extrn color_set
extrn getmaxx
extrn getmaxy
extrn clear
extrn refresh
extrn move
extrn printw
extrn getch
extrn printf
extrn malloc
extrn free
extrn fopen
extrn fclose
extrn fgetc
extrn rand
extrn srand
extrn time
extrn usleep
extrn stdscr
extrn timeout
extrn exit

public _start

section '.data' writeable
    ; Форматные строки для ввода/вывода
    mode_msg        db 'Режим работы циклов:',0xA,'(1) - самостоятельная работа',0xA,'(2) - ручные итерации',0xA,0
    fill_msg        db 'Стартовое наполнение:',0xA,'(1) - заполнение из файла',0xA,'(2) - случайное',0xA,0
    file_error_msg  db 'Ошибка при обработке файла',0xA,0
    filename        db 'start.txt',0
    read_mode       db 'r',0
    space_str       db ' ',0
    newline         db 0xA,0
    
    ; Буфер для ввода
    input_buffer    db 0, 0  ; буфер на 2 байта: цифра + newline
    
    ; Переменные (64-битные)
    type            dq 0
    type2           dq 0
    max_y           dq 0
    max_x           dq 0
    file_ptr        dq 0

section '.text' executable
_start:
    ; Инициализация генератора случайных чисел
    xor rdi, rdi
    call time
    mov rdi, rax
    call srand
    
    mov rsi, mode_msg
    call print_str  ; вывод первого сообщения
    
    ; Чтение ввода
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 2      ; читаем 2 байта (цифра + newline)
    syscall
    
    ; Преобразование в число
    mov al, [input_buffer]
    sub al, '0'
    mov [type], rax
    
    
    mov rsi, fill_msg
    call print_str  ; вывод второго сообщения
    
    ; Чтение ввода
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 2
    syscall
    
    ; Преобразование в число
    mov al, [input_buffer]
    sub al, '0'
    mov [type2], rax
    

    ; Инициализация ncurses
    call initscr
	mov rdi, [stdscr]
    
    ; Получение размеров экрана
    call getmaxy
    mov [max_y], rax
    
    call getmaxx
    mov [max_x], rax

    ; Настройка ncurses (невидимый курсор)
    mov rdi, 0
    call curs_set
    
    ; Инициализация цветов
    call start_color
    mov rdi, 1
    mov rsi, 7
    mov rdx, 7
    call init_pair
    mov rdi, 1
    xor rsi, rsi
    call color_set
    
    
    ; Выделение памяти для массивов
    mov rax, [max_y]
    mov rbx, [max_x]
    mul rbx       ; 64-битное умножение
    mov rbx, rax        ; сохраняем размер
    
    ; Проверка размера массивов
    cmp rax, 1000000    ; максимальный разумный размер
    jg .error_exit
    
    mov rdi, rax
    call malloc
    test rax, rax       ; проверка успешности malloc
    jz .error_exit
    mov r12, rax        ; r12 = array (основное отображение)
    
    mov rdi, rbx
    call malloc
    test rax, rax       ; проверка успешности malloc
    jz .error_exit
    mov r13, rax        ; r13 = new_array (скрытое отображение)
    
    ; Инициализация массивов нулями
    mov rdi, r12
    mov rcx, rbx
    xor al, al
    rep stosb
    
    mov rdi, r13
    mov rcx, rbx
    xor al, al
    rep stosb
    
    ; Заполнение в зависимости от type2
    cmp qword [type2], 1
    je .fill_from_file  ; из файла
    jmp .fill_random    ; случайное

.fill_from_file:
    ; Открытие файла
    mov rdi, filename
    mov rsi, read_mode
    call fopen
    mov [file_ptr], rax
    
    test rax, rax
    jz .file_error
    
    ; Чтение файла
    xor r14, r14    ; row_i = 0
    xor r15, r15    ; col_j = 0
    mov rbx, [max_x] ; максимальная ширина
    
.read_loop:
    mov rdi, [file_ptr]
    call fgetc
    cmp eax, -1     ; EOF
    je .close_file
    
    ; Обработка символов
    cmp eax, 0xA    ; новая строка
    je .handle_newline
    
    cmp eax, '1'    ; живая клетка
    je .handle_live_cell
    
    cmp eax, '.'    ; мертвая клетка
    je .handle_dead_cell
    
    ; Пропускаем другие символы
    jmp .read_loop

.handle_newline:
    inc r14         ; следующая строка
    xor r15, r15    ; сброс столбца
    jmp .read_loop

.handle_live_cell:
    ; Проверяем границы перед записью
    mov rax, [max_y]
    cmp r14, rax
    jge .read_loop  ; пропускаем если за границами
    
    mov rax, [max_x]
    cmp r15, rax
    jge .read_loop  ; пропускаем если за границами
    
    ; Записываем живую клетку
    mov rax, [max_x]
    mul r14
    add rax, r15
    mov byte [r12 + rax], 1
    inc r15
    jmp .read_loop

.handle_dead_cell:
    ; Просто увеличиваем столбец для '.'
    inc r15
    jmp .read_loop

.close_file:
    mov rdi, [file_ptr]
    call fclose
    jmp .game_loop

.file_error:
    mov rdi, file_error_msg
    xor rax, rax
    call printf
    jmp .cleanup_exit

.error_exit:
    mov rdi, newline
    call printf
    jmp .cleanup_exit

.fill_random:
    ; Заполнение случайными значениями (с проверкой границ)
    mov r14, 1          ; i = 1
.random_outer:
    mov rax, [max_y]
    dec rax
    cmp r14, rax
    jge .game_loop
    
    mov r15, 1          ; j = 1
.random_inner:
    mov rax, [max_x]
    dec rax
    cmp r15, rax
    jge .random_next_row
    
    call rand
    and eax, 1
    test eax, eax
    jz .random_skip
    
    mov rax, [max_x]
    mul r14
    add rax, r15
    mov byte [r12 + rax], 1

.random_skip:
    inc r15
    jmp .random_inner

.random_next_row:
    inc r14
    jmp .random_outer

.game_loop:   ; основной цикл
    call clear
    
    ; Отрисовка клеток
    xor r14, r14        ; i = 0
.draw_outer:
    mov rax, [max_y]
    cmp r14, rax
    jge .draw_done
    
    xor r15, r15        ; j = 0
.draw_inner:
    mov rax, [max_x]
    cmp r15, rax
    jge .draw_next_row
    
    mov rax, [max_x]
    mul r14
    add rax, r15
    cmp byte [r12 + rax], 0
    je .draw_skip
    
    ; Отрисовка с проверкой границ
    mov rdi, r14
    mov rsi, r15
    call move
    
    mov rdi, space_str
    call printw

.draw_skip:
    inc r15
    jmp .draw_inner

.draw_next_row:
    inc r14
    jmp .draw_outer

.draw_done:
    call refresh
    
    ; Обработка режима работы
    cmp qword [type], 2
    je .manual_mode
    
.auto_mode:
    ; Задаем таймаут для getch
	mov rdi, 1
	call timeout
	call getch

    ; Анализируем нажатую клавишу
	cmp rax, ' '
	je .cleanup_exit

    ; Используем usleep для задержки между автоматическим переходом
    mov rdi, 100000     ; 100000 микросекунд = 100 миллисекунд
    call usleep
    jmp .update_game

.manual_mode:  ; ожиадние любой клавиши, кроме пробела для следущей итерации
    call getch
    cmp eax, ' '
    je .cleanup_exit
    cmp eax, 27
    je .cleanup_exit

.update_game:
    ; Вычисление нового состояния
    xor r14, r14        ; i = 0
.calc_outer:
    mov rax, [max_y]
    cmp r14, rax
    jge .copy_array
    
    xor r15, r15        ; j = 0
.calc_inner:
    mov rax, [max_x]
    cmp r15, rax
    jge .calc_next_row
    
    xor rbx, rbx        ; sum = 0
    
    ; Проверяем 8 соседей
    mov r8, r14
    mov r9, r15
    dec r8
    dec r9
    call .check_neighbor
    
    mov r8, r14
    mov r9, r15
    dec r8
    call .check_neighbor
    
    mov r8, r14
    mov r9, r15
    dec r8
    inc r9
    call .check_neighbor
    
    mov r8, r14
    mov r9, r15
    dec r9
    call .check_neighbor
    
    mov r8, r14
    mov r9, r15
    inc r9
    call .check_neighbor
    
    mov r8, r14
    mov r9, r15
    inc r8
    dec r9
    call .check_neighbor
    
    mov r8, r14
    mov r9, r15
    inc r8
    call .check_neighbor
    
    mov r8, r14
    mov r9, r15
    inc r8
    inc r9
    call .check_neighbor
    
    ; Вычисляем индекс
    mov rax, [max_x]
    mul r14
    add rax, r15
    
    mov cl, byte [r12 + rax]  ; текущее состояние
    
    test cl, cl
    jnz .live_cell

.dead_cell:   ; переход состояния мёртвой клетки
    cmp rbx, 3
    je .set_alive
    jmp .set_dead

.live_cell:     ; переход состояния живой клетки
    cmp rbx, 2
    je .set_alive
    cmp rbx, 3
    je .set_alive
    jmp .set_dead

.set_alive:    ; делем клетку живой
    mov byte [r13 + rax], 1
    jmp .calc_next_cell

.set_dead:     ; делаем клетку мёртвой
    mov byte [r13 + rax], 0

.calc_next_cell:   ; переход на следующий столбец
    inc r15
    jmp .calc_inner

.calc_next_row:    ; переход на следующий ряд
    inc r14
    jmp .calc_outer

.check_neighbor:
    ; Проверка границ экрана
    cmp r8, 0
    jl .check_done
    cmp r9, 0
    jl .check_done
    mov rax, [max_y]
    cmp r8, rax
    jge .check_done
    mov rax, [max_x]
    cmp r9, rax
    jge .check_done
    
    ; Проверка клетки
    mov rax, [max_x]
    mul r8
    add rax, r9
    cmp byte [r12 + rax], 0
    je .check_done
    inc rbx

.check_done:
    ret

.copy_array:
    ; Копируем new_array в array
    mov rax, [max_y]
    mul [max_x]
    mov rcx, rax
    xor rdx, rdx
.copy_loop:
    mov bl, byte [r13 + rdx]
    mov byte [r12 + rdx], bl
    inc rdx
    dec rcx
    jnz .copy_loop
    
    jmp .game_loop

.cleanup_exit:
    ; Завершение ncurses
    call endwin
    
    ; Освобождение памяти
    mov rdi, r12
    call free
    
    mov rdi, r13
    call free
    
    ; Выход
    call exit