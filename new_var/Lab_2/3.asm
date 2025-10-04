format ELF64

public _start
public exit
public print_symb

section '.bss' writable
  array db 29 dup ('|')          
  newline db 29 dup (0xA)  
  place db 1
  count dq 0                

section '.text' executable
  _start:
    xor r9, r9    

    .iter1:              
      xor rdi, rdi  

      mov rbx, [count]
      inc rbx
      mov [count], rbx  

      .iter2:
        mov al, [array + rdi]   
        call print_symb        
        inc rdi                
        cmp rdi, [count]           
        jne .iter2             

      ; вывод новой строки
      mov al, [newline + r9]    
      call print_symb            

      inc r9                  
      cmp r9, 10                
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