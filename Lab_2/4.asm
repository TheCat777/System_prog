format ELF64

public _start
public exit
public print_symb

section '.bss' writable
  number dq 2269503710
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

exit:
  mov eax, 1
  mov ebx, 0
  int 0x80