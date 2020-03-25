SYS_READ  equ 0
SYS_WRITE equ 1
SYS_EXIT  equ 60
STDIN     equ 0
STDOUT    equ 1

; Wykonanie programu zaczyna się od etyiety _start.
global _start

; Wypisuje pierwszy argument na standardowe wyjście.
; Drugi argument to ilość bajtów do wypisania.
%macro PRINT 2
  mov rsi, %1
  mov rax, SYS_WRITE
  mov rdi, STDOUT
  mov rdx, %2
  syscall
%endmacro

%macro READ_INPUT 0
  mov rax, SYS_READ
  mov rdi, STDIN
  mov rsi, buffer
  mov rdx, 4096
  syscall
%endmacro

%macro INC_MOD 1
  inc %1 ; dokonczyc
  cmp %1, 41
  ja %%fix
  jmp %%exit
%%fix:
  mov %1, 0
%%exit:
%endmacro

%macro PERMUT 1
  movzx ebp, byte [%1 + rbp - '1']
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
  test bpl, bpl
  jz %%exit
  cmp bpl, 10
  je %%end_loop
  call check_sign
  INC_MOD byte [r]
  CHECK_CYCLE_POINTS
  mov r12B, byte [r]
  call q_shift
  PERMUT r14
  call q_shift_rev
  mov r12B, byte [l]
  call q_shift
  PERMUT r13
  call q_shift_rev
  PERMUT r15
  call q_shift
  PERMUT perm_l
  call q_shift_rev
  mov r12B, byte [r]
  call q_shift
  PERMUT perm_r
  call q_shift_rev
%%end_loop:
  mov byte [buffer + ebx], bpl
  inc ebx
  jmp %%buff_loop
%%exit:
%endmacro

section .rodata
  new_line db `\n`

section .bss
  buffer: resb 4096
  l:      resb 1
  r:      resb 1
  jol:    resb 1

section .data
  ; Poprawna liczba argumentów to 4, ale jeszcze nazwa programu.
  correct_argc     equ 5
  lower_edge       equ 49 
  upper_edge       equ 90
  perm_l: times 42 db 0
  perm_r: times 42 db 0
  perm_t: times 42 db 0

section .text
q_shift:
  add bpl, r12B
  cmp bpl, upper_edge
  ja .fix
  jmp .exit
.fix:
  sub bpl, upper_edge
  add bpl, '0'
.exit:
  ret
q_shift_rev:
  sub bpl, r12B
  cmp bpl, lower_edge
  jb .fix
  jmp .exit
.fix:
  sub bpl, '0'
  add bpl, upper_edge
.exit:
  ret
reverse_perm:
  mov r8b, lower_edge
  mov rsi, r14
arg_loop:
  mov bpl, byte [rsi]
  test bpl, bpl
  jz end
  call check_sign
  sub bpl, lower_edge
  cmp byte [r15 + rbp], 0
  jne error_exit
  mov [r15 + rbp], r8b
  inc rsi
  inc r8b
  jmp arg_loop
end:
  cld
  xor al, al
  mov ecx, 42
  mov rdi, r15
  repne scasb
  sub rdi, r15
  cmp rdi, 42
  jne error_exit
  ret
check_sign:
  cmp bpl, lower_edge
  jb error_exit
  cmp bpl, upper_edge
  ja error_exit
  ret
_start:
  cmp byte [rsp], correct_argc          
  jne error_exit      ; Błędna liczba parametrów.
  mov r14, [rsp + 8 * 2]
  lea r15, [perm_l]
  call reverse_perm
  mov r14, [rsp + 8 * 3]
  lea r15, [perm_r]
  call reverse_perm
  mov r14, [rsp + 8 * 4]
  lea r15, [perm_t]
  call reverse_perm
last_arg:
  mov rsi, [rsp + 8 * 5]
  mov bpl, [rsi]
  call check_sign
  mov [l], bpl
  mov bpl, [rsi + 1]
  call check_sign
  mov [r], bpl
  sub byte [l], lower_edge
  sub byte [r], lower_edge
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
  mov rax, SYS_EXIT
  mov rdi, 1
  syscall
exit:
  mov rax, SYS_EXIT
  mov rdi, 0
  syscall