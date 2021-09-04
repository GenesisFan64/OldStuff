; ====================================================================
; ---------------------------------------------
; Pads_Init
;
; Init joypads
; ---------------------------------------------

		rsreset
CtrlID		rs.b	1
FightPad	rs.b	1
ExOnHold	rs.b	1		;MYXZ
OnHold		rs.b	1		;SACBRLDU
ExOnPress	rs.b	1
OnPress		rs.b	1
Port2		equ	$10

MousePress	equ	3
MouseX		equ	4
MouseY		equ	5

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
; Pads_Init
; --------------------------------------------

Pads_Init:
		move.w	#$100,($A11100)
		move.w	#$100,($A11200)
@WaitZ80:
		btst	#0,($A11100)
 		bne.s	@WaitZ80
 
		moveq	#$40,d1
		move.b	d1,($A10009).l
		move.b	d1,($A1000B).l
		move.b	d1,($A1000D).l

		move.w	#0,($A11100).l
		rts

; --------------------------------------------
; Pads_Read
; --------------------------------------------

Pads_Read:
		move.w	#$100,($A11100)
		move.w	#$100,($A11200)
@WaitZ80:
		btst	#0,($A11100)
 		bne.s	@WaitZ80

		lea	(RAM_Joypads),a1
		moveq	#0,d0
		bsr.s	@DoIt
		lea	(RAM_Joypads+Port2),a1
		moveq	#1,d0
		bsr.s	@DoIt

		move.w	#0,($A11100).l
		rts

; ---------------------------------------

@DoIt:
		lea	($A10003).l,a0
		add.w	d0,d0			;1+1=2
		add.w	d0,a0			;Add result to port
		bsr	@FindJoypad
		move.b	d0,(a1)

                cmp.b	#$F,d0
                beq	@End
		cmp.b	#$D,d0
                beq	@Controller
  		cmp.b	#7,d0
                beq	@Multitap
		cmp.b	#3,d0
                beq	@Mouse

@End:
		rts

; ------------------------------------
; Controller
; ------------------------------------

@Controller:
		move.b	#$40,6(a0)
		nop
		nop
		move.b	#$40,(a0)		; Show CB|RLDU
		nop
		nop
		move.b	#$00,(a0)		; Show SA|RLDU
		nop
		nop
		move.b	#$40,(a0)		; Show CB|RLDU
		nop
		nop
		move.b	#$00,(a0)		; Show SA|RLDU
		nop
		nop
		move.b	#$40,(a0)		; "Okay OKAY!, I have more buttons"
		nop
		nop
		move.b	(a0),d0
 		move.b	#$00,(a0)		; "Heres my ID"
  		nop
  		nop
 		move.b	(a0),d1
 		move.b	#$40,(a0)
 		nop
 		nop
		
		moveq	#0,d2
		and.w	#$F,d1
		cmp.w	#$F,d1
		bne.s	@Original
		
		moveq	#1,d2
 		moveq	#0,d1
 		move.b	ExOnHold(a1),d1
		not.b	d1
;  		and.w	#$F,d2
;  		move.b	d2,d1
 		eor.b	d0,d1
;  		move.b	d0,d2
 		and.b	d0,d1
 		and.w	#$F,d1
 		move.b	d1,ExOnPress(a1)
;  		move.b	d2,d0
 		not.b	d0
 		and.w	#$F,d0
 		move.b	d0,ExOnHold(a1)
 		
@Original:	
		move.b	d2,FightPad(a1)
	
		move.b	#0,(a0)
		nop
		nop
		move.b	(a0),d0
		lsl.b	#2,d0
		and.b	#$C0,d0	
		move.b	#$40,(a0)
		nop
		nop
		move.b	(a0),d1
		and.b	#$3F,d1
		or.b	d1,d0
		not.b	d0
		move.b	OnHold(a1),d1
		eor.b	d0,d1
		move.b	d0,OnHold(a1)
		and.b	d0,d1
		move.b	d1,OnPress(a1)
		rts

; ------------------------------------
; Multitap
; ------------------------------------

@Multitap:
		bra	@End

; ------------------------------------
; Sega Mega Mouse
;
; in: d1 - port number
; out: d0 - status
;      d2
; ------------------------------------

@Mouse:
		moveq	#0,d1
		bsr	@ReadIt
		move.l	d2,2(a1)
		bra	@End

@ReadIt:
		movem.l	d1/d3/d4/d7/a0,-(sp)

		moveq	#0,d0			;Error flag
		cmp.w	#2,d1			;Control ID < 2?
		bhi	@Error
		add.w	d1,d1
	;	lea	($A10003),a0
@Connect:
		move.b	#$60,6(a0)
                nop
                nop
                move.b	#$60,(a0)		;TH,TR=11 (END DATA)
                moveq	#0,d2
                moveq	#0,d3
@NotReady:
 		btst	#4,(a0)
 		beq.s	@NotReady
 		move.b	(a0),d4			;d4.b = ? 1 1 1 | 0 0 0
 		and.b	#$F,d4
 		tst.b	d4
 		bne	@Error			;No mouse
 		move.b	#$20,(a0)		;Select t1 m1 1 1
 		move.w	#$FE,d7
@lp1:
		btst.b	#4,(a0)
		bne.s	@Mouse_10
		dbra	d7,@lp1
		bra	@Error
		
@Mouse_10:
		move.b	(a0),d0			;d0 = xxxx|xxxx|xxxx|t1 m1 1 1
		lsl.w	#8,d0			;d0 = xxxx|t1 m1 1 1|0000|0000
		move.b	#0,(a0)
		nop
@lp2:
		btst	#4,(a0)
		beq.s	@Mouse_20
		dbra	d7,@lp2
		bra	@Error
		
@Mouse_20:
		move.b	(a0),d3
		move.b	#$20,(a0)
		lsl.w	#8,d3
@lp3:
		btst	#4,(a0)
		bne.s	@Mouse_30
		dbra	d7,@lp3
		bra	@Error
		
@Mouse_30:
		move.b	(a0),d3
		lsl.b	#4,d3
		lsr.w	#4,d3
		move.b	#0,(a0)
		or.w	d3,d0
		moveq	#0,d3
@lp4:
		btst	#4,(a0)
                beq.s	@Mouse_40
                dbra	d7,@lp4
                bra	@Error

@Mouse_40:
		move.b	(a0),d2
		move.b	#$20,(a0)
		lsl.w	#8,d2
@lp5:
		btst	#4,(a0)
		bne.s	@Mouse_50
		dbra	d7,@lp5
		bra	@Error
		
@Mouse_50:
		move.b	(a0),d2
		move.b	#0,(a0)
		lsl.b	#4,d2
		lsl.w	#4,d2
@lp6:
		btst	#4,(a0)
		beq.s	@Mouse_60
		dbra	d7,@lp6
		bra	@Error

@Mouse_60:
		move.b	(a0),d2
		move.b	#$20,(a0)
		lsl.b	#4,d2
		lsl.l	#4,d2
@lp7:
		btst	#4,(a0)
		bne.s	@Mouse_70
		dbra	d7,@lp7
		bra.s	@Error

@Mouse_70:
		move.b	(a0),d2
		move.b	#0,(a0)
		lsl.b	#4,d2
		lsl.l	#4,d2
@lp8:
		btst	#4,(a0)
		beq.s	@Mouse_80
		dbra	d7,@Mouse_80
		bra.s	@Error

@Mouse_80:
		move.b	(a0),d2
		move.b	#$20,(a0)
		lsl.b	#4,d2
		lsl.l	#4,d2
@lp9:
		btst	#4,(a0)
		beq.s	@Mouse_90
		dbra	d7,@lp9
		bra.s	@Error

@Mouse_90:
		move.b	(a0),d2
		move.b	#$60,(a0)
		lsl.b	#4,d2
		lsr.l	#4,d2
@lp10:
		btst	#4,(a0)
		beq.s	@lp10
		or.l	#0,d2
@Exit:
		move.w	#0,($A11100)
		movem.l	(sp)+,d1/d3/d4/d7/a0
		rts

@Error:
		move.b	#$60,(a0)
		nop
		nop
@erlp:
		move.b	#4,(a0)
		beq.s	@erlp
		or.l	#$80000000,d2
		moveq	#0,d0
		move.w	#0,($A11100)
		movem.l	(sp)+,d1/d3/d4/d7/a0
		rts

; ------------------------------------
; d0.w
; $0F - Nothing
; $0D - Controller
; $07 - Multitap
; $03 - Mouse
;
; d1.l
; $00xx00yy - Key presses
; ------------------------------------

@FindJoypad:
		moveq	#0,d0
		move.b	#$70,(a0)
		bsr.s	@GetPress
		swap	d1
		move.b	#$30,(a0)
		add.w	d0,d0

@GetPress:
		move.b	(a0),d1
		move.b	d1,d2
		and.b	#$C,d2
		beq.s	@Nope1
		addq.w	#1,d0

@Nope1:
		add.w	d0,d0
		move.b	d1,d3
		and.w	#3,d3
		beq.s	@Nope2
		addq.w	#1,d0

@Nope2:
		rts