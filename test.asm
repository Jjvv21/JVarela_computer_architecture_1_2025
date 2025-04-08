BITS 32
GLOBAL _start

SECTION .data
    filename_in  db "input.txt", 0
    filename_out db "output.txt", 0
    file_mode_in  dd 0          ; O_RDONLY
    file_mode_out dd 0x241      ; O_WRONLY | O_CREAT | O_TRUNC
    scale         dd 4.0        ; Factor de escala
    width         dd 97         ; Ancho original
    height        dd 97         ; Alto original
    new_width     dd 388        ; Nuevo ancho (97 * 4)
    new_height    dd 388        ; Nuevo alto (97 * 4)
    newline       db 10
    space         db 32

SECTION .bss
    buffer_in     resb 65536    ; Buffer para leer input.txt (64 KB)
    bytes_read    resd 1        ; Cantidad de bytes leídos
    image_orig    resb 9409     ; 97x97 = 9409 bytes
    image_scaled  resb 150544   ; 388x388 = 150544 bytes
    fd_in         resd 1
    fd_out        resd 1
    x_float       resd 1
    y_float       resd 1
    x0            resd 1
    y0            resd 1
    x1            resd 1
    y1            resd 1
    disx          resd 1
    disy          resd 1
    p00           resb 1
    p10           resb 1
    p01           resb 1
    p11           resb 1
    result        resd 1
    temp          resd 1
    temp2         resd 1
    term1         resd 1
    term2         resd 1
    term3         resd 1
    term4         resd 1
    temp_int      resd 1        ; Temporal para fild
    temp_counter  resd 1        ; Temporal para contadores
    num_str       resb 4        ; Buffer para conversión a string

SECTION .text
_start:
    ; Inicializar image_orig con ceros
    mov edi, image_orig
    mov ecx, 9409               ; 97*97
    xor eax, eax
    rep stosb

    ; Abrir input.txt
    mov eax, 5
    mov ebx, filename_in
    mov ecx, [file_mode_in]
    int 0x80
    mov [fd_in], eax
    cmp eax, 0
    jl error_exit_input_open

    ; Leer archivo
    mov eax, 3
    mov ebx, [fd_in]
    mov ecx, buffer_in
    mov edx, 65536              ; Tamaño del buffer
    int 0x80
    mov [bytes_read], eax
    cmp eax, 0
    jle error_exit_input_read

    ; Parsear buffer_in y llenar image_orig
    call parse_input

    ; Cerrar input.txt
    mov eax, 6
    mov ebx, [fd_in]
    int 0x80

    ; Aplicar interpolación bilineal
    call bilinear_interpolation

    ; Abrir output.txt
    mov eax, 5
    mov ebx, filename_out
    mov ecx, [file_mode_out]
    mov edx, 0o644
    int 0x80
    mov [fd_out], eax
    cmp eax, 0
    jl error_exit_output_open

    ; Escribir image_scaled en output.txt
    call write_output

    ; Cerrar output.txt
    mov eax, 6
    mov ebx, [fd_out]
    int 0x80

    ; Salir normalmente
    mov eax, 1
    xor ebx, ebx
    int 0x80

error_exit_input_open:
    mov eax, 1
    mov ebx, 1
    int 0x80

error_exit_input_read:
    mov eax, 1
    mov ebx, 2
    int 0x80

error_exit_output_open:
    mov eax, 1
    mov ebx, 3
    int 0x80

error_exit_parse:
    mov eax, 1
    mov ebx, 4
    int 0x80

error_exit_index:
    mov eax, 1
    mov ebx, 5
    int 0x80

; Subrutina para parsear input.txt
parse_input:
    pusha
    mov esi, 0                  ; Índice en image_orig
    mov edi, buffer_in          ; Puntero al buffer
    xor ecx, ecx                ; Contador de bytes procesados
parse_loop:
    cmp esi, 9409               ; 97*97
    jge parse_done
    cmp ecx, [bytes_read]
    jge parse_done

    movzx eax, byte [edi]
    cmp eax, 32
    je skip_space_or_newline
    cmp eax, 10
    je skip_space_or_newline
    cmp eax, 0
    je parse_done

    push ecx
    call parse_number
    pop ecx
    cmp ebx, 255
    ja skip_invalid
    mov [image_orig + esi], bl
    inc esi
    jmp parse_loop

skip_space_or_newline:
    inc edi
    inc ecx
    jmp parse_loop

skip_invalid:
    movzx eax, byte [edi]
    cmp eax, 32
    je parse_loop
    cmp eax, 10
    je parse_loop
    cmp eax, 0
    je parse_done
    inc edi
    inc ecx
    cmp ecx, [bytes_read]
    jge parse_done
    jmp skip_invalid

parse_done:
    popa
    ret

; Subrutina para parsear un número
parse_number:
    xor ebx, ebx
    xor edx, edx
parse_num_loop:
    cmp ecx, [bytes_read]
    jge parse_num_end
    movzx eax, byte [edi]
    cmp eax, 32
    je parse_num_end
    cmp eax, 10
    je parse_num_end
    cmp eax, 0
    je parse_num_end
    cmp eax, '0'
    jl parse_num_end
    cmp eax, '9'
    jg parse_num_end
    sub eax, '0'
    imul ebx, 10
    add ebx, eax
    inc edi
    inc ecx
    inc edx
    cmp edx, 3
    jge parse_num_end
    jmp parse_num_loop
parse_num_end:
    inc edi
    inc ecx
    ret

; Subrutina para interpolación bilineal
bilinear_interpolation:
    pusha
    xor esi, esi
outer_loop:
    cmp esi, [new_height]       ; 388
    jge end_outer
    
    xor edi, edi
inner_loop:
    cmp edi, [new_width]        ; 388
    jge end_inner

    mov [temp_counter], esi
    fild dword [temp_counter]
    fdiv dword [scale]
    fstp dword [x_float]

    mov [temp_counter], edi
    fild dword [temp_counter]
    fdiv dword [scale]
    fstp dword [y_float]

    fld dword [x_float]
    fisttp dword [x0]

    fld dword [y_float]
    fisttp dword [y0]

    mov eax, [x0]
    inc eax
    cmp eax, [height]
    jl no_clamp_x
    mov eax, [height]
    dec eax
no_clamp_x:
    mov [x1], eax

    mov eax, [y0]
    inc eax
    cmp eax, [width]
    jl no_clamp_y
    mov eax, [width]
    dec eax
no_clamp_y:
    mov [y1], eax

    fld dword [x_float]
    fisub dword [x0]
    fstp dword [disx]

    fld dword [y_float]
    fisub dword [y0]
    fstp dword [disy]

    mov eax, [x0]
    mov ebx, [width]
    mul ebx
    add eax, [y0]
    cmp eax, 9409               ; 97*97
    jae error_exit_index
    movzx ebx, byte [image_orig + eax]
    mov [p00], bl

    mov eax, [x1]
    mov ebx, [width]
    mul ebx
    add eax, [y0]
    cmp eax, 9409
    jae error_exit_index
    movzx ebx, byte [image_orig + eax]
    mov [p10], bl

    mov eax, [x0]
    mov ebx, [width]
    mul ebx
    add eax, [y1]
    cmp eax, 9409
    jae error_exit_index
    movzx ebx, byte [image_orig + eax]
    mov [p01], bl

    mov eax, [x1]
    mov ebx, [width]
    mul ebx
    add eax, [y1]
    cmp eax, 9409
    jae error_exit_index
    movzx ebx, byte [image_orig + eax]
    mov [p11], bl

    fld1
    fsub dword [disx]
    fstp dword [temp]

    fld1
    fsub dword [disy]
    fstp dword [temp2]

    movzx eax, byte [p00]
    mov [temp_int], eax
    fild dword [temp_int]
    fmul dword [temp]
    fmul dword [temp2]
    fstp dword [term1]

    movzx eax, byte [p10]
    mov [temp_int], eax
    fild dword [temp_int]
    fmul dword [disx]
    fmul dword [temp2]
    fstp dword [term2]

    movzx eax, byte [p01]
    mov [temp_int], eax
    fild dword [temp_int]
    fmul dword [temp]
    fmul dword [disy]
    fstp dword [term3]

    movzx eax, byte [p11]
    mov [temp_int], eax
    fild dword [temp_int]
    fmul dword [disx]
    fmul dword [disy]
    fstp dword [term4]

    fld dword [term1]
    fadd dword [term2]
    fadd dword [term3]
    fadd dword [term4]
    fistp dword [result]

    mov eax, esi
    mov ebx, [new_width]
    mul ebx
    add eax, edi
    cmp eax, 150544             ; 388*388
    jae error_exit_index
    mov bl, [result]
    mov [image_scaled + eax], bl

    inc edi
    jmp inner_loop

end_inner:
    inc esi
    jmp outer_loop

end_outer:
    popa
    ret

; Subrutina para escribir output.txt
write_output:
    pusha
    xor esi, esi
write_outer:
    cmp esi, [new_height]       ; 388
    jge write_done

    xor edi, edi
write_inner:
    cmp edi, [new_width]        ; 388
    jge write_end_inner

    mov eax, esi
    mov ebx, [new_width]
    mul ebx
    add eax, edi
    cmp eax, 150544             ; 388*388
    jae error_exit_index
    movzx eax, byte [image_scaled + eax]
    call int_to_string

    mov eax, 4
    mov ebx, [fd_out]
    mov ecx, num_str
    mov edx, 4
    int 0x80

    cmp edi, 387                ; Última columna (388-1)
    je no_space
    mov eax, 4
    mov ebx, [fd_out]
    mov ecx, space
    mov edx, 1
    int 0x80
no_space:
    inc edi
    jmp write_inner

write_end_inner:
    mov eax, 4
    mov ebx, [fd_out]
    mov ecx, newline
    mov edx, 1
    int 0x80

    inc esi
    jmp write_outer

write_done:
    popa
    ret

; Subrutina para convertir entero a string
int_to_string:
    pusha
    mov edi, num_str + 3
    mov byte [edi], 32
    mov ecx, 10
    mov ebx, eax
    test ebx, ebx
    jnz convert_loop
    mov byte [edi-1], '0'
    jmp convert_end

convert_loop:
    test ebx, ebx
    jz convert_end
    xor edx, edx
    mov eax, ebx
    div ecx
    add dl, '0'
    dec edi
    mov [edi], dl
    mov ebx, eax
    jmp convert_loop

convert_end:
    mov ecx, num_str
    cmp edi, ecx
    jg fill_spaces
    mov edi, ecx
fill_spaces:
    cmp edi, num_str
    je convert_done
    dec edi
    mov byte [edi], 32
    jmp fill_spaces

convert_done:
    popa
    ret
