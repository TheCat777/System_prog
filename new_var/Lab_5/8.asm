format elf64
public _start

include 'func.asm'


section '.bss' writeable
buffer rb 2
buffer2 rb 2

section '.text' executable
_start:
    pop rcx
    cmp rcx, 4
    jne l1

    mov rdi,[rsp+8]
    mov rbp,[rsp+16]
    mov r9, [rsp+24]

    mov rax, 2
    mov rsi, 0o
    syscall
    cmp rax, 0
    jl l1

    mov r8, rax

    .loop_read:
        mov rax, 0
        mov rdi, r8
        mov rsi, buffer
        mov rdx, 1
        syscall
        cmp rax, 0

        je eclose

        mov byte [rsi+rax], 0

        xor rax, rax
        .find:
            mov bl, byte [rsi]
            movzx rax, bl
            mov r10, rax

            call read2



        jmp .loop_read
    call eclose

read2:
    push rdi
    push rbp
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push r8
    push r9
    push r10


    mov rdi, rbp

    mov rax, 2
    mov rsi, 0o
    syscall
    cmp rax, 0
    jl l1

    mov r8, rax

    .loop_read:
        mov rax, 0
        mov rdi, r8
        mov rsi, buffer
        mov rdx, 1
        syscall
        cmp rax, 0

        je .stopclose

        mov byte [rsi+rax], 0

        xor rax, rax
        .find:
            mov bl, byte [rsi]
            movzx rax, bl
            cmp rax, r10
            jne .loop_read

            mov rbx, rsi
            call write

        jmp .loop_read
    .stopclose:
        call close
    pop r10
    pop r9
    pop r8
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    pop rbp
    pop rdi
    ret


write:
    push rdi
    push rbp
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push r8

    mov rdi, r9
    mov rax, 2
    mov rsi, 1078
    mov rdx, 777o
    syscall
    cmp rax, 0
    jl l1

    mov r8, rax

    mov rsi, rbx

    mov rax, buffer2
    call len_str
    mov rdx, rax
    mov [buffer2+rdx], 0
    inc rdx

    mov rax, 1
    mov rdi, r8
    mov rsi, buffer
    syscall

    pop r8
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    pop rbp
    pop rdi
    ret


eclose:
  mov rdi, r8
  mov rax, 3
  syscall
  call exit

l1:
  call exit


close:
  mov rdi, r8
  mov rax, 3
  syscall
  ret