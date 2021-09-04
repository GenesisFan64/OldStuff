; ====================================================================
; -------------------------------------------------
; Start
; -------------------------------------------------

MD_Main:
		move.w	#$2700,sr
		
		move.l	#VInt_Default,(RAM_VIntAddr)
		move.l	#Hint_Default,(RAM_HIntAddr)
		clr.b	(RAM_VIntWait)
		clr.l	(RAM_DMA_Buffer)
		
		bsr	Vdp_Init
		bsr	Pads_Init
		bsr	Z80_Init
		
		move.w	#$2000,sr
		
		move.l	#ID_FadeOut,d0
 		move.l	#$003F0001,d1
 		bsr	PalFade_Set
 		bsr	PalFade_Wait
 		
; -------------------------------------------------
; Modes
; -------------------------------------------------

@RunMode:
                moveq	#0,d0
                move.b	(RAM_GameMode),d0
                lsl.w	#2,d0
                and.w	#%11111100,d0
                lea	GameModes(pc),a0
                movea.l	(a0,d0.w),a0
                jsr	(a0)
                bra.s	@RunMode