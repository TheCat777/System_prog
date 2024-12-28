format elf64

public _start

include '/workspaces/System_programming/Lab_5/func.asm'

section '.bss' writable
buffer rb 200
pid rq 1
status rd 1
args rq 4
inp db "input.txt", 0
outp db "output.txt", 0
	
section '.text' executable
_start:	
main_loop:
mov rsi, buffer
call input_keyboard
mov rax, 57
syscall
cmp rax, 0
jne wait_up
mov [args], buffer
mov [args+8], inp
mov [args+16], outp
mov [args+24], 0
mov rsi, args
mov rdi, buffer
mov rax, 59
syscall
call exit

wait_up:
mov rdi, -1
mov rsi, status
mov rdx, 0
mov r10, 0
mov rax, 61
syscall
jmp main_loop