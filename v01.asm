[bits 16]           ; tell assembler that working in real mode(16 bit mode)
[org 0x7c00]        ; organize from 0x7C00 memory location where BIOS will load us

SET_CURSOR equ 0x02

USERNAME_SIZE equ 5;30


	
	


start:			; start label from where our code starts
	
	xor ax, ax	; clears all registers
	mov ds, ax
	mov es, ax
	
	
; move line pointer to -1 (0xFF) since newline function increases dh by one so the first call starts from 0
	mov dh, 0xFF
	mov bx, 0x8000 ;reserving space in memory between 0x7c00 and 0x8000
	
	
;	mov al, 2	; uncomment to have small text
	
;	mov bl, 15	; you must uncomment this if you want to use one of the two below
;	mov ax, 0x10	; uncomment to have arcade-ish text
;	mov ax, 0x13	; uncomment to have large text
	
	int 0x10
	
	call newline
	mov si, line1	; point string to source index
	call print
	
	call newline
	call newline
	mov si, line2
	call print
	
	mov cx, USERNAME_SIZE
	call input
	ret

input:	
	
	
	mov ax, 0x00	; get keyboard input
	int 0x16	; interrupt for hold & read input
	
	;for input, al is ASCII code / ah is keyboard code
	
	cmp ah, 0x1C
	je .exitinput
	
	
	
	
	mov [username], al	; move input to pointed place in memory
	sub byte [username], 0x101 
	inc byte [username]	; increase pointer by 1
	
	mov ah, 0x0E
	int 0x10
	
	loop input
	jmp .exitinput

.exitinput:
	call newline
	mov si, username
	call print
	ret
	
;	mov si, os_info
;	call print



	; declaring strings
	line1 db 'LOGIC, 16-BIT, V1.0', 0
	line2 db 'USERNAME : ', 0

	login_username db 'Username : ',0
	login_password db 'Password : ',0

	display_text db '! Welcome to my Operating System !', 0

	os_info db 10, 'My Operating System, 16-Bit, version=1.0.0',13,0

	press_key_2 db 10,'Press any key to go to graphics view',0

	window_text db 10,'Graphics in OS......', 0
	hello_world_text db 10,10, '    Hello World!',0
	login_label db '#] Login please....(ESC to skip login)', 0
	
	username times USERNAME_SIZE db 0x00
	username_index equ username


    ;/////////////////////////////////////////////////////////////
    ; defining functions here

newline:
	mov ah, SET_CURSOR
	mov bh, 0x00
	add dh, 0x01
	mov dl, 0x00
	int 0x10
	ret

print:
	mov ah, 0x0E            ; value to tell interrupt handler that take value from al & print it

.repeat_next_char:
	lodsb                ; get character from string
	cmp al, 0                    ; cmp al with end of string
	je .done_print    ; if char is zero, end of string
	int 0x10                     ; otherwise, print it
	jmp .repeat_next_char        ; jmp to .repeat_next_char if not 0

.done_print:
	ret                         ;return




    ;///////////////////////////////////////////
    ; boot loader magic number
    times ((0x200 - 2) - ($ - $$)) db 0x00     ;set 512 bytes for boot sector which are necessary
    dw 0xAA55                                  ; boot signature 0xAA & 0x55























;////////////////////////////////////////////////////////////////////////////////////////





_OS_Stage_2 :

    mov al,2                    ; set font to normal mode
    mov ah,0                    ; clear the screen
    int 0x10                    ; call video interrupt

    mov cx,0                    ; initialize counter(cx) to get input

    ;***** print login_label on screen
    ;set cursor to specific position on screen
    mov ah, SET_CURSOR
    mov bh,0x00
    mov dh,0x00
    mov dl,0x00
    int 0x10

    mov si,login_label              ; point si to login_username
    call print               ; display it on screen

    ;****** read username

    ;set cursor to specific position on screen
    mov ah, SET_CURSOR
    mov bh,0x00
    mov dh,0x02
    mov dl,0x00
    int 0x10

    mov si,login_username          ; point si to login_username
    call print              ; display it on screen

_getUsernameinput:

    mov ax,0x00             ; get keyboard input
    int 0x16                ; hold for input

    cmp ah,0x1C             ; compare input is enter(1C) or not
    je .exitinput           ; if enter then jump to exitinput

    cmp ah,0x01             ; compare input is escape(01) or not
    je _skipLogin           ; jump to _skipLogin

    mov ah,0x0E             ;display input char
    int 0x10

    inc cx                  ; increase counter
    cmp cx,5                ; compare counter reached to 5
    jbe _getUsernameinput   ; yes jump to _getUsernameinput
    jmp .inputdone          ; else jump to inputdone

.inputdone:
    mov cx,0                ; set counter to 0
    jmp _getUsernameinput   ; jump to _getUsernameinput
    ret                     ; return

.exitinput:
    hlt


    ;****** read password

    ;set x y position to text
    mov ah, SET_CURSOR
    mov bh,0x00
    mov dh,0x03
    mov dl,0x00
    int 0x10

    mov si,login_password               ; point si to login_username
    call print                   ; display it on screen

_getPasswordinput:

    mov ax,0x00
    int 0x16

    cmp ah,0x1C
    je .exitinput
    

    cmp ah,0x01
    je _skipLogin

    inc cx

    cmp cx,5
    jbe _getPasswordinput
    
    jmp .inputdone

.inputdone:
    mov cx,0
    jmp _getPasswordinput
    ret
.exitinput:
    hlt

;****** display display_text on screen

    ;set x y position to text
    mov ah, SET_CURSOR
    mov bh,0x00
    mov dh,0x08
    mov dl,0x12
    int 0x10

    mov si, display_text        ;display display_text on screen
    call print

    ;set x y position to text
    mov ah, SET_CURSOR
    mov bh,0x00
    mov dh,0x9
    mov dl,0x10
    int 0x10

    mov si, os_info     ;display os_info on screen
    call print

    ;set x y position to text
    mov ah, SET_CURSOR
    mov bh,0x00
    mov dh,0x11
    mov dl,0x11
    int 0x10

    mov si, press_key_2     ;display press_key_2 on screen
    call print

    mov ah,0x00
    int 0x16


;//////////////////////////////////////////////////////////////////

_skipLogin:

    ;/////////////////////////////////////////////////////////////
    ; load third sector into memory

    mov ah, 0x03                    ; load third stage to memory
    mov al, 1
    mov dl, 0x80
    mov ch, 0
    mov dh, 0
    mov cl, 3                       ; sector number 3
    mov bx, _OS_Stage_3
    int 0x13

    jmp _OS_Stage_3





;////////////////////////////////////////////////////////////////////////////////////////





_OS_Stage_3:

    mov ax,0x13              ; clears the screen
    int 0x10

;//////////////////////////////////////////////////////////
; drawing window with lines

    push 0x0A000                ; video memory graphics segment
    pop es                      ; pop any extar segments from stack
    xor di,di                   ; set destination index to 0
    xor ax,ax                   ; set color register to zero

    ;//////////////////////////////////////////////
    ;******drawing top line of our window
    mov ax,0x02                 ; set color to green

    mov dx,0                    ; initialize counter(dx) to 0

    add di,320                  ; add di to 320(next line)
    imul di,10                  ;multiply by 10 to di to set y cordinate from where we need to start drawing

    add di,10                   ;set x cordinate of line from where to be drawn

_topLine_perPixel_Loop:

    mov [es:di],ax              ; move value ax to memory location es:di

    inc di                      ; increment di for next pixel
    inc dx                      ; increment our counter
    cmp dx,300                  ; comprae counter value with 300
    jbe _topLine_perPixel_Loop  ; if <= 300 jump to _topLine_perPixel_Loop

    hlt                         ; halt process after drawing

    ;//////////////////////////////////////////////
    ;******drawing bottm line of our window
    xor dx,dx
    xor di,di
    add di,320
    imul di,190         ; set y cordinate for line to be drawn
    add di,10           ;set x cordinate of line to be drawn

    mov ax,0x01         ; blue color

_bottmLine_perPixel_Loop:

    mov [es:di],ax

    inc di
    inc dx
    cmp dx,300
    jbe _bottmLine_perPixel_Loop
    hlt

    ;//////////////////////////////////////////////
    ;******drawing left line of our window
    xor dx,dx
    xor di,di
    add di,320
    imul di,10           ; set y cordinate for line to be drawn

    add di,10            ; set x cordinate for line to be drawn

    mov ax,0x03          ; cyan color

_leftLine_perPixel_Loop:

    mov [es:di],ax

    inc dx
    add di,320
    cmp dx,180
    jbe _leftLine_perPixel_Loop

    hlt 

    ;//////////////////////////////////////////////
    ;******drawing right line of our window
    xor dx,dx
    xor di,di
    add di,320
    imul di,10           ; set y cordinate for line to be drawn

    add di,310           ; set x cordinate for line to be drawn

    mov ax,0x06          ; orange color

_rightLine_perPixel_Loop:

    mov [es:di],ax

    inc dx
    add di,320
    cmp dx,180
    jbe _rightLine_perPixel_Loop

    hlt

    ;//////////////////////////////////////////////
    ;******drawing line below top line of our window
    xor dx,dx
    xor di,di

    add di,320
    imul di,27           ; set y cordinate for line to be drawn

    add di,11            ; set x cordinate for line to be drawn

    mov ax,0x05         ; pink color

_belowLineTopLine_perPixel_Loop:

    mov [es:di],ax

    inc di
    inc dx
    cmp dx,298
    jbe _belowLineTopLine_perPixel_Loop

    hlt 

    ;***** print window_text & X char

    ;set cursor to specific position
    mov ah, SET_CURSOR
    mov bh,0x00
    mov dh,0x01         ; y cordinate
    mov dl,0x02         ; x cordinate
    int 0x10

    mov si,window_text              ; point si to window_text
    call print

    hlt

    ;set cursor to specific position
    mov ah, SET_CURSOR
    mov bh,0x00
    mov dh,0x02           ; y cordinate
    mov dl,0x25           ; x cordinate
    int 0x10

    mov ah,0x0E
    mov al,0x58           ; 0x58=X
    mov bh,0x00
    mov bl,4              ; red color
    int 0x10

    hlt

    ;set cursor to specific position
    mov ah, SET_CURSOR
    mov bh,0x00
    mov dh,0x02           ; y cordinate
    mov dl,0x23           ; x cordinate
    int 0x10

    mov ah,0x0E
    mov al,0x5F           ; 0x58=X
    mov bh,0x00
    mov bl,9              ; red color
    int 0x10

    hlt

    ;set cursor to specific position
    mov ah, SET_CURSOR
    mov bh,0x00
    mov dh,0x05   ; y cordinate
    mov dl,0x09    ; x cordinate
    int 0x10

    mov si,hello_world_text
    call print

    hlt

    ;set cursor to specific position
    mov ah, SET_CURSOR
    mov bh,0x00
    mov dh,0x12   ; y cordinate
    mov dl,0x03  ; x cordinate
    int 0x10

    mov si,display_text
    call print

    hlt


    ; add how much memory we need
    times (1024 - ($-$$)) db 0x00
