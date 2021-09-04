; ====================================================================
; --------------------------------------------
; Include
; --------------------------------------------

		include	"system/macros.asm"
		include	"system/ram.asm"
		include	"engine/ram.asm"
		include	"system/hardware/map.asm"
		
; ====================================================================
; -------------------------------------------------
; Level
; 
; MEGA CD ONLY
; -------------------------------------------------

		obj $200000
    		move.l	#RAM_HintJumpTo,($FFFFFD0E)
    		move.l	#RAM_VintJumpTo,($FFFFFD08)
		jmp	MD_Main
		
; ====================================================================
; -------------------------------------------------
; Subs
; -------------------------------------------------

		include	"system/video.asm"
		include	"system/sound/68k/main.asm"
		include	"system/misc.asm"
		include	"system/input/map.asm"
		include	"system/hardware/mcd/m68k/comm/calls.asm"
		
; ====================================================================
; --------------------------------------------
; Code
; --------------------------------------------

MD_Main:
		include	"engine/modes/level/md.asm"
		
; ====================================================================		
; --------------------------------------------
; Data
; --------------------------------------------

		include	"engine/modes/level/data.asm"
		
		;SOLO PARA MCD
Art_DebugFont:	incbin "engine/shared/dbgfont.bin"
Art_DebugFont_e:
                even

; ====================================================================	

		inform 0,"LEVEL MODE ROM uses: %h",*-$200000
		objend
		align $40000
