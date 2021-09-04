; ====================================================================
; Main engine at RAM
; ====================================================================

; ====================================================================
; -------------------------------------------------
; Call routines from anywhere in MCD
; -------------------------------------------------

		jmp	(MD_Vint).l
		jmp	(MD_Hint).l
		jmp	(SubCpu_Task_Wait).l
		jmp	(SubCpu_Task).l
		jmp	(SubCpu_Wait).l
		jmp	(SubCpu_Wait_Flag).l
		jmp	(Input_Read).l
		jmp	$FFFF0000
		
; ====================================================================
; -------------------------------------------------
; Engine Main loop
; -------------------------------------------------

MD_Main:
 		move.w	#$2700,sr
		bsr	System_Init		; init System
		bsr	Video_Init		; init Video
		bsr	Audio_Init		; init Audio
 		bsr	Input_Init		; init Input devices
		
; -------------------------------------------------

 		clr.b	(RAM_GameMode)
 		move.w	#$2000,sr
		
@LOOP:
		moveq	#0,d0
 		move.b	(RAM_GameMode),d0
 		lsl.w	#4,d0
		lea	mode_list(pc),a0
  		move.l	4(a0,d0.w),d1
  		move.l	8(a0,d0.w),d2
  		move.l	(a0,d0.w),d0
  		bsr	Load_PrgWord
  		jsr	($200000)
 		
		bra.s	@LOOP
		
Return:
		rts
		
; ====================================================================
; -------------------------------------------------
; Data
; -------------------------------------------------

mode_list:
		dc.b	"PRG_TITL.BIN"
		dc.w	0,0
		dc.b	"PRG_LEVL.BIN"
		dc.w	0,0
		
; ====================================================================
; -------------------------------------------------
; Subs
; -------------------------------------------------

		include	"system/video.asm"
		include	"system/sound/68k/main.asm"
		include	"system/misc.asm"
		include	"system/input/code.asm"
		include	"system/hardware/mcd/m68k/comm/main.asm"
		include	"system/ints.asm"
