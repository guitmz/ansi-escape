SYS_EXIT        = 60
SYS_WRITE       = 1
SYS_READ        = 0
SYS_IOCTL       = 16
SYS_NANOSLEEP   = 35

STDIN           = 0
STDOUT          = 1

ESC             = 0x1b
TIOCGWINSZ      = 0x5413

struc WINSZ {
    .ws_row     dw ?
    .ws_col     dw ?
    .ws_xpixel  dw ?
    .ws_ypixel  dw ?
    .size = $ - .ws_row
}

struc TIMESPEC {
    .tv_sec     dq 0                    ; seconds to sleep
    .tv_nsec    dq 060000000            ; nanoseconds to sleep
}

; TODO usage here
create_cursor:
    lea rdi, [cursor_buffer]            ; loading [cursor_buffer] into rdi

    mov byte [rdi], ESC                 ; the 'ESC' character
    inc rdi                             ; advance [cursor_buffer]
    mov byte [rdi], 0x5b                ; the '[' character
    inc rdi                             ; advance [cursor_buffer]

    mov rcx, 3                          ; loading denominator into rax
    mov r8w, [winsz.ws_row]             ; loading numerator (X axis = rows) into r8w
    call divideRoundUp                  ; dividing r8w/rcx with result in rax

    cmp ax, [previous_axisX]            ; comparing X axis with previous X axis (this one will be zero during the first run)
    je .bad_axisX                       ; if current X axis = previous X axis, we should recalculate it
    jg .all_good                        ; else, we continue normally
    .bad_axisX:                         
        inc [winsz.ws_row]              ; increasing current X axis since its the same as previous one (same cursor position not allowed)             
        jmp create_cursor               ; recreating cursor ANSI escape code with proper coordinates
    .all_good:
    mov [previous_axisX], ax            ; save X axis after dividing and rounding up into [previous_axisX]

    mov rdx, rax                        ; loading X axis into rdx
    call convertStoreAxis               ; converting X axis to ascii and storing in rdi (at current buffer position)

    mov byte [rdi], 0x3b                ; the ';' character 
    inc rdi                             ; advance [cursor_buffer]

    mov rcx, 3                          ; loading denominator into rax
    mov r8w, [winsz.ws_col]             ; loading numerator (columns) into r8w
    call divideRoundUp                  ; dividing r8w/rcx with result in rax
    
    mov rdx, rax                        ; loading Y axis into rdx
    call convertStoreAxis               ; converting Y axis to ascii and storing in rdi (at current buffer position)

    mov byte [rdi], 0x48                ; the 'H' character

    lea rdi, [cursor_buffer]	        ; loading rdi with ANSI code that moves cursor ("ESC[x;yH")
    call strLen					        ; calculating code lenght from [cursor_buffer], result in rax
    ret

; converts bytes to ascii
; RDX = bytes to be converted
; result will be written to current RDI position
convertStoreAxis:
    lea rsi, [itoa_buffer]              ; loading rsi with [itoa_buffer]
    call itoa                           ; converting X axis to ascii
    lea rsi, [itoa_buffer]              ; loading [itoa_buffer] with itoa result into rsi
    call copySrc                        ; copying contents of rsi into rdi (from current rdi position)
    ret

; divides r8 by RCX, rounding result up
; result in RAX
divideRoundUp:
    xor rdx, rdx
    mov rax, rcx                        ; copy denominator to numerator register
    shr rax, 1                          ; getting denominator
    add ax, r8w                         ; adding to numerator
    div rcx                             ; dividing and rounding up, same as (numerator + (denominator / 2)) / denominator
    ret

; calculate string lenght
; RDI = address of string buffer (rdi is the default search for scasb)
; RAX = calculated string lenght
strLen:
    push    rdi
    push    rcx
    mov     rcx, -1            
    xor     eax, eax
    repne   scasb
    not     rcx
    mov     rax, rcx
    pop     rcx
    pop     rdi 
    ret

; Copies data from a register to [RDI]
; RSI = address of source data
copySrc:
     mov     al, [rsi]    
     mov     [rdi], al    
     inc     rsi
     inc     rdi
     cmp     byte [rsi], 0              ; Check for null terminator
     jne     copySrc                    ; loop if not null
     ret         

; Converts numbers to string (adapted from https://board.flatassembler.net/topic.php?p=178500)
; RSI = address of source buffer with message to print
; RDX = lenght of RSI buffer
itoa:                                           ; void itoa(int, char*); eax = dividend
        push rbx                             ; esi = char*
        mov     ax, dx                        ; eax = dividend
        xor     rcx, rcx                        ; string buffer index
        mov     rbx, 10                        ; divisor

conversion_loop:
        xor     rdx, rdx
        div     rbx                             ; eax   = edx:eax/ebx
        add     rdx, '0'                        ; convert int to ascii
        push    rdx
        inc     rcx
        test    rax, rax
        jz      end_conversion_loop
        jmp     conversion_loop

end_conversion_loop:
        mov     rdx, rsi                        ; string buffer

copy_reversing_loop:
        pop     rax
        mov     byte    [rdx], al
        dec     rcx
        inc     rdx
        test    rcx, rcx
        jz      end_copy_reversing_loop
        jmp     copy_reversing_loop
        
end_copy_reversing_loop:
        mov     byte    [rdx], 0
        pop rbx
        ret
