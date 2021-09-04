; ====================================================================
; -------------------------------------------------
; Joypads/GG controller
; -------------------------------------------------

; -------------------------------------------------
; Variables
; -------------------------------------------------

pad             equ     0DCh    ; I/O PORT FOR JOYPAD AND FIRE BUTTONS
padright        equ     08h     ; \
padleft         equ     04h     ;  \___ bit values in joypad port register
padup           equ     01h     ;  /
paddown         equ     02h     ; /

bitJoyStart	equ	7	;MUST BE 7
bitJoy1		equ	4
bitJoy2		equ	5
bitJoyRight	equ	3
bitJoyLeft	equ	2
bitJoyDown	equ	1
bitJoyUp	equ	0

on_hold		equ	0
on_press	equ	1

; -------------------------------------------------
; Read
; -------------------------------------------------

pads_read:
		ld	ix,ram_joypads
		if MERCURY
		in	a,(00h)
		cpl
		and	%10000000
		ld	b,a
		endif
		in      a,(pad)
		xor     0FFh
		if MERCURY
		or	b
		endif
		ld	b,a
 		ld	a,(ix+on_hold)
 		xor	b
		ld	(ix+on_hold),b
		and	b	
		ld	(ix+on_press),a
		ret
		