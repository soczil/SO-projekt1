SYS_READ       equ 0
SYS_WRITE      equ 1
SYS_EXIT       equ 60
STDIN          equ 0
STDOUT         equ 1
ARGC           equ 5
LOWER_BOUND    equ 49 
UPPER_BOUND    equ 90
BUFFER_SIZE    equ 4096
PERM_LENGTH    equ 42
PIVOT_POINT_1  equ 27 ; 'L' - '1'
PIVOT_POINT_2  equ 33 ; 'R' - '1'
PIVOT_POINT_3  equ 35 ; 'T' - '1'
CYLINDER_BOUND equ 41 ; Największa poprawna wartość bębenka.
REAL_PERM_LEN  equ 43 ; Długość permutacji razem ze znakiem końca napisu.

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
%macro CHECK_PIVOT_POINTS 0
  mov r8d, r14d ; Wartość bębenka L.
  inc r8d
  cmp r8d, CYLINDER_BOUND
  cmova r8d, r9d ; Jeśli wyszedł poza zakres, przypisz wartość 0.
  cmp r15d, PIVOT_POINT_1
  cmove r14d, r8d ; Obróć bębenek L, jeśli bębenek R osiągnął pozycję 'L'.
  cmp r15d, PIVOT_POINT_2
  cmove r14d, r8d ; Obróć bębenek L, jeśli bębenek R osiągnął pozycję 'R'.
  cmp r15d, PIVOT_POINT_3
  cmove r14d, r8d ; Obróć bębenek L, jeśli bębenek R osiągnął pozycję 'T'.
%endmacro

; Szyfruje bufor.
%macro CYPHER 0
  xor ebx, ebx   ; Licznik zaszyfrowanych znaków.
  xor r9d, r9d   ; Potrzebujemy wartości 0 na rejestrze, gdy bębenek się przekręci.
%%buff_loop:
  cmp rbx, rax
  je %%exit ; Zaszyfrowano wszystkie wczytane bajty, nie ma nic więcej do zrobienia.
  movzx ebp, byte [buffer + ebx] ; Kolejny znak do zaszyfrowania.
  call check_sign
  inc r15d  ; Obracanie bębenka R.
  cmp r15d, CYLINDER_BOUND
  cmova r15d, r9d ; Przypisz bębenkowi R wartość 0, jeśli wyszedł poza zakres.
  CHECK_PIVOT_POINTS
  mov r12d, r15d  ; Wartość bębenka R.
  call q_shift
  mov r13, [rsp + 8 * 3] ; Adres permutacji R.
  movzx ebp, byte [r13 + rbp - '1'] ; Szyfrowanie przy użyciu permutacji R.
  call q_shift_rev
  mov r12d, r14d ; Wartość bębenka L.
  call q_shift
  mov r13, [rsp + 8 * 2] ; Adres permutacji L.
  movzx ebp, byte [r13 + rbp - '1'] ; Szyfrowanie przy użyciu permutacji L.
  call q_shift_rev
  mov r13, [rsp + 8 * 4] ; Adres permutacji T.
  movzx ebp, byte [r13 + rbp - '1'] ; Szyfrowanie przy użyciu permutacji T.
  call q_shift
  movzx ebp, byte [rev_L + rbp - '1'] ; Szyfrowanie przy użyciu odwrotności permutacji L.
  call q_shift_rev
  mov r12d, r15d ; Wartość bębenka R.
  call q_shift
  movzx ebp, byte [rev_R + rbp - '1'] ; Szyfrowanie przy użyciu odwrotności permutacji R.
  call q_shift_rev
  mov byte [buffer + ebx], bpl ; Zapisz zaszyfrowany znak w bufferze.
  inc ebx
  jmp %%buff_loop
%%exit:
%endmacro

; Sprawdza, czy permutacja T jest złożeniem 21 cykli dwuelementowych.
%macro CHECK_T_PERMUTATION 0
  xor esi, esi
  mov esi, LOWER_BOUND
%%rev_Loop:
  cmp esi, UPPER_BOUND
  ja %%exit   ; Nie ma nic więcej do sprawdzenia.
  cmp sil, byte [r14 + rsi - '1']
  je error_exit ; Permutacja T zawiera punkt stały.
  movzx rcx, byte [r14 + rsi - '1']
  cmp sil, byte [r14 + rcx - '1']
  jne error_exit ; Dany cykl nie jest dwuelementowy.
  inc esi
  jmp %%rev_Loop
%%exit:
%endmacro

section .bss
  buffer: resb BUFFER_SIZE
  rev_L:  resb PERM_LENGTH
  rev_R:  resb PERM_LENGTH
  rev_T:  resb PERM_LENGTH

section .text
q_shift: ; Wykonuje cykliczne przesunięcie znaku w rejestrze ebp "w przód".
  add ebp, r12d ; Dodaj wartość bębenka L lub R do szyfrowanego znaku.
  mov ecx, ebp
  sub ecx, PERM_LENGTH  ; Odejmij 'Z' i dodaj '0' = odejmij 42.
  cmp ebp, UPPER_BOUND
  cmova ebp, ecx ; Przepisz nową wartość, gdy szyfrowany znak wyszedł poza skalę.
  ret
q_shift_rev: ; Wykonuje cykliczne przesunięcie znaku w rejestrze ebp "w tył".
  sub ebp, r12d ; Odejmij wartość bębenka L lub R od szyfrowanego znaku.
  mov ecx, ebp
  add ecx, PERM_LENGTH  ; Dodaj 'Z' i odejmij '0' = dodaj 42.
  cmp ebp, LOWER_BOUND
  cmovb ebp, ecx ; Przepisz nową wartość, gdy szyfrowany znak wyszedł poza skalę.
  ret
reverse_perm: ; Sprawdza poprawność permutacji, której adres jest w r14 i zapisuje jej odwrotność pod adres z r15.
  mov r8d, LOWER_BOUND
.arg_loop:
  movzx rbp, byte [r14 + r8 - '1']
  test ebp, ebp 
  jz .end               ; Napotkano znak końca napisu, koniec permutacji.
  call check_sign
  cmp byte [r15 + rbp - '1'], 0
  jne error_exit        ; Dwa takie same znaki w permutacji.
  mov byte [r15 + rbp - '1'], r8b ; Wstawiamy kolejny znak do odwrotności permutacji.
  inc r8d
  jmp .arg_loop
.end:
  cld
  xor al, al   ; Szukaj zera.
  mov ecx, REAL_PERM_LEN  ; Ogranicz przeszukiwanie do 43 znaków.
  mov rdi, r15 ; Ustaw adres, od którego rozpocząć szukanie.
  repne scasb  ; Szukaj bajtu o wartości 0.
  sub rdi, r15
  cmp rdi, REAL_PERM_LEN
  jne error_exit ; Permutacja nie ma 42 znaków.
  ret
check_sign: ; Sprawdza, czy znak w rejestrze ebp jest dozwolonym znakiem.
  cmp ebp, LOWER_BOUND
  jb error_exit         ; Znak <= '1'.
  cmp ebp, UPPER_BOUND
  ja error_exit         ; Znak >= 'Z'.
  ret
_start:
  cmp byte [rsp], ARGC  ; Pod rsp mamy wskaźnik na argc.         
  jne error_exit        ; Błędna liczba parametrów.
  xor r8, r8            ; Wyczyść r8, potrzebne do procedury reverse_perm.
  mov r14, [rsp + 8 * 2] ; Adres permutacji L.
  lea r15, [rev_L]       ; Adres odwrotności permutacji L.
  call reverse_perm      
  mov r14, [rsp + 8 * 3] ; Adres permutacji R.
  lea r15, [rev_R]       ; Adres odwrotności permutacji R.
  call reverse_perm
  mov r14, [rsp + 8 * 4] ; Adres permutacji T.
  lea r15, [rev_T]       ; Adres odwrotności permutacji T.
  call reverse_perm
  CHECK_T_PERMUTATION
  mov rsi, [rsp + 8 * 5] ; Adres klucza.
  movzx ebp, byte [rsi] ; Początkowa pozycja bębenka L.
  call check_sign
  mov r14d, ebp
  movzx ebp, byte [rsi + 1] ; Początkowa pozycja bębenka R.
  call check_sign
  mov r15d, ebp
  sub r14d, LOWER_BOUND     ; Zakres bębenków to 0 - 41.
  sub r15d, LOWER_BOUND
  cmp byte [rsi + 2], 0
  jne error_exit            ; Klucz ma więcej niż 2 elementy.
io_loop:
  READ_INPUT
  test rax, rax
  jz exit                   ; Koniec danych do wczytania, zakończ wykonanie programu.
  CYPHER
  PRINT buffer, rbx
  jmp io_loop
error_exit: ; Zakończenie wykonania programu z kodem 1.
  mov eax, SYS_EXIT
  mov edi, 1
  syscall
exit:       ; Poprawne zakończenie programu.
  mov eax, SYS_EXIT
  xor edi, edi
  syscall