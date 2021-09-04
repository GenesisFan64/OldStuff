; ====================================================================
; -------------------------------------------------
; Game Gear / Master System
; -------------------------------------------------

		include "incl/macros.asm"
		include "ram.asm"
		
; ====================================================================
; -------------------------------------------------
; Game starts
; -------------------------------------------------

		org     0
		di				; disable interrupts
		im      1
		ld      sp,0DFF8h
		jp      Init

; ====================================================================
; -------------------------------------------------
; IRQ
; -------------------------------------------------

		include "ints.asm"
		
; ====================================================================
; -------------------------------------------------
; Subs
; -------------------------------------------------

		include "subs/vdp.asm"
		include "subs/misc.asm"
		include "subs/fade.asm"
		include "subs/pads.asm"
		
; ====================================================================
; -------------------------------------------------
; Init
; -------------------------------------------------

Init:
		call    initsys			; init I/O ports and bank registers
		call    VDP_Init		; init VDP and VRAM
		call	SMEG_Init
		
		ld	a,0C3h			; JMP @here
		ld	(ram_vintjmpto),a
		ld	(ram_hintjmpto),a
		ld	bc,VBlank_Default
		ld	(ram_vintaddr),bc
		ld	bc,HBlank_Default
		ld	(ram_hintaddr),bc
		ei
		
@MainLoop:
		ld	a,(ram_gamemode)
		sla	a
		sla	a
		sla	a
		ld	bc,0
		ld	c,a
		ld	hl,@modes_list
 		add 	hl,bc
		jp	(hl)
	
; -------------------------------------------------

@modes_list:
		call	segalogo
		jp	@MainLoop
		nop
		nop
		call	Level
		jp	@MainLoop
		nop
		nop
		
; ====================================================================
; -------------------------------------------------
; Modes
; -------------------------------------------------

		include "modes/title/code.asm"
		include "modes/level/code.asm"		
		
; ====================================================================
; -------------------------------------------------
; Sound
; -------------------------------------------------

 		include "sound/code.asm"
 		include "sound/data.asm"
 		
; ====================================================================

		inform 0,"CODE Size: %h",*
    		cnop 0,4000h
    		
; ====================================================================
; -------------------------------------------------
; Data | SLOT 2
; 
; Header at the end
; -------------------------------------------------

 		cnop 0,7FF0h
 		db "TMR SEGA",0,0		; TMR SEGA + unused
 		dw 0				; Checksum
 		db 0,0				; Product code + PCode|Version
 		db 0,0				; Version + Region code|ROM size
 		
; ====================================================================
; -------------------------------------------------
; Data | SLOT 3
; 
; TO-DO: This can be used as extra RAM
; -------------------------------------------------

    		cnop 0,0C000h
    		
; ====================================================================
; -------------------------------------------------
; DATA BANKS for Slot 2
; -------------------------------------------------

; -----------------------
; Title Screen
; -----------------------

BANK_Title:	obj 4000h
		include "modes/title/data.asm"
    		objend
    		inform 0,"BANK Title size: %h",(*-BANK_Title)
    		cnop 0,4000h

; -----------------------
; Level
; -----------------------

BANK_LvlMd_Init:
		obj 4000h
		include "modes/level/data_1.asm"
    		objend
    		inform 0,"BANK Level (init) size: %h",(*-BANK_LvlMd_Init)
    		cnop 0,4000h

BANK_LvlMd_Loop:
		obj 4000h
		include "modes/level/data_2.asm"
    		objend
    		inform 0,"BANK Level (loop) size: %h",(*-BANK_LvlMd_Loop)
    		cnop 0,4000h
    		
; ====================================================================

; thisaddr = 0
; BANK_WAVE:
;      		rept 110
;      		obj 4000h
;     		incbin "sound/data/pcm/new.raw",thisaddr,4000h
;  ;    		cnop 0,4000h
;     		objend
; thisaddr = thisaddr+4000h
;     		endr
    		
; ====================================================================

		inform 0,"ROM Size: %h",*
		cnop 0,10000h
		
		