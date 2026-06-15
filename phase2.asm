 [org 0x0100]
jmp start

; Game Variables
game_score       dw 0
game_time        dw 20
balloons_popped  dw 0
balloons_missed  dw 0
game_running     db 0
tick_counter     dw 0
old_timer_int    dd 0
frame_count      dw 0
difficulty_level db 1
pause_flag 		 db 0

; Color mode variables
dark_mode       db 0    ; 0 = light mode, 1 = dark mode
bg_color        db 0x30 ; Default light mode background (black on cyan)
ground_color	db 0x2A ; Default light mode ground (green on green)
text_color      db 0x3F ; Default light mode text (white on cyan)
text_color1		db 0x3E ;Color for printing Balloon on Start Screen
text_color2		db 0x3A ;Color for printing Game on Start Screen
text_color3		db 0x34 ;Color for printing Game Over on End Screen
text_color4		db 0x6F ;Color for printing Game Over on End Screen

; Keyboard interrupt variables
old_keyboard_int dd 0
key_buffer      db 0
key_ready       db 0
esc_pressed     db 0
music_enabled   db 1    ; Music on by default
backspace_pressed db 0
ins_pressed     db 0    ; For dark mode toggle

; Balloon data
MAX_BALLOONS    equ 5
balloon_active  db 0,0,0,0,0
balloon_char    db 'A','B','C','D','E'
balloon_x       db 15,35,55,25,45
balloon_y       db 19,19,19,19,19
balloon_speed   db 1,1,1,1,1

random_seed     dw 0x1234

; Background music variables
music_note_index dw 0
music_tempo_counter dw 0
music_notes:    ; Simple melody (frequency divisor values)
    dw 2280, 2280, 2024, 2024, 1804, 1804, 2280, 0
    dw 2024, 2024, 1804, 1804, 1607, 1607, 2024, 0
    dw 2280, 2280, 2024, 2024, 1804, 1804, 2280, 0
    dw 2024, 2024, 1804, 1804, 1607, 1607, 1804, 0
    dw 0  ; End marker

; Scan code to ASCII table (simplified)
scan_codes:
    db 0, 27, '1234567890-=', 8, 9, 'QWERTYUIOP[]', 13, 0
    db 'ASDFGHJKL;', 39, '`', 0, '\ZXCVBNM,./', 0, 0, 0, ' ', 0
    times 128 db 0

; Strings
title_line1     db ' _____ __   __ ____   ___  _   _  ____   ', 0
title_line2     db '|_   _|\ \ / /|  _ \  | | | \ | |/ ___|  ', 0
title_line3     db '  | |   \ V / | |_) | | | |  \| | |  _   ', 0
title_line4     db '  | |    | |  |  __/  | | | |\  | |_| |  ', 0
title_line5     db '  |_|    |_|  |_|     |_| |_| \_|\____|  ', 0
title_line6     db ' ____    _    _     _      ___   ___  _   _ ', 0
title_line7     db '| __ )  / \  | |   | |    / _ \ / _ \| \ | |', 0
title_line8     db '|  _ \ / _ \ | |   | |   | | | | | | |  \| |', 0
title_line9     db '| |_) / ___ \| |___| |___| |_| | |_| | |\  |', 0
title_line10    db '|____/_/   \_|_____|_____|\___/ \___/|_| \_|', 0
title_line11    db '  ____    _    __  __ _____ ', 0
title_line12    db ' / ___|  / \  |  \/  | ____|', 0
title_line13    db '| |  _  / _ \ | |\/| |  _|  ', 0
title_line14    db '| |_| |/ ___ \| |  | | |___ ', 0
title_line15    db ' \____/_/   \_|_|  |_|_____|', 0

pause_line1 db '  ____    _     _   _   ___  _____  ____  ',0
pause_line2 db ' |  _ \  / \   | | | | /  / | ____|| __ \ ',0
pause_line3 db ' | |_) |/ _ \  | | | | \  \ |  _|  ||  \ |',0
pause_line4 db ' |  __// ___ \ | |_| | 	\  \| |___ ||__/ |',0
pause_line5 db ' |_|  / /   \ \|_____|  /__/|_____||____/ ',0
pause_msg1 db ' Press SPACE to Continue ',0
pause_msg2 db ' Press ESC to Exit ',0

gameover_line6  db '  ___  __     __ _____  ____   _ ', 0
gameover_line7  db ' / _ \ \ \   / /| ____||  _ \ | |', 0
gameover_line8  db '| | | | \ \ / / |  _|  | |_) ||_|', 0
gameover_line9  db '| |_| |  \ V /  | |___ |  _ <  _ ', 0
gameover_line10 db ' \___/    \_/   |_____||_| \_\(_)', 0


start_msg       db 'Press SPACE to Start', 0
esc_msg         db 'Press ESC to Exit', 0
instructions    db 'Type the letter/number on balloon to pop it!', 0
score_label     db 'SCORE: ', 0
time_label      db 'TIME: ', 0
final_score_txt db ' Final Score:     ', 0
popped_txt      db ' Balloons Popped:    ', 0
missed_txt      db ' Balloons Missed:    ', 0
restart_txt     db 'Press R to Restart or ESC to Exit', 0
dark_mode_txt   db 'DARK MODE: ', 0

; Toggle Dark/Light Mode
toggle_dark_mode:
    push ax
    push ds
    
    mov ax, cs
    mov ds, ax
    
    ; Toggle dark mode flag
    mov al, [dark_mode]
    xor al, 1
    mov [dark_mode], al
    
    ; Update colors based on mode
    test al, al
    jz .light_mode
    
    ; Dark mode colors
    mov byte [bg_color], 0x00    ; Black on black
    mov byte [text_color], 0x0F  ; White on black
    mov byte [ground_color], 0x22 ; Green on black
	mov byte [text_color1], 0x0E  ; Yellow on black
    mov byte [text_color2], 0x0A  ; Green on black
	mov byte [text_color3], 0x04  ; Red on black
	mov byte [text_color4], 0x6F  ; White on orange
	
    jmp .mode_set
    
.light_mode:
    ; Light mode colors
    mov byte [bg_color], 0x30    ; Black on cyan
    mov byte [text_color], 0x3F  ; White on cyan
    mov byte [ground_color], 0x2A ; Green on green
    mov byte [text_color1], 0x3E  ; Yellow on cyan
    mov byte [text_color2], 0x3A  ; Red on cyan
    mov byte [text_color3], 0x34  ; Red on cyan
	mov byte [text_color4], 0x0F  ; White on orange

.mode_set:
    pop ds
    pop ax
    ret

; Update colors in game
update_colors:
    push ax
    push ds
    
    mov ax, cs
    mov ds, ax
    
    ; Redraw screen elements with new colors
    cmp byte [game_running], 0
    je .update_done
    
    call clear_screen
    call draw_ground
    call draw_hud
    
    ; Redraw active balloons
    xor bx, bx
.redraw_balloons:
    cmp bx, MAX_BALLOONS
    jge .update_done
    cmp byte [balloon_active + bx], 0
    je .next_balloon
    call draw_balloon
.next_balloon:
    inc bx
    jmp .redraw_balloons
    
.update_done:
    pop ds
    pop ax
    ret

; Keyboard Interrupt Handler (INT 09h)
keyboard_interrupt:
    push ax
    push bx
    push ds
   
    mov ax, cs
    mov ds, ax
   
    in al, 0x60
   
    test al, 0x80
    jnz .key_release
   
    mov bl, al
    mov bh, 0
    
    ; Check for special keys first
    cmp bl, 0x52  ; INS key
    je .ins_pressed_key
    
    ; Handle regular keys
    mov al, [scan_codes + bx]
   
    cmp al, 0
    je .end_handler
   
    mov [key_buffer], al
    mov byte [key_ready], 1
   
    cmp al, 27
    jne .check_backspace
    mov byte [esc_pressed], 1
    jmp .end_handler

.check_backspace:
    cmp bl, 0x0E
    jne .end_handler
    mov byte [backspace_pressed], 1
    jmp .end_handler

.ins_pressed_key:
    mov byte [ins_pressed], 1
    jmp .end_handler

.key_release:
    and al, 0x7F
   
.end_handler:
    mov al, 0x20
    out 0x20, al
   
    pop ds
    pop bx
    pop ax
    iret

; Get Key (Blocking)
get_key:
    push ds
    mov ax, cs
    mov ds, ax
   
.wait_loop:
    cmp byte [key_ready], 0
    je .wait_loop
   
    mov al, [key_buffer]
    mov byte [key_ready], 0
    pop ds
    ret

; Check Key Available (Non-blocking)
check_key_available:
    push ds
    mov ax, cs
    mov ds, ax
   
    cmp byte [key_ready], 0
    je .no_key
   
    mov al, [key_buffer]
    mov byte [key_ready], 0
    pop ds
    ret
   
.no_key:
    xor al, al
    pop ds
    ret

; Check ESC Pressed
check_esc:
    push ds
    mov ax, cs
    mov ds, ax
   
    cmp byte [esc_pressed], 0
    je .no_esc
   
    mov byte [esc_pressed], 0
    mov al, 1
    pop ds
    ret
   
.no_esc:
    xor al, al
    pop ds
    ret

; Check Backspace Pressed
check_backspace:
    push ds
    mov ax, cs
    mov ds, ax
   
    cmp byte [backspace_pressed], 0
    je .no_backspace
   
    mov byte [backspace_pressed], 0
    mov al, 1
    pop ds
    ret
   
.no_backspace:
    xor al, al
    pop ds
    ret

; Check INS Pressed (for dark mode)
check_ins:
    push ds
    mov ax, cs
    mov ds, ax
   
    cmp byte [ins_pressed], 0
    je .no_ins
   
    mov byte [ins_pressed], 0
    mov al, 1
    pop ds
    ret
   
.no_ins:
    xor al, al
    pop ds
    ret

; Install Keyboard Interrupt
install_keyboard:
    push es
    push ds
   
    mov ax, 0x3509
    int 0x21
    mov [old_keyboard_int], bx
    mov [old_keyboard_int + 2], es
   
    mov ax, cs
    mov ds, ax
    mov ax, 0x2509
    mov dx, keyboard_interrupt
    int 0x21
   
    pop ds
    pop es
    ret

; Restore Keyboard Interrupt
restore_keyboard:
    push ds
   
    lds dx, [cs:old_keyboard_int]
    mov ax, 0x2509
    int 0x21
   
    pop ds
    ret

; Check Key for Balloon Match
check_key_balloon:
    push ax
    push bx
    push cx
    push dx
    push ds
   
    mov cx, cs
    mov ds, cx
   
    mov dl, al
   
    cmp al, 'a'
    jl .check_balloons
    cmp al, 'z'
    jg .check_balloons
    sub al, 0x20
   
.check_balloons:
    mov cl, al
    xor bx, bx
   
.check_loop:
    cmp bx, MAX_BALLOONS
    jge .no_match
   
    cmp byte [balloon_active + bx], 0
    je .next_balloon
   
    mov al, [balloon_char + bx]
   
    cmp al, 'a'
    jl .compare
    cmp al, 'z'
    jg .compare
    sub al, 0x20
   
.compare:
    cmp cl, al
    jne .next_balloon
   
    call erase_balloon
    call play_pop_sound
    mov byte [balloon_active + bx], 0
    add word [game_score], 10
    inc word [balloons_popped]
    jmp .match_found
   
.next_balloon:
    inc bx
    jmp .check_loop

.no_match:
.match_found:
    pop ds
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Print String
print_string:
    push di
    push ax
.print_loop:
    lodsb
    test al, al
    jz .print_done
    stosw
    jmp .print_loop
.print_done:
    pop ax
    pop di
    ret

; Print Number with current text color
print_num:
    push ax
    push bx
    push cx
    push dx
   
    mov bx, 10
    xor cx, cx
   
    test ax, ax
    jnz .divide_loop
   
    mov al, '0'
    mov ah, [text_color]
    stosw
    jmp .print_done
   
.divide_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz .divide_loop
   
.print_digits:
    pop ax
    add al, '0'
    mov ah, [text_color]
    stosw
    loop .print_digits
   
.print_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Print Number with red background
print_num_red:
    push ax
    push bx
    push cx
    push dx
   
    mov bx, 10
    xor cx, cx
   
    test ax, ax
    jnz .divide_loop
   
    mov al, '0'
    mov ah, 0x4F
    stosw
    jmp .print_done
   
.divide_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz .divide_loop
   
.print_digits:
    pop ax
    add al, '0'
    mov ah, 0x4F
    stosw
    loop .print_digits
   
.print_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Random Number
get_random:
    push ds
    mov ax, cs
    mov ds, ax
    
    mov ax, [random_seed]
    mov dx, 0x8405
    mul dx
    inc ax
    mov [random_seed], ax
    
    pop ds
    ret

; Clear Screen with current background color
clear_screen:
    push es
    push di
    push cx
    push ds
   
    mov ax, cs
    mov ds, ax
   
    mov ax, 0xB800
    mov es, ax
    xor di, di
    mov cx, 2000
    mov al, ' '
    mov ah, [bg_color]
    rep stosw
   
    pop ds
    pop cx
    pop di
    pop es
    ret

; Draw Ground with current ground color
draw_ground:
    push es
    push di
    push cx
    push ax
    push ds
   
    mov ax, cs
    mov ds, ax
   
    mov ax, 0xB800
    mov es, ax
    mov di, 160 * 22
    mov cx, 80
    mov al, '='
    mov ah, [ground_color]
.ground_loop:
    stosw
    loop .ground_loop
   
    pop ds
    pop ax
    pop cx
    pop di
    pop es
    ret

; Draw HUD with current colors
draw_hud:
    push es
    push di
    push si
    push ax
    push ds
    
    mov ax, cs
    mov ds, ax
   
    mov ax, 0xB800
    mov es, ax
   
    ; Clear top HUD area
    mov di, 160 * 0
    mov cx, 160
    mov al, ' '
    mov ah, [bg_color]
    rep stosw
   
    mov di, 160 * 1 + 4
    mov cx, 20
    rep stosw
   
    mov di, 160 * 1 + 130
    mov cx, 20
    rep stosw
   
    ; Draw score label
    mov di, 160 * 1 + 50
    mov si, score_label
    mov ah, [text_color]
    call print_string
   
    mov ax, [game_score]
    add di, 14
    call print_num
   
    ; Draw time label
    mov di, 160 * 1 + 130
    mov si, time_label
    mov ah, [text_color]
    call print_string

    ; Calculate minutes and seconds
    mov ax, [game_time]
    mov bx, 60
    xor dx, dx 
    div bx 

    push dx  

    add di, 12
    cmp ax, 10
    jae .print_minutes

    push ax
    mov al, '0'
    mov ah, [text_color]
    stosw
    pop ax
.print_minutes:
    call print_num

    ; Print colon separator ':'
    mov al, ':'
    mov ah, [text_color]
    stosw

    ; Print seconds with leading zero
    pop dx
    mov ax, dx
    cmp ax, 10
    jae .print_seconds
    ; Print leading zero for single digit seconds
    push ax
    mov al, '0'
    mov ah, [text_color]
    stosw
    pop ax
.print_seconds:
    call print_num
   
    ; Draw instructions
    mov di, 160 * 23 + 17 * 2
    mov si, instructions
    mov ah, [text_color]
    call print_string
   
    ; Draw music status
    mov di, 160 * 1 + 4
    mov ah, [text_color]
    cmp byte [music_enabled], 0
    je .music_off_hud
    mov al, 'M'
    stosw
    mov al, 'U'
    stosw
    mov al, 'S'
    stosw
    mov al, 'I'
    stosw
    mov al, 'C'
    stosw
    mov al, ':'
    stosw
	mov ah, 0x2F
    mov al, 'O'
    stosw
    mov al, 'N'
    stosw
    jmp .dark_mode_hud
.music_off_hud:
    mov al, 'M'
    stosw
    mov al, 'U'
    stosw
    mov al, 'S'
    stosw
    mov al, 'I'
    stosw
    mov al, 'C'
    stosw
    mov al, ':'
    stosw
    mov ah, 0x4F
    mov al, 'O'
    stosw
    mov al, 'F'
    stosw
    mov al, 'F'
    stosw
   
.dark_mode_hud:
    ; Draw dark mode status
    mov di, 160 * 0 + 4
    mov si, dark_mode_txt
    mov ah, [text_color]
    call print_string
    
    add di, 22
    cmp byte [dark_mode], 0
    je .light_mode_hud
    mov al, 'O'
    stosw
    mov al, 'N'
    stosw
    jmp .hud_done
.light_mode_hud:
    mov al, 'O'
    stosw
    mov al, 'F'
    stosw
    mov al, 'F'
    stosw
   
.hud_done:
    pop ds
    pop ax
    pop si
    pop di
    pop es
    ret

; Draw Balloon (colors adjusted for dark mode)
draw_balloon:
    push bx
    push ax
    push cx
    push dx
    push di
    push es
    push ds
   
    ; Set DS to CS for data access
    mov ax, cs
    mov ds, ax
   
    ; Check if balloon is active
    cmp byte [balloon_active + bx], 0
    je .draw_done
   
    ; Get Y position and validate
    mov al, [balloon_y + bx]
    cmp al, 3
    jl .draw_done
    cmp al, 21
    jg .draw_done
   
    ; Calculate screen position: Y * 160
    xor ah, ah
    mov cx, 160
    mul cx
    mov di, ax
    
    ; Add X position * 2
    mov al, [balloon_x + bx]
    xor ah, ah
    shl ax, 1
    add di, ax
   
    ; Set video segment
    mov ax, 0xB800
    mov es, ax
   
    ; Get balloon character
    mov dl, [balloon_char + bx]
   
    ; Set colors based on balloon index and dark mode
    cmp byte [dark_mode], 0
    jne .dark_mode_colors
    
    ; Light mode colors
    mov ah, 0x1F  ; Light blue
    mov dh, 0x17  ; Dark blue
    
    cmp bx, 1
    jne .color2
    mov ah, 0x6F
    mov dh, 0x67
    jmp .draw_body
    
.color2:
    cmp bx, 2
    jne .color3
    mov ah, 0x5F
    mov dh, 0x57
    jmp .draw_body
    
.color3:
    cmp bx, 3
    jne .color4
    mov ah, 0x2F
    mov dh, 0x27
    jmp .draw_body
    
.color4:
    cmp bx, 4
    jne .draw_body
    mov ah, 0x4F
    mov dh, 0x47
    jmp .draw_body
.dark_mode_colors:
    ; Dark mode colors (brighter versions)
    mov ah, 0x1F  ; Light blue on black
    mov dh, 0x17  ; Dark blue on black
    
    cmp bx, 1
    jne .dark_color2
    mov ah, 0x6F
    mov dh, 0x67
    jmp .draw_body
    
.dark_color2:
    cmp bx, 2
    jne .dark_color3
    mov ah, 0x5F
    mov dh, 0x57
    jmp .draw_body
    
.dark_color3:
    cmp bx, 3
    jne .dark_color4
    mov ah, 0x2F
    mov dh, 0x27
    jmp .draw_body
    
.dark_color4:
    cmp bx, 4
    jne .draw_body
    mov ah, 0x4F
    mov dh, 0x47
   
.draw_body:
    ; Save the main balloon color (ah) in SI for later use with string
    mov si, ax
    
    ; Row 1 - Top of balloon
    push di
    mov al, ' '
    stosw
    mov al, 0xDF
    stosw
    stosw
    stosw
    mov al, ' '
    stosw
    pop di
   
    ; Row 2
    add di, 160
    push di
    mov al, 0xDB
    stosw
    mov ah, dh
    mov al, ' '
    stosw
    stosw
    stosw
    mov al, 0xDB
    mov ah, [es:di-2]  ; Restore original color
    and ah, 0xF0
    or ah, 0x0F
    stosw
    pop di
   
    ; Row 3 - Middle with character
    add di, 160
    push di
    mov al, 0xDB
    stosw
    mov ah, dh
    mov al, ' '
    stosw
    mov ah, 0x0F
    mov al, dl
    stosw
    mov ah, dh
    mov al, ' '
    stosw
    mov al, 0xDB
    mov ah, [es:di-2]
    and ah, 0xF0
    or ah, 0x0F
    stosw
    pop di
   
    ; Row 4
    add di, 160
    push di
    ; Save the outer color temporarily
    push ax
    mov al, 0xDB
    stosw
    ; Restore and use dh (darker inner color) for spaces
    pop ax
    mov ah, dh
    mov al, ' '
    stosw
    stosw
    stosw
    ; Use outer color for right edge
    push ax
    mov ax, si  ; Get original outer color from si
    mov al, 0xDB
    stosw
    pop ax
    pop di
    ; Row 5 - Bottom
    add di, 160
    push di
    mov al, ' '
    stosw
    mov al, 0xDC
    stosw
    stosw
    stosw
    mov al, ' '
    stosw
    pop di
   
    ; Restore the balloon color from SI
    mov ax, si
    
    ; Row 6 - String part 1 (using balloon color)
    add di, 160
    push di
    add di, 4
    mov al, 0xB3
    stosw
    pop di
   
    ; Row 7 - String part 2 (using balloon color)
    add di, 160
    push di
    add di, 4
    mov al, 0xB3
    stosw
    pop di
   
.draw_done:
    pop ds
    pop es
    pop di
    pop dx
    pop cx
    pop ax
    pop bx
    ret
	
; Erase Balloon
erase_balloon:
    push bx
    push ax
    push cx
    push di
    push es
    push ds
   
    ; Set DS to CS
    mov ax, cs
    mov ds, ax
    
    ; Get Y position
    mov al, [balloon_y + bx]
    
    ; Validate Y position
    cmp al, 0
    jl .erase_done
    cmp al, 24
    jg .erase_done
    
    ; Calculate screen position
    xor ah, ah
    mov cl, 160
    mul cl
    mov di, ax
    
    ; Add X offset
    mov al, [balloon_x + bx]
    xor ah, ah
    shl ax, 1
    add di, ax
   
    ; Set video segment
    mov ax, 0xB800
    mov es, ax
    
    ; Clear with current background color
    mov al, ' '
    mov ah, [bg_color]
   
    ; Erase 7 rows (balloon height)
    mov cx, 7
.erase_rows:
    push cx
    push di
    
    ; Erase 5 characters width
    mov cx, 5
    rep stosw
    
    pop di
    add di, 160  ; Next row
    pop cx
    loop .erase_rows
   
.erase_done:
    pop ds
    pop es
    pop di
    pop cx
    pop ax
    pop bx
    ret

; Update Balloons
update_balloons:
    push bx
    push ax
    push ds
    
    mov ax, cs
    mov ds, ax
   
    xor bx, bx
.update_loop:
    cmp bx, MAX_BALLOONS
    jge .update_done
   
    cmp byte [balloon_active + bx], 0
    je .next_balloon
   
    ; Erase current position
    call erase_balloon
   
    ; Move balloon up
    mov al, [balloon_y + bx]
    dec al
    mov [balloon_y + bx], al
   
    ; Check if balloon went off screen
    cmp al, 3
    jg .still_on_screen
   
    ; Balloon missed
    mov byte [balloon_active + bx], 0
    inc word [balloons_missed]
    jmp .next_balloon
   
.still_on_screen:
    ; Draw at new position
    call draw_balloon
   
.next_balloon:
    inc bx
    jmp .update_loop
   
.update_done:
    pop ds
    pop ax
    pop bx
    ret

; Spawn Balloon
spawn_balloon:
    push bx
    push ax
    push dx
    push cx
    push ds
    
    mov ax, cs
    mov ds, ax
   
    ; Find inactive balloon slot
    xor bx, bx
.find_slot:
    cmp bx, MAX_BALLOONS
    jge .spawn_done
    cmp byte [balloon_active + bx], 0
    je .found_slot
    inc bx
    jmp .find_slot
   
.found_slot:
    ; Activate balloon
    mov byte [balloon_active + bx], 1
   
    ; Random X position (5-70)
    call get_random
    xor dx, dx
    mov cx, 65
    div cx
    add dl, 5
    mov [balloon_x + bx], dl
   
    ; Start at bottom
    mov byte [balloon_y + bx], 19
   
    ; Random character (A-Z, a-z, 0-9)
    call get_random
    xor dx, dx
    mov cx, 62
    div cx
   
    cmp dx, 26
    jl .uppercase
    cmp dx, 52
    jl .lowercase
   
    ; Digit
    sub dx, 52
    add dl, '0'
    jmp .set_char
   
.uppercase:
    add dl, 'A'
    jmp .set_char
   
.lowercase:
    sub dx, 26
    add dl, 'a'
   
.set_char:
    mov [balloon_char + bx], dl
   
    ; Draw the new balloon
    call draw_balloon
   
.spawn_done:
    pop ds
    pop cx
    pop dx
    pop ax
    pop bx
    ret

; Play Background Music Note
play_music_note:
    push ax
    push bx
    push cx
    push dx
    push ds
   
    mov ax, cs
    mov ds, ax
   
    cmp byte [music_enabled], 0
    je .music_off
   
    mov bx, [music_note_index]
    shl bx, 1
    mov cx, [music_notes + bx]
   
    test cx, cx
    jz .reset_melody
   
    mov al, 0xB6
    out 0x43, al
   
    mov ax, cx
    out 0x42, al
    mov al, ah
    out 0x42, al
   
    in al, 0x61
    or al, 0x03
    out 0x61, al
   
    jmp .music_done
   
.reset_melody:
    mov word [music_note_index], 0
    jmp .music_off
   
.music_off:
    in al, 0x61
    and al, 0xFC
    out 0x61, al
   
.music_done:
    pop ds
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Stop Music
stop_music:
    push ax
   
    in al, 0x61
    and al, 0xFC
    out 0x61, al
   
    pop ax
    ret

; Toggle Music
toggle_music:
    push ax
    push ds
   
    mov ax, cs
    mov ds, ax
   
    mov al, [music_enabled]
    xor al, 1
    mov [music_enabled], al
   
    test al, al
    jnz .toggle_done
   
    call stop_music
   
.toggle_done:
    pop ds
    pop ax
    ret

; Play Pop Sound
play_pop_sound:
    push ax
    push cx
    push bx
   
    mov bl, [music_enabled]
    push bx
    mov byte [music_enabled], 0
    call stop_music
   
    in al, 0x61
    push ax
    or al, 0x03
    out 0x61, al
   
    mov al, 0xB6
    out 0x43, al
   
    mov al, 0x30
    out 0x42, al
    mov al, 0x05
    out 0x42, al
   
    mov cx, 0x3000
.delay1:
    nop
    loop .delay1
   
    mov al, 0x80
    out 0x42, al
    mov al, 0x06
    out 0x42, al
   
    mov cx, 0x2000
.delay2:
    nop
    loop .delay2
   
    pop ax
    out 0x61, al
   
    pop bx
    mov [music_enabled], bl
   
    pop bx
    pop cx
    pop ax
    ret

; Timer Interrupt Handler (INT 08h)
timer_interrupt:
    push ax
    push ds
   
    mov ax, cs
    mov ds, ax
   
    inc word [tick_counter]
   
    inc word [music_tempo_counter]
    cmp word [music_tempo_counter], 6  ; Adjust music tempo
    jl .check_game_tick
   
    mov word [music_tempo_counter], 0
   
    cmp byte [game_running], 0
    je .check_game_tick
   
    inc word [music_note_index]
    call play_music_note
   
.check_game_tick:
    cmp word [tick_counter], 18
    jl .chain_timer
   
    mov word [tick_counter], 0
   
    cmp byte [game_running], 0
    je .chain_timer
   
    cmp word [game_time], 0
    je .chain_timer
   
    dec word [game_time]
   
.chain_timer:
    pop ds
    pop ax
    jmp far [cs:old_timer_int]

; Install Timer Interrupt
install_timer:
    push es
    push ds
    
    mov ax, cs
    mov ds, ax
   
    mov ax, 0x3508
    int 0x21
    mov [old_timer_int], bx
    mov [old_timer_int + 2], es
   
    mov ax, 0x2508
    mov dx, timer_interrupt
    int 0x21
   
    pop ds
    pop es
    ret

; Restore Timer Interrupt
restore_timer:
    push ds
   
    lds dx, [cs:old_timer_int]
    mov ax, 0x2508
    int 0x21
   
    pop ds
    ret

; Start Screen
show_start_screen:
    call clear_screen
    call draw_ground
   
    mov ax, 0xB800
    mov es, ax
    
    mov ax, cs
    mov ds, ax
   
    ; Typing
    mov di, 160 * 1 + 18 * 2
    mov si, title_line1
    mov ah, [text_color]
    call print_string
    mov di, 160 * 2 + 18 * 2
    mov si, title_line2
    call print_string
    mov di, 160 * 3 + 18 * 2
    mov si, title_line3
    call print_string
    mov di, 160 * 4 + 18 * 2
    mov si, title_line4
    call print_string
    mov di, 160 * 5 + 18 * 2
    mov si, title_line5
    call print_string
    
    ; BALLOON
    mov di, 160 * 6 + 16 * 2
    mov si, title_line6
    mov ah, [text_color1]
    call print_string
    mov di, 160 * 7 + 16 * 2
    mov si, title_line7
    call print_string
    mov di, 160 * 8 + 16 * 2
    mov si, title_line8
    call print_string
    mov di, 160 * 9 + 16 * 2
    mov si, title_line9
    call print_string
    mov di, 160 * 10 + 16 * 2
    mov si, title_line10
    call print_string
    
    ; GAME
    mov di, 160 * 11 + 26 * 2
    mov si, title_line11
    mov ah, [text_color2]
    call print_string
    mov di, 160 * 12 + 26 * 2
    mov si, title_line12
    call print_string
    mov di, 160 * 13 + 26 * 2
    mov si, title_line13
    call print_string
    mov di, 160 * 14 + 26 * 2
    mov si, title_line14
    call print_string
    mov di, 160 * 15 + 26 * 2
    mov si, title_line15
    call print_string
   
    mov di, 160 * 17 + 29 * 2
    mov si, start_msg
    mov ah, [text_color]
    call print_string
   
    mov di, 160 * 19 + 29 * 2
    mov si, esc_msg
    mov ah, [text_color]
    call print_string

    mov di, 160 * 21 + 17 * 2
    mov si, instructions
    mov ah, [text_color]
    call print_string
   
    ; Add dark mode toggle hint
    mov di, 160 * 23 + 4 * 2
    mov si, dark_mode_txt
    call print_string
    add di, 22
    cmp byte [dark_mode], 0
    je .light_mode_msg
    mov al, 'O'
    stosw
    mov al, 'N'
    stosw
    mov al, ' '
    stosw
    mov al, '('
    stosw
    mov al, 'I'
    stosw
    mov al, 'N'
    stosw
    mov al, 'S'
    stosw
    mov al, ' '
    stosw
    mov al, 't'
    stosw
    mov al, 'o'
    stosw
    mov al, ' '
    stosw
    mov al, 't'
    stosw
    mov al, 'o'
    stosw
    mov al, 'g'
    stosw
    mov al, 'g'
    stosw
    mov al, 'l'
    stosw
    mov al, 'e'
    stosw
    mov al, ')'
    stosw
    jmp .start_wait
.light_mode_msg:
    mov al, 'O'
    stosw
    mov al, 'F'
    stosw
    mov al, 'F'
    stosw
    mov al, ' '
    stosw
    mov al, '('
    stosw
    mov al, 'I'
    stosw
    mov al, 'N'
    stosw
    mov al, 'S'
    stosw
    mov al, ' '
    stosw
    mov al, 't'
    stosw
    mov al, 'o'
    stosw
    mov al, ' '
    stosw
    mov al, 't'
    stosw
    mov al, 'o'
    stosw
    mov al, 'g'
    stosw
    mov al, 'g'
    stosw
    mov al, 'l'
    stosw
    mov al, 'e'
    stosw
    mov al, ')'
    stosw
   
.start_wait:
    call check_esc
    test al, al
    jnz .start_exit
   
    call check_ins
    test al, al
    jnz .toggle_dark_mode
   
    call check_key_available
    test al, al
    jz .start_wait
   
    cmp al, ' '
    je .start_game
    cmp al, 27
    je .start_exit
    jmp .start_wait
   
.toggle_dark_mode:
    call toggle_dark_mode
    call show_start_screen
    jmp .start_wait
   
.start_game:
    xor ax, ax
    ret
   
.start_exit:
    mov ax, 1
    ret

show_difficulty_screen:
	call clear_screen
	call draw_ground
	mov ax, 0xB800
	mov es, ax
	mov ax, cs
	mov ds, ax

	mov di, 160*5 + 10*6
	mov ah, [text_color]
	mov al, 'S'
	stosw
	mov al, 'E'
	stosw
	mov al, 'L'
	stosw
	mov al, 'E'
	stosw
	mov al, 'C'
	stosw
	mov al, 'T'
	stosw
	mov al, ' '
	stosw
	mov al, 'D'
	stosw
	mov al, 'I'
	stosw
	mov al, 'F'
	stosw
	mov al, 'F'
	stosw
	mov al, 'I'
	stosw
	mov al, 'C'
	stosw
	mov al, 'U'
	stosw
	mov al, 'L'
	stosw
	mov al, 'T'
	stosw
	mov al, 'Y'
	stosw

	mov di, 160*9 + 10*7
	mov ah, [text_color2]
	mov al, '1'
	stosw
	mov al, '.'
	stosw
	mov al, ' '
	stosw
	mov al, 'E'
	stosw
	mov al, 'A'
	stosw
	mov al, 'S'
	stosw
	mov al, 'Y'
	stosw

	mov di, 160*11 + 10*7
	mov ah, [text_color3]
	mov al, '2'
	stosw
	mov al, '.'
	stosw
	mov al, ' '
	stosw
	mov al, 'H'
	stosw
	mov al, 'A'
	stosw
	mov al, 'R'
	stosw
	mov al, 'D'
	stosw
	
.diff_wait:
	call check_esc
	test al, al
	jnz .diff_exit
	call check_ins
	test al, al
	jnz .diff_toggle_dm

	call check_key_available
	test al, al
	jz .diff_wait

	cmp al, '1'
	je .diff_easy
	cmp al, '2'
	je .diff_hard
	cmp al, 27
	je .diff_exit
	jmp .diff_wait

.diff_easy:
	mov byte [difficulty_level], 1
	xor ax, ax
	ret

.diff_hard:
	mov byte [difficulty_level], 2
	xor ax, ax
	ret

.diff_exit:
	mov ax, 1
	ret

.diff_toggle_dm:
	call toggle_dark_mode
	call show_difficulty_screen
	jmp .diff_wait

show_pause_screen:
	 mov ax, 0xB800
	 mov es, ax

	 mov ax, cs
	 mov ds, ax

	 mov di, 160*3 + 5*2
	 mov si, title_line11
	 mov ah, [text_color1]
	 call print_string
	 
	 mov di, 160*4 + 5*2
	 mov si, title_line12
	 call print_string
	 
	 mov di, 160*5 + 5*2
	 mov si, title_line13
	 call print_string
	 
	 mov di, 160*6 + 5*2
	 mov si, title_line14
	 call print_string
	 
	 mov di, 160*7 + 5*2
	 mov si, title_line15
	 call print_string
	 
	 mov di, 160*3 + 35*2
	 mov si, pause_line1
	 mov ah, [text_color1]
	 call print_string

	 mov di, 160*4 + 35*2
	 mov si, pause_line2
	 call print_string

	 mov di, 160*5 + 35*2
	 mov si, pause_line3
	 call print_string

	 mov di, 160*6 + 35*2
	 mov si, pause_line4
	 call print_string

	 mov di, 160*7 + 35*2
	 mov si, pause_line5
	 call print_string

	 mov di, 160*12 + 25*2
	 mov si, pause_msg1
	 mov ah, [text_color4]
	 call print_string

	 mov di, 160*14 + 28*2
	 mov si, pause_msg2
	 mov ah, [text_color4]
	 call print_string

	 ret


pause_loop:
	call show_pause_screen
.pause_wait:
	call check_esc
	test al, al
	jnz .pause_quit

	call check_ins
	test al, al
	jnz .pause_toggle_dm

	call check_key_available
	test al, al
	jz .pause_wait

	cmp al, ' '
	je .pause_resume
	cmp al, 27
	je .pause_quit
	jmp .pause_wait

.pause_toggle_dm:
	call toggle_dark_mode
	call pause_loop

.pause_resume:
	mov byte [pause_flag], 0
	ret
	
.pause_quit:
	mov byte [pause_flag], 0
	mov ax, 1
	ret
	
; Game Over Screen
show_game_over:
    call clear_screen
   
    mov ax, 0xB800
    mov es, ax
    
    mov ax, cs
    mov ds, ax
   
    ; Game
    mov di, 160 * 3 + 8 * 2
    mov si, title_line11
    mov ah, [text_color3]
    call print_string
	
    mov di, 160 * 4 + 8 * 2
    mov si, title_line12
    call print_string
	
    mov di, 160 * 5 + 8 * 2
    mov si, title_line13
    call print_string
	
    mov di, 160 * 6 + 8 * 2
    mov si, title_line14
    call print_string
	
    mov di, 160 * 7 + 8 * 2
    mov si, title_line15
    call print_string
    
    ; OVER
    mov di, 160 * 3 + 40 * 2
    mov si, gameover_line6
    mov ah, [text_color3]
    call print_string
    mov di, 160 * 4 + 40 * 2
    mov si, gameover_line7
    call print_string
    mov di, 160 * 5 + 40 * 2
    mov si, gameover_line8
    call print_string
    mov di, 160 * 6 + 40 * 2
    mov si, gameover_line9
    call print_string
    mov di, 160 * 7 + 40 * 2
    mov si, gameover_line10
    call print_string
   
    mov di, 160 * 10 + 30 * 2
    mov si, final_score_txt
    mov ah, 0x4E
    call print_string
    mov ax, [game_score]
    add di, 26
    call print_num_red
   
    mov di, 160 * 12 + 28 * 2
    mov si, popped_txt
    mov ah, 0x4A
    call print_string
    mov ax, [balloons_popped]
    add di, 34
    call print_num_red
   
    mov di, 160 * 14 + 28 * 2
    mov si, missed_txt
    mov ah, 0x4C
    call print_string
    mov ax, [balloons_missed]
    add di, 34
    call print_num_red
   
    mov di, 160 * 18 + 21 * 2
    mov si, restart_txt
    mov ah, [text_color4]
    call print_string
   
.game_over_wait:
    call check_esc
    test al, al
    jnz .game_over_exit
   
    call check_ins
    test al, al
    jnz .toggle_dark_mode
   
    call check_key_available
    test al, al
    jz .game_over_wait
   
    cmp al, 'r'
    je .game_over_restart
    cmp al, 'R'
    je .game_over_restart
    cmp al, 27
    je .game_over_exit
    jmp .game_over_wait
   
.toggle_dark_mode:
    call toggle_dark_mode
    call show_game_over
    jmp .game_over_wait
   
.game_over_restart:
    xor ax, ax
    ret
   
.game_over_exit:
    mov ax, 1
    ret

; Game Loop
game_loop:
    mov word [game_score], 0
    mov word [game_time], 120
    mov word [balloons_popped], 0
    mov word [balloons_missed], 0
    mov word [tick_counter], 0
    mov word [frame_count], 0
    mov byte [key_ready], 0
    mov byte [esc_pressed], 0
    mov byte [backspace_pressed], 0
    mov byte [ins_pressed], 0
    mov word [music_note_index], 0
    mov word [music_tempo_counter], 0
   
    xor bx, bx
.clear_balloons:
    mov byte [balloon_active + bx], 0
    inc bx
    cmp bx, MAX_BALLOONS
    jl .clear_balloons
   
    call clear_screen
    call draw_ground
    call draw_hud
   
    mov byte [game_running], 1
   
    mov bx, 0
    call spawn_balloon
    mov bx, 1
    call spawn_balloon
   
.main_loop:
    ; Check game over conditions
    cmp word [game_time], 0
    jle .game_over
   
    call check_esc
    test al, al
    jnz .game_over
   
    ; Check for backspace (music toggle)
    call check_backspace
    test al, al
    jz .check_ins
   
    call toggle_music
    call draw_hud
   
.check_ins:
    ; Check for INS (dark mode toggle)
    call check_ins
    test al, al
    jz .continue_game
    
    call toggle_dark_mode
    call update_colors
   
.continue_game:
	inc word [frame_count]

	mov ax, [frame_count]
	mov bl, [difficulty_level]
	cmp bl, 2
	jne .easy_update
	and ax, 31
	jmp .do_update_check
	
.easy_update:
	and ax, 63
.do_update_check:
	jnz .check_spawn
	call update_balloons
	call draw_hud
	
.check_spawn:
	mov ax, [frame_count]
	mov bl, [difficulty_level]
	cmp bl, 2
	jne .easy_spawn
	and ax, 63
	jmp .do_spawn_check
.easy_spawn:
	and ax, 127
.do_spawn_check:
	jnz .check_input
    call spawn_balloon
	jmp .check_input
     
.check_input:
    call check_key_available
    test al, al
    jz .frame_delay

    cmp al, 27
    je .game_over

    cmp al, 32
    je .do_pause

    call check_key_balloon
    call draw_hud
    jmp .frame_delay

.do_pause:
    mov byte [pause_flag], 1
    call pause_loop
    cmp ax, 1
    je .game_over
    call clear_screen
    call draw_ground
    call draw_hud
    mov bx, 0
.redraw_after_pause:
    cmp bx, MAX_BALLOONS
    jge .frame_delay
    cmp byte [balloon_active + bx], 0
    je .next_reb
    call draw_balloon
.next_reb:
    inc bx
    jmp .redraw_after_pause


    ; Check for balloon match
    call check_key_balloon
    call draw_hud
   
.frame_delay:
    ; Small delay to control game speed
    mov cx, 0x0FFF
.delay_loop:
    nop
    loop .delay_loop
   
    jmp .main_loop
   
.game_over:
    mov byte [game_running], 0
    call stop_music  ; Stop music when game ends
    ret
 
start:
    ; Set text mode
    mov ax, 0x0003
    int 0x10
   
    ; Initialize dark mode to light mode (0)
    mov byte [cs:dark_mode], 0
    call toggle_dark_mode  ; This will set the light mode colors
   
    ; Install interrupts
    call install_timer
    call install_keyboard
   
.game_restart:
    ; Show start screen
    call show_start_screen
    test ax, ax
    jnz .program_exit

.select_diff:
	call show_difficulty_screen
	test ax, ax
	jnz .program_exit

    ; Run game
    call game_loop
   
    ; Show game over screen
    call show_game_over
    test ax, ax
    jz .game_restart

.program_exit:
    ; Restore interrupts
    call restore_keyboard
    call restore_timer

    ; Exit to DOS
    mov ax, 0x4C00
    int 0x21
    int 0x21