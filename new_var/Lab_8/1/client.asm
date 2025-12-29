format ELF64
public _start

SOCK_STREAM = 1
AF_INET = 2
BUFFER_SIZE = 512

SYS_EXIT = 60
SYS_SOCKET = 41
SYS_CONNECT = 42
SYS_READ = 0
SYS_WRITE = 1
SYS_CLOSE = 3

section '.bss' writeable
    socket_fd dq ?
    buffer rb BUFFER_SIZE
    input_buffer rb BUFFER_SIZE
    
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

section '.data' writeable
    prompt db '> ',0
    newline db 0dh,0ah
    quit_cmd db 'QUIT',0
    connect_error_msg db 'Ошибка подключения к серверу',0dh,0ah,0
    connect_error_len = $ - connect_error_msg

section '.text' executable

_start:
    mov rax, SYS_SOCKET
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .error_exit
    mov [socket_fd], rax
    
    
    mov rax, SYS_CONNECT
    mov rdi, [socket_fd]
    mov rsi, addrstr
    mov rdx, addrlen
    syscall
    cmp rax, 0
    jl .connect_error
    
    call receive_and_print
    
.game_loop:
    mov rax, 1
    mov rdi, 1
    lea rsi, [prompt]
    mov rdx, 2
    syscall
    
    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, BUFFER_SIZE
    syscall
    test rax, rax
    jle exit
    
    call process_input
    
    call receive_and_print
    
    jmp .game_loop


.connect_error:
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, connect_error_msg
    mov rdx, connect_error_len
    syscall
    
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

.error_exit:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall
    

process_input:
    push rbx
    
    mov rbx, rax
    
    lea rdi, [input_buffer]
    add rdi, rbx
    dec rdi
    
    cmp byte [rdi], 0ah
    jne .check_cr
    mov byte [rdi], 0
    dec rbx
    dec rdi
    
.check_cr:
    cmp byte [rdi], 0dh
    jne .check_empty
    mov byte [rdi], 0
    dec rbx
    
.check_empty:
    test rbx, rbx
    jz .skip_send
    
    lea rdi, [input_buffer]
    lea rsi, [quit_cmd]
    call strcmp
    test rax, rax
    jnz .send_command
    
    lea rsi, [input_buffer]
    mov rdx, rbx
    call send_to_server
    pop rbx
    jmp exit
    
.send_command:
    lea rdi, [input_buffer]
    add rdi, rbx
    mov byte [rdi], 0dh
    mov byte [rdi + 1], 0ah
    add rbx, 2
    
    lea rsi, [input_buffer]
    mov rdx, rbx
    call send_to_server
    
.skip_send:
    pop rbx
    ret


receive_and_print:
    push rbx
    
    mov rax, SYS_READ
    mov rdi, [socket_fd]
    lea rsi, [buffer]
    mov rdx, BUFFER_SIZE
    syscall
    
    test rax, rax
    jle .server_closed
    
    
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [buffer]
    syscall
    
    pop rbx
    ret

.server_closed:
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 2
    syscall
    jmp exit



send_to_server:
    mov rax, SYS_WRITE
    mov rdi, [socket_fd]
    syscall
    ret


strcmp:
    xor rcx, rcx
.compare:
    mov al, [rdi + rcx]
    mov bl, [rsi + rcx]
    cmp al, bl
    jne .not_equal
    test al, al
    jz .equal
    inc rcx
    jmp .compare
.not_equal:
    mov rax, 1
    ret
.equal:
    xor rax, rax
    ret


exit:
    mov rax, SYS_CLOSE
    mov rdi, [socket_fd]
    syscall
    
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall
