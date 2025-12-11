format ELF64

; Константы для clone
CLONE_VM      = 0x00000100
CLONE_FS      = 0x00000200
CLONE_FILES   = 0x00000400
CLONE_SIGHAND = 0x00000800
CLONE_PARENT  = 0x00008000
SIGCHLD       = 0x00000011

STACK_SIZE    = 8192

section '.data' writeable
    space db " ", 0
    newline db 10, 0
    
    array rb 1000
    buffer rb 20
    N dq 0
    
    stack1 rb STACK_SIZE
    stack2 rb STACK_SIZE
    
    pid1 dq 0
    pid2 dq 0
    
    status dq 0

section '.text' executable
public _start

_start:
    pop rax
    cmp rax, 2
    jl exit_error
    
    pop rdi
    pop rdi 
    call atoi
    test rax, rax
    jle exit_error
    
    mov [N], rax
    
    mov rcx, rax
    xor rbx, rbx
.fill_array:
    inc bl
    mov [array + rcx - 1], bl
    loop .fill_array
    
    lea rsi, [stack1 + STACK_SIZE - 16]
    
    mov rax, process_even
    mov [rsi], rax
    
    mov rax, 56
    mov rdi, CLONE_VM or CLONE_FS or CLONE_FILES or CLONE_SIGHAND or SIGCHLD
    lea rsi, [stack1 + STACK_SIZE - 16]
    xor rdx, rdx 
    xor r10, r10
    xor r8, r8
    syscall
    
    cmp rax, 0
    jl exit_error 
    je process_even 
    
    mov [pid1], rax 
    
    lea rsi, [stack2 + STACK_SIZE - 16]
    
    mov rax, process_odd
    mov [rsi], rax
    
    mov rax, 56
    mov rdi, CLONE_VM or CLONE_FS or CLONE_FILES or CLONE_SIGHAND or SIGCHLD
    lea rsi, [stack2 + STACK_SIZE - 16]
    xor rdx, rdx
    xor r10, r10 
    xor r8, r8  
    syscall
    
    cmp rax, 0
    jl exit_error
    je process_odd 
    
    mov [pid2], rax
    
    mov rax, 61
    mov rdi, [pid1]
    mov rsi, status
    xor rdx, rdx
    xor r10, r10
    syscall
    
    mov rax, 61 
    mov rdi, [pid2]
    mov rsi, status
    xor rdx, rdx
    xor r10, r10
    syscall
    
    mov rcx, [N]
    test rcx, rcx
    jz .print_done
    
    xor rbx, rbx
.print_loop:
    xor rax, rax
    mov al, [array + rbx]
    
    push rbx
    push rcx
    mov rdi, rax
    lea rsi, [buffer]
    call int_to_str
    lea rsi, [buffer]
    call print_string
    lea rsi, [space]
    call print_string
    pop rcx
    pop rbx
    
    inc rbx
    loop .print_loop

.print_done:
    lea rsi, [newline]
    call print_string
    
    mov rax, 60
    xor rdi, rdi
    syscall

exit_error:
    mov rax, 60
    mov rdi, 1
    syscall

process_even:
    mov rcx, [N]
    test rcx, rcx
    jz .exit
    
    xor rbx, rbx
.even_loop:
    mov al, [array + rbx]
    test al, 1
    jnz .even_skip
    inc al
    mov [array + rbx], al
.even_skip:
    inc rbx
    loop .even_loop
    
.exit:
    mov rax, 60
    xor rdi, rdi
    syscall

process_odd:
    mov rcx, [N]
    test rcx, rcx
    jz .exit1
    
    xor rbx, rbx
.odd_loop:
    mov al, [array + rbx]
    test al, 1
    jz .odd_skip
    dec al
    mov [array + rbx], al
.odd_skip:
    inc rbx
    loop .odd_loop
    
.exit1:
    mov rax, 60
    xor rdi, rdi
    syscall

atoi:
    xor rax, rax
    xor rcx, rcx
    xor rbx, rbx
    
.convert:
    mov bl, byte [rdi + rcx]
    test bl, bl
    jz .done
    
    cmp bl, '0'
    jl .error
    cmp bl, '9'
    jg .error
    
    sub bl, '0'
    imul rax, 10
    add rax, rbx
    inc rcx
    jmp .convert

.error:
    xor rax, rax
.done:
    ret

int_to_str:
    push rbp
    mov rbp, rsp
    
    mov rax, rdi
    mov rbx, 10
    lea rcx, [rsi + 18]
    mov byte [rcx], 0
    
    test al, al
    jnz .convert
    dec rcx
    mov byte [rcx], '0'
    jmp .done
    
.convert:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rcx
    mov [rcx], dl
    test rax, rax
    jnz .convert
    
.done:
    mov rdi, rsi
.copy:
    mov al, [rcx]
    mov [rdi], al
    test al, al
    jz .finish
    inc rcx
    inc rdi
    jmp .copy
    
.finish:
    pop rbp
    ret

print_string:
    push rbp
    mov rbp, rsp
    push rbx
    
    mov rbx, rsi
    xor rcx, rcx
.strlen:
    cmp byte [rbx + rcx], 0
    je .print
    inc rcx
    jmp .strlen
    
.print:
    mov rax, 1
    mov rdi, 1 
    mov rdx, rcx 
    syscall
    
    pop rbx
    pop rbp
    ret