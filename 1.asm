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

struc _main_stack
.p:   resq 1
.pad: resq 1
endstruc

; long@<rax> _abs(long@<rax>)
; Returns absolute value of a variable.
_abs:
  test  rax, rax
  jns   .ret
  neg   rax
.ret:
  ret

; long@<rax>, long@<rbx> _visit(<rdi> x, <rsi> y, <rdx> dir, <rcx> n)
_visit:
  ; r8: x direction
  ; r9: y direction
  ; r10: visited pointer
  mov   r8, qword dir_x_map
  movsx r8, byte [r8+rdx]
  mov   r9, qword dir_y_map
  movsx r9, byte [r9+rdx]
  mov   r11, qword visit_map

  .loop:
    test  rcx, rcx
    jz    .nohit
    ; Could use a bitmap, but at that time I'm getting tired, so bytemap it is.
    mov   r10, rdi
    add   r10, 100h
    imul  r10, 200h
    add   r10, 100h
    add   r10, rsi
    add   r10, r11
    movzx r11, byte [r10]
    test  r11, r11
    jnz   .hit
    mov   byte [r10], 1

    add   rdi, r8
    add   rsi, r9
    dec   rcx
    jmp   _visit
.hit:
  mov   rax, rdi
  mov   rbx, rsi
  ret
.nohit:
  mov   rax, 7fffffffh
  ret

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
  sub   rsp, sizeof(_main_stack)

  ; Open input file.
  mov   rdi, qword input_path
  mov   rsi, qword rb_mode
  call  _fopen
  mov   [qword input_file], rax
  test  rax, rax
  jz    .abort

  ; Read all the input file into a fixed size buffer.
  lea   rdi, [rel input_buffer]
  mov   rsi, 1000h
  mov   rdx, 1
  mov   rcx, [rel input_file]
  call  _fread
  add   rdi, rax
  mov   byte [rdi], 0

  ; Process the directions.
  ; r12:  direction
  ; r13: x
  ; r14: y
  mov   r8, qword input_buffer
  mov   [rsp+_main_stack.p], r8
  xor   r12, r12  ; North
  xor   r13, r13
  xor   r14, r14

.process_cmd:
  ; Apply new direction.
  mov   rcx, [rsp+_main_stack.p]
  mov   cl, byte [rcx]

  cmp  cl, 'L'
  jnz .right
  .left:
    mov   rcx, qword l_transition_map
    jmp   .move
  .right:
    cmp  cl, 'R'
    jnz .process_done
    mov   rcx, qword r_transition_map

  .move:
    movzx r12, byte [rcx + r12]

    ; Read the movement length.
    mov   rdi, [rsp+_main_stack.p]
    inc   rdi
    lea   rsi, [rsp+_main_stack.p]
    mov   rdx, 10
    call  _strtol
    mov   r15, rax

    ; Check if the path hit a previous path.
    mov   rdi, r13
    mov   rsi, r14
    mov   rdx, r12
    mov   rcx, r15
    call  _visit
    cmp   rax, 7fffffffh
    jnz   .hit

    ; Move x axis.
    mov   rdi, qword dir_x_map
    movsx rax, byte [rdi+r12]
    imul  r15
    add   r13, rax

    ; Move y axis.
    mov   rdi, qword dir_y_map
    movsx rax, byte [rdi+r12]
    imul  r15
    add   r14, rax

    ;mov rdx, r14
    ;mov rsi, r13
    ;mov rdi, qword debugf
    ;call _printf

    ; Go to next command.
    mov   rdi, [rsp+_main_stack.p]
    add   rdi, 2
    mov   [rsp+_main_stack.p], rdi
    jmp   .process_cmd

.hit:
  mov   r13, rax
  mov   r14, rbx

  ;mov rdx, r14
  ;mov rsi, r13
  ;mov rdi, qword debugf
  ;call _printf
.process_done:
  ; Sum absolute value of x and y.
  mov   rax, r13
  call  _abs
  mov   r13, rax

  mov   rax, r14
  call  _abs
  add   rax, r13

  mov rsi, rax
  mov rdi, qword resultf
  call _printf

.clean:
  mov   rdi, [rel input_file]
  call  _fclose

  mov   rax, 0
  pop   r14
  pop   r13
  pop   r12
  add   rsp, sizeof(_main_stack)
  pop   rcx
  pop   rbp
  lea   rsp, [rcx-8]
  ret

.abort:
  mov   rdi, 1
  call  _exit

section .bss
input_file: resq    1
input_buffer: resb  1000h
visit_map:  resb    40000h

section .data
input_path: db      "./1.txt", 0
rb_mode:    db      "rb", 0
resultf:    db      "Day 1.5: %d", 10, 0
debugf:     db      "[%d, %d]", 10, 0
; Directions:
; 0 = North
; 1 = East
; 2 = South
; 3 = West
r_transition_map: db 1, 2, 3, 0
l_transition_map: db 3, 0, 1, 2
dir_x_map    db      0, 1, 0, -1
dir_y_map    db      1, 0, -1, 0
