; ====================================================================
; -------------------------------------------------
; MACROS
; -------------------------------------------------

; -------------------------------------------------
; Slot 2 bankswitch
; -------------------------------------------------

bankdata macro LABEL
	ld	a,(LABEL>>14)&0FFh
	ld      (0FFFEh),a
	endm