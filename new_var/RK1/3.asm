format ELF64

public _start

section '.bss' writeable
    dir_fd dq 0
    file_count dq 0
    dir_path dq 0
    
    buffer rb 8192
    dirent_buffer rb 1024
    file_names rb 256 * 256
    path_buffer rb 1024

section '.text' executable

_start:
    mov rax, [rsp]
    cmp rax, 2
    jne exit

    mov rax, [rsp + 16]
    mov [dir_path], rax
    
    mov rax, 2
    mov rdi, [dir_path]
    mov rsi, 0
    mov rdx, 0
    syscall
    cmp rax, 0
    jl exit
    mov [dir_fd], rax

    xor r15, r15
    lea r14, [file_names]

.read_dir_loop:
    mov rax, 217
    mov rdi, [dir_fd]
    mov rsi, dirent_buffer
    mov rdx, 1024
    syscall
    test rax, rax
    jle dir_read_done
    
    mov r13, rax
    xor r12, r12

.process_dirent:
    lea rbx, [dirent_buffer + r12]
    
    movzx ecx, word [rbx + 16]
    test cx, cx
    jz dir_read_done
    
    mov al, byte [rbx + 19]
    cmp al, '.'
    je .next_dirent
    
    mov al, byte [rbx + 18]
    cmp al, 8
    jne .next_dirent
    
    lea rsi, [rbx + 19]
    mov rdi, r14
    call strcpy
    
    add r14, 256
    inc r15
    
    cmp r15, 256
    jge dir_read_done
    
.next_dirent:
    add r12, rcx
    cmp r12, r13
    jl .process_dirent
    jmp .read_dir_loop

dir_read_done:
    mov rax, 3
    mov rdi, [dir_fd]
    syscall
    
    mov [file_count], r15
    
    cmp r15, 2
    jl exit
    
    call get_random_index
    mov r12, rax
    
.get_second_index:
    call get_random_index
    cmp rax, r12
    je .get_second_index
    mov r13, rax 

    lea rbx, [file_names]
    
    mov rax, 256
    mul r12
    lea rsi, [rbx + rax]
    lea rdi, [path_buffer]
    call make_full_path
    lea r14, [path_buffer]
     
    mov rax, 256
    mul r13
    lea rsi, [rbx + rax]
    lea rdi, [path_buffer + 512] 
    call make_full_path
    lea r15, [path_buffer + 512] 

    mov rdi, r14
    mov rsi, r15
    call swap_files

exit:
    mov rax,1
    mov rbx,0
    int 0x80

make_full_path:
    push rax
    push rsi
    push rdi
    
    mov rsi, [dir_path]
.copy_dir:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .add_slash
    inc rsi
    inc rdi
    jmp .copy_dir

.add_slash:
    dec rdi
    mov al, [rdi]
    cmp al, '/'
    je .copy_filename
    inc rdi
    mov byte [rdi], '/'
    inc rdi

.copy_filename:
    pop rsi
    push rsi
    mov rsi, [rsp + 8]
.copy_name:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .done
    inc rsi
    inc rdi
    jmp .copy_name

.done:
    pop rdi
    pop rsi
    pop rax
    ret

swap_files:
    push r12
    push r13
    push r14
    push r15
    
    mov r14, rdi
    mov r15, rsi
    
    mov rax, 2
    mov rdi, r14
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .swap_error
    mov r12, rax
    
    mov rax, 2
    mov rdi, r15
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .swap_error
    mov r13, rax
    
    mov rax, 0 
    mov rdi, r12
    mov rsi, buffer
    mov rdx, 4096
    syscall
    cmp rax, 0
    jl .swap_error
    push rax 
    
    mov rax, 0
    mov rdi, r13
    mov rsi, buffer + 4096
    mov rdx, 4096
    syscall
    cmp rax, 0
    jl .swap_error
    push rax
    
    mov rax, 3 
    mov rdi, r12
    syscall
    
    mov rax, 3
    mov rdi, r13
    syscall
    
    mov rax, 2
    mov rdi, r14
    mov rsi, 0x241
    mov rdx, 0644o
    syscall
    cmp rax, 0
    jl .swap_error
    mov r12, rax
    
    mov rax, 1
    mov rdi, r12
    mov rsi, buffer + 4096
    pop rdx
    syscall
    
    mov rax, 3
    mov rdi, r12
    syscall
    
    mov rax, 2
    mov rdi, r15
    mov rsi, 0x241
    mov rdx, 0644o
    syscall
    cmp rax, 0
    jl .swap_error
    mov r13, rax
    
    mov rax, 1
    mov rdi, r13
    mov rsi, buffer
    pop rdx
    syscall
    
    mov rax, 3
    mov rdi, r13
    syscall
    
    pop r15
    pop r14
    pop r13
    pop r12
    ret

.swap_error:
    cmp r12, 0
    jle .close_file2
    mov rax, 3
    mov rdi, r12
    syscall
.close_file2:
    cmp r13, 0
    jle .swap_done
    mov rax, 3
    mov rdi, r13
    syscall
.swap_done:
    pop r15
    pop r14
    pop r13
    pop r12
    ret

get_random_index:
    push rbx
    push rdx
    
    mov rax, 201 ; sys_time
    xor rdi, rdi
    syscall
    
    xor rdx, rdx
    mov rbx, [file_count]
    test rbx, rbx
    jz .zero
    div rbx
    mov rax, rdx
    jmp .done
.zero:
    xor rax, rdx
.done:
    pop rdx
    pop rbx
    ret

strcpy:
    push rax
.loop:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .done
    inc rsi
    inc rdi
    jmp .loop
.done:
    pop rax
    ret

strlen:
    push rcx
    mov rcx, rsi
    xor rax, rax
.loop:
    cmp byte [rcx + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    pop rcx
    ret