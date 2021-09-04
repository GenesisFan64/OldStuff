; =====================================================
; FadeIn/FadeOut
; =====================================================

; ---------------------------------------
; Equs
; ---------------------------------------

; PalFadeHint		equ	$50

ID_FadeOut		equ	$01000000
ID_FadeIn		equ	$02000000
ID_ToWhite		equ	$03000000
ID_FadeWhite		equ	$04000000

; ---------------------------------------

PalFadeFlags		equ	1
PalFadeStart		equ	2
PalFadeEnd		equ	3
PalFadeTmr		equ	4
PalFadeSource		equ	8

; =====================================================

PalFade:
		lea	(RAM_RunFadeCol),a6
		btst	#7,(a6)
		beq.s	@NotFinished
		sub.w	#1,PalFadeTmr+2(a6)
		bpl	@Return
		bra	@Finished

@NotFinished:
		moveq	#0,d0
		move.b	(a6),d0
		add.w	d0,d0
		move.w	@DoList(pc,d0.w),d1
		jmp	@DoList(pc,d1.w)

; =====================================================

@DoList:
		dc.w	@Return-@DoList
		dc.w	@FadeOut-@DoList
		dc.w	@FadeIn-@DoList
		dc.w	@ToWhite-@DoList
		dc.w	@FromWhite-@DoList
		even

; =====================================================
; ---------------------------------------------------
; FadeOut
; ---------------------------------------------------

@FadeOut:
		sub.w	#1,PalFadeTmr+2(a6)
		bpl	@Return
		move.w	PalFadeTmr(a6),PalFadeTmr+2(a6)

		lea	(RAM_PalBuffer),a0
		lea	(RAM_PalBufferHint),a1

		move.w	PalFadeStart(a6),d3
		move.w	d3,d4
		lsr.w	#8,d4
		adda	d4,a0
		adda	d4,a1

		move.w	#$3F,d6
		moveq	#0,d2
@Next:
		move.w	(a0),d0
		move.w	d0,d1
		and.w	#$F,d1
		tst.w	d1
		beq.s	@RedLast
		sub.b	#2,d0
@RedLast:
		move.w	d0,d1
		lsr.w	#4,d1
		and.w	#$F,d1
		tst.w	d1
		beq.s	@GreenLast
		sub.w	#$20,d0
@GreenLast:
		move.w	d0,d1
		lsr.w	#8,d1
		and.w	#$F,d1
		tst.w	d1
		beq.s	@BlueLast
		sub.w	#$200,d0
@BlueLast:
		tst.w	d0
		bne.w	@NotBlack
		add.w	#1,d2
@NotBlack:
		move.w	d0,(a0)+
		move.w	d0,(a1)+
		dbf	d6,@Next

		moveq	#0,d4
		move.b	d3,d4
		cmp.w	d4,d2
		blt	@Return

		bset	#7,(a6)
		move.w	PalFadeTmr(a6),PalFadeTmr+2(a6)
		rts

; =====================================================
; ---------------------------------------------------
; FadeIn
; ---------------------------------------------------

@FadeIn:
		sub.w	#1,PalFadeTmr+2(a6)
		bpl	@Return
		move.w	PalFadeTmr(a6),PalFadeTmr+2(a6)

		lea	(RAM_PalBuffer),a0
		lea	(RAM_PalBufferHint),a2
		lea	(RAM_PalFadeBuff),a1

		move.w	PalFadeStart(a6),d7
		move.w	d7,d4
		lsr.w	#8,d4
		adda	d4,a0
		adda	d4,a2

		moveq	#0,d6
		move.b	PalFadeStart+1(a6),d6
		moveq	#0,d5
@Next_2:
		move.w	(a0),d0
		move.w	(a1),d1
		move.w	d0,d2
		move.w	d1,d3
		and.w	#$F,d2
		and.w	#$F,d3
		cmp.w	d3,d2
		bge.s	@RedFirst
		add.w	#2,d0
@RedFirst:

		move.w	d0,d2
		move.w	d1,d3
		lsr.w	#4,d2
		lsr.w	#4,d3
		and.w	#$F,d2
		and.w	#$F,d3
		cmp.w	d3,d2
		bge.s	@GreenFirst
		add.w	#$20,d0
@GreenFirst:

		move.w	d0,d2
		move.w	d1,d3
		lsr.w	#8,d2
		lsr.w	#8,d3
		and.w	#$F,d2
		and.w	#$F,d3
		cmp.w	d3,d2
		bge.s	@BlueFirst
		add.w	#$200,d0
@BlueFirst:	
		move.w	d0,d2
		move.w	(a1),d1
		cmp.w	d2,d1
		bne.s	@NotEqual
		add.w	#1,d5
@NotEqual:
		adda	#2,a1
		move.w	d0,(a0)+
		move.w	d0,(a2)+
		dbf	d6,@Next_2

		sub.w	#1,d5
		move.w	d5,PalFadeSource(a6)

		moveq	#0,d4
		moveq	#0,d2
		move.b	PalFadeStart+1(a6),d2
		move.b	d5,d4
		cmp.w	d4,d2
		bgt	@Return
		
		bset	#7,(a6)
		move.w	PalFadeTmr(a6),PalFadeTmr+2(a6)
		rts

; =====================================================
; ---------------------------------------------------
; ToWhite
; ---------------------------------------------------

@ToWhite:
		lea	(RAM_PalBuffer),a0
		sub.w	#1,PalFadeTmr+2(a6)
		bpl.s	@Return
		move.w	PalFadeTmr(a6),PalFadeTmr+2(a6)

		move.w	PalFadeStart(a6),d3

		move.w	#$3F,d6
		moveq	#0,d2
@NextW:
		move.w	(a0),d0
		move.w	d0,d1
		and.w	#$F,d1
		cmp.w	#$E,d1
		beq.s	@RedLastW
		add.b	#2,d0
@RedLastW:
		move.w	d0,d1
		lsr.w	#4,d1
		and.w	#$F,d1
		cmp.w	#$E,d1
		beq.s	@GreenLastW
		add.w	#$20,d0
@GreenLastW:
		move.w	d0,d1
		lsr.w	#8,d1
		and.w	#$F,d1
		cmp.w	#$E,d1
		beq.s	@BlueLastW
		add.w	#$200,d0
@BlueLastW:
		cmp.w	#$EEE,d0
		blt.w	@NotWhite
		add.w	#1,d2
@NotWhite:
		move.w	d0,(a0)+
		dbf	d6,@NextW

		moveq	#0,d4
		move.b	d3,d4
		cmp.w	d4,d2
		blt.s	@Return
		
		bset	#7,(a6)
		move.w	PalFadeTmr(a6),PalFadeTmr+2(a6)
		rts

; =====================================================
; ---------------------------------------------------
; FromWhite
; ---------------------------------------------------

@FromWhite:
		clr.b	(a6)
		rts

; =====================================================
; ---------------------------------------------------
; Subs
; ---------------------------------------------------

@Finished:
 		move.w	PalFadeTmr(a6),PalFadeTmr+2(a6)
		clr.b	(a6)
@Return:
		rts

; =====================================================
; External
; =====================================================

PalFade_Set:
		movem.l	a6,-(sp)
		lea	(RAM_RunFadeCol),a6

		move.l	d0,d2
		move.l	d1,PalFadeStart(a6)
		move.w	PalFadeTmr(a6),PalFadeTmr+2(a6)
		swap	d0
		lsr.w	#8,d0
		move.b	d0,(a6)
		move.l	d2,d0

		movem.l	(sp)+,a6
		rts
		
PalFade_Wait:
 		bsr	VSync

		tst.b	(RAM_RunFadeCol)
		bne.s	PalFade_Wait
		rts

PalFade_Wait_Flag:
 		moveq	#-1,d6
		tst.b	(RAM_RunFadeCol)
		bne.s	@no
		moveq	#0,d6
@no:
		tst.w	d6
		rts
		
; =====================================================
; MARS
; =====================================================

; PalFadeMars_Set:
;  		if MARS=1
;  		move.l	d0,d2
;  		cmp.l	#ID_FadeIn,d2
;  		bne.s	@NotFadeIn
;  
;  		move.w	d1,(marsreg+comm4)
;   		moveq	#M_PalFade_In,d0
;  		bsr	Mars_DoTask_Master
; @NotFadeIn:
;  		cmp.l	#ID_FadeOut,d2
;  		bne.s	@NotFadeOut
;  
;  		move.w	d1,(marsreg+comm4)
;   		moveq	#M_PalFade_Out,d0
;  		bsr	Mars_DoTask_Master
; @NotFadeOut:
;  		endif
; 		rts
		
