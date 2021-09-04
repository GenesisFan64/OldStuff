; ====================================================================
; -------------------------------------------------
; Variables
; -------------------------------------------------

bitFrameWait		equ	0
bitVBlankWait		equ	1
bitHBlankWait		equ	2
bitDontWaitHInt		equ	3
bitLockPads		equ	4
bitHotStart		equ	5
bitVerDir		equ	6

; -------------------------------------------------
; RAM
; -------------------------------------------------

			rsset 0C000h
ram_modebuffer		rb 800h
ram_sprbuffer		rb 100h

ram_vintjmpto		rb 1
ram_vintaddr		rw 1
ram_hintjmpto		rb 1
ram_hintaddr		rw 1

ram_vintwait		rb 1
ram_vdpregs		rb 0Ah
ram_runfadecol		rb 10h
ram_joypads		rb 8
ram_gamemode		rb 1

ram_vscroll		rw 1			;now a WORD
ram_hscroll		rw 1

ram_sounddriver		rb 0FFh
ram_palbuffer		rb 32*2
ram_palfadebuff		rb 32*2
ram_sprcontrol		rb 10h

ram_tilestovdp		rb 800h

ram_end			rb 0
; 			inform 0,"RAM ENDS AT: %h",ram_end
