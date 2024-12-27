format elf64
public _start

include 'func.asm'

input dq ?
output dq ?

buffer rb 2
buffer2 rb 2

_start:
    pop rcx     ;читаем количество параметров командной строки
    cmp rcx, 3  ;если один параметр(имя исполняемого файла)
    jne l1      ;завершаем работу

    mov rdi,[rsp+8]     ;загружаем адрес имени файла из стека
    mov r9, [rsp+16]    ;загружаемадрес файла для записи

    mov rax, 2          ;системный вызов открытия файла
    mov rsi, 0o         ;Права только на чтение
    syscall
    cmp rax, 0          ;если вернулось отрицательное значение,
    jl l1              ;то произошла ошибка открытия файла, также завершаем работу

    mov r8, rax         ;сохраняем файловый дескриптор

    .loop_read:         ;начинаем цикл чтения из файла
        mov rax, 0      ;номер системного вызова чтения
        mov rdi, r8     ;загружаем файловый дескриптор
        mov rsi, buffer ;указываем, куда помещать прочитанные данные
        mov rdx, 1      ;устанавливаем количество считываемых данных
        syscall         ;выполняем системный вызов read
        cmp rax, 0      ;если прочитано 0 байт, то достигли конца файла

        je eclose       ;выходим из цикла чтения

        mov byte [rsi+rax], 0   ;добавляем в буффер конец строки

        xor rax, rax
        .find:
            mov bl, byte [rsi]
            movzx rax, bl
            mov r10, rax      ; символ из первого файла сохраняем в r10

            mov rbx, r10

            cmp r10, '0'
            je .write
            cmp r10, '1'
            je .write
            cmp r10, '2'
            je .write
            cmp r10, '3'
            je .write
            cmp r10, '4'
            je .write
            cmp r10, '5'
            je .write
            cmp r10, '6'
            je .write
            cmp r10, '7'
            je .write
            cmp r10, '8'
            je .write
            cmp r10, '9'
            je .write

        jmp .loop_read  ;продолжаем цикл чтения
    call eclose

.write:
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

    ;;Сохраняем файловый дескриптор
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
    jmp .loop_read


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