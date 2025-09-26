format ELF64

public _start
public print_symb

section '.data'
  string db 'PBREUSjkMUTGFNkuEzpyOMLGeDmEHCFHlF'

section '.bss' writable
  place db 1

section '.text' executable
  _start:
    mov rcx, 33

    .iter:
       mov al, [string+rcx]
       push rcx             
       call print_symb      
       pop rcx             
       dec rcx              
       cmp rcx, -1         
       jne .iter

    mov eax, 60       
    xor edi, edi       
    syscall            

print_symb:
  push rax
  mov eax, 1          
  mov edi, 1          
  pop rdx             
  mov [place], dl     
  mov rsi, place       
  mov edx, 1          
  syscall             
  ret
