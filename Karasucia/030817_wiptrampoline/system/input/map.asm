; ====================================================================
; Input
; ====================================================================

; ====================================================================
; -------------------------------------------------
; Variables
; -------------------------------------------------

JoyUp		equ	%00000001
JoyDown		equ	%00000010
JoyLeft		equ	%00000100
JoyRight	equ	%00001000
JoyB		equ	%00010000
JoyC		equ	%00100000
JoyA		equ	%01000000
JoyStart	equ	%10000000
bitJoyUp	equ	0
bitJoyDown	equ	1
bitJoyLeft	equ	2
bitJoyRight	equ	3
bitJoyB		equ	4
bitJoyC		equ	5
bitJoyA		equ	6
bitJoyStart	equ	7

JoyZ		equ	%00000001
JoyY		equ	%00000010
JoyX		equ	%00000100
JoyMode		equ	%00001000
bitJoyZ		equ	0
bitJoyY		equ	1
bitJoyX		equ	2
bitJoyMode	equ	3

; --------------------------------------------

		rsreset
CtrlID		rs.b	1
PadType		rs.b	1		;only TRUE $01 or FALSE $00
ExOnHold	rs.b	1		;MYXZ		DONT SEPARATE (so this can be read as a word)
OnHold		rs.b	1		;SACBRLDU
ExOnPress	rs.b	1		;MYXZ		DONT SEPARATE (so this can be read as a word)
OnPress		rs.b	1		;SACBRLDU
MouseX		rs.w	1		;TODO
MouseY		rs.w	1
sizeof_control	rs.l	0

; ====================================================================
; -------------------------------------------------
; RAM
; -------------------------------------------------

                rsset	RAM_Input
RAM_Control_1	rs.b sizeof_control
RAM_Control_2	rs.b sizeof_control

; --------------------------------------------

sizeof_input	rs.l	0
; 		inform 0,"input ram: %h",(sizeof_input-RAM_Input)
 				
; ====================================================================
; -------------------------------------------------
; Macros
; -------------------------------------------------

; --------------------------------------------
