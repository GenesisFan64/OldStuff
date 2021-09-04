;By HardWareMan

;"
;And I think, that second byte (when first time you set SYN=0) contains in LRUD field an ID, wich will different for each hardware
;and 0xF for unattached open port. At least Comix Zone, using this field, recognize 3 or 6 button pads.
;I wish to get full ID table of Genesis/MD peripheral hardware.
;And one more thing: 6 button joypad, when you set it to extra button mode for reading them, needs some time to reset own state.
;So, you can't read twice 6 button joypad so fast
;"

;====================================================================================================================================

;Buttons map
RAM_Control_1_Extra		equ	$FFFFFFA0;$FFFFF602
RAM_Control_1_ExtraPress	equ	$FFFFFFA2;$FFFFF603
RAM_Control_1_Hold		equ	$FFFFFFA4;$FFFFF604
RAM_Control_1_Press 		equ     $FFFFFFA6;$FFFFF605

RAM_Control_2_Extra 		equ     $FFFFFFA8;$FFFFF606
RAM_Control_2_ExtraPress 	equ     $FFFFFFAA;$FFFFF607
RAM_Control_2_Hold 		equ     $FFFFFFAC;$FFFFF608
RAM_Control_2_Press 		equ     $FFFFFFAE;$FFFFF609

JoyUp		equ	$0001
JoyDown		equ	$0002
JoyUpDown	equ	$0003
JoyLeft		equ	$0004
JoyRight	equ	$0008
JoyLeftRight	equ	$000C
JoyCursor	equ	$000F
JoyB		equ	$0010
JoyC		equ	$0020
JoyA		equ	$0040
JoyABC		equ	$0070
JoyStart	equ	$0080
JoyABCS		equ	$00F0
JoyZ		equ	$0100
JoyY		equ	$0200
JoyX		equ	$0400
JoyMode		equ	$0800
JoyMS		equ	$0880
JoyXYZM		equ	$0F00
JoyAnyButton	equ	$0FF0
JoyAnyKey	equ	$0FFF

Detect6buttonPad_Player1:			   ; It works on the real thing and emus (Tiido)
		MOVE.B  #$00, ($A10003) ; Pull TH line low
		MOVE.B  #$40, ($A10003) ; Pull TH line high
		MOVE.B  #$00, ($A10003) ; Pull TH line low
		MOVE.B  #$40, ($A10003) ; Pull TH line high
		MOVE.B  #$00, ($A10003) ; Pull TH line low
		MOVE.B  ($A10003),D0    ; Read controller port
		AND.B   #$0F, D0	    ; Mask out unneeded data
		MOVE.B  #$40, ($A10003) ; Pull TH line high
		MOVE.B  #$00, ($A10003) ; Pull TH line low
		MOVE.B  ($A10003),D1    ; Read controller port
		LSL.B   #4, D1
		OR.B    D1, D0
		RTS

ReadJoypads:
		jsr    Detect6buttonPad_Player1
		cmp.b  #$F0,d0
		bne    ReadJoypads_3Button

ReadJoypads_6Button:
	lea	(RAM_Control_1_Hold).w,a0
	lea	($A10003).l,a1
	jsr	Joypad_Read_6Button
	lea	(RAM_Control_2_Hold).w,a0
	adda	#2,a1

;By HardWareMan (SpritesMind), modified by GF64

Joypad_Read_6Button:
	clr.l    d0                ;Clear d0
	clr.l    d1                ;Clear d1
	move.b    #$40,(a1)            ;SYN = 1
	nop                    ;Delay
	nop                    ;Delay
	move.b    (a1),d1                ;Reading first 6 buttons
	andi.b    #$3F,d1                ;Mask it
	move.b    #$00,(a1)            ;SYN = 0
	nop                    ;Delay
	nop                    ;Delay
	move.b    (a1),d0                ;Read second 2 buttons
	and.b    #$30,d0                ;Mask it
	rol.b    #2,d0                ;Shift by 2 bits
	or.b    d0,d1                ;Combine basic 8 buttons and store it to d1
	move.b    #$40,(a1)            ;SYN = 1
	nop                    ;Delay
	nop                    ;Delay
	move.b    #$00,(a1)            ;SYN = 0
	nop                    ;Delay
	nop                    ;Delay
	move.b    #$40,(a1)            ;SYN = 1
	nop                    ;Delay
	nop                    ;Delay
	move.b    #$00,(a1)            ;SYN = 0
	nop                    ;Delay
	nop                    ;Delay
	move.b    #$40,(a1)            ;SYN = 1
	nop                    ;Delay
	nop                    ;All this for unlock extra buttons (XYZM)
	move.b    (a1),d0                ;Read extra buttons
	andi.b    #$0F,d0                ;Mask it
	eor.b    #$0F,d0                ;Invert it
	rol.l    #8,d0                ;Shift it by 8 bits
	or.w    d1,d0                ;Combine it with basic buttons
	not.b    d0                ;Invert basic buttons
	move.w    (a0),d1                ;[GF64]
	eor.w    d0,d1                ;[GF64]
	move.b    #$40,(a1)            ;SYN = 1
	move.w    d0,(a0)+            ;Save joystick state
	and.w    d0,d1                ;[GF64]
	move.w    d1,(a0)+            ;[GF64]
	rts

;--------------------------------------------------------------------------
ReadJoypads_3Button:
	lea    (RAM_Control_1_Hold+$1).w,a0
	lea    ($A10003).l,a1
	jsr    Joypad_Read
	lea    (RAM_Control_2_Hold+$1).w,a0
	lea    ($A10005).l,a1
Joypad_Read:
	move.b    #0,(a1)
	nop
	nop
	move.b    (a1),d0
	lsl.b    #2,d0
	andi.b    #$C0,d0
	move.b    #$40,(a1)
	nop
	nop
	move.b    (a1),d1
	andi.b    #$3F,d1
	or.b    d1,d0
	not.b    d0
	move.b    (a0),d1
	eor.b    d0,d1
	move.b    d0,(a0)+
	and.b    d0,d1
	move.b    d1,1(a0)
	rts

JoypadInit:
	moveq	#$40,d0
	move.b	d0,($A10009).l
	move.b	d0,($A1000B).l
	move.b	d0,($A1000D).l
	move.w	#0,($A11100).l
	rts