BITS 32
GLOBAL _start

SECTION .data
    filename_in  db "input.txt", 0
    filename_out db "output.txt", 0
    file_mode_in  dd 0          ; Modo lectura (O_RDONLY)
    file_mode_out dd 0x241      ; Modo escritura (O_WRONLY | O_CREAT | O_TRUNC)
    scale         dd 4.0        ; Factor de escala
    width         dd 100        ; Ancho original
    height        dd 100        ; Alto original
    new_width     dd 400        ; Nuevo ancho (100 * 4)
    new_height    dd 400        ; Nuevo alto (100 * 4)
    newline       db 10         ; Salto de línea
    space         db 32         ; Espacio

SECTION .bss
    buffer_in     resb 65536    ; Buffer para leer input.txt (64 KB)
    bytes_read    resd 1        ; Cantidad de bytes leídos
    image_orig    resb 10000    ; Imagen original: 100x100 = 10000 bytes
    image_scaled  resb 160000   ; Imagen escalada: 400x400 = 160000 bytes
    fd_in         resd 1        ; Descriptor de archivo de entrada
    fd_out        resd 1        ; Descriptor de archivo de salida
    x_float       resd 1        ; Coordenada x flotante
    y_float       resd 1        ; Coordenada y flotante
    x0            resd 1        ; x0 entero
    y0            resd 1        ; y0 entero
    x1            resd 1        ; x1 entero
    y1            resd 1        ; y1 entero
    disx          resd 1        ; Distancia fraccional en x
    disy          resd 1        ; Distancia fraccional en y
    p00           resb 1        ; Píxel en (x0, y0)
    p10           resb 1        ; Píxel en (x1, y0)
    p01           resb 1        ; Píxel en (x0, y1)
    p11           resb 1        ; Píxel en (x1, y1)
    result        resd 1        ; Resultado de interpolación
    temp          resd 1        ; Temporal para cálculos
    temp2         resd 1        ; Segundo temporal
    term1         resd 1        ; Término 1 de interpolación
    term2         resd 1        ; Término 2
    term3         resd 1        ; Término 3
    term4         resd 1        ; Término 4
    temp_int      resd 1        ; Temporal para conversión a entero
    temp_counter  resd 1        ; Contador temporal
    num_str       resb 4        ; Buffer para conversión a string

SECTION .text
_start:
    ; Inicializar image_orig con ceros
    mov edi, image_orig
    mov ecx, 10000              ; Tamaño de la imagen original (100*100)
    xor eax, eax
    rep stosb

    ; Abrir input.txt
    mov eax, 5                  ; Syscall: open
    mov ebx, filename_in
    mov ecx, [file_mode_in]
    int 0x80
    mov [fd_in], eax
    cmp eax, 0
    jl error_exit_input_open

    ; Leer archivo
    mov eax, 3                  ; Syscall: read
    mov ebx, [fd_in]
    mov ecx, buffer_in
    mov edx, 65536              ; Tamaño del buffer
    int 0x80
    mov [bytes_read], eax
    cmp eax, 0
    jle error_exit_input_read

    call parse_input            ; Parsear input.txt

    ; Cerrar input.txt
    mov eax, 6                  ; Syscall: close
    mov ebx, [fd_in]
    int 0x80

    call bilinear_interpolation ; Aplicar interpolación bilineal

    ; Abrir output.txt
    mov eax, 5                  ; Syscall: open
    mov ebx, filename_out
    mov ecx, [file_mode_out]
    mov edx, 0o644              ; Permisos 644
    int 0x80
    mov [fd_out], eax
    cmp eax, 0
    jl error_exit_output_open

    call write_output           ; Escribir resultado en output.txt

    ; Cerrar output.txt
    mov eax, 6                  ; Syscall: close
    mov ebx, [fd_out]
    int 0x80

    ; Salir
    mov eax, 1                  ; Syscall: exit
    xor ebx, ebx                ; Código de salida 0
    int 0x80

; Manejo de errores
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
    cmp esi, 10000              ; Límite de la imagen original (100*100)
    jge parse_done
    cmp ecx, [bytes_read]
    jge parse_done

    movzx eax, byte [edi]
    cmp eax, 32                 ; Espacio
    je skip_space_or_newline
    cmp eax, 10                 ; Nueva línea
    je skip_space_or_newline
    cmp eax, 0                  ; Fin de buffer
    je parse_done

    push ecx
    call parse_number           ; Convertir texto a número
    pop ecx
    cmp ebx, 255                ; Validar rango de píxel (0-255)
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

; Subrutina para parsear un número desde texto
parse_number:
    xor ebx, ebx                ; Acumulador del número
    xor edx, edx                ; Contador de dígitos
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
    cmp edx, 3                  ; Máximo 3 dígitos
    jge parse_num_end
    jmp parse_num_loop
parse_num_end:
    inc edi
    inc ecx
    ret

; Subrutina para interpolación bilineal
bilinear_interpolation:
    pusha
    xor esi, esi                ; Contador de filas
outer_loop:
    cmp esi, [new_height]       ; Hasta 400
    jge end_outer
    
    xor edi, edi                ; Contador de columnas
inner_loop:
    cmp edi, [new_width]        ; Hasta 400
    jge end_inner

    ; Calcular coordenadas originales (x_float, y_float)
    mov [temp_counter], esi
    fild dword [temp_counter]
    fdiv dword [scale]
    fstp dword [x_float]

    mov [temp_counter], edi
    fild dword [temp_counter]
    fdiv dword [scale]
    fstp dword [y_float]

    ; Obtener partes enteras (x0, y0)
    fld dword [x_float]
    fisttp dword [x0]
    fld dword [y_float]
    fisttp dword [y0]

    ; Calcular x1 (clamp al borde)
    mov eax, [x0]
    inc eax
    cmp eax, [height]
    jl no_clamp_x
    mov eax, [height]
    dec eax
no_clamp_x:
    mov [x1], eax

    ; Calcular y1 (clamp al borde)
    mov eax, [y0]
    inc eax
    cmp eax, [width]
    jl no_clamp_y
    mov eax, [width]
    dec eax
no_clamp_y:
    mov [y1], eax

    ; Calcular distancias fraccionales
    fld dword [x_float]
    fisub dword [x0]
    fstp dword [disx]
    fld dword [y_float]
    fisub dword [y0]
    fstp dword [disy]

    ; Obtener valores de los 4 píxeles vecinos
    mov eax, [x0]
    mov ebx, [width]
    mul ebx
    add eax, [y0]
    cmp eax, 10000              ; Límite de image_orig
    jae error_exit_index
    movzx ebx, byte [image_orig + eax]
    mov [p00], bl

    mov eax, [x1]
    mov ebx, [width]
    mul ebx
    add eax, [y0]
    cmp eax, 10000
    jae error_exit_index
    movzx ebx, byte [image_orig + eax]
    mov [p10], bl

    mov eax, [x0]
    mov ebx, [width]
    mul ebx
    add eax, [y1]
    cmp eax, 10000
    jae error_exit_index
    movzx ebx, byte [image_orig + eax]
    mov [p01], bl

    mov eax, [x1]
    mov ebx, [width]
    mul ebx
    add eax, [y1]
    cmp eax, 10000
    jae error_exit_index
    movzx ebx, byte [image_orig + eax]
    mov [p11], bl

    ; Calcular términos de interpolación
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

    ; Sumar términos y obtener resultado
    fld dword [term1]
    fadd dword [term2]
    fadd dword [term3]
    fadd dword [term4]
    fistp dword [result]

    ; Guardar píxel en image_scaled
    mov eax, esi
    mov ebx, [new_width]
    mul ebx
    add eax, edi
    cmp eax, 160000             ; Límite de image_scaled
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
    cmp esi, [new_height]       ; Hasta 400
    jge write_done

    xor edi, edi
write_inner:
    cmp edi, [new_width]        ; Hasta 400
    jge write_end_inner

    ; Obtener píxel de image_scaled
    mov eax, esi
    mov ebx, [new_width]
    mul ebx
    add eax, edi
    cmp eax, 160000             ; Límite de image_scaled
    jae error_exit_index
    movzx eax, byte [image_scaled + eax]
    call int_to_string

    ; Escribir número
    mov eax, 4                  ; Syscall: write
    mov ebx, [fd_out]
    mov ecx, num_str
    mov edx, 4
    int 0x80

    ; Agregar espacio si no es la última columna
    cmp edi, 399                ; Última columna (400-1)
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
    ; Escribir salto de línea
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
    mov byte [edi], 32          ; Rellenar con espacio por defecto
    mov ecx, 10                 ; Base 10
    mov ebx, eax                ; Valor a convertir
    test ebx, ebx
    jnz convert_loop
    mov byte [edi-1], '0'       ; Caso especial: 0
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
    ; Rellenar con espacios si es necesario
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
