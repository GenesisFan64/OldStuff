; ====================================================================
; -------------------------------------------------
; VBlank
; 
; all registers available
; -------------------------------------------------

MD_Vint:
		tst.l	(RAM_VIntAddr)
		beq.s	@NoVIntEx
		
		movem.l	a0-a6/d0-d7,-(sp)
		movea.l	(RAM_VIntAddr),a0
		jsr	(a0)
		movem.l	(sp)+,a0-a6/d0-d7
@NoVIntEx:
		bset	#1,(RAM_VIntWait)
		bclr	#bitFrameWait,(RAM_VIntWait)
		rte

; ====================================================================
; -------------------------------------------------
; HBlank
; 
; ONLY available registers:
; a0-a3
; d0-d4
; -------------------------------------------------

MD_Hint:		
 		tst.l	(RAM_HIntAddr)
 		beq.s	@NoHintEx
 		
 		movem.l	a0-a3/d0-d4,-(sp)
 		movea.l	(RAM_HIntAddr),a0
 		jsr	(a0)
 		movem.l	(sp)+,a0-a3/d0-d4
@NoHintEx:
		rte
		
; ====================================================================
; -------------------------------------------------
; Separate routines
; -------------------------------------------------

VInt_Default:
		bsr	PalFade
		bsr	Pads_Read
		bsr	DMA_Read
; 		bsr	SMEG_Upd
			
		lea	(RAM_PalBuffer),a0
 		move.l	#$C0000000,($C00004).l
 		move.w	#$3F,d0
@PalBuf:
		move.w	(a0)+,($C00000).l
 		dbf	d0,@PalBuf

		lea	(RAM_SprBuffer),a0
		move.l	#$78000003,($C00004).l
		move.w	#$9F,d0
@SprBuf:
		move.l	(a0)+,($C00000).l
		dbf	d0,@SprBuf
		
		lea	(RAM_VerBuffer),a0
		move.l	#$40000010,($C00004).l
		move.w	#$F,d0
@VerBuf:
		move.l	(a0)+,($C00000).l
		dbf	d0,@VerBuf

		lea	(RAM_HorBuffer),a0
		move.l	#$7C000003,($C00004).l
		move.w	#224-1,d0
@HorBuf:
		move.l	(a0)+,($C00000).l
		dbf	d0,@HorBuf

		rts

; -------------------------------------------------

Hint_Default:
		rts
