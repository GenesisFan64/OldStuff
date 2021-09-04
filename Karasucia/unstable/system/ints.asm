; ====================================================================
; -------------------------------------------------
; VBlank
; -------------------------------------------------

MD_Vint:
 		btst	#7,(RAM_IntFlags)
 		bne	@nope
 		bset	#7,(RAM_IntFlags)
		movem.l	a0-a6/d0-d7,(RAM_VIntRegs)
		
		move.w	(vdp_ctrl),d0
		btst	#0,d0
		beq.s	@JapAme
		move.w	#$6BC,d0
		dbf	d0,*
@JapAme:

 		bsr	Input_Read
		bsr	PalFade_Upd
		bsr	DMA_Read
		
 		dmaTask	RAM_Palette,$C0000000,$80
 		dmaTask	RAM_ScrlHor,$7C000003,$400
 		dmaTask	RAM_ScrlVer,$40000010,$50
 		dmaTask	RAM_Sprites,$78000003,$280
		
 		bsr	Audio_run			; NO MOVERLO
		movem.l	(RAM_VIntRegs),a0-a6/d0-d7
 		bset	#1,(RAM_IntFlags)		; VBlank done flag
 		bclr	#7,(RAM_IntFlags)
 
@nope:
 		bclr	#0,(RAM_IntFlags)		; Frame done flag
		rte
 		
; ====================================================================
; -------------------------------------------------
; HBlank
; -------------------------------------------------

MD_HInt:
		rte
