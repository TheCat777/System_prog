format elf64
public _start

include 'func.asm'

section '.bss' writable
  
  buffer rb 100
    output dq ?

section '.text' executable

_start:
  pop rcx 
  cmp rcx, 1 
  je .l1 

  mov rdi,[rsp+8] 
  mov rax, 2 
  ;;Формируем O_WRONLY|O_TRUNC|O_CREAT
  mov rsi, 577
  mov rdx, 777o
  syscall 
  cmp rax, 0 
  jl .l1 
  
  ;;Сохраняем файловый дескриптор
  mov r8, rax

  ;;Читаем n в r9
  mov rsi, [rsp+16]
  call str_number
  mov r9, rax
  
  ;;Начинаем цикл
  mov rbx, 1
 .loop:
   inc rbx
   cmp rbx, r9
   jg .l2
   mov rcx, 2
   mov rax, rbx
   xor rdx, rdx
   div rcx
   cmp rdx, 0
   jne .loop
   
   mov rax, rbx
   mov rsi, buffer
   call number_str

   mov rax, buffer
   call len_str
   mov rdx, rax
   mov [buffer+rdx],0x0a
   inc rdx

   mov rsi, buffer
   call print_str
   
   mov rax, 1
   mov rdi, r8
   mov rsi, buffer
   syscall
   jmp .loop 

.l2:  
  mov rdi, r8
  mov rax, 3
  syscall

.l1:
  call exit



print:
    push rcx
    mov [output], rax
    mov eax, 1
    mov edi, 1
    mov rsi, output
    mov edx, 1
    syscall
    pop rcx
    ret

print_num:
    xor rbx, rbx
    mov rcx, 10
    test rax, rax
    jns .loop
    push rax
    mov rax, '-'
    call print
    pop rax
    neg rax

.loop:
    xor rdx, rdx
    div rcx
    push rdx
    inc rbx
    cmp rax, 0
    jne .loop

.print_loop:
    pop rax
    add rax, 48
    call print
    dec rbx
    cmp rbx, 0
    jne .print_loop
    ret