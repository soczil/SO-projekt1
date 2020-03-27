SYS_READ    equ 0
SYS_WRITE   equ 1
SYS_EXIT    equ 60
STDIN       equ 0
STDOUT      equ 1
ARGC        equ 5
LOWER_BOUND equ 49 
UPPER_BOUND equ 90

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
  mov rdx, 4096
  syscall
%endmacro

%macro INC_MOD 1
  inc %1
  cmp %1, 41
  ja %%fix
  jmp %%exit
%%fix:
  mov %1, 0
%%exit:
%endmacro

%macro CHECK_CYCLE_POINTS 0
  cmp byte [r], 27
  je %%inc_l
  cmp byte [r], 33
  je %%inc_l
  cmp byte [r], 35
  je %%inc_l
  jmp %%exit
%%inc_l:
  INC_MOD byte [l]
%%exit:
%endmacro

%macro CYPHER 0
  xor ebx, ebx
%%buff_loop:
  movzx ebp, byte [buffer + ebx]
  cmp rbx, rax
  je %%exit
  cmp bpl, 10
  je %%end_loop
  call check_sign
  INC_MOD byte [r]
  CHECK_CYCLE_POINTS
  mov r12B, byte [r]
  call q_shift
  movzx ebp, byte [r14 + rbp - '1']
  call q_shift_rev
  mov r12B, byte [l]
  call q_shift
  movzx ebp, byte [r13 + rbp - '1']
  call q_shift_rev
  movzx ebp, byte [r15 + rbp - '1']
  call q_shift
  movzx ebp, byte [rev_L + rbp - '1']
  call q_shift_rev
  mov r12B, byte [r]
  call q_shift
  movzx ebp, byte [rev_R + rbp - '1']
  call q_shift_rev
%%end_loop:
  mov byte [buffer + ebx], bpl
  inc ebx
  jmp %%buff_loop
%%exit:
%endmacro

%macro CHECK_T_PERMUTATION 0
  xor esi, esi
  mov sil, '1'
%%rev_Loop:
  cmp sil, 'Z'
  ja %%exit
  cmp sil, byte [r14 + rsi - '1']
  je error_exit
  movzx rcx, byte [r14 + rsi - '1']
  cmp sil, byte [r14 + rcx - '1']
  jne error_exit
  inc sil
  jmp %%rev_Loop
%%exit:
%endmacro

section .bss
  buffer: resb 4096
  l:      resb 1
  r:      resb 1
  jol:    resb 1
  rev_L:  resb 42
  rev_R:  resb 42
  rev_T:  resb 42

section .text
q_shift:
  add bpl, r12B
  cmp bpl, UPPER_BOUND
  ja .fix
  jmp .exit
.fix:
  sub bpl, UPPER_BOUND
  add bpl, '0'
.exit:
  ret
q_shift_rev:
  sub bpl, r12B
  cmp bpl, LOWER_BOUND
  jb .fix
  jmp .exit
.fix:
  sub bpl, '0'
  add bpl, UPPER_BOUND
.exit:
  ret
reverse_perm: ; zmiana
  mov r8b, LOWER_BOUND
.arg_loop:
  mov bpl, byte [r14 + r8 - '1']
  test bpl, bpl
  jz .end
  call check_sign
  sub bpl, LOWER_BOUND
  cmp byte [r15 + rbp], 0
  jne error_exit
  mov [r15 + rbp], r8b
  inc r8b
  jmp .arg_loop
.end:
  cld
  xor al, al
  mov ecx, 42
  mov rdi, r15
  repne scasb
  sub rdi, r15
  cmp rdi, 42
  jne error_exit
  ret
zero_perm:
  cld
  rep stosb
check_sign:
  cmp bpl, LOWER_BOUND
  jb error_exit
  cmp bpl, UPPER_BOUND
  ja error_exit
  ret
_start:
  cmp byte [rsp], ARGC          
  jne error_exit      ; Błędna liczba parametrów.
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
  mov bpl, byte [rsi]
  call check_sign
  mov [l], bpl
  mov bpl, [rsi + 1]
  call check_sign
  mov [r], bpl
  sub byte [l], LOWER_BOUND
  sub byte [r], LOWER_BOUND
  cmp byte [rsi + 2], 0
  jne error_exit
  mov r13, [rsp + 8 * 2] ; wskaźnik na permutację L
  mov r14, [rsp + 8 * 3] ; wskaźnik na permutację R
  mov r15, [rsp + 8 * 4] ; wskaźnik na permutację T
io_loop:
  READ_INPUT
  test rax, rax
  jz exit
  CYPHER
  PRINT buffer, rbx
  jmp io_loop
error_exit:
  mov eax, SYS_EXIT
  mov edi, 1
  syscall
exit:
  mov rax, SYS_EXIT
  xor edi, edi
  syscall