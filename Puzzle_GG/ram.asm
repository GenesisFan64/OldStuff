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
ram_modebuffer		rb 100h
ram_sounddriver		rb 0FFh
ram_palbuffer		rb 32*2
ram_palfadebuff		rb 32*2
ram_sprbuffer		rb 100h

ram_vscroll		rb 1
ram_hscroll		rb 1
ram_vintwait		rb 1
ram_vintframes		rb 1
ram_runfadecol		rb 10h
ram_temporal		rb 8
ram_joypads		rb 8
ram_gamemode		rb 1

; 			inform 0,"%h",ram_sounddriver

