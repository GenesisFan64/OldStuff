; ====================================================================
; Input
; ====================================================================

		include	"system/input/map.asm"

; ====================================================================
; -------------------------------------------------
; Read input
; -------------------------------------------------

Input_Read:
		lea	(RAM_Control_1),a5
		moveq	#0,d0
		bsr.s	@DoIt
		lea	(RAM_Control_2),a5
		moveq	#1,d0
		bsr.s	@DoIt
		rts

; ---------------------------------------

@DoIt:
		lea	($A10003).l,a6
		lsl.w	#1,d0
		add.w	d0,a6			;Add result to port
		bsr	@FindJoypad
		move.b	d0,(a5)

                cmp.b	#$F,d0
                beq.s	@End
		cmp.b	#$D,d0
                beq.s	@Controller
  		cmp.b	#7,d0			;Multitap
                beq.s	@End
		cmp.b	#3,d0
                beq	@Mouse

@End:
		rts

; ------------------------------------
; Controller
; ------------------------------------

@Controller:
		move.b	#$40,6(a6)
		nop
		nop
		move.b	#$40,(a6)		; Show CB|RLDU
		nop
		nop
		move.b	#$00,(a6)		; Show SA|RLDU
		nop
		nop
		move.b	#$40,(a6)		; Show CB|RLDU
		nop
		nop
		move.b	#$00,(a6)		; Show SA|RLDU
		nop
		nop
		move.b	#$40,(a6)		; "Okay OKAY!, I have more buttons"
		nop
		nop
		move.b	(a6),d0
 		move.b	#$00,(a6)		; "Heres my ID"
  		nop
  		nop
 		move.b	(a6),d1
 		move.b	#$40,(a6)
 		nop
 		nop
		
		move.b	PadType(a5),d2
		bclr	#0,d2
		and.w	#$F,d1
		cmp.w	#$F,d1
		bne.s	@Original
		
		bset	#0,d2
 		moveq	#0,d1
 		move.b	ExOnHold(a5),d1
		not.b	d1
 		eor.b	d0,d1
 		and.b	d0,d1
 		and.w	#$F,d1
 		move.b	d1,ExOnPress(a5)
 		not.b	d0
 		and.w	#$F,d0
 		move.b	d0,ExOnHold(a5)
 		
@Original:	
		move.b	d2,PadType(a5)
	
		move.b	#0,(a6)
		nop
		nop
		move.b	(a6),d0
		lsl.b	#2,d0
		and.b	#$C0,d0	
		move.b	#$40,(a6)
		nop
		nop
		move.b	(a6),d1
; 		move.w	#0,($A11100)
		and.b	#$3F,d1
		or.b	d1,d0
		not.b	d0
		move.b	OnHold(a5),d1
		eor.b	d0,d1
		move.b	d0,OnHold(a5)
		and.b	d0,d1
		move.b	d1,OnPress(a5)
		rts

; ; ------------------------------------
; ; Multitap
; ; ------------------------------------
; 
; @Multitap:
; 		bra	@End

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
		
		move.l	d2,d0
		swap	d0
		and.w	#$FF,d0
		move.b	OnHold(a5),d1
		eor.b	d0,d1
		move.b	d0,OnHold(a5)
 		and.b	d0,d1
		move.b	d1,OnPress(a5)
		
		;TODO
		move.w	d2,d0
		and.w	#$FF,d0
		ext.w	d0
		neg.w	d0
 		move.w	d0,MouseY(a5)
 		
 		lsr.w	#8,d2
 		and.w	#$FF,d2
		ext.w	d2
 		move.w	d2,MouseX(a5)
 		bra	@End

; ------------------------------------

@ReadIt:
; 		movem.l	d1/d3/d4/d7/a6,-(sp)

		moveq	#0,d0			;Error flag
		cmp.w	#2,d1			;Control ID < 2?
		bhi	@Error
		add.w	d1,d1
	;	lea	($A10003),a6
@Connect:
		move.b	#$60,6(a6)
                nop
                nop
                move.b	#$60,(a6)		;TH,TR=11 (END DATA)
                moveq	#0,d2
                moveq	#0,d3
@NotReady:
 		btst	#4,(a6)
 		beq.s	@NotReady
 		move.b	(a6),d4			;d4.b = ? 1 1 1 | 0 0 0
 		and.b	#$F,d4
 		tst.b	d4
 		bne	@Error			;No mouse
 		move.b	#$20,(a6)		;Select t1 m1 1 1
 		move.w	#$FE,d7
@lp1:
		btst.b	#4,(a6)
		bne.s	@Mouse_10
		dbra	d7,@lp1
		bra	@Error
		
@Mouse_10:
		move.b	(a6),d0			;d0 = xxxx|xxxx|xxxx|t1 m1 1 1
		lsl.w	#8,d0			;d0 = xxxx|t1 m1 1 1|0000|0000
		move.b	#0,(a6)
		nop
@lp2:
		btst	#4,(a6)
		beq.s	@Mouse_20
		dbra	d7,@lp2
		bra	@Error
		
@Mouse_20:
		move.b	(a6),d3
		move.b	#$20,(a6)
		lsl.w	#8,d3
@lp3:
		btst	#4,(a6)
		bne.s	@Mouse_30
		dbra	d7,@lp3
		bra	@Error
		
@Mouse_30:
		move.b	(a6),d3
		lsl.b	#4,d3
		lsr.w	#4,d3
		move.b	#0,(a6)
		or.w	d3,d0
		moveq	#0,d3
@lp4:
		btst	#4,(a6)
                beq.s	@Mouse_40
                dbra	d7,@lp4
                bra	@Error

@Mouse_40:
		move.b	(a6),d2
		move.b	#$20,(a6)
		lsl.w	#8,d2
@lp5:
		btst	#4,(a6)
		bne.s	@Mouse_50
		dbra	d7,@lp5
		bra	@Error
		
@Mouse_50:
		move.b	(a6),d2
		move.b	#0,(a6)
		lsl.b	#4,d2
		lsl.w	#4,d2
@lp6:
		btst	#4,(a6)
		beq.s	@Mouse_60
		dbra	d7,@lp6
		bra	@Error

@Mouse_60:
		move.b	(a6),d2
		move.b	#$20,(a6)
		lsl.b	#4,d2
		lsl.l	#4,d2
@lp7:
		btst	#4,(a6)
		bne.s	@Mouse_70
		dbra	d7,@lp7
		bra.s	@Error

@Mouse_70:
		move.b	(a6),d2
		move.b	#0,(a6)
		lsl.b	#4,d2
		lsl.l	#4,d2
@lp8:
		btst	#4,(a6)
		beq.s	@Mouse_80
		dbra	d7,@Mouse_80
		bra.s	@Error

@Mouse_80:
		move.b	(a6),d2
		move.b	#$20,(a6)
		lsl.b	#4,d2
		lsl.l	#4,d2
@lp9:
		btst	#4,(a6)
		beq.s	@Mouse_90
		dbra	d7,@lp9
		bra.s	@Error

@Mouse_90:
		move.b	(a6),d2
		move.b	#$60,(a6)
		lsl.b	#4,d2
		lsr.l	#4,d2
@lp10:
		btst	#4,(a6)
		beq.s	@lp10
		or.l	#0,d2
@Exit:
		move.w	#0,($A11100)
; 		movem.l	(sp)+,d1/d3/d4/d7/a6
		rts

@Error:
		move.b	#$60,(a6)
		nop
		nop
@erlp:
		move.b	#4,(a6)
		beq.s	@erlp
		or.l	#$80000000,d2
		moveq	#0,d0
		move.w	#0,($A11100)
; 		movem.l	(sp)+,d1/d3/d4/d7/a6
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
		move.b	#$70,(a6)
		bsr.s	@GetPress
		swap	d1
		move.b	#$30,(a6)
		add.w	d0,d0

@GetPress:
		move.b	(a6),d1
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
		
; ====================================================================
; -------------------------------------------------
; Subs
; -------------------------------------------------

Input_init:
; 		move.w	#$100,($A11100).l
; @WaitZ80:
; 		btst	#0,($A11100).l
; 		bne.s	@WaitZ80
 
		moveq	#$40,d1
		move.b	d1,($A10009).l
		move.b	d1,($A1000B).l
		move.b	d1,($A1000D).l

; 		move.w	#0,($A11100).l
		rts
		
