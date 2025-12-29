format elf64

public _start

extrn tan
extrn printf
extrn scanf

section '.data' writable
    input db "%lf", 0
    output db "%-10d%-15.7f%-15d%-10.7f", 0xa, 0
    text db "number    real tan       count          calc tan", 0xa, 0
    
    prt db "%.16f", 0xa, 0
    depth       dq ?
    x_squared   dq ?
    current_val dq ?
    denom       dq ?
    remainder   dq ?
    error_est   dq ?
    next_term   dq ?
    actual_err  dq ?
    tangens dq 1
    precision dq 1
    number dq -1
    calculated dq 0.0
    one dq 1.0
    abs_mask dq 0x7FFFFFFFFFFFFFFF

section '.text' executable
_start:
    mov rdi, input
    mov rsi, precision
    movq xmm0, rsi
    mov rax, 1
    call scanf   ; читаем epsilon

    mov rdi, text
    call printf  ; заголовок

    .loop:
        cmp [number], 5  ; предел number
        jg exit

        cvtsi2sd xmm0, qword [number]

        call tan    ; настоящий тангенс
        movq [tangens], xmm0

        cvtsi2sd xmm0, [number]
        movq xmm1, [precision]
        mov rdi, -1
        call continued_fraction_tan   ; посчитанный тангенс
        
        mov rdi, output
        mov rsi, [number]
        mov rdx, [depth]
        mov rax, 2
        movq xmm0, [tangens]
        movq xmm1, [calculated]
        call printf            ; строка таблицы

        inc [number]
        jmp .loop
    
     call exit

;Input: - xmm0 = x, xmm1 = epsilon
;Output: rax
estimate_depth:
    push    rbp
    mov     rbp, rsp
    
    ; if (x < epsilon)
    comisd  xmm0, xmm1
    jb      .return_one
    
    movsd   [rbp-8], xmm0
    movsd   [rbp-16], xmm1
    
    movsd   xmm2, xmm0
    mulsd   xmm2, xmm0
    movsd   [x_squared], xmm2
    
    mov     rbx, 1
    
.loop:
    mov     rax, rbx        ; n
    shl     rax, 1          ; 2*n
    lea     rcx, [rax + 1]  ; 2*n + 1
    lea     rdx, [rax + 3]  ; 2*n + 3
    
    cvtsi2sd xmm3, rcx
    cvtsi2sd xmm4, rdx
    mulsd   xmm3, xmm4      ; (2*n+1)*(2*n+3)
    
    movsd   xmm4, [x_squared]
    divsd   xmm4, xmm3 
    movsd   [remainder], xmm4
    
    ;fabs(remainder * x / (1 - remainder))
    movsd   xmm0, [rbp-8]
    mulsd   xmm4, xmm0 
    
    movsd   xmm5, [remainder]
    movsd   xmm6, [one]
    subsd   xmm6, xmm5    ; 1 - remainder
    
    divsd   xmm4, xmm6
    movq xmm12, [abs_mask]
    andpd   xmm4, xmm12 ; fabs
    movsd   [error_est], xmm4
    
    movsd   xmm1, [rbp-16]    ; epsilon
    comisd  xmm4, xmm1
    jb      .break_loop
    
    inc     rbx
    jmp     .loop

.break_loop:
    mov     rax, rbx 
    jmp     .return

.return_one:
    mov     rax, 1

.return:
    pop     rbp
    ret


;Input: xmm0 = x, xmm1 = epsilon, rdi = max_depth
continued_fraction_tan:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    
    movsd   [rbp-8], xmm0 
    movsd   [rbp-16], xmm1
    mov     [rbp-24], rdi
    
    ; if (fabs(x) < epsilon)
    movsd   xmm2, xmm0
    movq xmm12, [abs_mask]
    andpd   xmm2, xmm12
    comisd  xmm2, xmm1
    jae     .not_small_x
    
    ; depth = 1, return x (tan(~0) = ~0)
    mov     qword [depth], 1
    movsd   [calculated], xmm0
    jmp     .return
    
.not_small_x:
    ; Проверяем max_depth == -1
    cmp     rdi, -1
    jne     .depth_provided
    
    ; max_depth = estimate_depth(x, epsilon)
    movsd   xmm0, [rbp-8]
    movsd   xmm1, [rbp-16]
    call    estimate_depth      ; результат в rax
    
    mov     [rbp-24], rax
    
.depth_provided:
    mov     r12, [rbp-24]      ; max_depth в r12
    
    ; x_squared = x * x
    movsd   xmm0, [rbp-8]
    movsd   xmm1, xmm0
    mulsd   xmm1, xmm0
    movsd   [x_squared], xmm1
    
    ; current_value = 2 * max_depth + 1
    mov     rax, r12
    shl     rax, 1
    inc     rax 
    cvtsi2sd xmm2, rax
    movsd   [current_val], xmm2
    
    ; for (int n = max_depth; n > 0; --n)
    mov     r13, r12
    
.for_loop:
    test    r13, r13
    jz      .end_for
    
    ; denominator = 2 * n + 1
    mov     rax, r13
    shl     rax, 1
    inc     rax
    cvtsi2sd xmm3, rax
    movsd   [denom], xmm3
    
    ; current_value = denominator - x_squared / current_value
    movsd   xmm4, [x_squared]
    divsd   xmm4, [current_val]
    movsd   xmm5, [denom]
    subsd   xmm5, xmm4
    movsd   [current_val], xmm5
    
    dec     r13
    jmp     .for_loop
    
.end_for:
    ; result = x / (1 - x_squared / current_value)
    movsd   xmm6, [x_squared]
    divsd   xmm6, [current_val]
    movsd   xmm7, [one]
    subsd   xmm7, xmm6          ; 1 - x_squared/current_value
    
    movsd   xmm0, [rbp-8]       ; x
    divsd   xmm0, xmm7          ; result
    movsd   xmm8, xmm0          ; rusult в xmm8
    
    ; next_term = x_squared / (2 * max_depth + 1)
    mov     rax, r12
    shl     rax, 1
    inc     rax 
    cvtsi2sd xmm9, rax
    movsd   xmm10, [x_squared]
    divsd   xmm10, xmm9
    movsd   [next_term], xmm10
    
    ; actual_error = fabs(next_term * result / (1 - next_term))
    mulsd   xmm10, xmm8         ; next_term * result
    movsd   xmm11, [next_term]
    movsd   xmm12, [one]
    subsd   xmm12, xmm11        ; 1 - next_term
    divsd   xmm10, xmm12
    
    movq xmm12, [abs_mask]
    andpd   xmm10, xmm12   ; fabs
    movsd   [actual_err], xmm10
    
    ; if (actual_error > epsilon)
    movsd   xmm1, [rbp-16]
    comisd  xmm10, xmm1
    jbe     .error_ok
    
    ; depth = max_depth * 2
    mov     rax, r12
    shl     rax, 1
    mov     [depth], rax
    
    ; return continued_fraction_tan(x, epsilon, max_depth * 2)
    movsd   xmm0, [rbp-8] 
    movsd   xmm1, [rbp-16]
    mov     rdi, rax
    call    continued_fraction_tan
    
    movsd   [calculated], xmm0
    jmp     .return
    
.error_ok:
    mov     [depth], r12
    
    movsd   [calculated], xmm8
    movsd   xmm0, xmm8

.return:
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

exit:
    mov rax, 60
    syscall