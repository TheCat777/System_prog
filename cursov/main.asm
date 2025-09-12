format ELF64

include 'func.asm'


public _start


extrn initscr
extrn curs_set
extrn start_color
extrn init_pair
extrn color_set
extrn getmaxx
extrn getmaxy
extrn clear
extrn printw
extrn stdscr
extrn move
extrn getch
extrn refresh
extrn endwin
extrn exit
extrn timeout
extrn rand
extrn usleep


section '.data' writable

    max_x dq 1     ; размеры экрана/терминала
    max_y dq 1

    array dq ?     ; массив хранения позиций
    new_array dq ? ; массив хранения позиций, для смены циклов
    size dq ?      ; max_x * max_y

    msg1 db "Режим работы циклов:", 0xA, "(1) - самостоятельная работа", 0xA, "(2) - ручные итерации", 0xA, 0
    msg2 db "Стартовое наполнение:", 0xA, "(1) - заполнение из файла", 0xA, "(2) - случайное", 0xA, 0

    type db 0    ; буфер для чтения 1 ввода
    type2 db 0   ; буфер для чтения 2 ввода


section '.text' executable

_start:
    mov rsi, msg1
    call print_str  ; вывод первого сообщения

    mov rax, 0
    mov rdi, 0
    mov rsi, type
    mov rdx, 2
    syscall          ; чтение ответа

    mov rsi, msg2
    call print_str  ; вывод второго сообщения

    mov rax, 0
    mov rdi, 0
    mov rsi, type2
    mov rdx, 2
    syscall          ; чтение ответа

	call initscr   ; Инициализация ncurses
	mov rdi, [stdscr]
	call getmaxx   ; Получение макисмальной длины
	dec rax
	mov [max_x], rax

	call getmaxy   ; Получение максимальной высоты
	dec rax
	mov [max_y], rax

    mov rax, 0
    call curs_set   ; Невидимый курсор

    call start_color
	mov rdi, 1
	mov rsi, 7
	mov rdx, 7
	call init_pair  ; Белый цвет фона

    mov rax, max_x
    mul [max_y]

    mov [size], rax

    mov rax, 12         
    xor rdi, rdi        
    syscall
    
    mov rdi, rax
    add rdi, size       
    mov rax, 12        
    syscall
    
    mov [array], rax ; Выделение места под динамический массив
    mov rdi, rax
    add rdi, size       
    mov rax, 12        
    syscall
    
    mov [new_array], rax ; Выделение места под динамический массив

    mov rcx, [size]
    xor rax, rax
    .loop1:              ; зануление массива
        mov [array + rax], 0

        add rax, 4
        loop .loop1

    cmp [type2], '1'
    jne .random_init
                        ; из файла старт
        
    jmp .loop2
    .random_init:      ; случайный старт

    .loop2:

    call getch      ; Завершение работы
    call endwin

	call exit