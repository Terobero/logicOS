[bits 16]           ; tell assembler that working in real mode(16 bit mode)
[org 0x7c00]        ; organize from 0x7C00 memory location where BIOS will load us

SET_CURSOR equ 0x02

USERNAME_SIZE equ 30


	
	


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
	
	int 0x10	; video refresh
	
	call newline
	mov si, line1	; point string to source index
	call print
	
	call newline
	call newline
	mov si, line2
	call print
	
	mov cx, USERNAME_SIZE
	mov esi, username	; move pointer to username's location
	call input
	ret



input:	
	
	
	mov ax, 0x00	; get keyboard input
	int 0x16	; interrupt for hold & read input
	
	;for input, al is ASCII code / ah is keyboard code
	
	cmp ah, 0x1C	; check if ENTER is pressed
	je .exitInput
	
	cmp ah, 0x0E	; check if BACKSPACE is pressed
	je .backspace
	
	cmp al, 0x20	; check if SPACE is pressed
	je .canPrint
	
	cmp al, 0x61	; check if it is a small letter
	jge .validChar
	
	cmp al, 0x41	; check if it is a large letter
	jge .validCaps
	
	cmp al, 0x30	; check if it is an integer
	jge .validInt
	
	jmp input	; ask for a valid key
	
	.canPrint:
		mov [esi], al	; move input to pointed place in memory
		inc esi		; increase pointer by 1
		
		mov ah, 0x0E	; show the character pressed on the screen
		int 0x10	
		
		
	loop input
	jmp .exitInput
	
	
.validInt:
	cmp al, 0x39	; if it is an integer, print it
	jle .canPrint
	jmp input	; else, jump to input

.validCaps:
	cmp al, 0x5A	; if it is a large letter, print it
	jle .canPrint
	jmp input	; else, jump to input
	
.validChar:
	cmp al, 0x7A	; if it is a small letter, make it caps
	jle .makeCaps
	jmp input	; else, jump to input
	
.makeCaps:
	sub al, 0x20	; make the character large, print it
	jmp .canPrint
	
.backspace:
	cmp esi, username	; so the pointer doesn't go more back than the username array
	jle input		; goes back to input without doing anything
	
	dec dl	; decrease dl by 1, so the insert pointer goes one char left
	add cx, 0x02	; add 2 to cx 1 for BACKSPACE not counting as a loop and 1 for the letter you will put in place of the deleted one
	sub esi, 0x02	; decrease the pointer by one (the pointer goes 1 back in the USERNAME array), decrease again so BACKSPACE doesn't take a place in the array
	jmp .canPrint	; show it on screen
	
	
	


.exitInput:
	call newline
	
	sub esi, USERNAME_SIZE
	
	mov si, username_greet
	call print
	
	mov si, username
	call print
	
	ret



	; declaring strings
	line1 db 'LOGIC, 16-BIT, V1.0', 0
	line2 db 'USERNAME : ', 0

	login_username db 'Username : ',0
	login_password db 'Password : ',0
	
	username times USERNAME_SIZE db 0x00, 0
	username_greet db 'WELCOME ', 0


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
