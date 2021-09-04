; =====================================================
; RAM
; =====================================================

 			if SegaCD
 			if CD_PrgRamMode	
 			rsset $200000+$2A000 		;CD: PRG-RAM
 			else
 			rsset $FFFFA000			;CD: WordRAM
 			endif
 			else
			rsset $FFFFA000			;MD/32X RAM
 			endif
		
; =====================================================
; ----------------------------------------
; Variables
; ----------------------------------------

sizeof_dmabuff		equ	$400

bitFrameWait		equ	0
bitVBlankWait		equ	1
bitHBlankWait		equ	2
bitDontWaitHInt		equ	3
bitLockPads		equ	4
bitHotStart		equ	5

; ----------------------------------------
; Game vars
; ----------------------------------------


; =====================================================
; ----------------------------------------
; Mode buffer
; ----------------------------------------

RAM_ModeBuffer		rs.b	$3000

; ----------------------------------------
; Work stuff
; ----------------------------------------

RAM_VIntAddr		rs.l	1
RAM_HIntAddr		rs.l	1
RAM_VIntWait		rs.b 	1
RAM_GameMode		rs.b 	1
RAM_Joypads		rs.b	$80

; ----------------------------------------
; Sound
; ----------------------------------------

RAM_SndDriver		rs.b	$400

; ----------------------------------------
; DMA
; ----------------------------------------

RAM_DMA_Buffer		rs.b	sizeof_dmabuff

; ----------------------------------------
; PalFade
; ----------------------------------------

RAM_RunFadeCol		rs.w	$10
RAM_PalFadeBuff		rs.w	64
RAM_PalFadeBuffHint	rs.w	64

; ----------------------------------------
; Visual stuff
; ----------------------------------------

RAM_HorBuffer		rs.l	224
RAM_VerBuffer		rs.l	$20
RAM_SprBuffer		rs.b	(8*80)
RAM_PalBuffer		rs.w	64

RAM_VerBufferHint	rs.l	$20
RAM_SprBufferHint	rs.l	(8*80)
RAM_PalBufferHint	rs.w	64
RAM_VdpRegs		rs.b	$18

; =====================================================
; ----------------------------------------
; Last RAM
; ----------------------------------------

RAM_End			rs.b	0
;                        	inform 0,"RAM ENDS AT: %h",RAM_End