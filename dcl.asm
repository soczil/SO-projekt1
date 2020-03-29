SYS_READ    equ 0
SYS_WRITE   equ 1
SYS_EXIT    equ 60
STDIN       equ 0
STDOUT      equ 1
ARGC        equ 5
LOWER_BOUND equ 49 
UPPER_BOUND equ 90
BUFFER_SIZE equ 4096

; Wykonanie programu zaczyna się od etyiety _start.
global _start

; Wypisuje pierwszy argument na standardowe wyjście.
; Drugi argument to ilość bajtów do wypisania.
%macro PRINT 2
  mov rsi, %1
  mov eax, SYS_WRITE
  mov edi, STDOUT
  mov rdx, %2
  syscall
%endmacro

; Czyta ze standardowego wejścia.
%macro READ_INPUT 0
  mov eax, SYS_READ
  mov edi, STDIN
  mov rsi, buffer
  mov rdx, BUFFER_SIZE
  syscall
%endmacro

; Sprawdza, czy 'r' osiągnęło punkt obrotowy.
%macro CHECK_CYCLE_POINTS 0
  mov r8b, r14b 
  inc r8b
  cmp r8b, 41
  cmova r8d, r9d
  cmp r15b, 27
  cmove r14d, r8d
  cmp r15b, 33
  cmove r14d, r8d
  cmp r15b, 35
  cmove r14d, r8d
%endmacro

; Szyfruje bufor.
%macro CYPHER 0
  xor r9, r9
  xor ebx, ebx
%%buff_loop:
  movzx ebp, byte [buffer + ebx]
  cmp rbx, rax
  je %%exit
  cmp bpl, 10
  je %%end_loop
  call check_sign
  inc r15b
  cmp r15b, 41
  cmova r15d, r9d
  CHECK_CYCLE_POINTS
  mov r12b, r15b
  call q_shift
  mov r13, [rsp + 8 * 3]
  movzx ebp, byte [r13 + rbp - '1']
  call q_shift_rev
  mov r12b, r14b
  call q_shift
  mov r13, [rsp + 8 * 2]
  movzx ebp, byte [r13 + rbp - '1']
  call q_shift_rev
  mov r13, [rsp + 8 * 4]
  movzx ebp, byte [r13 + rbp - '1']
  call q_shift
  movzx ebp, byte [rev_L + rbp - '1']
  call q_shift_rev
  mov r12b, r15b
  call q_shift
  movzx ebp, byte [rev_R + rbp - '1']
  call q_shift_rev
%%end_loop:
  mov byte [buffer + ebx], bpl
  inc ebx
  jmp %%buff_loop
%%exit:
%endmacro

; Sprawdza, czy permutacja T jest złożeniem 21 cykli dwuelementowych.
%macro CHECK_T_PERMUTATION 0
  xor esi, esi
  mov esi, '1'
%%rev_Loop:
  cmp esi, 'Z'
  ja %%exit
  cmp sil, byte [r14 + rsi - '1']
  je error_exit
  movzx rcx, byte [r14 + rsi - '1']
  cmp sil, byte [r14 + rcx - '1']
  jne error_exit
  inc esi
  jmp %%rev_Loop
%%exit:
%endmacro

section .bss
  buffer: resb BUFFER_SIZE
  rev_L:  resb 42
  rev_R:  resb 42
  rev_T:  resb 42

section .text
q_shift:
  add bpl, r12b
  mov ecx, ebp
  sub ecx, 42
  cmp bpl, UPPER_BOUND
  cmova ebp, ecx
  ret
q_shift_rev:
  sub bpl, r12b
  mov ecx, ebp
  add ecx, 42
  cmp bpl, LOWER_BOUND
  cmovb ebp, ecx
  ret
reverse_perm: ; zmiana
  mov r8d, LOWER_BOUND
.arg_loop:
  movzx ebp, byte [r14 + r8 - '1']
  test ebp, ebp ; a moze test bpl, bpl
  jz .end
  call check_sign
  sub ebp, LOWER_BOUND
  cmp byte [r15 + rbp], 0
  jne error_exit
  mov [r15 + rbp], r8b
  inc r8d
  jmp .arg_loop
.end:
  cld
  xor al, al  ; Szukaj zera.
  mov ecx, 42
  mov rdi, r15
  repne scasb
  sub rdi, r15
  cmp rdi, 42
  jne error_exit
  ret
check_sign:
  cmp ebp, LOWER_BOUND
  jb error_exit
  cmp ebp, UPPER_BOUND
  ja error_exit
  ret
_start:
  cmp byte [rsp], ARGC ; Pod rsp mamy wskaźnik na argc.         
  jne error_exit       ; Błędna liczba parametrów.
  xor r8, r8
  mov r14, [rsp + 8 * 2]
  lea r15, [rev_L]
  call reverse_perm
  mov r14, [rsp + 8 * 3]
  lea r15, [rev_R]
  call reverse_perm
  mov r14, [rsp + 8 * 4]
  lea r15, [rev_T]
  call reverse_perm
  CHECK_T_PERMUTATION
last_arg:
  mov rsi, [rsp + 8 * 5]
  movzx ebp, byte [rsi] ; a moze mov bpl, [rsi]????????
  call check_sign
  mov r14d, ebp
  movzx ebp, byte [rsi + 1] ; tu moze tez???????????
  call check_sign
  mov r15d, ebp
  sub r14d, LOWER_BOUND
  sub r15d, LOWER_BOUND
  cmp byte [rsi + 2], 0
  jne error_exit
io_loop:
  READ_INPUT
  test rax, rax
  jz exit
  xor r9d, r9d
  CYPHER
  PRINT buffer, rbx
  jmp io_loop
error_exit:
  mov eax, SYS_EXIT
  mov edi, 1
  syscall
exit:
  mov eax, SYS_EXIT
  xor edi, edi
  syscall