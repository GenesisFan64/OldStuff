; =================================================================
; Object
; 
; Level end flag
; =================================================================

; =================================================================
; ------------------------------------------------
; Variables
; ------------------------------------------------

varHudBase	equ	$C000|$580
varVramHudCoinR	equ	$C000|$5A8
varVramHudCoinB	equ	$C000|$5AC
varHudLife	equ	$C000|$5B0
varHudLifeBar	equ	$C000|$5BC
varHudDigits	equ	$C000|$5C0

		rsset obj_ram
ramLastCoins	rs.w	1
ramDecCoins 	rs.w	1
ramLastLives	rs.w	1
ramDecLives 	rs.w	1

; =================================================================
; ------------------------------------------------
; Code start
; ------------------------------------------------

obj_HudInfo:
 		moveq	#0,d0
 		move.b	obj_index(a6),d0
 		add.w	d0,d0
 		move.w	@Index(pc,d0.w),d1
 		jmp	@Index(pc,d1.w)
 		
; ------------------------------------------------

@Index:
		dc.w	@Init-@Index
		dc.w	@Main-@Index
		even
		
; =================================================================
; ------------------------------------------------
; Index $00: Init
; ------------------------------------------------

@Init:
		add.b	#1,obj_index(a6)
 		bset	#bitobj_stay,obj_status(a6)
		move.w	#0,ramLastCoins(a6)
		
		move.w	#1,ramLastCoins(a6)
		move.w	#1,ramLastLives(a6)
		
; =================================================================
; ------------------------------------------------                  
; Index $01: Main
; ------------------------------------------------

@Main:
		move.l	#8<<16|8,d0
		move.l	#5<<16|varVramHudCoinR,d1
		bsr	Object_ExtSprite
		move.l	#8<<16|24,d0
		move.l	#5<<16|varHudLife,d1
		bsr	Object_ExtSprite
		

		move.l	#8<<16|48,d0
		move.l	#varHudLifeBar,d1
		move.w	(RAM_P1_Hits),d2
		cmp.w	#8,d2
		blt.s	@lower
		move.w	#8,d2
@lower:
		tst.w	d2
		beq.s	@dead
		sub.w	#1,d2
		tst.w	d2
		bne.s	@addbox
		add.w	#1,d1
@addbox:
		bsr	Object_ExtSprite
		add.l	#$80000,d0
		dbf	d2,@addbox
@dead:

		moveq	#0,d2
		move.w	(RAM_P1_Coins),d2
		cmp.w	ramLastCoins(a6),d2
		beq.s	@dontupdc
		move.w	d2,ramLastCoins(a6)
		bsr	HexToDec
		move.w	d2,ramDecCoins(a6)
@dontupdc:
		move.l	#24<<16|16,d0
		move.w	ramDecCoins(a6),d2
		bsr	@showsprval
		
		moveq	#0,d2
		move.w	(RAM_P1_Lives),d2
		cmp.w	ramLastLives(a6),d2
		beq.s	@dontupdlvs
		move.w	d2,ramLastLives(a6)
		bsr	HexToDec
		move.w	d2,ramDecLives(a6)
@dontupdlvs:
		move.l	#24<<16|32,d0
		move.w	ramDecLives(a6),d2
		
; -----------------------------

@showsprval:
		moveq	#1,d3
		ror.l	#4,d2
@nxtcoinnum:
		moveq	#0,d1
		move.b	d2,d1
		and.b	#$F,d1
		add.w	#varHudDigits,d1
		rol.l	#4,d2
		add.l	#$00080000,d0
		bsr	Object_ExtSprite	
		dbf	d3,@nxtcoinnum
		rts
		
; =================================================================
		
