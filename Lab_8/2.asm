format elf64

public _start

extrn printf
extrn scanf
extrn atof

section '.data' writable
input db "%lf", 0
output db "%-10d%-10d%-17lf%-15lf", 0xa, 0
text db "number    count     real cos         calc cos", 0xa, 0
const_1 dq 2.0

section '.bss' writable
const rq 1
cos rq 1
temp_sum rq 1
precesion rq 1
diff rq 1
number rq 1
count rq 1

section '.text' executable
_start:
    
    finit
    fldpi
    fld [const_1]
    fdiv st0, st1
    fstp [const]

    mov rdi, input
    mov rsi, precesion
    movq xmm0, rsi
    mov rax, 1
    call scanf

    mov rdi, text
    call printf

    mov [number], -1
    .loop:
        cmp [number], 5
        jg .end

        finit
        fild [number]
        fcos
        fstp [cos]

        mov [count], 0
        finit
        fld1
        fstp [temp_sum]

        .loop2:
            finit
            fld [temp_sum]
            fld [cos]
            fsub st0, st1
            fabs
            fstp [diff]

            finit
            fld [diff]
            fld [precesion]
            fcomip st0, st1
            ja .next

            inc [count]

            finit
            fild [count]
            fld [const_1]
            fmul st0, st1

            fld1
            fxch st1
            fsub st0, st1

            fild [number]
            fdiv st0, st1

            fld [const]
            fmul st0, st1

            fld st0
            fmul st0, st1

            fld1
            fsub st0, st1

            fld [temp_sum]
            fmul st0, st1
            fstp [temp_sum]

            jmp .loop2
  
.next:
    mov rdi, output
    mov rsi, [number]
    mov rdx, [count]
    mov rax, 2
    movq xmm0, [cos]
    movq xmm1, [temp_sum]
    call printf

    inc [number]
    jmp .loop

.end:
    mov rax, 60
    syscall