; ====================================================================
; Main engine
; ====================================================================

		include	"engine/ram.asm"

; ====================================================================
; -------------------------------------------------
; Engine Main loop
; -------------------------------------------------

MD_Main:
		bsr	System_Init		; init System
		bsr	Audio_Init		; init Audio
		bsr	Video_Init		; init Video
 		bsr	Input_Init		; init Input

; -------------------------------------------------

 		move.w	#$2000,sr
Main_Loop:
		moveq	#0,d0
		move.b	(RAM_GameMode),d0
		lsl.w	#2,d0
		movea.l	@list(pc,d0.w),a0
		jsr	(a0)
		
		bra.s	Main_Loop
		
; ====================================================================
; -------------------------------------------------
; Data
; -------------------------------------------------

@list:
		dc.l	mode_Title
		dc.l	mode_Level
		dc.l	mode_Title
		dc.l	mode_Title
		dc.l	mode_Title
		dc.l	mode_Title
		dc.l	mode_Title
		dc.l	mode_Title
		even
		
; ====================================================================
; -------------------------------------------------
; Default interrupts
; -------------------------------------------------

		include	"system/ints.asm"
		
; ====================================================================
; -------------------------------------------------
; CODE
; -------------------------------------------------

		;obj already set in MARS
		include	"engine/modes/title/md.asm"
		include "engine/modes/level/md.asm"
		
		if MARS
		inform 0,"MARS IPL ends at: %h",*-marsipl
		endif
		romSectionEnd
	
; ====================================================================
; -------------------------------------------------
; DATA
; -------------------------------------------------

		romSection DATA
THIS_BANK_1:
		include	"engine/modes/title/data.asm"
		include "engine/modes/level/data.asm"
		
		if MARS
		inform 0,"This 68k BANK uses: %h",*-THIS_BANK_1
		endif
		romSectionEnd
