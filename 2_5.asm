%define sizeof(x) x %+ _size

extern _puts
extern _fopen
extern _fread
extern _fclose
extern _exit
extern _printf
extern _strtol

global _main

section .text

; Must be 16 bytes aligned.
struc _s
.input_file: resq 1
.code_buffer: resb 18h
.input_buffer: resb 1000h
endstruc

_main:
  ; Align the stack.
  lea   rcx, [rsp+8]
  and   rsp, 0xfffffff0
  push  qword [rcx-8]
  push  rbp
  mov   rbp, rsp
  push  rcx
  ; Save preserved registers.
  push  r12
  push  r13
  push  r14
  ; Allocate stack storage.
  sub   rsp, sizeof(_s)

  ; Open input file.
  mov   rdi, qword input_path
  mov   rsi, qword rb_mode
  call  _fopen
  mov   [rsp + _s.input_file], rax
  test  rax, rax
  jz    .abort

  ; Read all the input file into a fixed size buffer.
  lea   rdi, [rsp + _s.input_buffer]
  mov   rsi, 1
  mov   rdx, 1000h
  mov   rcx, [rsp + _s.input_file]
  call  _fread
  lea   rdi, [rsp + _s.input_buffer]
  add   rdi, rax
  mov   byte [rdi], 0

  ; Process the directions.
  ; rbx: input iterator
  ; r12: current position
  ; r13: code pointer
  lea   rbx, [rsp + _s.input_buffer]
  mov   r12, 4
  mov   qword [rsp + _s.code_buffer], 0
  mov   qword [rsp + _s.code_buffer + 8], 0
  mov   qword [rsp + _s.code_buffer + 10h], 0
  lea   r13, [rsp + _s.code_buffer]
.process_dir:
  ;mov   rsi, r12
  ;mov   rdi, qword debugf
  ;call  _printf

  mov   al, byte [rbx]
  test  al, al
  jz    .print_result
  ; Switch on DLRU
  cmp   al, 'L'
  jz    .L
  jb    .D_or_n
  cmp   al, 'R'
  jz    .R
  mov   rax, 0
  jmp   .next_state
.L:
  mov   rax, 3
  jmp   .next_state
.R:
  mov   rax, 1
  jmp   .next_state
.D_or_n:
  cmp   al, 'D'
  jnz   .n
  mov   rax, 2
  jmp   .next_state
.n:
  mov   rcx, r12
  cmp   rcx, 9
  jb    .num
  add   rcx, 56
  jmp   .output
.num:
  add   rcx, '1'
.output:
  mov   byte [r13], cl
  inc   r13
  inc   rbx
  jmp   .process_dir

.next_state:
  mov   rdx, qword transition_map
  mov   rcx, r12
  shl   rcx, 2
  add   rcx, rax
  movzx r12, byte [rdx+rcx]
  inc   rbx
  jmp   .process_dir

.print_result:
  lea   rsi, [rsp + _s.code_buffer]
  mov   rdi, qword resultf
  call  _printf

.clean:
  mov   rdi, [rsp + _s.input_file]
  call  _fclose

  mov   rax, 0
  pop   r14
  pop   r13
  pop   r12
  add   rsp, sizeof(_s)
  pop   rcx
  pop   rbp
  lea   rsp, [rcx-8]
  ret

.abort:
  mov   rdi, 1
  call  _exit

section .data
input_path: db      "./2.txt", 0
rb_mode:    db      "rb", 0
resultf:    db      "Day 2.5: %s", 10, 0
debugf:     db      "%d", 0
; Keypad:
;    1
;  2 3 4
;5 6 7 8 9
;  A B C
;    D
; Transition map
transition_map:
  ;  U, R, D, L
  db 0, 0, 2, 0 ; 1
  db 1, 2, 5, 1 ; 2
  db 0, 3, 6, 1 ; 3
  db 3, 3, 7, 2 ; 4
  db 4, 5, 4, 4 ; 5
  db 1, 6, 9 ,4 ; 6
  db 2, 7, 10,5 ; 7
  db 3, 8, 11,6 ; 8
  db 8, 8, 8, 7 ; 9
  db 5, 10,9, 9 ; A
  db 6, 11,12,9 ; B
  db 7, 11,11,10; C
  db 10,12,12,12; D

