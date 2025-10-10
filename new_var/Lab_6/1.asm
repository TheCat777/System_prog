format ELF64

	public _start

	extrn initscr
	extrn start_color
	extrn init_pair
	extrn getmaxx
	extrn getmaxy
	extrn raw
	extrn printw
	extrn noecho
	extrn keypad
	extrn stdscr
	extrn move
	extrn getch
	extrn clear
	extrn addch
	extrn refresh
	extrn endwin
	extrn exit
	extrn color_pair
	extrn insch
	extrn cbreak
	extrn timeout
	extrn setrnd
	extrn get_random
    extrn usleep


	section '.bss' writable

    max_x dq 1
    max_y dq 1

    max_border_x dq 1
    max_border_y dq 1
    min_border_x dq 1
    min_border_y dq 1

    pos_x dq 0
    pos_y dq 0
	
	flag dq 1
	color_flag dq 0

	palette dq 1
    delay dq ?
    speed_mode dq 1

	h1 db "1",0
	h2 db "2",0
	h3 db "3",0
	h4 db "4",0


	section '.text' executable

_start:
	call initscr
	mov rdi, [stdscr]
	call getmaxx
	dec rax
	mov [max_x], rax
	call getmaxy
	dec rax
	mov [max_y], rax
	
	xor rdx, rdx
	mov rax, [max_y]
	mov rbx, 2
	div rbx
	mov [min_border_y], rax
	mov [min_border_x], rax
	mov [max_border_y], rax


	mov rax, [max_x]
	mov rbx, [min_border_x]
	sub rax, rbx
	mov [max_border_x], rax

	inc [max_border_x]
	inc [max_border_y]
	dec [min_border_x]
	dec [min_border_y]

	call start_color
	mov rdi, 1
	mov rsi, 2
	mov rdx, 2
	call init_pair
	mov rdi, 2
	mov rsi, 4
	mov rdx, 4
	call init_pair
	call refresh
	call noecho

	mov rax, ' '
	or rax, 0x100
	mov [palette], rax
	
	mov [delay], 10000
	mov [speed_mode], 10

	call refresh
	mov rax, [min_border_y]
	mov [pos_y], rax

	mov rax, [min_border_x]
	mov [pos_x], rax
	inc [pos_x]
	
	mov rdi, [pos_y]
	mov rsi, [pos_x]
	call move
	jmp .mloop


	;; Главный цикл программы
.mloop:

    xor rdi, rdi
	mov rdi, [delay]
	call usleep

	cmp [flag], 1
	je .down
	cmp [flag], 2
	je .right
	cmp [flag], 3
	je .up
	
	jmp .left

.end_loop:

	;; Обновляем экран и количество выведенных знакомест в заданной палитре
	mov rdi, [palette]
	call addch
	call refresh

    ;;Задаем таймаут для getch
	mov rdi, 1
	call timeout
	call getch

    ;;Анализируем нажатую клавишу
	cmp rax, 'u'
	je .all_exit

    cmp rax, 'e'
    je .fast

	;jmp .mloop
	jmp .check_r

.check_r:
	mov rax, [max_border_y]
	
	cmp [pos_y], rax
	je .set_right
	jmp .check_u

.check_u:
	mov rax, [max_border_x]
	cmp [pos_x], rax
	je .set_up
	jmp .check_l

.check_l:
	mov rax, [min_border_y]
	cmp [pos_y], rax
	je .set_left
	jmp .check_d

.check_d:
	mov rax, [min_border_x]
	cmp [pos_x], rax
	je .set_down
	jmp .check_next

.check_next:
	cmp [pos_x], 0
	jne .mloop

	mov rax, [max_y]
	cmp rax, [pos_y]
	jne .mloop


	xor rdx, rdx
	mov rax, [max_y]
	mov rbx, 2
	div rbx
	mov [min_border_y], rax
	mov [min_border_x], rax
	mov [max_border_y], rax


	mov rax, [max_x]
	mov rbx, [min_border_x]
	sub rax, rbx
	mov [max_border_x], rax

	inc [max_border_x]
	inc [max_border_y]
	dec [min_border_x]
	dec [min_border_y]

	cmp [color_flag], 0
	je .white

	jmp .orange

.white:
	mov [color_flag], 1
	mov rax, [palette]
	and rax, 0xff
	or rax, 0x200
	mov [palette], rax
	mov rax, [min_border_y]
	mov [pos_y], rax
	inc [pos_y]

	mov rax, [min_border_x]
	mov [pos_x], rax
	inc [pos_x]

	jmp .mloop

.orange:
	mov [color_flag], 0
	mov rax, [palette]
	and rax, 0xff
	or rax, 0x100
	mov [palette], rax
	mov rax, [min_border_y]
	mov [pos_y], rax
	inc [pos_y]

	mov rax, [min_border_x]
	mov [pos_x], rax
	inc [pos_x]

	jmp .mloop

.all_exit:
	call endwin
	call exit

.fast:
	cmp [speed_mode], 1
	jne .slow
	cmp [delay], 0
	jng .slow
	mov [delay], 0
.slow:
	mov [speed_mode], 0
	cmp [delay], 10000
	jnl .ch_mode
	add [delay], 1000
	jmp .mloop

.ch_mode:
	mov [speed_mode], 1
	jmp .fast

.down:
	inc [pos_y]
	jmp .set_pos

.right:
	inc [pos_x]
	jmp .set_pos

.up:
	dec [pos_y]
	jmp .set_pos

.left:
	dec [pos_x]
	jmp .set_pos

.set_pos:
	mov rdi, [pos_y]
	mov rsi, [pos_x]
	call move
	jmp .end_loop

.set_right:
	dec [pos_y]
	mov [flag], 2
	jmp .check_u

.set_up:
	dec [pos_x]
	mov [flag], 3
	jmp .check_l

.set_left:
	inc [pos_y]
	mov [flag], 4
	jmp .check_d

.set_down:
	inc [pos_x]

	mov [flag], 1

	inc [max_border_x]
	inc [max_border_y]

	dec [min_border_x]
	dec [min_border_y]
	jmp .mloop
