format ELF64

public _start

extrn initscr
extrn endwin
extrn clear
extrn refresh
extrn move
extrn addch
extrn addstr
extrn getmaxyx
extrn getmaxy
extrn getmaxx
extrn nodelay
extrn cbreak
extrn noecho
extrn curs_set
extrn keypad
extrn getch
extrn usleep
extrn sin

section '.data' writeable
    A dq 10.0 
    w dq 0.15 
    x dq 0.0 
    step dq 0.1 
    
    rows dd 0
    cols dd 0
    center_y dd 0
    center_x dd 0
    
    key db 0
    star db '*'


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
    call nodelay
    
	mov rdi, 0
    call getmaxy
    mov [rows], eax
    
    call getmaxx
    mov [cols], eax
    
    mov eax, [rows]
    shr eax, 1
    mov [center_y], eax
    
    mov eax, [cols]
    shr eax, 1
    mov [center_x], eax
    
    call main
    
    call endwin
    mov rax, 60
    xor rdi, rdi
    syscall

main:
    push rbp
    mov rbp, rsp
    
.loop:
    call clear
    
    call draw
    
    call refresh
    
    call getch
    mov [key], al
    
    cmp al, '+'
    je .incA
    cmp al, '-'
    je .decA
    cmp al, ']'
    je .incW
    cmp al, '['
    je .decW
    cmp al, 27
    je .exit
    
.input_done:
    movq xmm0, [x]
    addsd xmm0, [step]
    movq [x], xmm0
    
    comisd xmm0, qword [two_pi]
    jb .delay
    pxor xmm0, xmm0
    movq [x], xmm0
    
.delay:
    mov rdi, 30000
    call usleep
    jmp .loop

.incA:
    movq xmm0, [A]
    mov rax, 1
    movq xmm1, rax
    addsd xmm0, xmm1
    movq [A], xmm0
    jmp .input_done

.decA:
    movq xmm0, [A]
    mov rax, 1
    movq xmm1, rax
    subsd xmm0, xmm1
    comisd xmm0, qword [minA]
    ja .storeA
    movq xmm0, qword [minA]
.storeA:
    movq [A], xmm0
    jmp .input_done

.incW:
    movq xmm0, [w]
    mov rax, 0.05
    movq xmm1, rax
    addsd xmm0, xmm1
    movq [w], xmm0
    jmp .input_done

.decW:
    movq xmm0, [w]
    mov rax, 0.05
    movq xmm1, rax
    subsd xmm0, xmm1
    comisd xmm0, qword [minW]
    ja .storeW
    movq xmm0, qword [minW]
.storeW:
    movq [w], xmm0
    jmp .input_done

.exit:
    pop rbp
    ret

draw:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    
    ; y = A * sin(w*x)
    movq xmm0, [x]
    mulsd xmm0, [w]
    movq [rsp], xmm0
    mov rdi, [rsp]
    call sin
    movq xmm1, rax
    mulsd xmm1, [A]
    
    cvtsd2si rbx, xmm1      ; y
    cvtsd2si rcx, [x]       ; x
    
    mov eax, [center_y]
    sub eax, ebx
    mov edi, eax  
    
    mov eax, [center_x]
    add eax, ecx
    mov esi, eax  
    
    cmp edi, 2
    jl .skip
    cmp edi, [rows]
    jge .skip
    cmp esi, 0
    jl .skip
    cmp esi, [cols]
    jge .skip
    
    call move
    mov rdi, star
    call addch
    
.skip:
    add rsp, 16
    pop rbp
    ret

section '.data'
    two_pi dq 6.283185307179586
    minA dq 1.0
    minW dq 0.05