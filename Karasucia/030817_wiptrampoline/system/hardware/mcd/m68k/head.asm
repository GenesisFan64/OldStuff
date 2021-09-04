; ========================================================
;  Sega CD Program
; ========================================================

		dc.b "SEGADISCSYSTEM  "		; Disc Type (Must be SEGADISCSYSTEM)
		dc.b "KARASUCIA01",0		; Disc ID
		dc.w $100,1			; System ID, Type
		dc.b "KARA-SYS   ",0		; System Name
		dc.w 0,0			; System Version, Type
		dc.l IP_Start
		dc.l IP_End
		dc.l 0
		dc.l 0
		dc.l SP_Start
		dc.l SP_End
		dc.l 0
		dc.l 0

		align $100			; Pad to $100
		dc.b "SEGA MEGA DRIVE "
		dc.b "(C)GF64 2016.???"
		dc.b "Las aventuras de Dominoe                        "
                dc.b "Dominoe Adventures                              "
		dc.b "GM HOMEBREW-00  "
		dc.b "J               "
		
		align $1F0
		dc.b "U               "

; ========================================================
; -------------------------------------------------
; IP
; -------------------------------------------------

		incbin "system/hardware/mcd/m68k/region/usa.bin"

		bra	IP_Start
		align $800
IP_Start:
		include "system/hardware/mcd/m68k/boot.asm"
		align $800
IP_End:
		even
		
; ========================================================
; -------------------------------------------------
; SP
; -------------------------------------------------

		align $800
SP_Start:
		include "system/hardware/mcd/s68k/code.asm"
		align $800
SP_End:
		even
 		
; ========================================================
