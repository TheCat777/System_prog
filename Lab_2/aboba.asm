format ELF64
public _start

input dq 255

_start:
    call read
    call str_number
    call func
    mov rax, rsi
    call print
    call exit

; input:  rax
; output: rsi
func:
    mov rax, rax
    mov rcx, 10
    xor rbx, rbx
    mov rdi, 1 
    xor rsi, rsi 
    iter0:
        xor rdx, rdx
        div rcx

        push rax

        xor rbp, rbp 
        .zero:
            inc rbp
            mov rax, 10 ; rdx *= 10
            mov rdx, rdx
            mul rdx

            mov rdx, rax

            cmp rdi, rbp
            jne .zero
        add rsi, rdx
        pop rax
        inc rbx
        inc rdi
        inc rdi
        cmp rax, 0
        jne iter0

    ret


read:
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 255
    syscall
    ret


place db ?
print:
    mov rcx, 10
    xor rbx, rbx
    iter1:
        xor rdx, rdx
        div rcx
        add rdx, '0'
        push rdx
        inc rbx
        cmp rax, 0
    jne iter1
    iter2:
        pop rax
        call print_symbl
        dec rbx
        cmp rbx, 0
    jne iter2
 mov rax, 0xA
 call print_symbl
 ret

print_symbl:
    push rbx
    push rdx
    push rcx
    push rax
    push rax
    mov rax, 4
    mov rbx, 1
    pop rdx
    mov [place], dl
    mov rcx, place
    mov rdx, 1
    int 0x80
    pop rax
    pop rcx
    pop rdx
    pop rbx
    ret

;Function converting the string to the number
;input rsi - place of memory of begin string
;output rax - the number from the string
str_number:
    push rcx
    push rbx
    xor rax,rax
    xor rcx,rcx
.loop:
    xor     rbx, rbx
    mov     bl, byte [rsi+rcx]
    cmp     bl, 48
    jl      .finished
    cmp     bl, 57
    jg      .finished
    sub     bl, 48
    add     rax, rbx
    mov     rbx, 10
    mul     rbx
    inc     rcx
    jmp     .loop
.finished:
    cmp     rcx, 0
    je      .restore
    mov     rbx, 10
    div     rbx
.restore:
    pop rbx
    pop rcx
    ret

exit:
    mov rax, 60
    xor rdi, rdi
    syscall