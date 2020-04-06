format ELF64 executable 3

include "utils.inc"

; syscall(%rdi, %rsi, %rdx, %r10, %r8, %r9)

segment readable executable
entry $										; entrypoint is current address ($)										

	lea rsi, [save_buffer]					; loading rsi with ANSI code that saves current terminal buffer
	mov rdx, save_buffer_size				; loading rdx with save ANSI code size
    mov rdi, STDOUT
    mov rax, SYS_WRITE
    syscall									; saving current terminal

	lea rsi, [clear_screen]					; loading rsi with ANSI code that clears screen
	mov rdx, clear_screen_size				; loading rdx with clear screen ANSI code size
    mov rdi, STDOUT
    mov rax, SYS_WRITE
    syscall									; clearing the screen
	
	xor rdi, rdi							; this means fd will be STDIN (same as "mov rdi, STDIN")
	mov rsi, TIOCGWINSZ						; ioctl command to get window size
	mov rdx, winsz							; winsz struct will contain terminal size information
	mov rax, SYS_IOCTL 						; this approach is not always guaranteed to give results and
	syscall									; it's safer to use it in conjunction to a lookup in the termcap database

	call create_cursor						; creating ANSI code that moves to proper coordinates (result format: "ESC[x;yH")

	lea rsi, [cursor_buffer]				; loading rsi with ANSI code that moves cursor
	mov rdx, rax							; loading rdx with proper code length (without trailing null character)
    mov rdi, STDOUT						
    mov rax, SYS_WRITE						; in this program, the cursor will be set to the center of the screen
    syscall									; moving cursor to (x, y)

	xor rbx, rbx							; zeroing rbx to use it as index for message buffer		
	mov rcx, msg_size						; loading rcx with the message size

.outputLoop:
	push rcx								; saving msg_size in stack because syscall overwrites it

	lea rsi, [msg + rbx]					; loading rsi with msg[rbx] character
	mov rdx, 1								; length (rdx) is 1 since we are outputting a single byte at a time
   	mov rdi, STDOUT						
   	mov rax, SYS_WRITE						
    syscall									; prints msg[rbx] to STDOUT

	cmp byte [rsi], 0xa						; checking if current character is new line (\n)
  	jne .continue							; if not, skip .moveCursor and continue
	.moveCursor:
		inc [winsz.ws_row]					; incrementing X axis to account for new line
		call create_cursor					; creating new ANSI code to move cursor to new coordinates

		lea rsi, [cursor_buffer]			; loading rsi with ANSI code that moves cursor
		mov rdx, rax						; loading rdx with proper code length (without trailing null character)
	    mov rdi, STDOUT						
	    mov rax, SYS_WRITE
	    syscall								; moving cursor to (x, y)
	.continue:
		mov rdi, delay						; loading rdi with delay struct that contains seconds and nanoseconds to sleep
		xor rsi, rsi						; zeroing rsi because its not being used at this time
		mov rax, SYS_NANOSLEEP				; since it would contain the remaining time of the sleep in case command is interrupted
		syscall								; sleeping for the amount of time configured in delay struct

		pop rcx								; restoring msg_size from stack into rcx
		inc rbx								; incrementing rbx index
		loop .outputLoop					; repeat until whole msg is outputted

readline:
	lea rsi, [exit_msg]						; loading rsi formatted exit message with some included ANSI codes
	mov rdx, exit_msg_size					; loading rdx with exit message size
	mov rdi, STDOUT
	mov rax, SYS_WRITE
	syscall									; write exit message to the screen

	mov rdi, STDIN		
	mov rdx, 1
	mov rax, SYS_READ						; reading a single char from STDIN before restoring previous terminal buffer
	syscall									; pausing execution in the meantime

restoreTerminal:
	lea rsi, [restore_buffer]				; loading rsi with ANSI code to restore previous terminal buffer
	mov rdx, restore_buffer_size			; loading rdx with restore ANSI code size
	mov rdi, STDOUT
	mov rax, SYS_WRITE
	syscall									; restoring previous terminal (from before running this program)

exit:
	xor rdi, rdi							; exit code 0
	mov rax, SYS_EXIT						; ciao!
	syscall

; RO segment below
segment readable
delay				TIMESPEC
save_buffer			db ESC, "[?1049h"
save_buffer_size 	= $ - save_buffer

restore_buffer 		db ESC, "[?1049l"
restore_buffer_size = $ - restore_buffer

clear_screen 		db ESC, "[2J"
clear_screen_size 	= $ - clear_screen

; more about ANSI escape codes https://en.wikipedia.org/wiki/ANSI_escape_code
bold				equ ESC, "[1m"
reverse				equ ESC, "[7m"
blink				equ ESC, "[5m"
reset				equ ESC, "[0m"
red					equ ESC, "[31m"
green				equ ESC, "[32m"
yellow				equ ESC, "[33m"
blue				equ ESC, "[34m"

msg					db bold, "Obi-Wan Kenobi:", reset, " Hello there!", 0xa 
					db bold, "Grievous:", reset, " General Kenobi!", 0xa, 0xa
					db "Having fun with ", red, "A", green, "N", yellow, "S", blue, "I", reset, " codes and Assembly :)", 0xa, 0xa, 0
msg_size			= $ - msg

exit_msg			db "Press ", blink, reverse, "ENTER", reset, " to exit...", 0
exit_msg_size		= $ - exit_msg

; RW segment below
segment readable writable
winsz 				WINSZ
previous_axisX		dw ?
itoa_buffer			rb 11
cursor_buffer		rb 16
