format ELF64
public _start

SOCK_STREAM = 1
AF_INET = 2
PORT = 5555
MAX_CLIENTS = 1
BUFFER_SIZE = 1024
INADDR_ANY = 0
SOL_SOCKET = 1
SO_REUSEADDR = 2

struc sockaddr_in
{
  .sin_family dw 2
  .sin_port dw 5757
  .sin_addr dd 0          ; localhost
  .sin_zero_1 dd 0
  .sin_zero_2 dd 0
}

addrstr sockaddr_in 
addrlen = $ - addrstr

; Карты и их значения
; 6=6, 7=7, 8=8, 9=9, 10=10, J=2, Q=3, K=4, A=11
CARD_VALUES db 6,7,8,9,10,2,3,4,11
CARD_NAMES db '6','7','8','9','0','J','Q','K','A' ; 0 вместо 10
CARD_COUNT = 9

SYS_EXIT = 60
SYS_SOCKET = 41
SYS_BIND = 49
SYS_LISTEN = 50
SYS_ACCEPT = 43
SYS_READ = 0
SYS_WRITE = 1
SYS_CLOSE = 3
SYS_TIME = 201
SYS_SETSOCKOPT = 54
SYS_GETPID = 39
SYS_NANOSLEEP = 35

section '.bss' writeable
    socket_fd dq ?
    client_fd dq ?
    player_score db ?
    dealer_score db ?
    seed dq ?
    random_counter dq ?

    buffer rb BUFFER_SIZE
    card_name_buf rb 4


    timespec:
        .tv_sec dq ?
        .tv_nsec dq ?

section '.data' writeable
    reuseaddr dd 1

    welcome_msg db 'Добро пожаловать в игру 21! Команды:',0dh,0ah
            db 'HIT - взять карту',0dh,0ah
            db 'STAND - остановиться',0dh,0ah
            db 'QUIT - выйти из игры',0dh,0ah,0
    welcome_len = $ - welcome_msg

    hit_cmd db 'HIT',0
    stand_cmd db 'STAND',0
    quit_cmd db 'QUIT',0

    win_msg db 'Вы выиграли!',0dh,0ah,0
    win_len = $ - win_msg

    lose_msg db 'Вы проиграли.',0dh,0ah,0
    lose_len = $ - lose_msg

    draw_msg db 'Ничья!',0dh,0ah,0
    draw_len = $ - draw_msg

    player_turn_msg db 'Ваш ход. Ваши очки: '
    player_turn_len = $ - player_turn_msg

    dealer_turn_msg db 'Ход дилера. Очки дилера: '
    dealer_turn_len = $ - dealer_turn_msg

    card_msg db 'Вы получили карту: '
    card_len = $ - card_msg

    dealer_card_msg db 'Дилер получил карту: '
    dealer_card_len = $ - dealer_card_msg

    newline db 0dh,0ah
    newline_len = $ - newline

    card_10_msg db '10',0
    card_10_len = $ - card_10_msg

section '.text' executable

init_random:
    push rdi
    mov rax, SYS_TIME
    xor rdi, rdi
    syscall
    mov [seed], rax
    
    mov rax, SYS_GETPID
    syscall
    xor [seed], rax
    
    mov qword [random_counter], 0
    pop rdi
    ret

random:
    push rbx
    push rdx
    
    mov rax, [seed]
    mov rbx, 6365
    mul rbx
    add rax, 1407
    mov [seed], rax
    
    shr rax, 32
    
    inc qword [random_counter]
    
    pop rdx
    pop rbx
    ret

draw_card:
    push rbx
    push rdx
    
    call random
    xor rdx, rdx
    mov rbx, CARD_COUNT
    div rbx
    
    mov al, [CARD_VALUES + rdx]
    
    mov bl, [CARD_NAMES + rdx]
    cmp bl, '0'
    jne .not_10
    lea rsi, [card_10_msg]
    mov rdx, card_10_len
    lea rdi, [card_name_buf]
    mov rcx, rdx
    rep movsb
    mov byte [rdi], 0
    jmp .done
    
.not_10:
    mov [card_name_buf], bl
    mov byte [card_name_buf + 1], 0
    
.done:
    pop rdx
    pop rbx
    ret




strlen:
    xor rax, rax
    test rsi, rsi
    jz .done
.count_loop:
    cmp byte [rsi + rax], 0
    je .done
    inc rax
    jmp .count_loop
.done:
    ret


strcmp:
    xor rcx, rcx
.compare_loop:
    mov al, [rdi + rcx]
    mov bl, [rsi + rcx]
    cmp al, bl
    jne .not_equal
    test al, al
    jz .equal
    inc rcx
    jmp .compare_loop
.not_equal:
    mov rax, 1
    ret
.equal:
    xor rax, rax
    ret


int_to_string:
    push rbx
    push rcx
    push rdx
    push rdi
    
    mov rbx, 10
    xor rcx, rcx
    
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
    
    mov rbx, rdi
.pop_loop:
    pop rax
    mov [rbx], al
    inc rbx
    loop .pop_loop
    mov byte [rbx], 0
    
.done:
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret



send_message:
    push rdi
    mov rdi, [client_fd]
    mov rax, SYS_WRITE
    syscall
    pop rdi
    ret


receive_message:
    mov rdi, [client_fd]
    lea rsi, [buffer]
    mov rdx, BUFFER_SIZE
    mov rax, SYS_READ
    syscall
    ret



dealer_turn:
    lea rsi, [dealer_turn_msg]
    mov rdx, dealer_turn_len
    call send_message
    
    movzx rax, byte [dealer_score]
    lea rdi, [buffer]
    call int_to_string
    mov rsi, rdi
    call strlen
    mov rdx, rax
    call send_message
    
    lea rsi, [newline]
    mov rdx, newline_len
    call send_message
    
    
.dealer_loop:
    mov al, [dealer_score]
    cmp al, 17  ; максимум для набора
    jge .dealer_done
    
    call draw_card
    add [dealer_score], al
    
    lea rsi, [dealer_card_msg]
    mov rdx, dealer_card_len
    call send_message
    
    lea rsi, [card_name_buf]
    call strlen
    mov rdx, rax
    lea rsi, [card_name_buf]
    call send_message
    
    mov byte [buffer], ' '
    mov byte [buffer+1], '('
    lea rdi, [buffer+2]
    movzx rax, al
    call int_to_string
    lea rsi, [buffer+2]
    call strlen
    add rax, 2
    mov byte [buffer+rax], ')'
    inc rax
    mov rdx, rax
    lea rsi, [buffer]
    call send_message
    
    lea rsi, [newline]
    mov rdx, newline_len
    call send_message
    
    jmp .dealer_loop
    
.dealer_done:
    ret


determine_winner:
    mov al, [player_score]
    mov bl, [dealer_score]
    
    cmp al, 21
    jg .player_bust
    
    cmp bl, 21
    jg .dealer_bust
    
    cmp al, bl
    jg .player_wins
    jl .dealer_wins
    
    lea rsi, [draw_msg]
    mov rdx, draw_len
    jmp .send_result
    
.player_wins:
    lea rsi, [win_msg]
    mov rdx, win_len
    jmp .send_result
    
.dealer_wins:
    lea rsi, [lose_msg]
    mov rdx, lose_len
    jmp .send_result
    
.player_bust:
    lea rsi, [lose_msg]
    mov rdx, lose_len
    jmp .send_result
    
.dealer_bust:
    lea rsi, [win_msg]
    mov rdx, win_len
    
.send_result:
    call send_message

    call exit
    ret



_start:
    call init_random
    
    mov rax, SYS_SOCKET
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl exit
    mov [socket_fd], rax
    
    mov rax, SYS_SETSOCKOPT
    mov rdi, [socket_fd]
    mov rsi, SOL_SOCKET
    mov rdx, SO_REUSEADDR
    lea r10, [reuseaddr]
    mov r8, 4
    syscall
    
    mov rax, SYS_BIND
    mov rdi, [socket_fd]
    mov rsi, addrstr
    mov rdx, addrlen
    syscall
    cmp rax, 0
    jl exit
    
    mov rax, SYS_LISTEN
    mov rdi, [socket_fd]
    mov rsi, MAX_CLIENTS
    syscall
    cmp rax, 0
    jl exit
    
    mov rax, SYS_ACCEPT
    mov rdi, [socket_fd]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl exit
    mov [client_fd], rax
    
    lea rsi, [welcome_msg]
    mov rdx, welcome_len
    call send_message
    

game_loop:
    ; Сброс очков
    mov byte [player_score], 0
    mov byte [dealer_score], 0
    
    call draw_card
    add [player_score], al
    
    call draw_card
    add [player_score], al
    
    call draw_card
    add [dealer_score], al
    
    call draw_card
    add [dealer_score], al


player_turn:
    lea rsi, [player_turn_msg]
    mov rdx, player_turn_len
    call send_message
    
    movzx rax, byte [player_score]
    lea rdi, [buffer]
    call int_to_string
    mov rsi, rdi
    call strlen
    mov rdx, rax
    call send_message
    
    
    lea rsi, [newline]
    mov rdx, newline_len
    call send_message
    
    
    call receive_message
    test rax, rax
    jle exit
    
    lea rdi, [buffer]
    
    
    dec rax
    cmp byte [rdi + rax], 0ah
    jne .check_cr
    mov byte [rdi + rax], 0
    dec rax
.check_cr:
    cmp byte [rdi + rax], 0dh
    jne .check_commands
    mov byte [rdi + rax], 0
    
.check_commands:
    lea rsi, [hit_cmd]
    call strcmp
    test rax, rax
    jz .player_hit
    
    lea rsi, [stand_cmd]
    call strcmp
    test rax, rax
    jz .player_stand
    
    lea rsi, [quit_cmd]
    call strcmp
    test rax, rax
    jz exit
    
    jmp player_turn

.player_hit:
    call draw_card
    add [player_score], al
    
    lea rsi, [card_msg]
    mov rdx, card_len
    call send_message
    
    lea rsi, [card_name_buf]
    call strlen
    mov rdx, rax
    lea rsi, [card_name_buf]
    call send_message
    
    mov byte [buffer], ' '
    mov byte [buffer+1], '('
    lea rdi, [buffer+2]
    movzx rax, al
    call int_to_string
    lea rsi, [buffer+2]
    call strlen
    add rax, 2
    mov byte [buffer+rax], ')'
    inc rax
    mov rdx, rax
    lea rsi, [buffer]
    call send_message
    
    lea rsi, [newline]
    mov rdx, newline_len
    call send_message
    
    mov al, [player_score]
    cmp al, 21
    jg .player_busted
    jmp player_turn

.player_stand:
    jmp .player_done
    
.player_busted:
    lea rsi, [lose_msg]
    mov rdx, lose_len
    call send_message
    jmp game_loop
    
.player_done:
    call dealer_turn
    
    call determine_winner
    
    jmp game_loop



exit:
    mov rax, SYS_CLOSE
    mov rdi, [client_fd]
    syscall
    
    mov rax, SYS_CLOSE
    mov rdi, [socket_fd]
    syscall
    
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall