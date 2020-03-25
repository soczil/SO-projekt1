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

; Sprawdza, czy znak podany jako argument jest znakiem dozwolonym.
%macro CHECK_SIGN 1
  cmp %1, lower_edge
  jb error_exit
  cmp %1, upper_edge
  ja error_exit
%endmacro

%macro REVERSE_PERM 2
  mov r8b, lower_edge
  mov rsi, %1
%%arg_loop:
  mov bl, byte [rsi]
  test bl, bl
  jz %%end
  CHECK_SIGN bl
  sub bl, lower_edge
  cmp byte [%2 + ebx], 0
  jne error_exit
  mov byte [%2 + ebx], r8b
  inc rsi
  inc r8b
  jmp %%arg_loop
%%end:
  cld
  xor al, al
  mov ecx, 42
  mov rdi, %2
  repne scasb
  sub rdi, %2
  cmp rdi, 42
  jne error_exit
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

%macro Q_SHIFT 1
  add al, %1
  cmp al, upper_edge
  ja %%fix
  jmp %%exit
%%fix:
  sub al, upper_edge
  add al, '0'
%%exit:
%endmacro

%macro Q_SHIFT_REV 1
  sub al, %1
  cmp al, lower_edge
  jb %%fix
  jmp %%exit
%%fix:
  sub al, '0'
  add al, upper_edge
%%exit:
%endmacro

%macro PERMUT 1
  movzx eax, byte [%1 + rax - '1']
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

%macro PRINT_JOL 0
  mov [jol], rax
  mov rsi, jol
  mov rax, 1
  mov rdi, 1
  mov rdx, 1
  syscall
  mov rax, jol
%endmacro

%macro CYPHER 0
  xor ebx, ebx
%%buff_loop:
  movzx eax, byte [buffer + ebx]
  test al, al
  jz %%exit
  cmp al, 10
  je %%end_loop
  CHECK_SIGN al
  INC_MOD byte [r]
  CHECK_CYCLE_POINTS
  Q_SHIFT [r]
  PERMUT r14
  Q_SHIFT_REV [r]
  Q_SHIFT [l]
  PERMUT r13
  Q_SHIFT_REV [l]
  PERMUT r15
  Q_SHIFT [l]
  PERMUT perm_l
  Q_SHIFT_REV [l]
  Q_SHIFT [r]
  PERMUT perm_r
  Q_SHIFT_REV [r]
%%end_loop:
  mov byte [buffer + ebx], al
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
_start:
  cmp byte [rsp], correct_argc          
  jne error_exit      ; Błędna liczba parametrów.
  REVERSE_PERM [rsp + 8 * 2], perm_l
  REVERSE_PERM [rsp + 8 * 3], perm_r
  REVERSE_PERM [rsp + 8 * 4], perm_t
last_arg:
  mov rsi, [rsp + 8 * 5]
  mov cl, [rsi]
  mov [l], cl
  mov cl, [rsi + 1]
  mov [r], cl
  CHECK_SIGN byte [l]
  CHECK_SIGN byte [r]
  sub byte [l], lower_edge
  sub byte [r], lower_edge
  cmp byte [rsi + 2], 0
  jne error_exit
io_loop:
  READ_INPUT
  test rax, rax
  jz exit
  mov r13, [rsp + 8 * 2] ; wskaźnik na permutację L
  mov r14, [rsp + 8 * 3] ; wskaźnik na permutację R
  mov r15, [rsp + 8 * 4] ; wskaźnik na permutację T
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