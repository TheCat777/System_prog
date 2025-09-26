format ELF64

public _start
public exit
public print_symb

section '.bss' writable
  array db 15 dup ('!')
  newline db 29 dup (0xA)
  place db 1

section '.text' executable
  _start:
    xor rdi, rdi
    .iter1:
      xor rbp, rbp  
      .iter2:
        mov al, [array+rbp]
        push rbp
        call print_symb
        pop rbp
        inc rbp
        cmp rbp,15
        jne .iter2

      mov al, [newline+rdi]
      push rdi
      call print_symb
      pop rdi

      inc rdi
      cmp rdi,29
      jne .iter1
    call exit

print_symb:
  push rax           
  mov [place], al    
  mov eax, 4         
  mov ebx, 1         
  mov ecx, place     
  mov edx, 1        
  int 0x80           
  pop rax            
  ret

exit:
  mov eax, 1         
  mov ebx, 0         
  int 0x80