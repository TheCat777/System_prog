format ELF64

include 'func.asm'

public _start
public print_symb

section '.bss' writable
  number dq ./5_  
  result dq 0
  ten dq 10
  temp db 1

section '.text' executable
  _start:
    mov rax, [number]
    xor rbx, rbx

    .sum_loop:
      xor rdx, rdx
      div qword [ten]
      add rbx, rdx
      cmp rax, 0
      jne .sum_loop

    mov [result], rbx
    call print_symb

    call new_line

    mov eax, 60
    xor edi, edi
    call exit

print_symb:
    mov rax, [result]
    xor rbx, rbx

    cmp rax, 9
    jle .single_num

    mov rcx, 10
    .loop:
        xor rdx, rdx
        div rcx
        push rdx
        inc rbx
        test rax, rax
        jnz .loop

    .print_loop:
        pop rax
        add rax, '0'
        mov [temp], al

        mov eax, 1
        mov edi, 1
        mov rsi, temp
        mov edx, 1
        syscall

        dec rbx
        jnz .print_loop

        ret

    .single_num:
        add rax, '0'
        mov [temp], al

        mov eax, 1
        mov edi, 1
        mov rsi, temp
        mov edx, 1
        syscall
        ret
