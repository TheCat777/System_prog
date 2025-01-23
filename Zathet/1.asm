format elf64
public _start

include 'func.asm'


section '.bss' writable
    buffer rb 100
    status rd 1
    input dq ?
    output dq ?
    ARRLEN = 1000
    array rb ARRLEN
    space db " ", 0
    zero dq ?

    count rq 0

    buffer2 db 1
    buffer3 rb 200
    buffer7 rb 100

    buffer_space db " ", 0

    number rb 0
    const = 10

    output_name dq ?

section '.text' executable
_start:
    pop rcx 
    cmp rcx, 2
    jne l1
    mov rdi,[rsp+8]

    mov [zero], 48

    mov rax, 2          ;системный вызов открытия файла
    mov rsi, 0o         ;Права только на чтение
    syscall
    cmp rax, 0          ;если вернулось отрицательное значение,
    jl l1              ;то произошла ошибка открытия файла, также завершаем работу

    mov r8, rax         ;сохраняем файловый дескриптор
    xor r9, r9
    mov [number], 0
    xor r9, r9

    .loop_read:         ;начинаем цикл чтения из файла
        mov rax, 0      ;номер системного вызова чтения
        mov rdi, r8     ;загружаем файловый дескриптор
        mov rsi, buffer ;указываем, куда помещать прочитанные данные
        mov rdx, 1      ;устанавливаем количество считываемых данных
        syscall         ;выполняем системный вызов read
        cmp rax, 0      ;если прочитано 0 байт, то достигли конца файла

        je .temp      ;выходим из цикла чтения

        mov byte [rsi+rax], 0   ;добавляем в буффер конец строки

        xor rax, rax
        .find:
            mov bl, byte [rsi]
            movzx rax, bl
            mov r10, rax      ; символ из первого файла сохраняем в r10

            cmp r10, " "
            je add_num
            cmp r10, " "
            jne add_buf

        jmp .loop_read  ;продолжаем цикл чтения
    .temp:
    xor rax, rax
    mov al, [number]
    mov [array + 8*r9], al
    xor rax, rax
    mov al, [array + 8*r9]

    inc r9
    mov [number], 0

    xor r8, r8
    l:
        mov al, [array + 8*r8]
        call print_num
        call new_line
        inc r8
        cmp r8, r9
        jne l 

    call new_line
    mov [count], r9


    .filter_loop:
        call filter
        cmp rax, 0
        jne .filter_loop


    mov r9, [count]
    mov rax, r9
    call print_num
    call new_line
    call new_line
    xor r8, r8
    xor rax, rax
    l2:
        mov al, [array + 8*r8]
        call print_num
        call new_line
        
        inc r8
        cmp r8, r9
        jne l2 
    call write
    call eclose

add_num:
    xor rax, rax
    mov al, [number]
    mov [array + 8*r9], al
    xor rax, rax
    mov al, [array + 8*r9]

    inc r9
    mov [number], 0
    jmp _start.loop_read

add_buf:
    xor rax, rax
    xor rdx, rdx
    mov al, [number]
    mov rdx, const
    mul rdx
    mov rdx, rax
    mov rax, r10
    sub rax, [zero]
    add rax, rdx
    mov [number], al
    jmp _start.loop_read


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

filter:
    xor rax, rax
    mov rsi, array
    mov rcx, r9
    dec rcx
    .check:
        mov rdx, [rsi]
        mov rbx, [rsi+8]
        cmp rdx, rbx
        jbe .ok

        mov [rsi], rbx
        mov [rsi+8], rdx
        inc rax

        .ok:
        inc rsi
        inc rsi
        inc rsi
        inc rsi
        inc rsi
        inc rsi
        inc rsi
        inc rsi
    loop .check
    ret


write:

    mov rsi, buffer3
    call input_keyboard


    mov rdi, buffer3
    mov rax, 2
    mov rsi, 1078
    mov rdx, 777o
    syscall
    
    cmp rax, 0
    jl l1

    ;;Сохраняем файловый дескриптор
    mov r8, rax


    dec r9
    mov r10, r9

    mov rsi, rbx
    .loop_3:
        xor rax, rax
        mov al, [array+8*r9]
        mov rsi, buffer7
        call number_str

        mov rax, buffer7
        call len_str
        mov rdx, rax
        mov [buffer7+rdx], 0x0a
        inc rdx

        ;mov rsi, buffer7
        ;call print_str
        
        mov rax, 1
        mov rdi, r8
        mov rsi, buffer7
        syscall

        ;mov rsi, buffer_space
        ;syscall


        dec r9
        cmp r9, 0
        jnl .loop_3

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