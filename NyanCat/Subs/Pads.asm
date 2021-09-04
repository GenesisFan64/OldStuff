RAM_Control_1_Hold			equ		$FFFFFFE0	;Byte
RAM_Control_1_Press			equ		$FFFFFFE1	;Byte
RAM_Control_2_Hold			equ		$FFFFFFE2	;Byte
RAM_Control_2_Press			equ		$FFFFFFE3	;Byte

JoyUp					equ		$01
JoyDown					equ		$02
JoyUpDown				equ		$03
JoyLeft					equ		$04
JoyUpLeft				equ		$05
JoyDownLeft				equ		$06
JoyUnk07				equ		$07
JoyRight				equ		$08
JoyUpRight				equ		$09
JoyDownRight				equ		$0A
JoyUnk0B				equ		$0B
JoyLeftRight				equ		$0C
JoyCursor				equ		$0F
JoyB					equ		$10
JoyC					equ		$20
JoyA					equ		$40
JoyABC					equ		$70
JoyStart				equ		$80
JoyAStart				equ		$C0
JoyABCS					equ		$F0

; ======================== S U B R O U T I N E ==========================================

JoypadInit:
		move.w	#$100,($A11100).l

JoypadInit_Z80Wait:
		btst	#0,($A11100).l
		bne.s	JoypadInit_Z80Wait
		moveq	#$40,d0
		move.b	d0,($A10009).l
		move.b	d0,($A1000B).l
		move.b	d0,($A1000D).l
		move.w	#0,($A11100).l
		rts

; =============== S U B R O U T I N E ==========================================


ReadJoypads:
		lea	(RAM_Control_1_Hold).w,a0
		lea	($A10003).l,a1
		bsr.s	Joypad_Read
		addq.w	#2,a0
		addq.w	#2,a1

Joypad_Read:
		move.b	#0,(a1)
		nop
		nop
		move.b	(a1),d0
		lsl.b	#2,d0
		andi.b	#$C0,d0
		move.b	#$40,(a1) ; '@'
		nop
		nop
		move.b	(a1),d1
		andi.b	#$3F,d1	; '?'
		or.b	d1,d0
		not.b	d0
		move.b	(a0),d1
		eor.b	d0,d1
		move.b	d0,(a0)+
		and.b	d0,d1
		move.b	d1,(a0)+
		rts